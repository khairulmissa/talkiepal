"""TalkiePal appointment booking router.
Register in main.py after initializing Firebase Admin:
    from talkiepal_booking_routes_corrected import router as booking_router
    app.include_router(booking_router)
"""

from datetime import datetime, timedelta, timezone
import re

from fastapi import APIRouter, Header, HTTPException
from pydantic import BaseModel, Field
from firebase_admin import auth, firestore
from google.cloud.firestore_v1 import transactional

router = APIRouter(prefix="/appointments", tags=["Appointments"])
MALAYSIA_TZ = timezone(timedelta(hours=8))


class BookingRequest(BaseModel):
    therapistId: str = Field(min_length=1)
    childId: str = Field(min_length=1)
    dateKey: str
    startHour: int = Field(ge=0, le=23)


@router.post("/book")
def book_appointment(
    payload: BookingRequest,
    authorization: str | None = Header(default=None),
):
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Sign in required.")

    try:
        token = authorization.removeprefix("Bearer ").strip()
        uid = auth.verify_id_token(token, check_revoked=True)["uid"]
    except Exception as exc:
        print("BOOKING AUTH ERROR:", type(exc).__name__, str(exc), flush=True)
        raise HTTPException(status_code=401, detail="Invalid authentication token.") from exc

    if not re.fullmatch(r"\d{4}-\d{2}-\d{2}", payload.dateKey):
        raise HTTPException(status_code=400, detail="Invalid date format.")
    if any("/" in value or value in (".", "..") for value in (payload.therapistId, payload.childId)):
        raise HTTPException(status_code=400, detail="Invalid therapist or child ID.")

    try:
        day = datetime.strptime(payload.dateKey, "%Y-%m-%d")
    except ValueError as exc:
        raise HTTPException(status_code=400, detail="Invalid calendar date.") from exc

    start = datetime(day.year, day.month, day.day, payload.startHour, tzinfo=MALAYSIA_TZ)
    end = start + timedelta(hours=1)
    now = datetime.now(MALAYSIA_TZ)

    print(
        f"BOOKING TIME CHECK: requested={start.isoformat()} "
        f"now={now.isoformat()} uid={uid}",
        flush=True,
    )
    if start <= now:
        raise HTTPException(
            status_code=400,
            detail=f"Select a future time. Malaysia time now: {now.strftime('%Y-%m-%d %I:%M %p')}.",
        )
    if start > now + timedelta(days=91):
        raise HTTPException(status_code=400, detail="Date is outside the booking window.")

    db = firestore.client()
    child_ref = db.collection("users").document(uid).collection("children").document(payload.childId)
    therapist_ref = db.collection("users").document(payload.therapistId)
    availability_ref = (
        db.collection("therapists").document(payload.therapistId)
        .collection("availability").document(payload.dateKey)
    )
    slot_id = f"{payload.therapistId}_{payload.dateKey.replace('-', '')}_{payload.startHour:02d}00"
    appointment_ref = db.collection("appointments").document(slot_id)
    slot_ref = (
        db.collection("therapists").document(payload.therapistId)
        .collection("availability_slots").document(slot_id)
    )
    parent_ref = db.collection("users").document(uid)

    @transactional
    def reserve(tx):
        # All Firestore reads must occur before any transaction writes.
        child_doc = child_ref.get(transaction=tx)
        therapist_doc = therapist_ref.get(transaction=tx)
        availability_doc = availability_ref.get(transaction=tx)
        appointment_doc = appointment_ref.get(transaction=tx)
        slot_doc = slot_ref.get(transaction=tx)
        parent_doc = parent_ref.get(transaction=tx)

        child = child_doc.to_dict() or {}
        therapist = therapist_doc.to_dict() or {}
        schedule = availability_doc.to_dict() or {}
        parent = parent_doc.to_dict() or {}

        assigned_id = child.get("primaryTherapistId") or child.get("assignedTherapistId")
        if not child_doc.exists or assigned_id != payload.therapistId:
            raise HTTPException(status_code=403, detail="Selected therapist is not assigned to this child.")

        if (
            not therapist_doc.exists
            or therapist.get("role") != "therapist"
            or therapist.get("isActive") is not True
            or therapist.get("verificationStatus") != "verified"
        ):
            raise HTTPException(status_code=403, detail="Therapist is not verified or active.")

        mode = schedule.get("mode", "default")
        if mode == "off":
            raise HTTPException(status_code=409, detail="Therapist is unavailable that day.")
        if mode == "custom":
            first, last = schedule.get("startHour"), schedule.get("endHour")
            if (
                type(first) is not int
                or type(last) is not int
                or not (first <= payload.startHour and payload.startHour + 1 <= last)
            ):
                raise HTTPException(status_code=409, detail="Outside therapist working hours.")
        elif mode != "default":
            raise HTTPException(status_code=409, detail="Invalid therapist schedule.")

        # Repeat time validation inside transaction, including retries.
        if start <= datetime.now(MALAYSIA_TZ):
            raise HTTPException(status_code=400, detail="This time has already passed.")

        existing = appointment_doc.to_dict() or {}
        if appointment_doc.exists and existing.get("status") != "cancelled":
            raise HTTPException(status_code=409, detail="This time is already booked.")

        slot = slot_doc.to_dict() or {}
        if slot_doc.exists and slot.get("status") == "booked" and existing.get("status") != "cancelled":
            raise HTTPException(status_code=409, detail="This time is already reserved.")

        tx.set(appointment_ref, {
            "parentId": uid,
            "parentName": parent.get("username") or parent.get("displayName") or "Parent",
            "therapistId": payload.therapistId,
            "therapistUid": payload.therapistId,
            "childId": payload.childId,
            "childName": child.get("name") or child.get("childName") or "Child",
            "therapistName": therapist.get("username") or therapist.get("name") or "Therapist",
            "dateKey": payload.dateKey,
            "startTime": f"{payload.startHour:02d}:00",
            "endTime": f"{payload.startHour + 1:02d}:00",
            "startAt": start,
            "endAt": end,
            "durationMinutes": 60,
            "status": "booked",
            "createdAt": firestore.SERVER_TIMESTAMP,
        })
        tx.set(slot_ref, {
            "dateKey": payload.dateKey,
            "startHour": payload.startHour,
            "status": "booked",
        })

    try:
        reserve(db.transaction())
    except HTTPException:
        raise
    except Exception as exc:
        print("BOOKING ERROR:", type(exc).__name__, str(exc), flush=True)
        raise HTTPException(
            status_code=500,
            detail="Unable to complete booking. Check backend logs.",
        ) from exc

    return {"success": True, "appointmentId": slot_id}
