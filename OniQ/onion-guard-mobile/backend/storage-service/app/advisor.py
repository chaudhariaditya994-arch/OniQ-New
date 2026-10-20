"""
OniQ Storage Advisory & AI Decision Support
Synthesizes telemetry, storage structure type, onion variety, and risk metrics
into actionable storage recommendations for farmers and warehouse managers.
"""

import os
import json
import re
from datetime import datetime, timezone
from typing import Dict, Any, List
import httpx
from app.models import RiskAssessment, StorageAdvisoryResponse

GEMINI_API_KEY = os.getenv("GEMINI_API_KEY", "")


async def generate_storage_advisory(
    batch: Dict[str, Any],
    latest_reading: Dict[str, Any],
    risk: RiskAssessment,
) -> StorageAdvisoryResponse:
    batch_id = str(batch.get("id", batch.get("_id", "unknown")))
    batch_name = str(batch.get("name", "Onion Lot"))
    variety = str(batch.get("variety", "Garwa (Rabi)"))
    structure = str(batch.get("structure_type", "Traditional Chawl"))
    now_iso = datetime.now(timezone.utc).isoformat()

    # Attempt AI advisory via Gemini if API key is present
    if GEMINI_API_KEY:
        try:
            return await _call_gemini_advisor(
                batch_id=batch_id,
                batch_name=batch_name,
                variety=variety,
                structure=structure,
                latest_reading=latest_reading,
                risk=risk,
                now_iso=now_iso,
            )
        except Exception:
            # Fall through to deterministic rule-based advisory on any failure
            pass

    return _generate_rule_based_advisory(
        batch_id=batch_id,
        batch_name=batch_name,
        variety=variety,
        structure=structure,
        latest_reading=latest_reading,
        risk=risk,
        now_iso=now_iso,
    )


async def _call_gemini_advisor(
    batch_id: str,
    batch_name: str,
    variety: str,
    structure: str,
    latest_reading: Dict[str, Any],
    risk: RiskAssessment,
    now_iso: str,
) -> StorageAdvisoryResponse:
    prompt = (
        f"You are OniQ AI, an expert post-harvest agricultural specialist in Indian onion storage "
        f"(following ICAR-DOGR guidelines).\n\n"
        f"Batch Context:\n"
        f"- Batch Name: {batch_name}\n"
        f"- Variety: {variety}\n"
        f"- Structure: {structure}\n"
        f"- Temperature: {latest_reading.get('temperature')} °C (Status: {risk.temperature_status})\n"
        f"- Relative Humidity: {latest_reading.get('humidity')} %RH (Status: {risk.humidity_status})\n"
        f"- MQ-135 Air Quality / VOCs: {latest_reading.get('mq135_raw')} (Status: {risk.air_quality_status})\n"
        f"- MQ-136 Sulfurous Gases / H2S: {latest_reading.get('mq136_raw')} (Status: {risk.sulfur_gas_status})\n"
        f"- Risk Score: {risk.risk_score}/100 ({risk.risk_level})\n"
        f"- Primary Concern: {risk.primary_concern}\n\n"
        f"Provide an actionable, practical storage advisory for the farmer.\n"
        f"Respond ONLY in this exact JSON structure, nothing else:\n"
        f'{{"advisory_text": "2-3 concise paragraphs explaining what is happening inside the storage heap and immediate steps", '
        f'"action_checklist": ["Specific actionable step 1", "Specific actionable step 2", "Specific actionable step 3"]}}'
    )

    url = (
        "https://generativelanguage.googleapis.com/v1beta/models/"
        f"gemini-2.5-flash:generateContent?key={GEMINI_API_KEY}"
    )
    payload = {
        "contents": [{"parts": [{"text": prompt}]}],
        "generationConfig": {
            "maxOutputTokens": 1024,
            "responseMimeType": "application/json",
        },
    }

    async with httpx.AsyncClient(timeout=30) as client:
        resp = await client.post(url, json=payload)

    if resp.status_code != 200:
        raise RuntimeError(f"Gemini error: {resp.status_code}")

    candidates = resp.json().get("candidates", [])
    if not candidates:
        raise RuntimeError("Empty response from Gemini")

    parts = candidates[0].get("content", {}).get("parts", [])
    raw_text = "".join(p.get("text", "") for p in parts if isinstance(p, dict))
    cleaned = re.sub(r"```json\s*", "", raw_text)
    cleaned = re.sub(r"```\s*", "", cleaned).strip()
    data = json.loads(cleaned)

    return StorageAdvisoryResponse(
        batch_id=batch_id,
        batch_name=batch_name,
        risk_assessment=risk,
        advisory_text=data.get("advisory_text", ""),
        action_checklist=data.get("action_checklist", risk.recommendations),
        generated_at=now_iso,
        provider="gemini-2.5-flash",
    )


def _generate_rule_based_advisory(
    batch_id: str,
    batch_name: str,
    variety: str,
    structure: str,
    latest_reading: Dict[str, Any],
    risk: RiskAssessment,
    now_iso: str,
) -> StorageAdvisoryResponse:
    temp = latest_reading.get("temperature", 28.0)
    rh = latest_reading.get("humidity", 65.0)

    advisory_lines = [
        f"**Storage Assessment for {batch_name} ({variety} in {structure}):**",
        f"Currently, ambient temperature is **{temp:.1f}°C** and relative humidity is **{rh:.1f}%**.",
        f"Overall deterioration risk is evaluated at **{risk.risk_score}/100 ({risk.risk_level})**.",
    ]

    if risk.risk_level == "Low":
        advisory_lines.append(
            "Environmental conditions within the storage structure remain in the optimal preservation zone. "
            "Bulb moisture respiration is balanced, minimizing fungal proliferation (Botrytis, Aspergillus) and sprout development."
        )
    elif risk.risk_level == "Moderate":
        advisory_lines.append(
            "Certain microclimate indicators are drifting beyond optimal storage parameters. "
            "Proactive ventilation management is advised to prevent moisture condensation and hot-spots in the central heap."
        )
    elif risk.risk_level == "High":
        advisory_lines.append(
            "WARNING: The monitored storage sector has entered high-risk conditions. "
            "Sustained moisture or thermal accumulation will trigger scale softening, fungal rot, or premature dormancy break."
        )
    else:  # Critical
        advisory_lines.append(
            "CRITICAL ALERT: Sensory parameters indicate active deterioration and volatile decomposition inside the onion stack. "
            "Immediate physical inspection and aeration are vital to halt chain spoilage to adjacent crates."
        )

    advisory_text = "\n\n".join(advisory_lines)

    checklist: List[str] = list(risk.recommendations)
    if not checklist:
        checklist = [
            "Check ambient relative humidity before morning and evening aeration.",
            "Maintain 15-20 cm air space below bamboo/wooden racks for bottom draft.",
            "Record daily dry and wet bulb temperature readings.",
        ]

    return StorageAdvisoryResponse(
        batch_id=batch_id,
        batch_name=batch_name,
        risk_assessment=risk,
        advisory_text=advisory_text,
        action_checklist=checklist,
        generated_at=now_iso,
        provider="oniq-agronomic-engine",
    )
