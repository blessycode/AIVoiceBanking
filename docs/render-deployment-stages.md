# Render Deployment Stages

Use this order when deploying the backend to Render and the app to Android.

## Stage 1: Prepare the repository

Make sure these files are committed:

- `Dockerfile`
- `render.yaml`
- `render.env.example`
- `backend/app/`
- `backend/app/asr_runtime/`
- `backend/requirements.txt`
- `backend/requirements-render.txt`
- `agent/`

Do not rely on local-only files such as:

- `backend/voice_bank.db`
- `backend/uploads/`
- local `.env` files
- virtual environments
- generated ASR data or training artifacts
- the embedded `ASR ` repo

## Stage 2: Create Supabase Postgres

1. Create a Supabase project.
2. Open the database connection settings.
3. Copy the Postgres connection string.
4. Keep `sslmode=require` in the URL.

You will use this value as `DATABASE_URL` in Render.

## Stage 3: Push to GitHub

1. Commit the deployment files.
2. Push the branch to GitHub.
3. Confirm the repo contains the root-level `Dockerfile` and `render.yaml`.

## Stage 4: Create the Render service

1. Log in to Render.
2. Choose `New +`.
3. Select `Blueprint` if you want Render to use `render.yaml`.
4. Connect the GitHub repository.
5. Select the branch you pushed.

Render will create the web service defined in `render.yaml`.
The current blueprint is pinned to the `frankfurt` region.

## Stage 5: Add environment variables in Render

Add these values in the Render dashboard:

- `DATABASE_URL`
- `APP_STORAGE_ROOT=/tmp/voice-banking`
- `CORS_ALLOW_ORIGINS=*`

If you prefer, copy values from `render.env.example`.

## Stage 6: Deploy and verify

1. Start the first deploy.
2. Wait for the Docker build to finish.
3. Open:

```text
https://your-render-service.onrender.com/health
```

The expected response is:

```json
{"status":"ok"}
```

## Stage 7: Point the Flutter app to Render

Build the Android APK using the deployed backend URL:

```bash
cd kimari
flutter build apk --release --dart-define=BACKEND_URL=https://your-render-service.onrender.com
```

Install it on the phone:

```bash
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

## Stage 8: Optional store-ready signing

If you want a proper signed release instead of the debug fallback:

1. Create a keystore.
2. Copy `kimari/android/key.properties.example` to `kimari/android/key.properties`.
3. Fill in the keystore values.
4. Rebuild the release APK or app bundle.

## Stage 9: Demo checklist

Before showing the app:

- Render backend is awake
- `/health` returns success
- Supabase database is reachable
- APK was rebuilt with the real `BACKEND_URL`
- Phone has microphone permission enabled

## Notes

- Render free instances sleep when idle.
- The filesystem on Render free is ephemeral.
- Supabase fixes the database persistence problem, but uploaded audio files on Render are still temporary.
