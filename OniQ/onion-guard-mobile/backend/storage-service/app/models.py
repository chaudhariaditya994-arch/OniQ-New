from datetime import datetime, timezone
from typing import List, Optional, Dict, Any
from pydantic import BaseModel, Field


class StorageBatchCreate(BaseModel):
    user_email: str
    name: str = Field(..., description="Name or identifier for the storage lot/room, e.g. 'Chawl Bay #1'")
    structure_type: str = Field(
        default="Traditional Chawl (Naturally Ventilated)",
        description="Type of storage structure (Chawl, Naturally Ventilated Godown, Cold Storage, etc.)"
    )
    variety: str = Field(
        default="Garwa (Rabi)",
        description="Onion variety (Garwa, Rangda, Pol, Nashik Red, etc.)"
    )
    quantity_quintals: float = Field(default=50.0, description="Quantity stored in quintals (1 quintal = 100 kg)")
    start_date: Optional[str] = None
    location: str = Field(default="Nashik, Maharashtra", description="Farm / village / warehouse location")
    device_id: str = Field(..., description="ID of the ESP32 node or gateway assigned to this batch")
    notes: Optional[str] = ""


class StorageBatchResponse(BaseModel):
    id: str
    user_email: str
    name: str
    structure_type: str
    variety: str
    quantity_quintals: float
    start_date: str
    location: str
    device_id: str
    notes: Optional[str] = ""
    is_active: bool = True
    created_at: str
    latest_reading: Optional[Dict[str, Any]] = None
    latest_risk: Optional[Dict[str, Any]] = None


class SensorReading(BaseModel):
    device_id: str
    batch_id: Optional[str] = None
    timestamp: Optional[str] = None
    temperature: float = Field(..., description="Temperature in degrees Celsius (°C) from SHT30/31")
    humidity: float = Field(..., description="Relative Humidity percentage (%RH) from SHT30/31")
    mq135_raw: float = Field(..., description="Raw ADC reading or voltage from MQ-135 sensor (0-4095)")
    mq135_ppm: Optional[float] = Field(None, description="Calculated/calibrated air quality index / VOC ppm")
    mq136_raw: float = Field(..., description="Raw ADC reading or voltage from MQ-136 sensor (0-4095)")
    mq136_ppm: Optional[float] = Field(None, description="Calculated/calibrated H2S / sulfurous gas ppm")
    battery_pct: Optional[float] = Field(None, description="ESP32 battery voltage percentage if applicable")
    rssi: Optional[int] = Field(None, description="Wi-Fi Signal Strength (dBm)")


class TelemetryBatch(BaseModel):
    device_id: str
    gateway_id: Optional[str] = "rpi-gateway-01"
    readings: List[SensorReading]


class RiskAssessment(BaseModel):
    risk_score: float = Field(..., description="Composite Deterioration Risk Score (0-100)")
    risk_level: str = Field(..., description="'Low', 'Moderate', 'High', or 'Critical'")
    status_color: str = Field(..., description="'green', 'amber', 'orange', or 'red'")
    temperature_status: str
    humidity_status: str
    air_quality_status: str
    sulfur_gas_status: str
    primary_concern: str
    recommendations: List[str]
    evaluated_at: str


class StorageAlert(BaseModel):
    id: Optional[str] = None
    batch_id: str
    batch_name: str
    user_email: str
    severity: str = Field(..., description="'warning', 'danger', 'critical'")
    title: str
    message: str
    timestamp: str
    is_resolved: bool = False


class StorageAdvisoryResponse(BaseModel):
    batch_id: str
    batch_name: str
    risk_assessment: RiskAssessment
    advisory_text: str
    action_checklist: List[str]
    generated_at: str
    provider: str = "rule-engine"
