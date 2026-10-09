#!/usr/bin/env bash
# Checks what's installed and working. Safe to run any time; changes nothing.
#   ./scripts/check.sh
set -o pipefail

ROS_DISTRO=jazzy
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FAIL=0
ok()   { printf '  \033[32m[ok]\033[0m   %s\n' "$*"; }
bad()  { printf '  \033[31m[fail]\033[0m %s\n' "$*"; FAIL=1; }
skip() { printf '  \033[33m[--]\033[0m   %s\n' "$*"; }
has_pkg() { ros2 pkg prefix "$1" >/dev/null 2>&1; }

echo "Phase 1 · ROS 2 basics"
if [[ -f /opt/ros/$ROS_DISTRO/setup.bash ]]; then
  # shellcheck source=/dev/null
  source "/opt/ros/$ROS_DISTRO/setup.bash"
  ok "ROS 2 $ROS_DISTRO installed"
else
  bad "ROS 2 $ROS_DISTRO not found -> ./scripts/install.sh"
  exit 1
fi
if grep -q "/opt/ros/$ROS_DISTRO/setup.bash" "$HOME/.bashrc" 2>/dev/null || [[ -f /.dockerenv ]]; then
  ok "new terminals load ROS automatically"
else
  bad "your .bashrc doesn't source ROS -> ./scripts/install.sh"
fi
if has_pkg demo_nodes_cpp && has_pkg demo_nodes_py; then ok "demo talker/listener available"; else bad "demo nodes missing (ros-$ROS_DISTRO-desktop)"; fi
if command -v colcon >/dev/null; then ok "colcon (build tool)"; else bad "colcon missing (ros-dev-tools)"; fi
if command -v rosdep >/dev/null; then ok "rosdep"; else bad "rosdep missing (ros-dev-tools)"; fi
if python3 -c "import rclpy" 2>/dev/null; then ok "Python can import rclpy"; else bad "Python can't import rclpy"; fi

echo "Phase 2 · simulation"
if has_pkg ros_gz_sim; then
  ok "ros_gz (Gazebo bridge)"
  if gz sim --versions >/dev/null 2>&1; then ok "Gazebo $(gz sim --versions 2>/dev/null | head -1)"; else bad "'gz sim' command not working"; fi
  for p in xacro gz_ros2_control controller_manager teleop_twist_keyboard cv_bridge; do
    if has_pkg "$p"; then ok "$p"; else bad "$p missing -> ./scripts/install.sh 2"; fi
  done
else
  skip "not installed yet -> ./scripts/install.sh 2"
fi

echo "Phase 3 · navigation & sensors"
if has_pkg nav2_bringup; then
  for p in slam_toolbox robot_localization rplidar_ros usb_cam turtlebot3_gazebo; do
    if has_pkg "$p"; then ok "$p"; else bad "$p missing -> ./scripts/install.sh 3"; fi
  done
  if id -nG "$USER" | grep -qw dialout; then ok "serial port access (dialout group)"; else bad "not in 'dialout' group (log out/in after install)"; fi
else
  skip "not installed yet -> ./scripts/install.sh 3"
fi

echo "Phase 4 · drones"
if has_pkg mavros; then ok "MAVROS"; else skip "MAVROS not installed yet -> ./scripts/install.sh 4"; fi
if [[ -x "$HOME/ardupilot/build/sitl/bin/arducopter" ]]; then
  ok "ArduCopter SITL built (~/ardupilot)"
else
  skip "ArduPilot SITL not built yet -> ./scripts/install.sh 4"
fi

echo "Extras"
if [[ -x "$REPO_DIR/.venv/bin/python" ]]; then ok ".venv for extra pip libraries"; else skip ".venv not created -> ./scripts/setup-venv.sh"; fi

echo
if [[ $FAIL -eq 0 ]]; then echo "All installed parts look good."; else echo "Some checks failed - see [fail] lines above."; fi
exit $FAIL
