from firebase_admin import auth, firestore
from firebase_service import db

def register_therapist(
    name: str,
    email: str,
    password: str,
):
    name = name.strip()
    email = email.strip().lower()

    if not name:
        raise ValueError("Therapist name is required")

    if not email:
        raise ValueError("Email is required")

    if len(password) < 8:
        raise ValueError(
            "Password must contain at least 8 characters"
        )

    user = None

    try:
        # Create Firebase Authentication account
        user = auth.create_user(
            email=email,
            password=password,
            display_name=name,
            disabled=False,
        )

        # Create user account record
        db.collection("users").document(user.uid).set({
            "username": name,
            "email": email,
            "role": "therapist",
            "isActive": True,
            "verificationStatus": "pending",
            "accountStatus": "active",
            "mustChangePassword": True,
            "createdAt": firestore.SERVER_TIMESTAMP,
            "updatedAt": firestore.SERVER_TIMESTAMP,
        })

        # Create professional profile record
        # Therapist completes the remaining fields.
        db.collection("therapists").document(user.uid).set({
            "fullName": name,
            "email": email,
            "hospital": "",
            "specialization": "",
            "experienceYears": None,
            "qualification": "",
            "bio": "",
            "profileImagePath": "",
            "certificatePath": "",
            "isAvailable": False,
            "verificationStatus": "pending",
            "isActive": True,
            "createdAt": firestore.SERVER_TIMESTAMP,
            "updatedAt": firestore.SERVER_TIMESTAMP,
        })

        return {
            "success": True,
            "uid": user.uid,
            "message": (
                "Therapist registered successfully. "
                "Professional verification is pending."
            ),
        }

    except auth.EmailAlreadyExistsError:
        raise ValueError(
            "This email is already registered"
        )

    except Exception:
        # Remove partially created account if setup fails.
        if user is not None:
            try:
                auth.delete_user(user.uid)
                db.collection("users").document(
                    user.uid
                ).delete()
                db.collection("therapists").document(
                    user.uid
                ).delete()
            except Exception as cleanup_error:
                print(
                    f"Therapist cleanup error: {cleanup_error}"
                )
        raise

def approve_therapist(uid: str):
    therapist_ref = db.collection(
        "therapists"
    ).document(uid)

    therapist_doc = therapist_ref.get()

    if not therapist_doc.exists:
        raise ValueError(
            "Therapist profile not found"
        )

    therapist_data = therapist_doc.to_dict() or {}

    # Therapist must complete professional profile.
    required_fields = [
        "fullName",
        "hospital",
        "specialization",
        "qualification",
        "profileImagePath",
        "certificatePath",
    ]

    missing_fields = [
        field
        for field in required_fields
        if not str(
            therapist_data.get(field) or ""
        ).strip()
    ]

    if missing_fields:
        raise ValueError(
            "Therapist must complete these fields: "
            + ", ".join(missing_fields)
        )

    auth.update_user(uid, disabled=False)

    db.collection("users").document(uid).update({
        "isActive": True,
        "verificationStatus": "verified",
        "accountStatus": "active",
        "updatedAt": firestore.SERVER_TIMESTAMP,
    })

    therapist_ref.update({
        "isActive": True,
        "verificationStatus": "verified",
        "updatedAt": firestore.SERVER_TIMESTAMP,
    })

    return {
        "success": True,
        "message": "Therapist approved successfully",
    }
