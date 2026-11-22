import logging

from fastapi import Header, HTTPException
from firebase_admin import auth
from firebase_service import db

logger = logging.getLogger(__name__)


def require_admin(authorization: str = Header(default="")):
    # Check authorization header
    if not authorization.startswith("Bearer "):
        raise HTTPException(
            status_code=401,
            detail="Missing Firebase authentication token"
        )

    token = authorization.removeprefix("Bearer ").strip()

    if not token:
        raise HTTPException(
            status_code=401,
            detail="Empty Firebase authentication token"
        )

    # Verify Firebase ID token
    try:
        decoded = auth.verify_id_token(
            token,
            check_revoked=True
        )

    except auth.ExpiredIdTokenError:
        logger.warning("Admin authentication: expired ID token")
        raise HTTPException(
            status_code=401,
            detail="Firebase ID token expired. Please sign in again."
        )

    except auth.RevokedIdTokenError:
        logger.warning("Admin authentication: revoked ID token")
        raise HTTPException(
            status_code=401,
            detail="Firebase session revoked. Please sign in again."
        )

    except auth.InvalidIdTokenError:
        logger.warning("Admin authentication: invalid ID token")
        raise HTTPException(
            status_code=401,
            detail="Invalid Firebase ID token. Please sign in again."
        )

    except Exception:
        logger.exception("Unexpected Firebase token verification error")
        raise HTTPException(
            status_code=503,
            detail="Authentication verification temporarily unavailable"
        )

    # Check admin custom claim
    if decoded.get("admin") is not True:
        raise HTTPException(
            status_code=403,
            detail="Admin permission required"
        )

    admin_uid = decoded["uid"]

    # Check admin Firestore account
    try:
        user_doc = db.collection("users").document(admin_uid).get()

    except Exception:
        logger.exception("Unable to retrieve admin account")
        raise HTTPException(
            status_code=503,
            detail="Unable to verify admin account"
        )

    if not user_doc.exists:
        raise HTTPException(
            status_code=403,
            detail="Admin account not found"
        )

    user = user_doc.to_dict() or {}

    if (
        user.get("role") != "admin"
        or user.get("isActive") is not True
        or user.get("accountStatus") == "suspended"
    ):
        raise HTTPException(
            status_code=403,
            detail="Admin account is not active"
        )

    return admin_uid
