# OniQ IoT & Edge Architecture

This directory contains the edge telemetry and hardware modules for **OniQ**, an AI-powered onion storage monitoring and decision-support system.

---

## Architecture Flow

```
[ ESP32 Sensor Node ]
  ├── SHT30/SHT31 (I2C: Temp & %RH)
  ├── MQ-135 (ADC GPIO 34: Air Quality / VOCs)
  └── MQ-136 (ADC GPIO 35: H2S / Rotting Indicator)
          │
          │ Wi-Fi HTTP POST (every 15s)
          ▼
[ Raspberry Pi 3B Gateway ]
  ├── Ingestion Server (Port 5000: /reading)
  ├── Edge SQLite Buffer (offline queue)
  └── Cloud Synchronizer (Batched HTTPS Sync)
          │
          │ Batched HTTPS POST (every 15-30s)
          ▼
[ Backend API Gateway / Storage Service ] (:8005)
  ├── Telemetry Processing & Persistence
  ├── Agronomic Rules Engine (ICAR-DOGR calibrated)
  └── Gemini AI Decision Support & Advisory
```

---

## Directory Contents

- **`simulator/simulate_telemetry.py`**:
  A zero-dependency Python script that sends real-time synthetic sensor telemetry across multiple storage scenarios (`normal`, `humid_sprout`, `rot_spoilage`). Useful for testing the backend and mobile dashboard without hardware attached.

- **`rpi-gateway/gateway.py`**:
  Daemon designed to run on a local Raspberry Pi 3B. Collects data from ESP32 nodes over local Wi-Fi, writes immediately to a local SQLite database (`oniq_gateway_buffer.db`), and flushes batches to the cloud whenever an internet connection is available.

- **`esp32-node/esp32_oniq_node.ino`**:
  Arduino/ESP32 sketch with sensor drivers for SHT30/31, MQ-135, and MQ-136, multi-sample averaging, and HTTP publishing.

---

## Pinout & Wiring Guide (ESP32 DevKit V1)

| Sensor | Sensor Pin | ESP32 Pin | Purpose |
|---|---|---|---|
| **SHT30 / SHT31** | VCC | 3.3V | Power supply |
| | GND | GND | Ground |
| | SDA | GPIO 21 | I2C Serial Data |
| | SCL | GPIO 22 | I2C Serial Clock |
| **MQ-135** | VCC | 5V (VIN) | Heater power |
| | GND | GND | Ground |
| | AOUT | GPIO 34 (ADC1_CH6) | Analog air quality / VOCs |
| **MQ-136** | VCC | 5V (VIN) | Heater power |
| | GND | GND | Ground |
| | AOUT | GPIO 35 (ADC1_CH7) | Analog H2S / sulfurous gas |

> [!NOTE]
> MQ-series gas sensors require a 5V heater voltage (connect to ESP32 `VIN` pin when powered via 5V USB). The analog output voltage is read via ADC1 pins (`GPIO 34` and `GPIO 35`), which do not interfere with ESP32 Wi-Fi.

---

## Quick Start: Testing with the Simulator

1. Start the storage service or the full backend stack:
   ```bash
   cd onion-guard-mobile/backend
   docker compose up --build
   ```
   *(Or run standalone with `uvicorn app.main:app --port 8005` inside `onion-guard-mobile/backend/storage-service`)*

2. Run the telemetry simulator:
   ```bash
   python oniq-iot/simulator/simulate_telemetry.py --url http://localhost:8005 --mode normal
   ```

3. Simulate a rotting spoilage event:
   ```bash
   python oniq-iot/simulator/simulate_telemetry.py --url http://localhost:8005 --mode rot_spoilage
   ```
