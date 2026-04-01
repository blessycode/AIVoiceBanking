# Final System Assembly

## 1. Final Recommended Architecture Summary

The assembled system is now turn-based and agent-centered:

1. Flutter boots `VoiceHomeScreen`.
2. Flutter loads or creates a `session_id`.
3. Flutter calls `POST /voice-agent/start`.
4. Backend initializes the agent session and returns the welcome prompt.
5. Flutter speaks `response_text` with TTS.
6. Flutter records one voice turn and uploads `audio + session_id` to `POST /voice-agent`.
7. Backend saves the file under `backend/uploads/<session_id>/`.
8. Backend runs ASR through `backend/app/services/asr_service.py`.
9. Backend passes the transcript into `agent.process(session_id, transcript)`.
10. Agent reads and updates persistent session state in SQLite.
11. Agent calls database-backed actions for profile, auth, balance, transfers, bills, and airtime.
12. Backend logs the turn in `voice_logs` and returns the structured JSON response.
13. Flutter renders transcript, state, agent response, and speaks the response.
14. The loop continues.

## 2. Final Project Structure

```text
AI_Voice_Banking_System/
├── kimari/
│   └── lib/
│       ├── main.dart
│       ├── models/
│       │   └── voice_agent_response.dart
│       ├── screens/
│       │   └── voice_home_screen.dart
│       ├── services/
│       │   ├── api_service.dart
│       │   ├── audio_service.dart
│       │   └── tts_service.dart
│       └── theme/
├── ASR /
│   ├── inference/
│   ├── utils/
│   └── data/
├── backend/
│   ├── app/
│   │   ├── main.py
│   │   ├── routes/
│   │   │   └── voice_agent.py
│   │   ├── services/
│   │   │   ├── account_service.py
│   │   │   ├── asr_service.py
│   │   │   ├── audio_storage.py
│   │   │   ├── auth_service.py
│   │   │   ├── session_service.py
│   │   │   ├── transaction_service.py
│   │   │   ├── user_service.py
│   │   │   └── voice_log_service.py
│   │   ├── database/
│   │   │   ├── db.py
│   │   │   ├── init_db.py
│   │   │   └── models.py
│   │   ├── agent_bridge/
│   │   │   └── bridge.py
│   │   └── schemas.py
│   ├── uploads/
│   ├── requirements.txt
│   └── voice_bank.db
├── agent/
│   ├── __init__.py
│   ├── state_machine.py
│   ├── actions.py
│   ├── prompts.py
│   ├── session_store.py
│   ├── language_utils.py
│   ├── entity_extractor.py
│   ├── intent_router.py
│   └── agent/
│       └── ... existing implementation package
└── docs/
    └── final_system_assembly.md
```

### Folder Roles

- `kimari/`: Flutter Android client for recording, TTS, UI state, and session-driven voice looping.
- `ASR /`: standalone ASR project reused by the backend through a wrapper service.
- `backend/app/`: FastAPI assembly layer that glues uploads, ASR, agent, DB, and response schemas together.
- `backend/app/routes/`: API endpoints for session start and voice turns.
- `backend/app/services/`: ASR wrapper, upload storage, DB-backed business services, and logging hooks.
- `backend/app/database/`: SQLAlchemy engine, models, and DB initialization.
- `backend/app/agent_bridge/`: the only backend entry point into the agent.
- `agent/`: agent-facing public modules plus the existing implementation package.
- `docs/`: deployment, testing, and architecture notes.

## 3. Backend Files To Create Or Change

Create or use:

- `backend/app/main.py`
- `backend/app/routes/voice_agent.py`
- `backend/app/agent_bridge/bridge.py`
- `backend/app/schemas.py`
- `backend/app/services/asr_service.py`
- `backend/app/services/audio_storage.py`
- `backend/app/services/session_service.py`
- `backend/app/services/user_service.py`
- `backend/app/services/auth_service.py`
- `backend/app/services/account_service.py`
- `backend/app/services/transaction_service.py`
- `backend/app/services/voice_log_service.py`
- `backend/app/database/db.py`
- `backend/app/database/models.py`
- `backend/app/database/init_db.py`
- `backend/requirements.txt`

## 4. Full Backend Route Assembly

Primary route:

```http
POST /voice-agent
Content-Type: multipart/form-data
```

Form fields:

- `session_id`
- `audio`

Route flow:

1. Save audio in `backend/uploads/<session_id>/`.
2. Run ASR via `transcribe_audio_file()`.
3. Call `process_turn(session_id, transcript)`.
4. Log the turn in `voice_logs`.
5. Return:

```json
{
  "session_id": "string",
  "transcript": "string",
  "state": "string",
  "language": "string",
  "is_authenticated": true,
  "user_id": 1,
  "response_text": "string"
}
```

Bootstrap route:

```http
POST /voice-agent/start
Content-Type: application/json
```

Body:

```json
{
  "session_id": "session-123"
}
```

This triggers the agent welcome prompt so Flutter can speak first while preserving state on the backend.

## 5. ASR Integration Assembly

Backend wrapper:

- File: `backend/app/services/asr_service.py`
- Input: absolute audio file path
- Output: `transcript`, `language`, `normalized_audio_path`, `model_name`

Import strategy:

1. Resolve repo root.
2. Detect `ASR ` first, then fallback to `ASR`.
3. Add that directory to `sys.path`.
4. Import `inference.transcribe_mobile.transcribe_mobile_audio`.

ASR fixes applied:

- `ASR /inference/transcribe_mobile.py` now writes normalized audio under `ASR /data/normalized/`.
- `ASR /utils/log_utils.py` now writes logs under `ASR /data/learning_logs/`.

Fallback behavior:

- Import/bootstrap failure raises `ASRServiceError` and returns HTTP 503.
- Runtime transcription failure logs the exception and returns an empty transcript so the agent can still answer with a retry/fallback prompt on that turn.

## 6. Agent Integration Assembly

Backend import path:

```python
from agent.state_machine import VoiceBankingAgent
```

Bridge:

```python
_agent = VoiceBankingAgent()
```

Turn contract:

```python
agent.process(session_id, transcript)
```

Session persistence:

- `agent/agent/session_store.py` now supports `DatabaseSessionStore`.
- Agent session state is stored in SQLite `sessions`.
- Multi-turn flows survive across HTTP requests by keying strictly on `session_id`.

Actions:

- `agent/agent/actions.py` now calls the new backend SQLAlchemy service layer.
- The backend never bypasses the agent for decisions.

## 7. Database And Action Layer Assembly

Tables:

- `users`
- `accounts`
- `transactions`
- `voice_logs`
- `sessions`

Action mapping:

- `create_profile(name, phone, language, password)`
- `login(phone, password)`
- `get_balance(user_id)`
- `send_money(user_id, recipient, amount)`
- `pay_bill(user_id, biller, amount)`
- `buy_airtime(user_id, amount)`

Important behavior:

- `create_profile` creates both `users` and `accounts`.
- `login` validates `phone + password`.
- `send_money`, `pay_bill`, and `buy_airtime` debit the account and write `transactions`.
- `send_money` also credits a recipient account if the recipient exists locally.
- `voice_logs` records ASR, state, response, and audio references for each turn.

## 8. Flutter Integration Assembly

New or updated files:

- `kimari/lib/main.dart`
- `kimari/lib/models/voice_agent_response.dart`
- `kimari/lib/services/api_service.dart`
- `kimari/lib/services/audio_service.dart`
- `kimari/lib/services/tts_service.dart`
- `kimari/lib/screens/voice_home_screen.dart`

Responsibilities:

- `ApiService`: start session and send multipart voice turns to the backend.
- `AudioService`: record 16 kHz mono WAV turns into temporary storage.
- `TtsService`: speak `response_text` and map backend language codes to device voices.
- `VoiceHomeScreen`: show status, transcript, agent response, session metadata, and drive the conversation loop.

Loop behavior:

1. App starts.
2. `session_id` is loaded or generated.
3. Flutter calls `/voice-agent/start`.
4. Flutter speaks the welcome response.
5. Flutter records one turn.
6. Flutter uploads the turn to `/voice-agent`.
7. Flutter renders transcript and assistant reply.
8. Flutter speaks the assistant reply.
9. Loop repeats until paused or reset.

## 9. Android Configuration

Applied in `kimari/android/app/src/main/AndroidManifest.xml`:

- `android.permission.INTERNET`
- `android.permission.RECORD_AUDIO`
- `android:usesCleartextTraffic="true"`

Backend URL notes:

- Android emulator: use `http://10.0.2.2:8000`
- Physical Android device: use `http://<your-laptop-LAN-IP>:8000`

You can override the base URL with:

```bash
flutter run --dart-define=BACKEND_URL=http://10.0.2.2:8000
```

Run the backend with:

```bash
cd /home/blessy/AIVoiceBanking
uvicorn backend.app.main:app --reload --host 0.0.0.0 --port 8000
```

If you are already inside `backend/`, use:

```bash
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

Shortcut:

```bash
./backend/scripts/run_backend.sh
```

## 10. Testing Checklist

### Backend

- Start backend and verify `GET /health` returns `{"status":"ok"}`.
- Call `POST /voice-agent/start` with a fresh `session_id` and confirm `WELCOME -> AWAITING_LANGUAGE_CHOICE -> AWAITING_ENTRY_CHOICE`.
- Upload a short WAV file to `POST /voice-agent` and confirm transcript and response are returned.
- Create a profile and verify `users`, `accounts`, and `sessions` rows are created.
- Login and verify `is_authenticated=true`.
- Check balance and verify live balance is returned from SQLite.
- Send money, buy airtime, and pay bill and confirm new `transactions` plus balance updates.
- Logout and confirm the session remains but auth state clears.

### Flutter

- Launch on Android emulator and confirm the assistant speaks first.
- Verify microphone permission prompt appears on first listen turn.
- Verify transcript and assistant response update after each backend response.
- Verify pause/resume and reset session actions.
- Verify the same `session_id` is reused across turns until reset.

### End-To-End Flows

- App start welcome
- Create profile
- Login
- Check balance
- Send money
- Buy airtime
- Pay bill
- Logout

## 11. Logging And Continuous Learning Additions

Stored in `voice_logs`:

- `session_id`
- `user_id`
- `audio_file_path`
- `normalized_audio_path`
- `transcript`
- `corrected_transcript`
- `language`
- `agent_state`
- `response_text`
- `asr_model_name`
- `transaction_result`

Stored in ASR CSV logs:

- raw audio path
- normalized audio path
- predicted transcript
- corrected transcript placeholder
- language
- model name
- source

This is enough to add later retraining, transcript correction review, prompt evaluation, and ASR regression analysis.

## 12. Common Bugs And Fixes

- `422 session_id is required`: ensure Flutter includes `session_id` in form data.
- `503 Unable to import ASR module`: confirm the ASR dependencies are installed and the repo still contains `ASR ` or `ASR`.
- `ffmpeg` normalization failure: install `ffmpeg` on the backend host.
- Empty transcripts: verify the client records WAV at 16 kHz mono and the microphone permission is granted.
- Flutter cannot reach backend on emulator: use `10.0.2.2`, not `localhost`.
- Flutter cannot reach backend on a phone: use the machine LAN IP and ensure both devices are on the same network.
- TTS voice mismatch for Shona/Ndebele: fallback currently uses English-region voices because many Android devices do not ship native Shona/Ndebele TTS voices.
- Session resets unexpectedly: check the `sessions` table and confirm the app is not generating a new `session_id` on every turn.
