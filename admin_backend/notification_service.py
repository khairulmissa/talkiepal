"""TalkiePal admin notifications: FCM sending and persistent schedules."""
from datetime import datetime, timedelta, timezone
from zoneinfo import ZoneInfo
from firebase_admin import messaging, firestore
from firebase_service import db
from google.cloud.firestore_v1.base_query import FieldFilter

TZ = ZoneInfo('Asia/Kuala_Lumpur')
VALID_AUDIENCES = {'all', 'parents', 'therapists', 'specific', 'kids'}


def _recipients(audience, recipient_uids=None):
    if audience not in VALID_AUDIENCES:
        raise ValueError('Invalid notification audience')
    if audience == 'specific':
        ids = list(dict.fromkeys(recipient_uids or []))
        if not ids or len(ids) > 500:
            raise ValueError('Select 1 to 500 users')
        docs = [db.collection('users').document(uid).get() for uid in ids]
        if any(not d.exists for d in docs):
            raise ValueError('One or more selected users do not exist')
    elif audience == 'kids':
        # Child profiles are nested under parent users and have no FCM tokens.
        # Only send to parents who own at least one child profile.
        parents = db.collection('users').where(
            filter=FieldFilter('role', '==', 'parent')
        ).stream()
        docs = [parent for parent in parents
                if next(parent.reference.collection('children').limit(1).stream(), None) is not None]
    else:
        roles = ['parent', 'therapist'] if audience == 'all' else [audience[:-1]]
        docs = [doc for role in roles for doc in db.collection('users').where(
            filter=FieldFilter('role', '==', role)).stream()]
    tokens = set()
    for doc in docs:
        data = doc.to_dict() or {}
        if data.get('role') not in ('parent', 'therapist') or data.get('isActive') is not True or data.get('accountStatus') == 'suspended':
            continue
        for token in data.get('fcmTokens', []):
            if isinstance(token, str) and token.strip():
                tokens.add(token.strip())
    return sorted(tokens)


def send_admin_notification(title, body, audience, admin_uid, recipient_uids=None, schedule_id=None):
    if not title.strip() or not body.strip():
        raise ValueError('Title and message are required')
    tokens = _recipients(audience, recipient_uids)
    sent = failed = 0
    for i in range(0, len(tokens), 500):
        result = messaging.send_each_for_multicast(messaging.MulticastMessage(
            notification=messaging.Notification(title=title, body=body), tokens=tokens[i:i + 500]))
        sent += result.success_count
        failed += result.failure_count
    db.collection('admin_notification_history').add({
        'title': title, 'body': body, 'audience': audience,
        'recipientUids': recipient_uids if audience == 'specific' else [],
        'sentCount': sent, 'failedCount': failed, 'createdBy': admin_uid,
        'scheduleId': schedule_id, 'createdAt': firestore.SERVER_TIMESTAMP,
    })
    return {'success': True, 'sent': sent, 'failed': failed}


def _next_run(frequency, time_str, weekday=None, date_str=None, after=None):
    now = (after or datetime.now(timezone.utc)).astimezone(TZ)
    try:
        hour, minute = map(int, time_str.split(':'))
        if not (0 <= hour <= 23 and 0 <= minute <= 59):
            raise ValueError()
        if frequency == 'once':
            d = datetime.strptime(date_str, '%Y-%m-%d').date()
            result = datetime(d.year, d.month, d.day, hour, minute, tzinfo=TZ)
        else:
            result = now.replace(hour=hour, minute=minute, second=0, microsecond=0)
            if frequency == 'weekly':
                if not isinstance(weekday, int) or weekday not in range(1, 8):
                    raise ValueError('Invalid weekday')
                result += timedelta(days=(weekday - result.isoweekday()) % 7)
            if result <= now:
                result += timedelta(days=7 if frequency == 'weekly' else 1)
        if result <= now:
            raise ValueError('Scheduled time must be in the future')
        return result.astimezone(timezone.utc)
    except (TypeError, AttributeError, ValueError) as exc:
        raise ValueError('Invalid date/time or scheduled time is in the past') from exc


def create_schedule(data, admin_uid):
    frequency = data['frequency']
    if frequency not in ('once', 'daily', 'weekly'):
        raise ValueError('Invalid schedule frequency')
    if data.get('timezone') != 'Asia/Kuala_Lumpur':
        raise ValueError('Only Asia/Kuala_Lumpur timezone is supported')
    title, body = data['title'].strip(), data['body'].strip()
    if not title or not body or len(title) > 100 or len(body) > 1000:
        raise ValueError('Title/message missing or too long')
    audience = data['audience']
    uids = data.get('recipientUids', []) if audience == 'specific' else []
    _recipients(audience, uids)  # validate recipients now; recheck on send
    next_run = _next_run(frequency, data['time'], data.get('weekday'), data.get('date'))
    ref = db.collection('scheduled_notifications').document()
    ref.set({
        'title': title, 'body': body, 'audience': audience, 'recipientUids': uids,
        'frequency': frequency, 'date': data.get('date'), 'time': data['time'],
        'weekday': data.get('weekday'), 'timezone': 'Asia/Kuala_Lumpur',
        'status': 'active', 'isActive': True, 'nextRunAt': next_run,
        'createdBy': admin_uid, 'createdAt': firestore.SERVER_TIMESTAMP,
    })
    return {'success': True, 'id': ref.id}


def change_schedule_status(schedule_id, action):
    ref = db.collection('scheduled_notifications').document(schedule_id)
    doc = ref.get()
    if not doc.exists:
        raise ValueError('Schedule not found')
    data = doc.to_dict() or {}
    status = data.get('status')
    if action == 'pause' and status == 'active':
        ref.update({'status': 'paused', 'isActive': False})
    elif action == 'resume' and status == 'paused':
        next_run = _next_run(data['frequency'], data['time'], data.get('weekday'), data.get('date'))
        ref.update({'status': 'active', 'isActive': True, 'nextRunAt': next_run})
    elif action == 'stop' and status in ('active', 'paused'):
        ref.update({'status': 'stopped', 'isActive': False, 'nextRunAt': None, 'stoppedAt': firestore.SERVER_TIMESTAMP})
    else:
        raise ValueError('Action is not valid for current schedule status')
    return {'success': True}


def list_users():
    return [{'uid': d.id, 'name': (v.get('username') or v.get('name') or 'Unnamed'),
             'email': v.get('email', ''), 'role': v.get('role')}
            for d in db.collection('users').stream() if (v := (d.to_dict() or {})).get('role') in ('parent', 'therapist') and v.get('isActive') is True and v.get('accountStatus') != 'suspended']


def list_schedules():
    return [{'id': d.id, **{k: v for k, v in (d.to_dict() or {}).items() if k not in ('nextRunAt', 'createdAt', 'stoppedAt')}} for d in db.collection('scheduled_notifications').limit(100).stream()]


def list_history():
    rows = []
    for d in db.collection('admin_notification_history').order_by('createdAt', direction=firestore.Query.DESCENDING).limit(50).stream():
        v = d.to_dict() or {}
        rows.append({'id': d.id, 'title': v.get('title'), 'body': v.get('body'), 'audience': v.get('audience'), 'sent': v.get('sentCount', 0), 'failed': v.get('failedCount', 0), 'createdAt': v['createdAt'].isoformat() if v.get('createdAt') else None})
    return rows


def run_due_schedules():
    """Call periodically from a trusted single worker. Lease prevents parallel duplicate claims."""
    now = datetime.now(timezone.utc)
    processed = 0
    docs = list(db.collection('scheduled_notifications')
                .where(filter=FieldFilter('status', '==', 'active'))
                .where(filter=FieldFilter('nextRunAt', '<=', now))
                .limit(100).stream())
    processed = 0
    for doc in docs:
        ref = doc.reference
        transaction = db.transaction()
        @firestore.transactional
        def claim(tx):
            current = ref.get(transaction=tx)
            v = current.to_dict() or {}
            if v.get('status') != 'active' or not v.get('nextRunAt') or v['nextRunAt'] > now:
                return None
            tx.update(ref, {'status': 'processing', 'isActive': False})
            return v
        data = claim(transaction)
        if not data:
            continue
        try:
            result = send_admin_notification(data['title'], data['body'], data['audience'], data['createdBy'], data.get('recipientUids'), ref.id)
            if data['frequency'] == 'once':
                ref.update({'status': 'completed', 'isActive': False, 'nextRunAt': None, 'lastSentAt': firestore.SERVER_TIMESTAMP, 'lastResult': result})
            else:
                ref.update({'status': 'active', 'isActive': True, 'nextRunAt': _next_run(data['frequency'], data['time'], data.get('weekday'), after=now), 'lastSentAt': firestore.SERVER_TIMESTAMP, 'lastResult': result})
            processed += 1
        except Exception as exc:
            # No automatic retry: a partial FCM send could duplicate delivery.
            ref.update({'status': 'paused', 'isActive': False, 'lastError': str(type(exc).__name__)})
    return processed

