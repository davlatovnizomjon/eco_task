# Push notifications (Firebase Cloud Messaging)

Flow: the app registers its FCM token (`POST /api/v1/notifications/devices/`), `notify()` writes the inbox row and, after
the transaction commits, `apps/notifications/push.py` sends a push to every token of the recipients. Dead tokens
(uninstalled app) are deleted automatically. Push is off while `FIREBASE_CREDENTIALS_FILE` is empty.

## One-time setup
1. Firebase console → Project settings → **Service accounts** → *Generate new private key*. Save the JSON on the server
   (outside git), e.g. `/etc/eco/firebase-sa.json`, and set `FIREBASE_CREDENTIALS_FILE` to that path.
2. iOS: Apple Developer → Keys → create an **APNs Auth Key (.p8)**; Firebase console → Project settings → Cloud
   Messaging → Apple app → upload the key with its Key ID and Team ID.
3. Android: add `google-services.json` to `android/app/` (then enable the `com.google.gms.google-services` plugin).
4. `pip install -r requirements.txt` (adds `firebase-admin`) and `python manage.py migrate`.
