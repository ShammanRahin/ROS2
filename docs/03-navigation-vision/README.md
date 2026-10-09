# Phase 3 — Smarter robots (planned)

Goal: robots that see, map and plan — the skills a BFMC-style self-driving car needs.

Install: `./scripts/install.sh 3`

Planned steps:

1. OpenCV with ROS 2 (`cv_bridge`) — lane and line detection from a camera topic
2. TurtleBot3 in Gazebo — a known-good robot to learn navigation on
3. SLAM with `slam_toolbox` — building a map from lidar
4. Navigation with Nav2 — localization, path planning, obstacle avoidance
5. Real sensors — RPLIDAR C1 (`rplidar_ros`), USB camera (`usb_cam`)
6. Sensor fusion with `robot_localization` (wheel odometry + IMU)

Steps get detailed (with videos) when I reach this phase.
