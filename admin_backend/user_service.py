
from firebase_admin import auth, firestore
from firebase_service import db


def manage_account(uid: str, action: str, admin_uid: str):
    if uid == admin_uid:
        raise ValueError("Cannot modify your own admin account")

    user_ref = db.collection("users").document(uid)
    snapshot = user_ref.get()

    if not snapshot.exists:
        raise ValueError("User not found")

    user = snapshot.to_dict()
    role = user.get("role")

    if role not in ("parent", "therapist"):
        raise ValueError("Only parent or therapist accounts can be managed")

    if action not in ("suspend", "reactivate"):
        raise ValueError("Invalid action")

    if action == "reactivate":
        if (
            role == "therapist"
            and user.get("verificationStatus") != "verified"
        ):
            raise ValueError("Therapist must be verified first")

    is_active = action == "reactivate"

    auth.update_user(uid, disabled=not is_active)

    user_ref.update({
        "isActive": is_active,
        "accountStatus": "active" if is_active else "suspended",
        "updatedAt": firestore.SERVER_TIMESTAMP
    })

    if role == "therapist":
        db.collection("therapists").document(uid).update({
            "isActive": is_active,
            "updatedAt": firestore.SERVER_TIMESTAMP
        })

    return {
        "success": True,
        "message": f"Account {action} successful",
        "uid": uid
    }

