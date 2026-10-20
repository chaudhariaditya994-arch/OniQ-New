import os
import io
from fastapi import FastAPI, HTTPException
from fastapi.responses import StreamingResponse
from gtts import gTTS
from app.treatment_data import TREATMENTS

app = FastAPI(title="OnionGuard Treatment Service", version="1.0.0")

LANG_MAP = {
    "en": "en",
    "tw": "en",  # gTTS doesn't support Twi natively; use English TTS with Twi text
    "dg": "en",  # Dagbani fallback
    "ee": "en",  # Ewe fallback
    "ha": "ha",  # Hausa is supported by gTTS
}


@app.get("/health")
async def health():
    return {"status": "ok", "service": "treatment-service"}


@app.get("/treatment/{disease_name}")
async def get_treatment(disease_name: str):
    treatment = TREATMENTS.get(disease_name)
    if not treatment:
        available = list(TREATMENTS.keys())
        raise HTTPException(
            status_code=404,
            detail=f"Disease '{disease_name}' not found. Available: {available}"
        )

    return {"success": True, "treatment": treatment}


@app.get("/treatment/{disease_name}/voice/{language}")
async def get_voice(disease_name: str, language: str):
    treatment = TREATMENTS.get(disease_name)
    if not treatment:
        raise HTTPException(status_code=404, detail=f"Disease '{disease_name}' not found")

    description = treatment["description"].get(language)
    if not description:
        description = treatment["description"]["en"]

    # Build full voice text
    steps = treatment.get("treatment_steps", [])
    steps_text = ". ".join(f"Step {i+1}: {s}" for i, s in enumerate(steps))
    full_text = f"{treatment['disease_name']}. {description}. Treatment: {steps_text}"

    # Get gTTS language code
    tts_lang = LANG_MAP.get(language, "en")

    try:
        tts = gTTS(text=full_text, lang=tts_lang, slow=False)
        audio_buffer = io.BytesIO()
        tts.write_to_fp(audio_buffer)
        audio_buffer.seek(0)

        return StreamingResponse(
            audio_buffer,
            media_type="audio/mpeg",
            headers={"Content-Disposition": f"attachment; filename={disease_name}_{language}.mp3"},
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Voice generation failed: {str(e)}")


@app.get("/treatments")
async def list_treatments():
    summary = {}
    for name, data in TREATMENTS.items():
        summary[name] = {
            "disease_name": data["disease_name"],
            "severity": data["severity"],
            "symptoms_count": len(data["symptoms"]),
            "treatment_steps_count": len(data["treatment_steps"]),
        }
    return {"success": True, "treatments": summary}


if __name__ == "__main__":
    import uvicorn
    port = int(os.getenv("PORT", 8003))
    uvicorn.run(app, host="0.0.0.0", port=port)
