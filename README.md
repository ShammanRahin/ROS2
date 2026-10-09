# ROS2 — my robotics journey

A step-by-step learning log: **ROS 2 basics → simulation → smarter robots → drones**.
Everything I install, run and learn goes here, so I (or a teammate) can rebuild the same setup on any machine and follow the same path.

**Aiming at:** line followers and a BFMC-style self-driving car (in simulation and for real), then autonomous drones for TEKNOFEST.
**Stack:** Ubuntu 24.04 · ROS 2 Jazzy (LTS, supported until 2029) · Gazebo Harmonic · ArduPilot Copter 4.7

---

## Roadmap

| Phase | What I learn | Status |
|---|---|---|
| **1. ROS 2 basics** | nodes, topics, services, custom messages, parameters, launch files, tf2, talking to microcontrollers | 🔄 in progress |
| **2. Simulation** | robot models (URDF/xacro), Gazebo + `ros_gz` bridge, `ros2_control`, simulated camera/lidar, a line follower in sim | ⏳ |
| **3. Smarter robots** | OpenCV line/lane following, SLAM (`slam_toolbox`), navigation (Nav2), real sensors (RPLIDAR, USB camera) | ⏳ |
| **4. Drones** | ArduPilot SITL, MAVLink & MAVROS, drone simulation in Gazebo, mission state machine | ⏳ |

### Phase 1 — following DigiKey's *Introduction to ROS* (Shawn Hymel, ROS 2 Jazzy)

Videos: [YouTube playlist](https://www.youtube.com/playlist?list=PLEBQazB0HUySWueUF2zNyrA8LSX3rDvE7) · course code: [ShawnHymel/introduction-to-ros](https://github.com/ShawnHymel/introduction-to-ros)

| Step | Video | Topic | Done |
|---|---|---|---|
| [1](docs/01-ros2-basics/01-what-is-ros-and-install.md) | Parts 1–2 | What ROS is, topics & services, install ROS 2 natively, talker/listener | ⬜ |
| 2 | Part 3 | Nodes, publishers & subscribers in **Python** | ⬜ |
| 3 | Part 4 | The same in **C++** | ⬜ |
| 4 | Parts 5–6 | Services: requests & responses (Python, C++) | ⬜ |
| 5 | Part 7 | Custom interfaces (my own message & service types) | ⬜ |
| 6 | Part 8 | Parameters | ⬜ |
| 7 | Part 9 | Launch files | ⬜ |
| 8 | Parts 10–11 | tf2: coordinate frames, turtlesim leader/follower | ⬜ |
| 9 | Part 12 | Talking to microcontrollers (Arduino) | ⬜ |

Each step file has: the idea in plain words → video → commands → tasks → **my notes** (filled in after I finish it).
My own code for each step goes in [`ros2_ws/src/`](ros2_ws/).

---

## Set up a machine

There are two ways. Both give the same environment.

### A. Native install (Ubuntu 24.04) — fastest, used on my main PC

```bash
git clone https://github.com/ShammanRahin/ROS2.git ~/ROS2
cd ~/ROS2
./scripts/install.sh            # phase 1: ROS 2 Jazzy  ← start here (~2 GB download)
./scripts/check.sh              # verify everything
```

Install later phases when I reach them (or all at once):

```bash
./scripts/install.sh 2          # simulation: Gazebo Harmonic, ros2_control, robot models
./scripts/install.sh 3          # navigation, SLAM, real sensors
./scripts/install.sh 4          # drones: MAVROS + ArduPilot SITL (the build takes 20–40 min)
./scripts/install.sh all        # everything
```

The script is safe to re-run; it skips what's already installed.

### B. Docker — any other Linux, or Windows via WSL2

Same tools, packed in a container, so nothing needs installing on the machine except Docker:

```bash
git clone https://github.com/ShammanRahin/ROS2.git ~/ROS2
cd ~/ROS2
./docker/run.sh                 # first run builds the image (10–20 min), then opens a shell inside
./docker/run.sh --ardupilot     # bigger image that also contains ArduPilot SITL
```

Gazebo and RViz windows open on the normal desktop. To open a second terminal into the same container, run `./docker/run.sh` again.
In VS Code: install the *Dev Containers* extension → **Reopen in Container** (uses `.devcontainer/`).

### Extra Python libraries (venv)

ROS 2's own Python packages come from apt. Extra pip libraries (pymavlink, pyserial, …) go in a venv that can still see ROS:

```bash
./scripts/setup-venv.sh
source .venv/bin/activate       # after ROS is sourced (it is, automatically, in every terminal)
```

---

## What's in here

```
ROS2/
├── docs/
│   ├── 00-machine-setup.md        how this PC was set up (dual boot) + problems and fixes
│   ├── 01-ros2-basics/            Phase 1 lessons, one file per step
│   ├── 02-simulation/             Phase 2 (planned)
│   ├── 03-navigation-vision/      Phase 3 (planned)
│   ├── 04-drones/                 Phase 4 (planned) + drone notes
│   └── videos.md                  video list for every phase
├── ros2_ws/                       my ROS 2 workspace — my own packages go in ros2_ws/src/
├── drone/                         drone scripts (MAVLink mission state machine)
├── scripts/
│   ├── install.sh                 native installer, by phase
│   ├── check.sh                   checks what's installed and working
│   └── setup-venv.sh              creates .venv for extra pip libraries
├── docker/                        Dockerfile + run.sh for the portable setup
├── .devcontainer/                 VS Code "Reopen in Container" config
└── requirements.txt               extra pip libraries
```

> **Status of the setup scripts:** written from the official ROS 2 Jazzy and ArduPilot install instructions, with every package name checked against the official ROS 2 Jazzy package index. The first real end-to-end run is in Step 1 on my PC — anything that breaks gets fixed here and noted in the step's notes.
