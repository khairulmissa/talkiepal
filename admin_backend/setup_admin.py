
from firebase_admin import auth
from firebase_service import db

def setup_admin():
    email = input("Enter existing Admin email: ").strip()

    user = auth.get_user_by_email(email)

    admin_doc = db.collection("users").document(user.uid).get()

    if not admin_doc.exists:
        print("ERROR: Admin Firestore document not found.")
        return

    data = admin_doc.to_dict()

    if (
        data.get("role") != "admin"
        or data.get("isActive") is not True
        or data.get("accountStatus") != "active"
    ):
        print("ERROR: Admin Firestore account is not active.")
        return

    print(f"Admin UID: {user.uid}")
    confirm = input("Grant admin permission? Type YES: ")

    if confirm != "YES":
        print("Cancelled.")
        return

    existing_claims = user.custom_claims or {}
    updated_claims = {**existing_claims, "admin": True}

    auth.set_custom_user_claims(user.uid, updated_claims)

    print("SUCCESS: Admin permission granted!")


if __name__ == "__main__":
    setup_admin()
