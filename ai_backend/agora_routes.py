import os
import hashlib
from datetime import datetime, timedelta, timezone

from fastapi import APIRouter, Header, HTTPException, Query
from firebase_admin import auth, firestore
from agora_token_builder import RtcTokenBuilder

router = APIRouter(prefix='/agora', tags=['Agora Video Call'])


def get_firebase_user(authorization: str | None):
    if not authorization or not authorization.startswith('Bearer '):
        raise HTTPException(status_code=401, detail='Firebase authentication required')
    try:
        return auth.verify_id_token(authorization.split(' ', 1)[1].strip())['uid']
    except Exception:
        raise HTTPException(status_code=401, detail='Invalid or expired Firebase ID token')


def agora_uid_for(firebase_uid: str) -> int:
    digest = hashlib.sha256(firebase_uid.encode('utf-8')).digest()
    return (int.from_bytes(digest[:4], 'big') % 2147483646) + 1


def to_utc(value):
    if not isinstance(value, datetime) or value.tzinfo is None:
        raise HTTPException(status_code=409, detail='Appointment timestamps must be timezone-aware')
    return value.astimezone(timezone.utc)


@router.get('/token/{appointment_id}')
def get_agora_token(
    appointment_id: str,
    callId: str = Query(..., min_length=1),
    authorization: str | None = Header(default=None),
):
    firebase_uid = get_firebase_user(authorization)
    app_id = os.getenv('AGORA_APP_ID')
    certificate = os.getenv('AGORA_APP_CERTIFICATE')
    if not app_id or not certificate:
        raise HTTPException(status_code=500, detail='Agora backend credentials are missing')

    db = firestore.client()
    appointment = db.collection('appointments').document(appointment_id).get()
    if not appointment.exists:
        raise HTTPException(status_code=404, detail='Appointment not found')
    data = appointment.to_dict() or {}
    parent_id, therapist_id = data.get('parentId'), data.get('therapistId')
    if not parent_id or not therapist_id or parent_id == therapist_id:
        raise HTTPException(status_code=409, detail='Appointment participants are invalid')
    if firebase_uid not in (parent_id, therapist_id):
        raise HTTPException(status_code=403, detail='Not a participant in this appointment')
    if data.get('status') not in ('booked', 'confirmed'):
        raise HTTPException(status_code=403, detail='Appointment is not booked or confirmed')

    start_at, end_at = to_utc(data.get('startAt')), to_utc(data.get('endAt'))
    now = datetime.now(timezone.utc)
    if end_at <= start_at:
        raise HTTPException(status_code=409, detail='Invalid appointment time range')
    if not start_at <= now < end_at:
        raise HTTPException(status_code=403, detail='Outside scheduled video session')

    call_doc = db.collection('video_calls').document(callId).get()
    if not call_doc.exists:
        raise HTTPException(status_code=404, detail='Video call not found')
    call = call_doc.to_dict() or {}
    if (call.get('appointmentId') != appointment_id or
            call.get('parentId') != parent_id or
            call.get('therapistId') != therapist_id or
            call.get('childId') != data.get('childId')):
        raise HTTPException(status_code=403, detail='Call does not match appointment')
    caller, receiver = call.get('callerId'), call.get('receiverId')
    if {caller, receiver} != {parent_id, therapist_id} or caller == receiver:
        raise HTTPException(status_code=403, detail='Invalid call participants')
    if call.get('callerRole') != ('parent' if caller == parent_id else 'therapist'):
        raise HTTPException(status_code=403, detail='Invalid caller role')
    if call.get('status') != 'accepted' or call.get('answeredAt') is None:
        raise HTTPException(status_code=403, detail='Call is not accepted')

    channel_name = 'talkiepal_' + hashlib.sha256(appointment_id.encode('utf-8')).hexdigest()[:32]
    agora_uid = agora_uid_for(firebase_uid)
    if agora_uid_for(parent_id) == agora_uid_for(therapist_id):
        raise HTTPException(status_code=409, detail='Agora UID collision')

    remaining = int((end_at - now).total_seconds())
    if remaining <= 0:
        raise HTTPException(status_code=403, detail='Session ended')
    # Valid until appointment ends, so a 60-minute call does not expire at 15 minutes.
    expires_at = int(now.timestamp()) + remaining
    try:
        token = RtcTokenBuilder.buildTokenWithUid(
            app_id, certificate, channel_name, agora_uid, 1, expires_at
        )
    except Exception:
        raise HTTPException(status_code=500, detail='Could not generate Agora token')
    return {
        'appId': app_id, 'token': token, 'channelName': channel_name,
        'uid': agora_uid, 'appointmentId': appointment_id,
        'callId': callId, 'expiresAt': expires_at,
    }
