# ASR Retraining Loop

The backend now supports a safe feedback loop for ASR improvement.

## Important

The system should **not** retrain itself blindly on its own predictions.
That causes error reinforcement and model drift.

Use this loop instead:

1. Collect production voice turns.
2. Review the transcript.
3. Save a human-corrected transcript.
4. Export a retraining manifest from corrected samples.
5. Retrain the model offline on a stronger machine.
6. Deploy the improved model intentionally.

## What exists now

- Voice turns are already stored in `voice_logs`.
- `corrected_transcript` can now be updated through the API.
- A retraining manifest can now be exported from corrected samples.

## API endpoints

### Save a correction

```http
PATCH /voice-agent/logs/{voice_log_id}/correction
Content-Type: application/json
```

Body:

```json
{
  "corrected_transcript": "send ten dollars to Blessing"
}
```

### Read the correction status for a log

```http
GET /voice-agent/logs/{voice_log_id}/correction
```

### Export retraining manifest

```http
POST /voice-agent/retraining/export-manifest
```

The response includes:

- `manifest_path`
- `exported_samples`
- `corrected_samples`
- `minimum_recommended_samples`
- `ready_for_retraining`

## Local export script

You can also export the manifest from the command line:

```bash
.venv312/bin/python backend/scripts/export_asr_retrain_manifest.py
```

## Output file

The manifest is written under the app storage root:

```text
<APP_STORAGE_ROOT>/asr/manifests/retrain_manifest.csv
```

## Limits

- This improves **transcription**, not microphone capture quality.
- Audio capture quality depends on device microphones, noise, distance, and recording settings.
- On Render free, uploaded audio is stored on ephemeral disk, so long-term training data should eventually move to durable storage such as S3 or Supabase Storage.
- Retraining should not run on the live Render web service.

## Recommended operating model

- Run the live backend on Render.
- Store corrections in Postgres.
- Periodically export corrected samples.
- Retrain on a separate machine with enough CPU/GPU.
- Deploy the improved model in controlled releases.
