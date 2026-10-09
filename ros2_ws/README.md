# ros2_ws — my ROS 2 workspace

My own ROS 2 packages live in `src/`, one package per idea (e.g. `my_py_pkg` from Step 2).

```bash
cd ~/ROS2/ros2_ws
colcon build --symlink-install     # build everything in src/
source install/setup.bash          # load my packages (new terminals do this automatically)
ros2 run <package> <node>          # run one of my nodes
```

`build/`, `install/` and `log/` are created by `colcon build` and aren't committed.
