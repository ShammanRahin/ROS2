#!/usr/bin/env bash
# Runs this repo's dev environment in Docker (any Linux with Docker; Windows via WSL2).
#   ./docker/run.sh              build the image if needed, then open a shell inside
#   ./docker/run.sh --rebuild    rebuild the image (after editing docker/Dockerfile)
#   ./docker/run.sh --ardupilot  use the bigger image that also has ArduPilot SITL
# Run it again while the container is running to get a second terminal in it.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
NAME=ros2-dev
IMAGE=ros2-dev:jazzy
WITH_ARDUPILOT=0
REBUILD=0

for arg in "$@"; do
  case "$arg" in
    --rebuild)   REBUILD=1 ;;
    --ardupilot) WITH_ARDUPILOT=1; IMAGE=ros2-dev:jazzy-ardupilot ;;
    -h|--help)   sed -n '2,6p' "$0"; exit 0 ;;
    *) echo "Unknown option: $arg (try --help)" >&2; exit 1 ;;
  esac
done

if ! command -v docker >/dev/null; then
  echo "Docker isn't installed. Install it first: https://docs.docker.com/engine/install/" >&2
  exit 1
fi
if ! docker info >/dev/null 2>&1; then
  echo "Docker is installed but not reachable. Either it isn't running (start Docker Desktop / 'sudo systemctl start docker')," >&2
  echo "or your user isn't allowed to use it: sudo usermod -aG docker \$USER   then log out and back in." >&2
  exit 1
fi

# Already running? Open another shell in the same container.
if docker ps --format '{{.Names}}' | grep -qx "$NAME"; then
  exec docker exec -it "$NAME" bash
fi

if [[ $REBUILD -eq 1 ]] || ! docker image inspect "$IMAGE" >/dev/null 2>&1; then
  docker build -t "$IMAGE" \
    --build-arg USER_UID="$(id -u)" --build-arg USER_GID="$(id -g)" \
    --build-arg WITH_ARDUPILOT="$WITH_ARDUPILOT" \
    -f "$REPO_DIR/docker/Dockerfile" "$REPO_DIR/docker"
fi

args=(
  --rm -it --name "$NAME"
  --net=host --ipc=host                       # ROS 2 nodes inside and outside can see each other
  -e DISPLAY="${DISPLAY:-:0}" -e QT_X11_NO_MITSHM=1
  -v /tmp/.X11-unix:/tmp/.X11-unix:rw          # GUI windows (Gazebo, RViz) on your desktop
  -v "$REPO_DIR":/home/dev/ROS2
  -w /home/dev/ROS2
)

# Allow local containers to open windows on this display
if command -v xhost >/dev/null && [[ -n "${DISPLAY:-}" ]]; then
  xhost +local: >/dev/null || true
fi

# GPU acceleration (Intel/AMD; NVIDIA needs the NVIDIA Container Toolkit + --gpus all)
if [[ -d /dev/dri ]]; then
  args+=(--device /dev/dri)
  for g in video render; do
    gid="$(getent group "$g" | cut -d: -f3 || true)"
    if [[ -n "$gid" ]]; then args+=(--group-add "$gid"); fi
  done
fi

# Windows WSL2 (WSLg) display support
if [[ -d /mnt/wslg ]]; then
  args+=(-v /mnt/wslg:/mnt/wslg -e WAYLAND_DISPLAY -e XDG_RUNTIME_DIR -e PULSE_SERVER)
fi

# USB serial devices (Arduino, STM32, RPLIDAR) that are plugged in right now
for dev in /dev/ttyUSB* /dev/ttyACM*; do
  if [[ -e "$dev" ]]; then args+=(--device "$dev"); fi
done

exec docker run "${args[@]}" "$IMAGE" bash
