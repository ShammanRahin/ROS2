#!/usr/bin/env bash
# Creates .venv in the repo for extra pip libraries (requirements.txt).
# It uses --system-site-packages, so ROS 2's Python packages (rclpy, cv_bridge, ...) stay visible.
#   ./scripts/setup-venv.sh
#   source .venv/bin/activate
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VENV="$REPO_DIR/.venv"

if ! dpkg -s python3-venv >/dev/null 2>&1; then
  sudo apt-get install -y python3-venv
fi

python3 -m venv --system-site-packages "$VENV"
touch "$VENV/COLCON_IGNORE"   # keeps colcon from scanning the venv
"$VENV/bin/pip" install --upgrade pip
"$VENV/bin/pip" install -r "$REPO_DIR/requirements.txt"

echo
echo "Done. Activate it with:  source $VENV/bin/activate"
