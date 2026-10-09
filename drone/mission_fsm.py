#!/usr/bin/env python3
"""
Autonomous payload-drop mission for ArduCopter, driven by a non-blocking
state machine over MAVLink (pymavlink). Works in SITL and, later, on a real
drone (change --connect to your serial port).

Run SITL first (Terminal 1):
    cd ~/ardupilot/ArduCopter && sim_vehicle.py --console --map
Then run this (Terminal 2):
    python3 mission_fsm.py --connect tcp:127.0.0.1:5762

Flow: CONNECT -> PREFLIGHT -> ARM -> TAKEOFF -> WAYPOINTS -> TO_TARGET
      -> DROP -> RETURN -> DONE.  Any problem -> ABORT (RTL) -> DONE.
"""
import argparse
import math
import time
from enum import Enum, auto

from pymavlink import mavutil

# ---------------- mission settings (edit these) ----------------
ALT_M = 10.0                                   # flight altitude above home
WAYPOINTS_NE = [(20, 0), (20, 20), (0, 20)]    # (north, east) metres from home
TARGET_NE = (10, 10)                           # drop point (north, east)
DROP_SERVO = 9                                 # output channel of the release servo
PWM_CLOSED, PWM_OPEN = 1100, 1900
POS_TOL_M = 1.0                                # "arrived" radius
STATE_TIMEOUT_S = {                            # max time allowed in each state
    "PREFLIGHT": 120, "ARM": 30, "TAKEOFF": 40,
    "WAYPOINTS": 120, "TO_TARGET": 60, "DROP": 5, "RETURN": 180,
}
# position-only mask for SET_POSITION_TARGET_LOCAL_NED (ignore vel/acc/yaw)
POS_ONLY_MASK = 0b110111111000


class S(Enum):
    CONNECT = auto(); PREFLIGHT = auto(); ARM = auto(); TAKEOFF = auto()
    WAYPOINTS = auto(); TO_TARGET = auto(); DROP = auto(); RETURN = auto()
    ABORT = auto(); DONE = auto()


class Mission:
    def __init__(self, connect: str):
        self.m = mavutil.mavlink_connection(connect, source_system=255,
                                            source_component=191)
        self.state = S.CONNECT
        self.t_state = time.time()     # when we entered the current state
        self.t_last_cmd = 0.0          # for re-sending commands at 1 Hz
        self.wp_index = 0
        self.ned = None                # latest (north, east, down) in metres
        self.gps_fix = 0
        self.servo9 = None
        self.log = open("mission_log.csv", "w")
        self.log.write("time,state,north,east,alt,mode\n")

    # ---------- low-level helpers ----------
    def cmd(self, command, *params):
        """Send a COMMAND_LONG with up to 7 params."""
        p = list(params) + [0] * (7 - len(params))
        self.m.mav.command_long_send(self.m.target_system,
                                     self.m.target_component,
                                     command, 0, *p)

    def request_rate(self, msg_id, hz):
        self.cmd(mavutil.mavlink.MAV_CMD_SET_MESSAGE_INTERVAL,
                 msg_id, int(1e6 / hz))

    def goto_ne(self, n, e, alt):
        self.m.mav.set_position_target_local_ned_send(
            0, self.m.target_system, self.m.target_component,
            mavutil.mavlink.MAV_FRAME_LOCAL_NED, POS_ONLY_MASK,
            n, e, -alt, 0, 0, 0, 0, 0, 0, 0, 0)

    def dist_to(self, n, e):
        if self.ned is None:
            return float("inf")
        return math.hypot(self.ned[0] - n, self.ned[1] - e)

    def alt(self):
        return -self.ned[2] if self.ned else 0.0

    def every(self, seconds):
        """True at most once per `seconds` - used to re-send commands."""
        now = time.time()
        if now - self.t_last_cmd >= seconds:
            self.t_last_cmd = now
            return True
        return False

    def go(self, new_state):
        print(f"[{time.strftime('%H:%M:%S')}] {self.state.name} -> {new_state.name}")
        self.state, self.t_state, self.t_last_cmd = new_state, time.time(), 0.0

    # ---------- read everything waiting, never block ----------
    def pump(self):
        while True:
            msg = self.m.recv_match(blocking=False)
            if msg is None:
                return
            t = msg.get_type()
            if t == "LOCAL_POSITION_NED":
                self.ned = (msg.x, msg.y, msg.z)
            elif t == "GPS_RAW_INT":
                self.gps_fix = msg.fix_type
            elif t == "SERVO_OUTPUT_RAW":
                self.servo9 = getattr(msg, "servo9_raw", None)
            elif t == "STATUSTEXT":
                print(f"  autopilot: {msg.text}")
            elif t == "COMMAND_ACK" and msg.result != 0:
                print(f"  command {msg.command} rejected, result={msg.result}")

    # ---------- the state machine: one small step per call ----------
    def step(self):
        st, mode = self.state, self.m.flightmode
        armed = self.m.motors_armed()

        # timeout guard for every timed state
        limit = STATE_TIMEOUT_S.get(st.name)
        if limit and time.time() - self.t_state > limit:
            print(f"  timeout in {st.name}")
            return self.go(S.ABORT)

        # if a failsafe or the pilot changed mode mid-mission, stop our logic
        if st in (S.TAKEOFF, S.WAYPOINTS, S.TO_TARGET, S.DROP) and mode != "GUIDED":
            print(f"  mode changed to {mode} - aborting mission logic")
            return self.go(S.ABORT)

        if st == S.CONNECT:
            self.m.wait_heartbeat()
            print(f"  heartbeat from system {self.m.target_system}")
            self.request_rate(mavutil.mavlink.MAVLINK_MSG_ID_LOCAL_POSITION_NED, 10)
            self.request_rate(mavutil.mavlink.MAVLINK_MSG_ID_GPS_RAW_INT, 2)
            self.request_rate(mavutil.mavlink.MAVLINK_MSG_ID_SERVO_OUTPUT_RAW, 2)
            self.m.mav.param_set_send(self.m.target_system, self.m.target_component,
                                      b"SERVO9_FUNCTION", 0,
                                      mavutil.mavlink.MAV_PARAM_TYPE_INT8)
            self.go(S.PREFLIGHT)

        elif st == S.PREFLIGHT:
            if self.every(2):
                self.m.set_mode("GUIDED")
                self.cmd(mavutil.mavlink.MAV_CMD_DO_SET_SERVO, DROP_SERVO, PWM_CLOSED)
            if mode == "GUIDED" and self.gps_fix >= 3 and self.ned is not None:
                self.go(S.ARM)

        elif st == S.ARM:
            if self.every(3):   # pre-arm checks may fail at first: keep trying
                self.cmd(mavutil.mavlink.MAV_CMD_COMPONENT_ARM_DISARM, 1)
            if armed:
                self.cmd(mavutil.mavlink.MAV_CMD_NAV_TAKEOFF, 0, 0, 0, 0, 0, 0, ALT_M)
                self.go(S.TAKEOFF)

        elif st == S.TAKEOFF:
            if self.alt() >= 0.95 * ALT_M:
                self.go(S.WAYPOINTS)

        elif st == S.WAYPOINTS:
            n, e = WAYPOINTS_NE[self.wp_index]
            if self.every(1):
                self.goto_ne(n, e, ALT_M)
            if self.dist_to(n, e) < POS_TOL_M:
                print(f"  reached waypoint {self.wp_index + 1}/{len(WAYPOINTS_NE)}")
                self.wp_index += 1
                self.t_last_cmd = 0.0
                if self.wp_index == len(WAYPOINTS_NE):
                    self.go(S.TO_TARGET)

        elif st == S.TO_TARGET:
            if self.every(1):
                self.goto_ne(*TARGET_NE, ALT_M)
            if self.dist_to(*TARGET_NE) < POS_TOL_M:
                self.cmd(mavutil.mavlink.MAV_CMD_DO_SET_SERVO, DROP_SERVO, PWM_OPEN)
                self.go(S.DROP)

        elif st == S.DROP:
            if self.servo9 is not None and self.servo9 >= PWM_OPEN - 50 \
                    and time.time() - self.t_state > 1.5:
                print(f"  payload released (servo {DROP_SERVO} = {self.servo9} us)")
                self.m.set_mode("RTL")
                self.go(S.RETURN)

        elif st == S.RETURN:
            if mode != "RTL" and self.every(2):
                self.m.set_mode("RTL")
            if not armed and time.time() - self.t_state > 3:
                self.go(S.DONE)

        elif st == S.ABORT:
            # Only take action if we are still in our own GUIDED mode (e.g. a
            # timeout). If a failsafe or the pilot picked another mode, leave
            # them in charge and just wait for the landing.
            if armed and mode == "GUIDED" and self.every(2):
                self.m.set_mode("RTL")
            if not armed:
                self.go(S.DONE)

        # one CSV line per step at most every 0.5 s
        if self.ned and int(time.time() * 2) != getattr(self, "_last_log", None):
            self._last_log = int(time.time() * 2)
            self.log.write(f"{time.time():.1f},{self.state.name},{self.ned[0]:.2f},"
                           f"{self.ned[1]:.2f},{self.alt():.2f},{mode}\n")

    def run(self):
        while self.state != S.DONE:
            self.pump()
            self.step()
            time.sleep(0.05)   # 20 Hz loop
        self.log.close()
        print("Mission finished. Log saved to mission_log.csv")


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--connect", default="tcp:127.0.0.1:5762",
                    help="SITL: tcp:127.0.0.1:5762  |  real drone: /dev/ttyAMA0,921600")
    Mission(ap.parse_args().connect).run()
