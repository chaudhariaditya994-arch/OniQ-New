/*
 * OniQ - AI-Powered Onion Storage Monitoring Node
 * Microcontroller: ESP32 DevKit V1
 * Sensors:
 *   - SHT30 / SHT31: Temperature & Relative Humidity (I2C: SDA=21, SCL=22)
 *   - MQ-135: Air Quality & VOCs (Analog: GPIO 34)
 *   - MQ-136: Hydrogen Sulfide / Sulfurous Rotting Gas (Analog: GPIO 35)
 *
 * Targets:
 *   - Raspberry Pi 3B Local Gateway: http://<RPI_IP>:5000/reading
 *   - OR Direct Cloud Backend: http://<SERVER_IP>:8005/telemetry
 */

#include <WiFi.h>
#include <HTTPClient.h>
#include <Wire.h>
#include <Adafruit_SHT31.h>

// ── Configuration ────────────────────────────────────────────────────────────
const char* WIFI_SSID     = "YOUR_WIFI_SSID";
const char* WIFI_PASSWORD = "YOUR_WIFI_PASSWORD";

// Target Gateway URL (IP of Raspberry Pi 3B or Cloud Backend)
const char* GATEWAY_URL   = "http://192.168.1.100:5000/reading";
const char* DEVICE_ID     = "esp32-node-01";
const char* BATCH_ID      = ""; // Leave empty to auto-bind to active batch

// Pin Definitions
#define PIN_MQ135_ANALOG 34   // ADC1_CH6 (Input only)
#define PIN_MQ136_ANALOG 35   // ADC1_CH7 (Input only)
#define I2C_SDA_PIN      21
#define I2C_SCL_PIN      22

// Telemetry Sampling Interval (milliseconds)
const unsigned long SAMPLE_INTERVAL_MS = 15000; // 15 seconds

Adafruit_SHT31 sht31 = Adafruit_SHT31();
bool sht31_available = false;

// ── Setup ────────────────────────────────────────────────────────────────────
void setup() {
  Serial.begin(115200);
  delay(1000);
  Serial.println("\n==============================================");
  Serial.println("   OniQ ESP32 Onion Storage Monitoring Node   ");
  Serial.println("==============================================");

  // Configure Analog Pins
  analogReadResolution(12); // 12-bit ADC (0 - 4095)
  analogSetAttenuation(ADC_11db); // Full-scale voltage approx 3.3V

  // Initialize I2C for SHT31
  Wire.begin(I2C_SDA_PIN, I2C_SCL_PIN);
  if (sht31.begin(0x44)) {
    Serial.println("[SHT31] Sensor initialized at address 0x44.");
    sht31_available = true;
  } else if (sht31.begin(0x45)) {
    Serial.println("[SHT31] Sensor initialized at address 0x45.");
    sht31_available = true;
  } else {
    Serial.println("[WARNING] SHT31 sensor not detected! Using fallback simulator values.");
  }

  // Connect to Wi-Fi
  connectWiFi();
}

void connectWiFi() {
  Serial.print("[WiFi] Connecting to: ");
  Serial.println(WIFI_SSID);
  WiFi.mode(WIFI_STA);
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);

  int retries = 0;
  while (WiFi.status() != WL_CONNECTED && retries < 20) {
    delay(500);
    Serial.print(".");
    retries++;
  }

  if (WiFi.status() == WL_CONNECTED) {
    Serial.print("\n[WiFi] Connected! IP Address: ");
    Serial.println(WiFi.localIP());
  } else {
    Serial.println("\n[WiFi] Connection timeout. Will retry next cycle.");
  }
}

// ── Multi-Sample Analog Reader ───────────────────────────────────────────────
float readAveragedADC(int pin, int samples = 10) {
  long sum = 0;
  for (int i = 0; i < samples; i++) {
    sum += analogRead(pin);
    delay(10);
  }
  return (float)sum / samples;
}

// ── Main Loop ────────────────────────────────────────────────────────────────
void loop() {
  // Ensure Wi-Fi connection
  if (WiFi.status() != WL_CONNECTED) {
    connectWiFi();
  }

  // 1. Read SHT30/SHT31 (Temperature & Relative Humidity)
  float temperature = 27.5;
  float humidity = 66.0;

  if (sht31_available) {
    float t = sht31.readTemperature();
    float h = sht31.readHumidity();
    if (!isnan(t) && !isnan(h)) {
      temperature = t;
      humidity = h;
    } else {
      Serial.println("[SHT31] Failed to read sensor data, using previous baseline.");
    }
  }

  // 2. Read MQ-135 & MQ-136 Analog Channels
  float mq135_raw = readAveragedADC(PIN_MQ135_ANALOG, 12);
  float mq136_raw = readAveragedADC(PIN_MQ136_ANALOG, 12);

  // 3. Read Wi-Fi Signal
  int rssi = WiFi.RSSI();

  // Print to Serial Console
  Serial.println("\n[Sensor Telemetry]");
  Serial.print("  Temperature : "); Serial.print(temperature, 1); Serial.println(" °C");
  Serial.print("  Humidity    : "); Serial.print(humidity, 1); Serial.println(" %RH");
  Serial.print("  MQ-135 (Air): "); Serial.println(mq135_raw, 0);
  Serial.print("  MQ-136 (H2S): "); Serial.println(mq136_raw, 0);
  Serial.print("  RSSI        : "); Serial.print(rssi); Serial.println(" dBm");

  // 4. Build JSON Payload
  String payload = "{";
  payload += "\"device_id\":\"" + String(DEVICE_ID) + "\",";
  if (strlen(BATCH_ID) > 0) {
    payload += "\"batch_id\":\"" + String(BATCH_ID) + "\",";
  }
  payload += "\"temperature\":" + String(temperature, 2) + ",";
  payload += "\"humidity\":" + String(humidity, 2) + ",";
  payload += "\"mq135_raw\":" + String(mq135_raw, 1) + ",";
  payload += "\"mq136_raw\":" + String(mq136_raw, 1) + ",";
  payload += "\"rssi\":" + String(rssi);
  payload += "}";

  // 5. Send HTTP POST to Raspberry Pi Gateway or Cloud Backend
  if (WiFi.status() == WL_CONNECTED) {
    HTTPClient http;
    http.begin(GATEWAY_URL);
    http.addHeader("Content-Type", "application/json");

    int httpResponseCode = http.POST(payload);
    if (httpResponseCode > 0) {
      String response = http.getString();
      Serial.print("  Gateway Response ["); Serial.print(httpResponseCode); Serial.println("]: OK");
    } else {
      Serial.print("  Error on sending POST: ");
      Serial.println(httpResponseCode);
    }
    http.end();
  }

  delay(SAMPLE_INTERVAL_MS);
}
