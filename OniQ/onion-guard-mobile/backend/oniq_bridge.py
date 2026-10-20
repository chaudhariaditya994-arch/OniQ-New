import subprocess
import time
import sys
import os

ADB_EXE = r"C:\Users\adiga\platform-tools\adb.exe"

def run_adb(args, timeout=10):
    try:
        p = subprocess.run([ADB_EXE] + args, capture_output=True, text=True, timeout=timeout)
        return p.returncode, p.stdout.strip(), p.stderr.strip()
    except Exception as e:
        return -1, "", str(e)

def main():
    print("[OniQ Bridge] Starting ADB Server supervisor and reverse tunnel...", flush=True)

    # Start adb server if not already running
    run_adb(["start-server"])
    time.sleep(1)

    while True:
        try:
            # Check devices
            rc, out, _ = run_adb(["devices"])
            devices = [line.split()[0] for line in out.splitlines()[1:] if "\tdevice" in line]
            
            if devices:
                for dev in devices:
                    # Check reverse
                    _, rev_out, _ = run_adb(["-s", dev, "reverse", "--list"])
                    if "tcp:8000 tcp:8000" not in rev_out:
                        print(f"[OniQ Bridge] Setting reverse tunnel on {dev}...", flush=True)
                        run_adb(["-s", dev, "reverse", "tcp:8000", "tcp:8000"])
            else:
                pass
        except Exception as e:
            print(f"[OniQ Bridge] Error: {e}", flush=True)
            
        time.sleep(3)

if __name__ == "__main__":
    main()
