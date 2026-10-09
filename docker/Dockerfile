# Portable dev environment for this repo:
# ROS 2 Jazzy + Gazebo Harmonic + every package used in phases 1-4.
# Build and run it with ./docker/run.sh (or VS Code "Reopen in Container").
FROM osrf/ros:jazzy-desktop-full

ARG USERNAME=dev
ARG USER_UID=1000
ARG USER_GID=1000
ARG WITH_ARDUPILOT=0
ARG ARDUPILOT_TAG=Copter-4.7.0

ENV DEBIAN_FRONTEND=noninteractive \
    GZ_VERSION=harmonic \
    QT_QPA_PLATFORM=xcb
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# desktop-full already has ROS 2 desktop, perception and Gazebo Harmonic (ros_gz).
# These are the extra packages for phases 2-4 (same list as scripts/install.sh).
RUN apt-get update && apt-get install -y \
      sudo git curl wget nano less bash-completion \
      python3-pip python3-venv python3-opencv \
      mesa-utils libgl1-mesa-dri \
      ros-dev-tools \
      ros-${ROS_DISTRO}-xacro ros-${ROS_DISTRO}-joint-state-publisher-gui \
      ros-${ROS_DISTRO}-ros2-control ros-${ROS_DISTRO}-ros2-controllers ros-${ROS_DISTRO}-gz-ros2-control \
      ros-${ROS_DISTRO}-teleop-twist-keyboard ros-${ROS_DISTRO}-rqt-robot-steering \
      ros-${ROS_DISTRO}-image-transport-plugins ros-${ROS_DISTRO}-plotjuggler-ros \
      ros-${ROS_DISTRO}-navigation2 ros-${ROS_DISTRO}-nav2-bringup \
      ros-${ROS_DISTRO}-slam-toolbox ros-${ROS_DISTRO}-robot-localization \
      ros-${ROS_DISTRO}-turtlebot3 ros-${ROS_DISTRO}-turtlebot3-simulations \
      ros-${ROS_DISTRO}-rplidar-ros ros-${ROS_DISTRO}-usb-cam ros-${ROS_DISTRO}-v4l2-camera \
      ros-${ROS_DISTRO}-mavros ros-${ROS_DISTRO}-mavros-extras \
 && /opt/ros/${ROS_DISTRO}/lib/mavros/install_geographiclib_datasets.sh \
 && rm -rf /var/lib/apt/lists/*

# A normal user with the same UID/GID as you on the host, so files in the mounted repo stay yours.
# Ubuntu 24.04 images ship a default 'ubuntu' user with UID 1000: remove it first.
RUN if id -u ubuntu >/dev/null 2>&1; then userdel -r ubuntu; fi \
 && if ! getent group "${USER_GID}" >/dev/null; then groupadd --gid "${USER_GID}" "${USERNAME}"; fi \
 && useradd --uid "${USER_UID}" --gid "${USER_GID}" --create-home --shell /bin/bash "${USERNAME}" \
 && usermod -aG sudo,dialout,video "${USERNAME}" \
 && echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/${USERNAME}" \
 && chmod 0440 "/etc/sudoers.d/${USERNAME}"

USER ${USERNAME}
WORKDIR /home/${USERNAME}

RUN rosdep update \
 && { echo "source /opt/ros/${ROS_DISTRO}/setup.bash"; \
      echo '[ -f /usr/share/colcon_argcomplete/hook/colcon-argcomplete.bash ] && source /usr/share/colcon_argcomplete/hook/colcon-argcomplete.bash'; \
      echo '[ -f "$HOME/ROS2/ros2_ws/install/setup.bash" ] && source "$HOME/ROS2/ros2_ws/install/setup.bash"'; \
      echo 'export GZ_VERSION=harmonic'; \
    } >> ~/.bashrc

# Optional (phase 4): ArduPilot SITL. Build with: ./docker/run.sh --ardupilot
RUN if [ "${WITH_ARDUPILOT}" = "1" ]; then \
      git clone --depth 1 --branch "${ARDUPILOT_TAG}" --recurse-submodules \
          https://github.com/ArduPilot/ardupilot.git ~/ardupilot \
   && cd ~/ardupilot \
   && DO_AP_STM_ENV=0 DO_PYTHON_VENV_ENV=0 SKIP_AP_GIT_CHECK=1 AP_DOCKER_BUILD=1 USER="${USERNAME}" \
      Tools/environment_install/install-prereqs-ubuntu.sh -y \
   && source ~/venv-ardupilot/bin/activate \
   && ./waf configure --board sitl \
   && ./waf copter \
   && echo 'source ~/.ardupilot_env' >> ~/.bashrc \
   && echo "alias apenv='source ~/venv-ardupilot/bin/activate'" >> ~/.bashrc \
   && sudo rm -rf /var/lib/apt/lists/* ; \
    fi

CMD ["bash"]
