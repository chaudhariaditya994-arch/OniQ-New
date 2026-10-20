#!/usr/bin/env python3
"""
OniQ Raspberry Pi 3B Edge Gateway Service
Collects sensor readings from ESP32 nodes via local Wi-Fi (HTTP / MQTT),
buffers telemetry in local SQLite for offline resilience, and synchronizes
batches upstream to the OniQ Cloud Backend.

Standard library only (sqlite3, http.server, urllib.request, threading).
Optional: paho-mqtt if Mosquitto broker is preferred.
"""

import os
import sys
import time
import json
import sqlite3
import threading
import urllib.request
import urllib.error
from http.server import HTTPServer, BaseHTTPRequestHandler
from datetime import datetime, timezone

DB_PATH = os.getenv("GATEWAY_DB", "oniq_gateway_buffer.db")
BACKEND_URL = os.getenv("BACKEND_URL", "http://localhost:8000/api/v1/storage/telemetry")
GATEWAY_KEY = os.getenv("GATEWAY_KEY", "oniq-gateway-secret-key")
HTTP_PORT = int(os.getenv("GATEWAY_HTTP_PORT", "5000"))
SYNC_INTERVAL = int(os.getenv("SYNC_INTERVAL_SEC", "15"))
BATCH_SIZE = int(os.getenv("SYNC_BATCH_SIZE", "20"))


# ── SQLite Edge Buffer Setup ──────────────────────────────────────────────────

def init_db():
    conn = sqlite3.connect(DB_PATH)
    cur = conn.cursor()
    cur.execute("""
        CREATE TABLE IF NOT EXISTS telemetry_buffer (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            device_id TEXT NOT NULL,
            batch_id TEXT,
            timestamp TEXT NOT NULL,
            temperature REAL NOT NULL,
            humidity REAL NOT NULL,
            mq135_raw REAL NOT NULL,
            mq136_raw REAL NOT NULL,
            battery_pct REAL,
            rssi INTEGER,
            is_synced INTEGER DEFAULT 0,
            created_at TEXT NOT NULL
        )
    """)
    conn.commit()
    conn.close()
    print(f"[OniQ Gateway] Initialized SQLite buffer at {DB_PATH}")


def buffer_reading(reading: dict) -> bool:
    try:
        conn = sqlite3.connect(DB_PATH)
        cur = conn.cursor()
        now_iso = datetime.now(timezone.utc).isoformat()
        cur.execute("""
            INSERT INTO telemetry_buffer 
            (device_id, batch_id, timestamp, temperature, humidity, mq135_raw, mq136_raw, battery_pct, rssi, is_synced, created_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 0, ?)
        """, (
            str(reading.get("device_id", "esp32-node-01")),
            reading.get("batch_id"),
            str(reading.get("timestamp", now_iso)),
            float(reading.get("temperature", 28.0)),
            float(reading.get("humidity", 65.0)),
            float(reading.get("mq135_raw", 600.0)),
            float(reading.get("mq136_raw", 350.0)),
            reading.get("battery_pct"),
            reading.get("rssi"),
            now_iso,
        ))
        conn.commit()
        conn.close()
        return True
    except Exception as e:
        print(f"[OniQ Gateway] Error buffering reading: {e}")
        return False


# ── Cloud Synchronization Worker ──────────────────────────────────────────────

def sync_worker():
    print(f"[OniQ Gateway] Sync worker started. Target: {BACKEND_URL}")
    while True:
        try:
            conn = sqlite3.connect(DB_PATH)
            cur = conn.cursor()
            cur.execute("""
                SELECT id, device_id, batch_id, timestamp, temperature, humidity, mq135_raw, mq136_raw, battery_pct, rssi
                FROM telemetry_buffer
                WHERE is_synced = 0
                ORDER BY id ASC
                LIMIT ?
            """, (BATCH_SIZE,))
            rows = cur.fetchall()

            if rows:
                readings = []
                ids = []
                for r in rows:
                    ids.append(r[0])
                    readings.append({
                        "device_id": r[1],
                        "batch_id": r[2],
                        "timestamp": r[3],
                        "temperature": r[4],
                        "humidity": r[5],
                        "mq135_raw": r[6],
                        "mq136_raw": r[7],
                        "battery_pct": r[8],
                        "rssi": r[9],
                    })

                payload = {
                    "gateway_id": "rpi3b-gateway-01",
                    "readings": readings,
                }

                # Push to backend
                req = urllib.request.Request(
                    BACKEND_URL,
                    data=json.dumps(payload).encode("utf-8"),
                    headers={
                        "Content-Type": "application/json",
                        "X-Gateway-Key": GATEWAY_KEY,
                    },
                    method="POST",
                )

                try:
                    with urllib.request.urlopen(req, timeout=12) as resp:
                        if resp.status == 200:
                            placeholders = ",".join("?" * len(ids))
                            cur.execute(f"UPDATE telemetry_buffer SET is_synced = 1 WHERE id IN ({placeholders})", ids)
                            conn.commit()
                            print(f"[OniQ Gateway] Successfully synced {len(ids)} buffered readings to cloud.")
                except urllib.error.URLError as ue:
                    print(f"[OniQ Gateway] Network unreachable ({ue.reason}). Keeping records in local SQLite buffer.")
                except Exception as ex:
                    print(f"[OniQ Gateway] Cloud sync error: {ex}")

            # Prune synced rows older than 7 days
            cur.execute("DELETE FROM telemetry_buffer WHERE is_synced = 1 AND id < (SELECT MAX(id) - 5000 FROM telemetry_buffer)")
            conn.commit()
            conn.close()

        except Exception as e:
            print(f"[OniQ Gateway] Error in sync loop: {e}")

        time.sleep(SYNC_INTERVAL)


# ── Local Ingestion HTTP Server (for ESP32 HTTP Posts) ─────────────────────────

class GatewayRequestHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/health":
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            self.wfile.write(b'{"status":"ok","role":"oniq-edge-gateway"}')
        else:
            self.send_response(404)
            self.end_headers()

    def do_POST(self):
        if self.path in ["/reading", "/telemetry"]:
            content_len = int(self.headers.get("Content-Length", 0))
            body = self.rfile.read(content_len)
            try:
                data = json.loads(body.decode("utf-8"))
                success = buffer_reading(data)
                if success:
                    self.send_response(200)
                    self.send_header("Content-Type", "application/json")
                    self.end_headers()
                    self.wfile.write(b'{"success":true,"buffered":true}')
                    return
            except Exception as e:
                print(f"[OniQ Gateway] Invalid JSON payload: {e}")

            self.send_response(400)
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            self.wfile.write(b'{"error":"invalid payload"}')
        else:
            self.send_response(404)
            self.end_headers()

    def log_message(self, format, *args):
        # Suppress noisy HTTP access logs
        return


def main():
    print("=" * 65)
    print("   OniQ Raspberry Pi 3B Gateway Service")
    print(f"   Listening on port : {HTTP_PORT}")
    print(f"   Buffer DB         : {DB_PATH}")
    print(f"   Cloud Target      : {BACKEND_URL}")
    print("=" * 65)

    init_db()

    # Start background sync thread
    t = threading.Thread(target=sync_worker, daemon=True)
    t.start()

    # Start HTTP server
    server = HTTPServer(("0.0.0.0", HTTP_PORT), GatewayRequestHandler)
    print(f"[OniQ Gateway] Edge HTTP server running at http://0.0.0.0:{HTTP_PORT}")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\n[OniQ Gateway] Shutting down.")


if __name__ == "__main__":
    main()
