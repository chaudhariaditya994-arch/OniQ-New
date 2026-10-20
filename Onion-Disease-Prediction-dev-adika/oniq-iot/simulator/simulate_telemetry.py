#!/usr/bin/env python3
"""
OniQ Telemetry Simulator
Simulates ESP32 sensor telemetry (SHT30/31, MQ-135, MQ-136) and streams data
to the OniQ Storage Backend (or Raspberry Pi Gateway).

Zero external dependencies required (uses standard Python library urllib.request).
"""

import sys
import time
import json
import random
import argparse
import urllib.request
import urllib.error
from datetime import datetime, timezone


def post_json(url: str, data: dict, headers: dict = None) -> dict:
    req_headers = {"Content-Type": "application/json"}
    if headers:
        req_headers.update(headers)
    req = urllib.request.Request(
        url,
        data=json.dumps(data).encode("utf-8"),
        headers=req_headers,
        method="POST"
    )
    with urllib.request.urlopen(req, timeout=10) as resp:
        return json.loads(resp.read().decode("utf-8"))


def get_json(url: str) -> dict:
    req = urllib.request.Request(url, method="GET")
    with urllib.request.urlopen(req, timeout=10) as resp:
        return json.loads(resp.read().decode("utf-8"))


def ensure_demo_batch(backend_url: str, user_email: str, device_id: str) -> str:
    """Ensures at least one active storage batch exists for this device."""
    try:
        batches_url = f"{backend_url}/batches?user_email={user_email}"
        batches = get_json(batches_url)
        for b in batches:
            if b.get("device_id") == device_id and b.get("is_active"):
                print(f"[OniQ Simulator] Found existing batch: '{b.get('name')}' (ID: {b.get('id')})")
                return b.get("id")
    except Exception as e:
        print(f"[OniQ Simulator] Note: Could not query existing batches ({e}), creating one...")

    # Create new demo batch
    payload = {
        "user_email": user_email,
        "name": "Nashik Chawl Bay #1 (Naturally Ventilated)",
        "structure_type": "Traditional Chawl (Naturally Ventilated)",
        "variety": "Garwa (Rabi)",
        "quantity_quintals": 120.0,
        "location": "Lasalgaon, Nashik, Maharashtra",
        "device_id": device_id,
        "notes": "Bottom rack equipped with OniQ ESP32 sensor node",
    }
    try:
        new_b = post_json(f"{backend_url}/batches", payload)
        batch_id = new_b.get("id", "batch-01")
        print(f"[OniQ Simulator] Created demo batch: '{new_b.get('name')}' (ID: {batch_id})")
        return batch_id
    except Exception as e:
        print(f"[OniQ Simulator] Warning: Could not create batch ({e}). Using fallback ID.")
        return "demo-batch-01"


def generate_reading(mode: str, device_id: str, batch_id: str) -> dict:
    now_iso = datetime.now(timezone.utc).isoformat()

    if mode == "normal":
        temp = round(26.5 + random.uniform(-1.0, 1.5), 1)
        rh = round(66.0 + random.uniform(-2.0, 2.5), 1)
        mq135 = round(620.0 + random.uniform(-40.0, 50.0), 0)
        mq136 = round(340.0 + random.uniform(-20.0, 30.0), 0)
    elif mode == "humid_sprout":
        temp = round(18.5 + random.uniform(-1.0, 1.5), 1)
        rh = round(77.5 + random.uniform(-1.5, 3.0), 1)
        mq135 = round(980.0 + random.uniform(-30.0, 60.0), 0)
        mq136 = round(480.0 + random.uniform(-20.0, 40.0), 0)
    elif mode == "rot_spoilage":
        temp = round(32.5 + random.uniform(-0.5, 2.0), 1)
        rh = round(81.0 + random.uniform(-1.0, 3.5), 1)
        mq135 = round(1550.0 + random.uniform(-80.0, 120.0), 0)
        mq136 = round(1280.0 + random.uniform(-60.0, 150.0), 0)
    else:  # random drift
        temp = round(random.uniform(22.0, 33.0), 1)
        rh = round(random.uniform(58.0, 82.0), 1)
        mq135 = round(random.uniform(500.0, 1400.0), 0)
        mq136 = round(random.uniform(300.0, 1100.0), 0)

    return {
        "device_id": device_id,
        "batch_id": batch_id,
        "timestamp": now_iso,
        "temperature": temp,
        "humidity": rh,
        "mq135_raw": mq135,
        "mq136_raw": mq136,
        "battery_pct": round(random.uniform(92.0, 99.0), 1),
        "rssi": -62,
    }


def main():
    parser = argparse.ArgumentParser(description="OniQ Telemetry Sensor Simulator")
    parser.add_argument("--url", default="http://localhost:8005", help="Target URL (direct storage-service :8005 or gateway :8000/api/v1/storage)")
    parser.add_argument("--mode", choices=["normal", "humid_sprout", "rot_spoilage", "drift"], default="normal", help="Simulation scenario")
    parser.add_argument("--email", default="farmer@oniq.io", help="User account email")
    parser.add_argument("--device", default="esp32-node-01", help="Device ID")
    parser.add_argument("--count", type=int, default=10, help="Number of telemetry packets to stream (0 = infinite)")
    parser.add_argument("--interval", type=float, default=2.0, help="Seconds between telemetry pulses")

    args = parser.parse_args()
    base_url = args.url.rstrip("/")

    # Normalize endpoint path
    telemetry_url = f"{base_url}/telemetry" if not base_url.endswith("/storage") else f"{base_url}/telemetry"

    print("=" * 70)
    print("   OniQ IoT Storage Telemetry Simulator")
    print(f"   Target URL : {telemetry_url}")
    print(f"   Scenario   : {args.mode.upper()}")
    print(f"   Device ID  : {args.device}")
    print("=" * 70)

    # Ensure demo batch exists
    batch_id = ensure_demo_batch(base_url, args.email, args.device)

    sent = 0
    try:
        while True:
            reading = generate_reading(args.mode, args.device, batch_id)
            print(f"\n[#{sent+1}] Transmitting sensor packet:")
            print(f"   Temp: {reading['temperature']}°C | RH: {reading['humidity']}% | MQ-135: {reading['mq135_raw']} | MQ-136: {reading['mq136_raw']}")

            try:
                resp = post_json(telemetry_url, reading)
                risk = resp.get("latest_risk", {})
                score = risk.get("risk_score", "?")
                level = risk.get("risk_level", "?")
                print(f"   --> Response: OK | Risk: {score}/100 ({level})")
                recs = risk.get("recommendations", [])
                if recs:
                    print(f"   --> Action Advice: {recs[0]}")
            except Exception as e:
                print(f"   --> Transmission failed: {e}")

            sent += 1
            if args.count > 0 and sent >= args.count:
                print(f"\nCompleted transmission of {sent} packets.")
                break

            time.sleep(args.interval)

    except KeyboardInterrupt:
        print("\nSimulator stopped by user.")


if __name__ == "__main__":
    main()
