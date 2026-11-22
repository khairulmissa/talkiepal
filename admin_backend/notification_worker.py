"""Local development worker. Run from admin_backend while laptop is on."""
import time
from notification_service import run_due_schedules

if __name__ == '__main__':
    print('TalkiePal notification scheduler started. Press Ctrl+C to stop.')
    while True:
        try:
            count = run_due_schedules()
            if count:
                print(f'Processed {count} notification schedules', flush=True)
        except Exception as exc:
            print(f'Scheduler error: {type(exc).__name__}: {exc}', flush=True)
        time.sleep(30)