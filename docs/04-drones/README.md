# Phase 4 — Drones (planned)

Goal: autonomous multicopter missions in simulation with ArduPilot, then on real hardware — aimed at TEKNOFEST.

Install: `./scripts/install.sh 4` (MAVROS + ArduPilot Copter 4.7.0 SITL; the build takes 20–40 min)

Planned steps:

1. ArduPilot SITL — first simulated takeoff with MAVProxy
2. MAVLink with pymavlink — reading telemetry, sending commands
3. Mission state machine — [`drone/mission_fsm.py`](../../drone/mission_fsm.py)
4. MAVROS — controlling the drone from ROS 2
5. Drone in Gazebo — ArduPilot + Gazebo Harmonic (`ardupilot_gazebo` / `ardupilot_gz`), camera stream
6. Failsafes and geofence testing in simulation

## Running the mission state machine (after `./scripts/install.sh 4`)

```bash
# Terminal 1 — simulated drone
apenv                                  # activate ArduPilot's Python venv
cd ~/ardupilot/ArduCopter
sim_vehicle.py -w --console --map      # -w resets parameters on the first run

# Terminal 2 — the mission
apenv
python3 ~/ROS2/drone/mission_fsm.py --connect tcp:127.0.0.1:5762
```

The script arms, takes off to 10 m, flies 3 waypoints, goes to a drop point, opens a servo and returns home, logging to `mission_log.csv`. It was tested in Copter 4.7.0 SITL (full mission in about 90 s; taking over in LOITER makes it abort safely).
