#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# Native installer for this repo. Ubuntu 24.04 (noble) only.
#
#   ./scripts/install.sh          phase 1: ROS 2 Jazzy            <- start here
#   ./scripts/install.sh 2        phase 2: simulation (Gazebo Harmonic, ros2_control, robot models)
#   ./scripts/install.sh 3        phase 3: navigation, SLAM, real sensors
#   ./scripts/install.sh 4        phase 4: drones (MAVROS + ArduPilot SITL, long build)
#   ./scripts/install.sh all      everything
#
# Safe to re-run: steps that are already done are skipped.
# Different OS or Ubuntu version? Use the Docker setup instead: ./docker/run.sh
# ---------------------------------------------------------------------------
set -euo pipefail

ROS_DISTRO=jazzy
ARDUPILOT_TAG=Copter-4.7.0
ARDUPILOT_DIR="$HOME/ardupilot"
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
NEED_RELOGIN=0

step() { printf '\n\033[1;34m==> %s\033[0m\n' "$*"; }
info() { printf '    %s\n' "$*"; }
die()  { printf '\n\033[1;31mERROR: %s\033[0m\n' "$*" >&2; exit 1; }

# Append a line to ~/.bashrc only if it isn't there yet
add_to_bashrc() {
  if ! grep -qxF -- "$1" "$HOME/.bashrc" 2>/dev/null; then
    echo "$1" >> "$HOME/.bashrc"
    info "added to ~/.bashrc: $1"
  fi
}

# ---------------------------------------------------------------- checks ---
if [[ $EUID -eq 0 ]]; then
  die "Don't run this with sudo. Run it as your normal user; it asks for your password when it needs it."
fi
# shellcheck source=/dev/null
. /etc/os-release
if [[ "${VERSION_CODENAME:-}" != "noble" ]]; then
  die "This installer is for Ubuntu 24.04 (noble); this machine is ${PRETTY_NAME:-unknown}. Use ./docker/run.sh instead."
fi
ARCH="$(dpkg --print-architecture)"
if [[ "$ARCH" != "amd64" && "$ARCH" != "arm64" ]]; then
  die "ROS 2 Jazzy packages exist for amd64 and arm64 only (this is $ARCH)."
fi

# ----------------------------------------------------------- arguments ---
declare -A RUN=()
if [[ $# -eq 0 ]]; then RUN[1]=1; fi
for arg in "$@"; do
  case "$arg" in
    1|2|3|4) RUN[$arg]=1 ;;
    all)     RUN[1]=1; RUN[2]=1; RUN[3]=1; RUN[4]=1 ;;
    -h|--help) sed -n '2,13p' "$0"; exit 0 ;;
    *) die "Unknown option '$arg'. Use 1, 2, 3, 4 or all." ;;
  esac
done
RUN[1]=1   # every phase builds on phase 1; already-installed parts are skipped quickly

# --------------------------------------------------------------- phase 1 ---
phase1() {
  step "Phase 1 · base tools"
  sudo apt-get update
  sudo apt-get install -y software-properties-common curl git build-essential \
                          python3-pip python3-venv locales

  step "Phase 1 · UTF-8 locale"
  if locale 2>/dev/null | grep -qi 'utf-8'; then
    info "already UTF-8"
  else
    sudo locale-gen en_US en_US.UTF-8
    sudo update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8
    export LANG=en_US.UTF-8
  fi

  step "Phase 1 · Ubuntu 'universe' repository"
  sudo add-apt-repository -y universe
  local sources=/etc/apt/sources.list.d/ubuntu.sources
  if [[ -f "$sources" ]]; then
    if ! grep -Eq '^Suites:.*noble-updates' "$sources" || ! grep -Eq '^Suites:.*noble-backports' "$sources"; then
      die "$sources is missing noble-updates or noble-backports. Edit its first 'Suites:' line to read
       Suites: noble noble-updates noble-backports
       then run: sudo apt clean && sudo apt update && sudo apt full-upgrade -y   and re-run this script."
    fi
  fi

  step "Phase 1 · ROS 2 apt repository (ros2-apt-source)"
  if dpkg -s ros2-apt-source >/dev/null 2>&1; then
    info "already configured"
  else
    local ver
    ver="$(curl -fsSL https://api.github.com/repos/ros-infrastructure/ros-apt-source/releases/latest \
           | grep -F '"tag_name"' | awk -F'"' '{print $4}')" || true
    if [[ -z "$ver" ]]; then
      die "Couldn't get the latest ros-apt-source version from GitHub (no internet, or GitHub's API limit - wait a few minutes and re-run)."
    fi
    curl -fL -o /tmp/ros2-apt-source.deb \
      "https://github.com/ros-infrastructure/ros-apt-source/releases/download/${ver}/ros2-apt-source_${ver}.${UBUNTU_CODENAME:-$VERSION_CODENAME}_all.deb"
    sudo apt-get install -y /tmp/ros2-apt-source.deb
  fi

  step "Phase 1 · ROS 2 ${ROS_DISTRO} desktop + developer tools (big download)"
  sudo apt-get update
  sudo apt-get upgrade -y
  sudo apt-get install -y "ros-${ROS_DISTRO}-desktop" ros-dev-tools

  step "Phase 1 · rosdep (installs dependencies for ROS packages)"
  if [[ ! -f /etc/ros/rosdep/sources.list.d/20-default.list ]]; then
    sudo rosdep init
  fi
  rosdep update

  step "Phase 1 · load ROS automatically in every new terminal"
  add_to_bashrc "source /opt/ros/${ROS_DISTRO}/setup.bash"
  add_to_bashrc '[ -f /usr/share/colcon_argcomplete/hook/colcon-argcomplete.bash ] && source /usr/share/colcon_argcomplete/hook/colcon-argcomplete.bash'
  add_to_bashrc "[ -f \"$REPO_DIR/ros2_ws/install/setup.bash\" ] && source \"$REPO_DIR/ros2_ws/install/setup.bash\""
}

# --------------------------------------------------------------- phase 2 ---
phase2() {
  step "Phase 2 · simulation: Gazebo Harmonic (via ros_gz), robot models, ros2_control, vision"
  sudo apt-get install -y \
    "ros-${ROS_DISTRO}-ros-gz" \
    "ros-${ROS_DISTRO}-xacro" \
    "ros-${ROS_DISTRO}-joint-state-publisher-gui" \
    "ros-${ROS_DISTRO}-ros2-control" "ros-${ROS_DISTRO}-ros2-controllers" "ros-${ROS_DISTRO}-gz-ros2-control" \
    "ros-${ROS_DISTRO}-teleop-twist-keyboard" "ros-${ROS_DISTRO}-rqt-robot-steering" \
    "ros-${ROS_DISTRO}-cv-bridge" "ros-${ROS_DISTRO}-image-transport-plugins" python3-opencv \
    "ros-${ROS_DISTRO}-plotjuggler-ros"
  add_to_bashrc 'export GZ_VERSION=harmonic'
}

# --------------------------------------------------------------- phase 3 ---
phase3() {
  step "Phase 3 · navigation (Nav2), SLAM, localization, TurtleBot3 examples, real sensors"
  sudo apt-get install -y \
    "ros-${ROS_DISTRO}-navigation2" "ros-${ROS_DISTRO}-nav2-bringup" \
    "ros-${ROS_DISTRO}-slam-toolbox" "ros-${ROS_DISTRO}-robot-localization" \
    "ros-${ROS_DISTRO}-turtlebot3" "ros-${ROS_DISTRO}-turtlebot3-simulations" \
    "ros-${ROS_DISTRO}-rplidar-ros" "ros-${ROS_DISTRO}-usb-cam" "ros-${ROS_DISTRO}-v4l2-camera"

  step "Phase 3 · serial port access (Arduino, STM32, RPLIDAR)"
  if id -nG "$USER" | grep -qw dialout; then
    info "already in the 'dialout' group"
  else
    sudo usermod -aG dialout "$USER"
    NEED_RELOGIN=1
  fi
}

# --------------------------------------------------------------- phase 4 ---
phase4() {
  step "Phase 4 · MAVROS (bridge between ROS 2 and MAVLink autopilots)"
  sudo apt-get install -y "ros-${ROS_DISTRO}-mavros" "ros-${ROS_DISTRO}-mavros-extras"
  sudo "/opt/ros/${ROS_DISTRO}/lib/mavros/install_geographiclib_datasets.sh"

  step "Phase 4 · ArduPilot ${ARDUPILOT_TAG} source code -> $ARDUPILOT_DIR"
  if [[ -d "$ARDUPILOT_DIR/.git" ]]; then
    info "already there"
  else
    git clone --branch "$ARDUPILOT_TAG" --recurse-submodules https://github.com/ArduPilot/ardupilot.git "$ARDUPILOT_DIR"
  fi

  step "Phase 4 · ArduPilot prerequisites (ArduPilot's own script; creates ~/venv-ardupilot)"
  ( cd "$ARDUPILOT_DIR" \
    && DO_AP_STM_ENV=0 DO_PYTHON_VENV_ENV=0 SKIP_AP_GIT_CHECK=1 \
       Tools/environment_install/install-prereqs-ubuntu.sh -y )

  step "Phase 4 · build ArduCopter for SITL (simulation) - this takes a while"
  # shellcheck source=/dev/null
  ( cd "$ARDUPILOT_DIR" \
    && source "$HOME/venv-ardupilot/bin/activate" \
    && ./waf configure --board sitl \
    && ./waf copter )

  add_to_bashrc "export PATH=\"$ARDUPILOT_DIR/Tools/autotest:\$PATH\""
  add_to_bashrc "alias apenv='source \$HOME/venv-ardupilot/bin/activate'"
}

# ------------------------------------------------------------------- run ---
for p in 1 2 3 4; do
  if [[ -n "${RUN[$p]:-}" ]]; then "phase$p"; fi
done

step "Done"
info "Open a NEW terminal (or run: source ~/.bashrc), then check with: ./scripts/check.sh"
if [[ $NEED_RELOGIN -eq 1 ]]; then
  info "You were added to the 'dialout' group - log out and back in once so serial ports work."
fi
