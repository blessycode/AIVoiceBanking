# Render + Supabase + Android

This repository is now set up to run locally with SQLite and in the cloud with hosted Postgres.

## 1. Create the database in Supabase

1. Create a new Supabase project.
2. Click `Connect` in the project dashboard and copy the session pooler connection string.
3. Keep `sslmode=require` if Supabase includes it.

Example:

```text
postgresql://postgres.project-ref:password@aws-1-eu-central-1.pooler.supabase.com:5432/postgres
```

The FastAPI app will create tables on startup for an empty database.

## 2. Deploy the backend to Render

This repo includes:

- `Dockerfile`
- `render.yaml`
- environment-based database and storage config

### Render environment variables

Set these in Render:

- `DATABASE_URL`
  Use the Supabase Postgres connection string.
- `CORS_ALLOW_ORIGINS`
  Use the Android app origin only if you later add a web client. For native Android installs, `*` is acceptable because the app is not a browser.
- `APP_STORAGE_ROOT`
  Keep `/tmp/voice-banking` on Render free.
- `ASR_MODEL_SIZE`
  Set this to `tiny` on Render free for faster CPU inference.
- `ASR_COMPUTE_TYPE`
  Keep this as `int8`.
- `ASR_MIN_CORRECTIONS_FOR_RETRAIN`
  Keep this at `25` unless you want a different retraining threshold.

### Recommended Render flow

1. Push this repository to GitHub.
2. In Render, create a new Blueprint or Web Service from the repo.
3. Let Render use the root `Dockerfile`.
4. Add the required environment variables.
5. Deploy and verify `https://your-service.onrender.com/health`.

## 3. Local backend fallback

For local development:

```bash
cp backend/.env.example backend/.env
.venv312/bin/pip install -r backend/requirements-render.txt
backend/scripts/run_backend.sh
```

If `DATABASE_URL` is omitted, the backend falls back to SQLite in `backend/voice_bank.db`.

## 4. Build the Android app

The Flutter app already accepts the backend URL via Dart define.

### Quick release APK

```bash
cd kimari
flutter build apk --release --dart-define=BACKEND_URL=https://your-service.onrender.com
```

Install on a connected phone:

```bash
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

### Play Store bundle

```bash
cd kimari
flutter build appbundle --release --dart-define=BACKEND_URL=https://your-service.onrender.com
```

## 5. Optional Android signing

The Android project now supports a real release keystore if `kimari/android/key.properties` exists.

Create it from the example file:

```bash
cp kimari/android/key.properties.example kimari/android/key.properties
```

Then update:

- `storePassword`
- `keyPassword`
- `keyAlias`
- `storeFile`

If `key.properties` is absent, Flutter still falls back to the debug keystore for test installs.

## 6. Limits to expect

- Render free instances sleep when idle and use ephemeral disk.
- Uploaded audio and normalized audio files are not durable on Render free.
- Supabase solves the database durability problem, but not file persistence.
- If CPU ASR is too slow on Render free, upgrade the backend plan or move ASR to a separate service.
