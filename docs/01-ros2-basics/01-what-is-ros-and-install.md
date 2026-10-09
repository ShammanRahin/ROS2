# Step 1 — What ROS is, install it, see two programs talk

**Videos:** DigiKey *Introduction to ROS* [Part 1: What is the Robot Operating System?](https://www.youtube.com/watch?v=mjrxf8EFSb8) and [Part 2: topics and services](https://www.youtube.com/watch?v=HTIcxrauU8U)
**Time:** ~1 hour (most of it is the download)

---

## 1. The idea

ROS isn't an operating system. It's a toolkit for building a robot out of **many small programs that talk to each other**, instead of one giant program.

A line follower, built the ROS way:

```
[camera node] ──image──▶ [line-detection node] ──steering──▶ [motor node]
```

| Word | Meaning | Analogy |
|---|---|---|
| **Node** | one small program with one job | one person in a team |
| **Topic** | a named channel, e.g. `/camera/image` or `/cmd_vel` | a radio station |
| **Publisher** | a node that sends on a topic | the station broadcasting |
| **Subscriber** | a node that listens to a topic (any number can) | everyone tuned in |
| **Message** | the data format on a topic, e.g. "an image" or "speed + turn rate" | the language spoken on that station |
| **Service** | ask a question, get one answer back (request → response) | a phone call |

**Why this matters for simulation:** swap the real camera node for a *simulated* camera in Gazebo, and the line-detection and motor nodes don't change at all. You test in simulation, then run the exact same code on the real robot.

**Versions:** Ubuntu 24.04 → **ROS 2 Jazzy** (long-term support until 2029) → pairs with the **Gazebo Harmonic** simulator (Phase 2). The DigiKey course uses Jazzy too.

## 2. About the course's Docker setup

The course repo ([ShawnHymel/introduction-to-ros](https://github.com/ShawnHymel/introduction-to-ros)) runs ROS inside a Docker container in the browser, for people on Windows/macOS. **I don't need that on this PC** — ROS is installed natively on Ubuntu, so:

- I type the commands from the videos in a normal terminal.
- GUI tools like `rqt` and `turtlesim` open as normal windows (in the course's SSH setup they don't work at all).
- Where the video uses the folder `/config/workspace`, I use `~/ROS2/ros2_ws`.
- The course repo's `workspace/src/` has the finished code for every part. I write my own version first, then compare.

## 3. Install ROS 2 Jazzy

One command does everything (details in [`scripts/install.sh`](../../scripts/install.sh)):

```bash
cd ~/ROS2
./scripts/install.sh
```

What it does, in order:

1. Installs base tools (curl, git, compilers, Python venv).
2. Checks the language setting is UTF-8 (ROS needs it).
3. Turns on Ubuntu's *universe* collection and adds the official ROS software source (`ros2-apt-source`).
4. Installs `ros-jazzy-desktop` (ROS + RViz + rqt + demos) and `ros-dev-tools` (colcon, rosdep — for building my own packages). **~1–2 GB.**
5. Sets up `rosdep` (finds and installs dependencies for ROS packages).
6. Adds `source /opt/ros/jazzy/setup.bash` to `~/.bashrc`.

> **What "sourcing" means:** each terminal has to load ROS's settings (paths to programs and libraries) before `ros2` commands work. Putting the line in `~/.bashrc` makes every new terminal do it automatically.

Then open a **new terminal** and check:

```bash
./scripts/check.sh
```

## 4. Experiment: two nodes talking

Open **3 terminals**.

**Terminal 1** — a node that **publishes** "Hello World: 1, 2, 3…":
```bash
ros2 run demo_nodes_cpp talker
```

**Terminal 2** — a node that **subscribes** and prints what it hears:
```bash
ros2 run demo_nodes_py listener
```
The talker is written in C++ and the listener in Python — they still talk, because ROS handles the communication.

**Terminal 3** — look inside:
```bash
ros2 node list            # which nodes are running?
ros2 topic list           # which channels exist?
ros2 topic info /chatter  # who publishes / subscribes on /chatter?
ros2 topic echo /chatter  # listen in yourself (Ctrl+C to stop)
rqt_graph                 # picture of nodes and the channel between them
```

## 5. Tasks

1. Take a screenshot of `rqt_graph` → save it as `docs/01-ros2-basics/img/step1-rqt-graph.png`.
2. Stop the talker (Ctrl+C). What does the listener do? Start the talker again — what happens?
3. Start a **second** listener in a 4th terminal. Do both get the messages?
4. In my own words, one line each: what is a node, a topic, a message?

---

## My notes

*(fill in after finishing the step)*

- Install: worked first time? Any errors and how I fixed them:
- Task 2 — when the talker stops, the listener…
- Task 3 — with two listeners…
- Node:
- Topic:
- Message:
- Questions I still have:
