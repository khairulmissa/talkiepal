from pathlib import Path
import os
from typing import Literal

from dotenv import load_dotenv

# =====================================================
# LOAD ENVIRONMENT VARIABLES
# =====================================================

load_dotenv(
    Path(__file__).resolve().parent.parent / "ai_backend" / ".env",
    override=True,
)

from fastapi import FastAPI, Depends, HTTPException
from pydantic import BaseModel
from supabase import create_client

from firebase_service import db
from admin_auth import require_admin
from therapist_service import register_therapist, approve_therapist
from user_service import manage_account
from notification_service import send_admin_notification


# =====================================================
# FASTAPI APPLICATION
# =====================================================

app = FastAPI(
    title="TalkiePal Admin Backend",
    description="Admin API for TalkiePal Speech Therapy Application",
    version="1.0.0",
)


# =====================================================
# REQUEST MODELS
# =====================================================

class TherapistCreate(BaseModel):
    name: str
    email: str
    password: str


class AccountAction(BaseModel):
    uid: str
    action: Literal["suspend", "reactivate"]


class NotificationRequest(BaseModel):
    title: str
    body: str
    audience: Literal["all", "parents", "therapists", "kids"]


# =====================================================
# HOME
# =====================================================

@app.get("/")
def home():
    return {
        "message": "TalkiePal Admin Backend is working!",
        "status": "success",
    }


# =====================================================
# REGISTER THERAPIST
# =====================================================

@app.post("/admin/therapists")
def create_therapist(
    data: TherapistCreate,
    admin_uid: str = Depends(require_admin),
):
    try:
        return register_therapist(
            name=data.name.strip(),
            email=data.email.strip().lower(),
            password=data.password,
        )

    except ValueError as e:
        raise HTTPException(
            status_code=400,
            detail=str(e),
        ) from e

    except Exception as e:
        print(
            "Register therapist error:",
            type(e).__name__,
        )
        raise HTTPException(
            status_code=500,
            detail="Unable to register therapist",
        ) from e


# =====================================================
# APPROVE THERAPIST
# =====================================================

@app.patch("/admin/therapists/{uid}/approve")
def approve_therapist_endpoint(
    uid: str,
    admin_uid: str = Depends(require_admin),
):
    try:
        return approve_therapist(uid)

    except ValueError as e:
        raise HTTPException(
            status_code=400,
            detail=str(e),
        ) from e

    except Exception as e:
        print(
            "Approve therapist error:",
            type(e).__name__,
        )
        raise HTTPException(
            status_code=500,
            detail="Unable to approve therapist",
        ) from e


# =====================================================
# SUSPEND / REACTIVATE ACCOUNT
# =====================================================

@app.post("/admin/accounts/action")
def account_action(
    data: AccountAction,
    admin_uid: str = Depends(require_admin),
):
    try:
        return manage_account(
            uid=data.uid,
            action=data.action,
            admin_uid=admin_uid,
        )

    except ValueError as e:
        raise HTTPException(
            status_code=400,
            detail=str(e),
        ) from e

    except Exception as e:
        print(
            "Manage account error:",
            type(e).__name__,
        )
        raise HTTPException(
            status_code=500,
            detail="Unable to manage account",
        ) from e


# =====================================================
# ADMIN NOTIFICATIONS
# =====================================================

@app.post("/admin/notifications")
def create_notification(
    data: NotificationRequest,
    admin_uid: str = Depends(require_admin),
):
    try:
        return send_admin_notification(
            title=data.title,
            body=data.body,
            audience=data.audience,
            admin_uid=admin_uid,
        )

    except ValueError as e:
        raise HTTPException(
            status_code=400,
            detail=str(e),
        ) from e

    except Exception as e:
        print(
            "Send notification error:",
            type(e).__name__,
        )
        raise HTTPException(
            status_code=500,
            detail="Unable to send notification",
        ) from e


# =====================================================
# ADMIN DASHBOARD STATISTICS
# =====================================================

@app.get("/admin/dashboard-stats")
def get_dashboard_stats(
    admin_uid: str = Depends(require_admin),
):
    try:
        users = list(db.collection("users").stream())

        parents = 0
        therapists = 0
        active_accounts = 0

        for doc in users:
            data = doc.to_dict() or {}
            role = data.get("role")

            if role == "parent":
                parents += 1

            if role == "therapist":
                therapists += 1

            if (
                data.get("isActive") is not False
                and data.get("accountStatus") != "suspended"
            ):
                active_accounts += 1

        children = sum(
            1 for _ in db.collection_group("children").stream()
        )

        admin_doc = (
            db.collection("users")
            .document(admin_uid)
            .get()
        )

        admin_data = (
            admin_doc.to_dict() or {}
        ) if admin_doc.exists else {}

        normalized_admin_data = {
            str(key).strip(): value
            for key, value in admin_data.items()
        }

        username = str(
            normalized_admin_data.get("username") or ""
        ).strip()

        name = str(
            normalized_admin_data.get("name") or ""
        ).strip()

        return {
            "success": True,
            "parents": parents,
            "therapists": therapists,
            "children": children,
            "activeAccounts": active_accounts,
            "adminName": (
                username or name or "Administrator"
            ),
        }

    except Exception as e:
        print(
            "Dashboard statistics error:",
            type(e).__name__,
        )
        raise HTTPException(
            status_code=500,
            detail="Unable to load dashboard statistics",
        ) from e


# =====================================================
# SUPABASE PRIVATE STORAGE SIGNED URL
# =====================================================

def _signed_storage_url(
    bucket: str,
    path: str,
    seconds: int = 3600,
) -> str:

    path = str(path or "").strip()

    if (
        not path
        or path.startswith(("http://", "https://", "/"))
        or "\\" in path
        or any(
            part in ("", ".", "..")
            for part in path.split("/")
        )
    ):
        raise HTTPException(
            status_code=400,
            detail="Invalid storage object path",
        )

    supabase_url = os.getenv("SUPABASE_URL")
    supabase_key = os.getenv("SUPABASE_SERVICE_ROLE_KEY")

    if not supabase_url or not supabase_key:
        raise HTTPException(
            status_code=503,
            detail="Supabase backend configuration missing",
        )

    try:
        client = create_client(
            supabase_url,
            supabase_key,
        )

        result = (
            client.storage
            .from_(bucket)
            .create_signed_url(path, seconds)
        )

        signed_url = (
            result.get("signedURL")
            or result.get("signedUrl")
            or result.get("signed_url")
        )

        if not signed_url:
            raise ValueError(
                "Supabase returned no signed URL"
            )

        return signed_url

    except Exception as e:
        print(
            "Supabase signed URL error:",
            type(e).__name__,
            "bucket:",
            bucket,
        )

        raise HTTPException(
            status_code=502,
            detail="Unable to generate signed URL",
        ) from e


# =====================================================
# THERAPIST CERTIFICATE - PRIVATE STORAGE
# =====================================================

@app.get("/admin/therapists/{uid}/certificate")
def get_therapist_certificate(
    uid: str,
    admin_uid: str = Depends(require_admin),
):

    therapist_doc = (
        db.collection("therapists")
        .document(uid)
        .get()
    )

    if not therapist_doc.exists:
        raise HTTPException(
            status_code=404,
            detail="Therapist not found",
        )

    therapist = therapist_doc.to_dict() or {}

    path = str(
        therapist.get("certificatePath") or ""
    ).strip()

    if not path:
        raise HTTPException(
            status_code=404,
            detail="Certificate path missing in Firestore",
        )

    if path.startswith("therapist-certificates/"):
        path = path[len("therapist-certificates/"):]

    signed_url = _signed_storage_url(
        bucket="therapist-certificates",
        path=path,
        seconds=300,
    )

    return {
        "url": signed_url,
    }


# =====================================================
# PARENT PROFILE PHOTO - PRIVATE STORAGE
# =====================================================

@app.get("/admin/parents/{uid}/photo")
def get_parent_photo(
    uid: str,
    admin_uid: str = Depends(require_admin),
):

    parent_doc = (
        db.collection("users")
        .document(uid)
        .get()
    )

    if not parent_doc.exists:
        raise HTTPException(
            status_code=404,
            detail="Parent not found",
        )

    parent = parent_doc.to_dict() or {}

    if parent.get("role") != "parent":
        raise HTTPException(
            status_code=400,
            detail="Account is not a parent",
        )

    path = str(
        parent.get("parentPhotoPath") or ""
    ).strip()

    if not path:
        raise HTTPException(
            status_code=404,
            detail="Parent photo not found",
        )

    # Remove bucket prefix if present.
    if path.startswith("parent-photos/"):
        path = path[len("parent-photos/"):]

    signed_url = _signed_storage_url(
        bucket="parent-photos",
        path=path,
        seconds=3600,
    )

    return {
        "url": signed_url,
    }


# =====================================================
# SYSTEM REPORTS - ADMIN ONLY
# =====================================================
from datetime import datetime, date, time, timedelta
from fastapi import Query


def _report_date(value):
    if isinstance(value, datetime):
        return value.date()
    if isinstance(value, date):
        return value
    if isinstance(value, str):
        try:
            return date.fromisoformat(value[:10])
        except ValueError:
            return None
    return None


@app.get("/admin/reports")
def get_system_report(
    type: Literal["system", "users", "therapists", "progress", "practice", "appointments"] = Query("system"),
    start: date = Query(...),
    end: date = Query(...),
    admin_uid: str = Depends(require_admin),
):
    if end < start:
        raise HTTPException(status_code=400, detail="End date cannot precede start date")
    if (end - start).days > 3660:
        raise HTTPException(status_code=400, detail="Date range too large")

    def within(value):
        d = _report_date(value)
        return d is not None and start <= d <= end

    try:
        # Read only collections needed for the selected category.
        need_users = type in ("system", "users", "therapists")
        need_children = type in ("system", "users", "progress", "practice")
        need_sessions = type in ("system", "progress", "practice")
        users = [d.to_dict() or {} for d in db.collection("users").stream()] if need_users else []
        children = list(db.collection_group("children").stream()) if need_children else []
        sessions = list(db.collection_group("practiceSessions").stream()) if need_sessions else []
        assignments = [d.to_dict() or {} for d in db.collection("therapist_assignments").stream()] if type in ("system", "therapists") else []
        appointments = [d.to_dict() or {} for d in db.collection("appointments").stream()] if type in ("system", "appointments") else []

        registered_users = [u for u in users if within(u.get("createdAt"))]
        registered_children = [d for d in children if within((d.to_dict() or {}).get("createdAt"))]
        child_paths = {d.reference.path for d in children}
        filtered_sessions = []
        for doc in sessions:
            parent = doc.reference.parent.parent
            data = doc.to_dict() or {}
            if parent is not None and parent.path in child_paths and within(data.get("finishedAt") or data.get("createdAt") or data.get("time")):
                filtered_sessions.append((doc, data))
        filtered_assignments = [a for a in assignments if within(a.get("createdAt") or a.get("assignedAt"))]
        filtered_appointments = [a for a in appointments if within(a.get("date") or a.get("appointmentDate") or a.get("createdAt"))]
        metrics = {}
        if type in ("system", "users"):
            metrics.update({
                "Parents Registered": sum(u.get("role") == "parent" for u in registered_users),
                "Therapists Registered": sum(u.get("role") == "therapist" for u in registered_users),
                "Children Registered": len(registered_children),
                "Active Accounts (current)": sum(u.get("isActive") is not False and u.get("accountStatus") != "suspended" for u in users),
            })
        if type in ("system", "therapists"):
            metrics.update({
                "Verified Therapists (current)": sum(u.get("role") == "therapist" and u.get("verificationStatus") == "verified" for u in users),
                "Assignments Created": len(filtered_assignments),
                "Active Assignments (created in period)": sum(a.get("status") == "active" for a in filtered_assignments),
            })
        if type in ("system", "progress"):
            metrics.update({
                "Children Registered": len(registered_children),
                "Children With Practice": len({doc.reference.parent.parent.path for doc, _ in filtered_sessions}),
                "Practice Sessions": len(filtered_sessions),
            })
        if type in ("system", "practice"):
            def total(key):
                return sum(int(data.get(key) or 0) for _, data in filtered_sessions)
            metrics.update({
                "Practice Sessions": len(filtered_sessions),
                "Total Stars": total("stars"),
                "Passed Items": total("passedCount"),
                "Total Items": total("itemCount"),
            })
        if type in ("system", "appointments"):
            metrics.update({
                "Appointments": len(filtered_appointments),
                "Pending Appointments": sum(str(a.get("status", "")).lower() == "pending" for a in filtered_appointments),
                "Completed Appointments": sum(str(a.get("status", "")).lower() == "completed" for a in filtered_appointments),
                "Cancelled Appointments": sum(str(a.get("status", "")).lower() == "cancelled" for a in filtered_appointments),
            })
        return {"success": True, "metrics": metrics}
    except Exception as exc:
        print("System reports error:", type(exc).__name__)
        raise HTTPException(status_code=500, detail="Unable to load system report") from exc


# Add these imports near the top of admin_backend/main.py:
from notification_service import (
    create_schedule, change_schedule_status, list_users,
    list_schedules, list_history,
)

# Add the following routes at the bottom of main.py.
# All endpoints are protected by the existing require_admin dependency.

from typing import Optional
from fastapi import Body

class SpecificNotificationRequest(BaseModel):
    title: str
    body: str
    recipientUids: list[str]

class ScheduleNotificationRequest(BaseModel):
    title: str
    body: str
    audience: Literal['all', 'parents', 'therapists', 'specific', 'kids']
    recipientUids: list[str] = []
    frequency: Literal['once', 'daily', 'weekly']
    date: Optional[str] = None
    time: str
    weekday: Optional[int] = None
    timezone: str = 'Asia/Kuala_Lumpur'

@app.get('/admin/notifications/users')
def notification_users(admin_uid: str = Depends(require_admin)):
    return {'users': list_users()}

@app.get('/admin/notifications/schedules')
def notification_schedules(admin_uid: str = Depends(require_admin)):
    return {'schedules': list_schedules()}

@app.get('/admin/notifications/history')
def notification_history(admin_uid: str = Depends(require_admin)):
    return {'history': list_history()}

@app.post('/admin/notifications/specific')
def send_specific_notification(data: SpecificNotificationRequest, admin_uid: str = Depends(require_admin)):
    try:
        return send_admin_notification(data.title, data.body, 'specific', admin_uid, data.recipientUids)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc

@app.post('/admin/notifications/schedules')
def add_notification_schedule(data: ScheduleNotificationRequest, admin_uid: str = Depends(require_admin)):
    try:
        return create_schedule(data.model_dump(), admin_uid)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc

@app.patch('/admin/notifications/schedules/{schedule_id}/{action}')
def update_notification_schedule(schedule_id: str, action: Literal['pause', 'resume', 'stop'], admin_uid: str = Depends(require_admin)):
    try:
        return change_schedule_status(schedule_id, action)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc
