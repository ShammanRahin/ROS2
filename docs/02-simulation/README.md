# Phase 2 — Simulation (planned)

Goal: build robots in software and drive them in Gazebo with the same ROS 2 code a real robot would run.

Install: `./scripts/install.sh 2`

Planned steps:

1. Robot description: URDF and xacro — links, joints, a simple two-wheel robot shown in RViz
2. Gazebo Harmonic basics — worlds, models, the `gz` tools
3. `ros_gz` bridge — connecting Gazebo topics to ROS 2 topics
4. Driving it: `ros2_control` + diff-drive controller, keyboard teleop
5. Sensors: simulated camera and lidar
6. **Line follower in simulation** — camera → OpenCV line detection → steering
7. Compare with my earlier [LineFollower-Sim](https://github.com/ShammanRahin/LineFollower-Sim) project

Steps get detailed (with videos) when I reach this phase.
