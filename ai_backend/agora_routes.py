
import os
import hashlib
from datetime import datetime, timedelta, timezone

from fastapi import APIRouter, Header, HTTPException
from firebase_admin import auth, firestore
from agora_token_builder import RtcTokenBuilder

router = APIRouter(prefix="/agora", tags=["Agora Video Call"])


def get_firebase_user(authorization: str | None):
    """Verify the Firebase ID token sent by Flutter."""
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(
            status_code=401,
            detail="Firebase authentication required",
        )

    id_token = authorization.split(" ", 1)[1].strip()

    try:
        decoded = auth.verify_id_token(id_token)
        return decoded["uid"]
    except Exception:
        raise HTTPException(
            status_code=401,
            detail="Invalid or expired Firebase ID token",
        )


def agora_uid_for(firebase_uid: str) -> int:
    """Create a stable, nonzero numeric Agora UID."""
    digest = hashlib.sha256(firebase_uid.encode("utf-8")).digest()
    return (int.from_bytes(digest[:4], "big") % 2147483646) + 1


def to_utc(value):
    """Accept Firestore timestamps represented as Python datetimes."""
    if not isinstance(value, datetime):
        raise HTTPException(
            status_code=409,
            detail="Appointment startAt/endAt must be Firestore timestamps",
        )

    if value.tzinfo is None:
        raise HTTPException(
            status_code=409,
            detail="Appointment timestamp has no timezone",
        )

    return value.astimezone(timezone.utc)


@router.get("/token/{appointment_id}")
def get_agora_token(
    appointment_id: str,
    authorization: str | None = Header(default=None),
):
    firebase_uid = get_firebase_user(authorization)

    app_id = os.getenv("AGORA_APP_ID")
    certificate = os.getenv("AGORA_APP_CERTIFICATE")

    if not app_id or not certificate:
        raise HTTPException(
            status_code=500,
            detail="Agora backend credentials are missing",
        )

    # Firebase Admin must be initialized in main.py.
    db = firestore.client()

    appointment = db.collection("appointments").document(
        appointment_id
    ).get()

    if not appointment.exists:
        raise HTTPException(
            status_code=404,
            detail="Appointment not found",
        )

    data = appointment.to_dict() or {}

    parent_id = data.get("parentId")
    therapist_id = data.get("therapistId")

    # Only the booked parent or therapist can request a token.
    if firebase_uid not in (parent_id, therapist_id):
        raise HTTPException(
            status_code=403,
            detail="You are not a participant in this appointment",
        )

    if not parent_id or not therapist_id or parent_id == therapist_id:
        raise HTTPException(
            status_code=409,
            detail="Appointment participants are invalid",
        )

    if data.get("status") not in ("booked", "confirmed"):
        raise HTTPException(
            status_code=403,
            detail="Appointment is not confirmed",
        )

    start_at = to_utc(data.get("startAt"))
    end_at = to_utc(data.get("endAt"))
    now = datetime.now(timezone.utc)

    if end_at - start_at != timedelta(minutes=60):
        raise HTTPException(
            status_code=409,
            detail="Appointment must last exactly 60 minutes",
        )

    if now < start_at:
        raise HTTPException(
            status_code=403,
            detail="Video session has not started yet",
        )

    if now >= end_at:
        raise HTTPException(
            status_code=403,
            detail="Video session has ended",
        )

    # A unique Agora channel for this appointment.
    channel_name = "talkiepal_" + hashlib.sha256(
        appointment_id.encode("utf-8")
    ).hexdigest()[:32]

    agora_uid = agora_uid_for(firebase_uid)

    # Prevent the two participants from sharing the same Agora UID.
    if agora_uid_for(parent_id) == agora_uid_for(therapist_id):
        raise HTTPException(
            status_code=409,
            detail="Agora participant UID collision",
        )

    # Token is short-lived and never extends past session end.
    remaining_seconds = int((end_at - now).total_seconds())
    token_lifetime = min(900, remaining_seconds)

    if token_lifetime <= 0:
        raise HTTPException(
            status_code=403,
            detail="Video session has ended",
        )

    expires_at = int(now.timestamp()) + token_lifetime

    try:
        rtc_token = RtcTokenBuilder.buildTokenWithUid(
            app_id,
            certificate,
            channel_name,
            agora_uid,
            1,  # Publisher role: video and audio
            expires_at,
        )
    except Exception:
        raise HTTPException(
            status_code=500,
            detail="Could not generate Agora token",
        )

    return {
        "appId": app_id,
        "token": rtc_token,
        "channelName": channel_name,
        "uid": agora_uid,
        "appointmentId": appointment_id,
        "expiresAt": expires_at,
    }
