import io
import os
import re
import threading
import wave

import numpy as np
from fastapi import APIRouter, File, Form, HTTPException, UploadFile
from pydantic import BaseModel

import pronunciation

router = APIRouter(prefix="/speech", tags=["speech"])

WHISPER_MODEL = os.getenv("WHISPER_MODEL", "base.en")
WHISPER_DEVICE = os.getenv("WHISPER_DEVICE", "cpu")
WHISPER_COMPUTE = os.getenv("WHISPER_COMPUTE", "int8")

SAMPLE_RATE = 16000
MAX_UPLOAD_BYTES = 5 * 1024 * 1024
MAX_SECONDS = 30.0
MIN_SECONDS = 0.15
PAD_SECONDS = 0.5
SHORT_MIN_SECONDS = 1.5
SILENT_PEAK_DB = -45.0
TARGET_PEAK = 0.9
NO_SPEECH_PROB = 0.6
LOW_LOGPROB = -1.0

HALLUCINATIONS = {
    "thanks for watching",
    "thank you for watching",
    "please subscribe",
    "subscribe to my channel",
    "like and subscribe",
}

_model = None
_model_lock = threading.Lock()
_run_lock = threading.Lock()


class SoundMistake(BaseModel):
    expected: str
    heard: str | None = None


class Pronunciation(BaseModel):
    score: int
    expected: list[str]
    heard: list[str]
    mistakes: list[SoundMistake]


class TranscribeResponse(BaseModel):
    text: str
    alternatives: list[str]
    heard: bool
    reason: str
    seconds: float
    pronunciation: Pronunciation | None = None


def get_model():
    global _model
    if _model is None:
        with _model_lock:
            if _model is None:
                from faster_whisper import WhisperModel

                _model = WhisperModel(
                    WHISPER_MODEL,
                    device=WHISPER_DEVICE,
                    compute_type=WHISPER_COMPUTE,
                )
    return _model


def load_whisper_in_background():
    def load():
        try:
            get_model()
            print(f"WHISPER READY: {WHISPER_MODEL}", flush=True)
        except Exception as error:
            print(f"WHISPER NOT LOADED: {error}", flush=True)
        pronunciation.load_in_background()

    threading.Thread(target=load, daemon=True).start()


def read_wav(data: bytes) -> np.ndarray:
    try:
        with wave.open(io.BytesIO(data), "rb") as wav:
            channels = wav.getnchannels()
            width = wav.getsampwidth()
            rate = wav.getframerate()
            frames = wav.readframes(wav.getnframes())
    except (wave.Error, EOFError) as error:
        raise HTTPException(status_code=400, detail=f"Audio must be a WAV file: {error}")

    if width != 2:
        raise HTTPException(status_code=400, detail="Audio must be 16-bit PCM WAV")

    audio = np.frombuffer(frames, dtype="<i2").astype(np.float32) / 32768.0
    if channels > 1:
        audio = audio[: len(audio) - len(audio) % channels].reshape(-1, channels).mean(axis=1)

    if rate != SAMPLE_RATE and len(audio) > 1:
        new_length = int(round(len(audio) * SAMPLE_RATE / rate))
        old_positions = np.linspace(0, len(audio) - 1, num=len(audio))
        new_positions = np.linspace(0, len(audio) - 1, num=max(new_length, 1))
        audio = np.interp(new_positions, old_positions, audio).astype(np.float32)

    return audio


def peak_db(audio: np.ndarray) -> float:
    if audio.size == 0:
        return -120.0
    frame = int(SAMPLE_RATE * 0.03)
    usable = audio.size - audio.size % frame
    if usable <= 0:
        rms = float(np.sqrt(np.mean(audio ** 2)))
    else:
        frames = audio[:usable].reshape(-1, frame)
        rms = float(np.sqrt(np.mean(frames ** 2, axis=1)).max())
    if rms <= 0:
        return -120.0
    return 20.0 * np.log10(rms)


def prepare(audio: np.ndarray, short: bool) -> np.ndarray:
    audio = audio - float(np.mean(audio))
    peak = float(np.max(np.abs(audio))) if audio.size else 0.0
    if peak > 0:
        audio = audio * min(TARGET_PEAK / peak, 20.0)

    pad = np.zeros(int(SAMPLE_RATE * PAD_SECONDS), dtype=np.float32)
    audio = np.concatenate([pad, audio.astype(np.float32), pad])

    if short:
        missing = int(SAMPLE_RATE * SHORT_MIN_SECONDS) - audio.size
        if missing > 0:
            half = np.zeros(missing // 2 + 1, dtype=np.float32)
            audio = np.concatenate([half, audio, half])

    return audio.astype(np.float32)


def clean_text(text: str) -> str:
    return re.sub(r"\s+", " ", text).strip()


def is_hallucination(text: str) -> bool:
    plain = re.sub(r"[^a-z ]", "", text.lower()).strip()
    return plain in HALLUCINATIONS


def run_whisper(audio: np.ndarray, short: bool, use_vad: bool) -> str:
    options = dict(
        language="en",
        task="transcribe",
        beam_size=5,
        best_of=5,
        temperature=[0.0, 0.2, 0.4],
        condition_on_previous_text=False,
        no_speech_threshold=NO_SPEECH_PROB,
        log_prob_threshold=LOW_LOGPROB,
        without_timestamps=short,
        vad_filter=use_vad,
    )
    if use_vad:
        options["vad_parameters"] = dict(
            threshold=0.35,
            min_speech_duration_ms=100,
            min_silence_duration_ms=1500,
            speech_pad_ms=400,
        )

    model = get_model()
    parts = []
    with _run_lock:
        segments, _ = model.transcribe(audio, **options)
        for segment in segments:
            if segment.no_speech_prob > NO_SPEECH_PROB and segment.avg_logprob < LOW_LOGPROB:
                continue
            text = clean_text(segment.text)
            if text and not is_hallucination(text):
                parts.append(text)

    return clean_text(" ".join(parts))


def alternatives_for(text: str) -> list[str]:
    results = [text]
    plain = clean_text(re.sub(r"[^\w' ]", " ", text))
    if plain and plain.lower() != text.lower():
        results.append(plain)
    return results


@router.get("/health")
def speech_health():
    return {
        "model": WHISPER_MODEL,
        "ready": _model is not None,
        "phoneme_model": pronunciation.PHONEME_MODEL,
        "phoneme_ready": pronunciation.is_ready(),
    }


@router.post("/transcribe", response_model=TranscribeResponse)
def transcribe(
    audio: UploadFile = File(...),
    short: bool = Form(False),
    target: str = Form(""),
):
    data = audio.file.read(MAX_UPLOAD_BYTES + 1)
    if len(data) > MAX_UPLOAD_BYTES:
        raise HTTPException(status_code=413, detail="Recording is too long")

    samples = read_wav(data)
    seconds = round(samples.size / SAMPLE_RATE, 2)

    if seconds < MIN_SECONDS:
        return TranscribeResponse(text="", alternatives=[], heard=False, reason="too_short", seconds=seconds)
    if seconds > MAX_SECONDS:
        samples = samples[: int(SAMPLE_RATE * MAX_SECONDS)]
    if peak_db(samples) < SILENT_PEAK_DB:
        return TranscribeResponse(text="", alternatives=[], heard=False, reason="too_quiet", seconds=seconds)

    prepared = prepare(samples, short)

    try:
        text = run_whisper(prepared, short, use_vad=not short)
        if not text and not short:
            text = run_whisper(prepared, short, use_vad=False)
    except Exception as error:
        raise HTTPException(status_code=503, detail=f"Speech model is not available: {error}")

    if not text:
        return TranscribeResponse(text="", alternatives=[], heard=False, reason="no_words", seconds=seconds)

    return TranscribeResponse(
        text=text,
        alternatives=alternatives_for(text),
        heard=True,
        reason="ok",
        seconds=seconds,
        pronunciation=check_pronunciation(prepared, target),
    )


def check_pronunciation(audio: np.ndarray, target: str):
    target = target.strip()
    if not target or not pronunciation.is_ready():
        return None
    try:
        result = pronunciation.assess(audio, target)
    except Exception as error:
        print(f"PHONEME CHECK FAILED: {error}", flush=True)
        return None
    if result is None:
        return None
    print(f"PHONEME {target!r}: expected {result['expected']} heard {result['ipa']!r} -> {result['score']}", flush=True)
    return Pronunciation(
        score=result["score"],
        expected=result["expected"],
        heard=result["heard"],
        mistakes=[SoundMistake(**m) for m in result["mistakes"]],
    )