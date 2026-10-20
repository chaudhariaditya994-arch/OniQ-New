"""
OniQ Agronomic Decision & Rules Engine
Calibrated for Indian Onion Storage Structures (Naturally Ventilated Chawls & Godowns)
In accordance with ICAR-DOGR (Directorate of Onion and Garlic Research) post-harvest standards.
"""

from datetime import datetime, timezone
from typing import Dict, Any, List
from app.models import RiskAssessment


def evaluate_sensor_telemetry(reading: Dict[str, Any]) -> RiskAssessment:
    temp = float(reading.get("temperature", 28.0))
    rh = float(reading.get("humidity", 65.0))
    mq135 = float(reading.get("mq135_raw", 600.0))
    mq136 = float(reading.get("mq136_raw", 350.0))

    temp_score = 0.0
    rh_score = 0.0
    mq135_score = 0.0
    mq136_score = 0.0

    temp_status = "Optimal (25-30°C)"
    rh_status = "Optimal (65-70% RH)"
    air_status = "Good / Normal Baseline"
    sulfur_status = "Safe / Undetected"

    concerns: List[str] = []
    recommendations: List[str] = []

    # 1. Temperature Evaluation
    if 24.0 <= temp <= 30.5:
        temp_score = 5.0
        temp_status = f"Optimal ({temp:.1f}°C) - Natural dormancy preserved"
    elif 30.5 < temp <= 33.0:
        temp_score = 25.0
        temp_status = f"Elevated ({temp:.1f}°C) - Mild heat stress"
        concerns.append("Ambient temperature exceeding 30°C increases bulb respiration and moisture loss.")
        recommendations.append("Ensure top ridge ventilators and side shades are fully open during afternoon heat.")
    elif temp > 33.0:
        temp_score = 50.0
        temp_status = f"Severe Heat ({temp:.1f}°C) - Accelerating desiccation"
        concerns.append("High heat stress (>33°C) promotes scale peeling, weight shrinkage, and black mold (Aspergillus).")
        recommendations.append("Dampen the ground outside the chawl (without wetting the onions) or install shading nets to reduce radiant heat.")
    elif 10.0 <= temp < 20.0:
        if rh > 70.0:
            temp_score = 45.0
            temp_status = f"Sprouting Risk ({temp:.1f}°C with high RH)"
            concerns.append("Cool temperatures combined with high moisture break bulb dormancy, triggering root sprouting.")
            recommendations.append("Increase air circulation to keep bulbs dry and prevent sprout initiation.")
        else:
            temp_score = 20.0
            temp_status = f"Cool ({temp:.1f}°C) - Monitor humidity"
    else:
        temp_score = 15.0

    # 2. Relative Humidity Evaluation
    if 62.0 <= rh <= 70.0:
        rh_score = 5.0
        rh_status = f"Optimal ({rh:.1f}% RH) - Safe storage range"
    elif rh < 60.0:
        rh_score = 25.0
        rh_status = f"Dry ({rh:.1f}% RH) - Risk of desiccation"
        concerns.append("Low relative humidity (<60%) causes excessive water loss and brittle papery scales.")
        recommendations.append("Reduce turbulent draft ventilation during hot, dry winds to limit shrinkage.")
    elif 70.0 < rh <= 75.0:
        rh_score = 35.0
        rh_status = f"Warning: High Moisture ({rh:.1f}% RH)"
        concerns.append("Humidity between 70-75% creates micro-climates favoring neck rot (Botrytis) and fungal spores.")
        recommendations.append("Turn on bottom-ventilation fans or open bottom louvers for 45 minutes to evacuate trapped humid air.")
    else:  # rh > 75.0%
        rh_score = 60.0
        rh_status = f"CRITICAL: Excessive Humidity ({rh:.1f}% RH)"
        concerns.append("Humidity above 75% triggers rapid fungal germination, damp bulb necks, and soft rotting.")
        recommendations.append("URGENT: Force cross-ventilation immediately. Check top and bottom layers of the stack for dampness.")

    # 3. Air Quality (MQ-135) Evaluation (VOCs, CO2, and fermentation gases)
    # Calibrated assuming ADC 0-4095 range
    if mq135 < 900:
        mq135_score = 5.0
        air_status = f"Fresh ({mq135:.0f}) - Good natural airflow"
    elif 900 <= mq135 <= 1400:
        mq135_score = 30.0
        air_status = f"Moderate VOCs ({mq135:.0f}) - Stagnant air accumulation"
        concerns.append("Elevated organic volatiles indicate stagnant air or early bulb respiration build-up.")
        recommendations.append("Check that ventilation passages are not obstructed by overfilled onion heaps.")
    else:
        mq135_score = 55.0
        air_status = f"High VOCs / Stale ({mq135:.0f}) - Trapped respiration gases"
        concerns.append("High volatile gas levels indicate trapped respiration gases or localized fermentation.")
        recommendations.append("Run exhaust ventilation to flush accumulated heavy gases from the lower storage zone.")

    # 4. Hydrogen Sulfide & Sulfurous Gases (MQ-136) Evaluation (Rotting Indicator)
    # Decomposing onion allicin and sulfur compounds produce distinct spikes
    if mq136 < 600:
        mq136_score = 5.0
        sulfur_status = f"Normal ({mq136:.0f}) - No rotting detected"
    elif 600 <= mq136 <= 1100:
        mq136_score = 40.0
        sulfur_status = f"ALERT: Early Sulfurous Emission ({mq136:.0f})"
        concerns.append("Rising sulfur/H2S signals indicate localized bulb soft-rot decay starting inside the heap.")
        recommendations.append("Inspect the monitored bay immediately for soft, watery, or foul-smelling bulbs.")
    else:  # mq136 > 1100
        mq136_score = 75.0
        sulfur_status = f"CRITICAL: Active Spoilage Gases ({mq136:.0f})"
        concerns.append("High sulfurous gas concentration confirms active onion rotting and bacterial breakdown.")
        recommendations.append("CRITICAL: Isolate and sort the affected lot immediately to prevent disease spread to neighboring bulbs.")

    # 5. Composite Risk Calculation
    # Weights: Humidity (35%), Sulfurous Rot Gas (30%), Temperature (20%), Air Quality (15%)
    raw_composite = (
        (rh_score * 0.35) +
        (mq136_score * 0.30) +
        (temp_score * 0.20) +
        (mq135_score * 0.15)
    )
    risk_score = round(min(100.0, max(0.0, raw_composite)), 1)

    # Classify overall risk level
    if risk_score <= 30.0:
        risk_level = "Low"
        status_color = "green"
        primary_concern = "Storage environment is optimal. Natural curing and dormancy conditions are stable."
        if not recommendations:
            recommendations.append("Continue standard passive ventilation monitoring. Keep log of daily weather swings.")
    elif risk_score <= 60.0:
        risk_level = "Moderate"
        status_color = "amber"
        primary_concern = "; ".join(concerns) if concerns else "Conditions deviate slightly from ideal storage ranges."
        if not recommendations:
            recommendations.append("Inspect storage ventilation louvers and check ambient outdoor weather.")
    elif risk_score <= 80.0:
        risk_level = "High"
        status_color = "orange"
        primary_concern = "; ".join(concerns) if concerns else "Environmental parameters favor fungal growth or rot development."
    else:
        risk_level = "Critical"
        status_color = "red"
        primary_concern = "DANGER: " + ("; ".join(concerns) if concerns else "High risk of rapid batch spoilage and rot spread.")

    now_iso = datetime.now(timezone.utc).isoformat()

    return RiskAssessment(
        risk_score=risk_score,
        risk_level=risk_level,
        status_color=status_color,
        temperature_status=temp_status,
        humidity_status=rh_status,
        air_quality_status=air_status,
        sulfur_gas_status=sulfur_status,
        primary_concern=primary_concern,
        recommendations=recommendations,
        evaluated_at=now_iso,
    )
