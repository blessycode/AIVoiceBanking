import logging

from fastapi import APIRouter, File, Form, HTTPException, Query, UploadFile, status

from ..agent_bridge.bridge import process_turn, start_session
from ..database.db import SessionLocal
from ..schemas import (
    DashboardSummaryResponse,
    DashboardTransaction,
    RetrainingManifestResponse,
    StartSessionRequest,
    TransactionsResponse,
    VoiceLogCorrectionRequest,
    VoiceLogCorrectionResponse,
    VoiceAgentResponse,
)
from ..services.account_service import get_account_by_user_id
from ..services.asr_service import ASRServiceError, transcribe_audio_file, warmup_asr_async
from ..services.audio_storage import save_upload
from ..services.session_service import get_session_record
from ..services.transaction_service import list_recent_transactions
from ..services.user_service import get_user_by_id
from ..services.voice_log_service import (
    apply_transcript_correction,
    export_retraining_manifest,
    get_voice_log,
    log_voice_turn,
)


logger = logging.getLogger(__name__)
router = APIRouter(tags=["voice-agent"])


@router.post("/voice-agent/start", response_model=VoiceAgentResponse)
def begin_voice_session(payload: StartSessionRequest) -> VoiceAgentResponse:
    warmup_asr_async()
    agent_result = start_session(payload.session_id)

    with SessionLocal() as db:
        log_voice_turn(
            db,
            session_id=agent_result["session_id"],
            user_id=agent_result["user_id"],
            audio_file_path=None,
            normalized_audio_path=None,
            transcript="",
            language=agent_result["language"],
            agent_state=agent_result["state"],
            response_text=agent_result["response_text"],
            transaction_result="SESSION_START",
        )

    return VoiceAgentResponse(transcript="", **agent_result)


@router.post("/voice-agent", response_model=VoiceAgentResponse)
def run_voice_agent(
    session_id: str = Form(...),
    audio: UploadFile = File(...),
) -> VoiceAgentResponse:
    if not session_id.strip():
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="session_id is required.",
        )

    if audio.filename is None:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="audio file is required.",
        )

    try:
        audio_path = save_upload(session_id, audio)
    except OSError as exc:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Unable to save uploaded audio: {exc}",
        ) from exc

    try:
        asr_result = transcribe_audio_file(str(audio_path))
    except ASRServiceError as exc:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=str(exc),
        ) from exc

    agent_result = process_turn(session_id, asr_result.transcript)

    with SessionLocal() as db:
        log_voice_turn(
            db,
            session_id=agent_result["session_id"],
            user_id=agent_result["user_id"],
            audio_file_path=str(audio_path),
            normalized_audio_path=asr_result.normalized_audio_path,
            transcript=asr_result.transcript,
            language=agent_result["language"] or asr_result.language,
            agent_state=agent_result["state"],
            response_text=agent_result["response_text"],
            asr_model_name=asr_result.model_name,
            transaction_result=agent_result.get("transaction_result"),
        )

    logger.info(
        "Voice turn completed",
        extra={
            "session_id": session_id,
            "state": agent_result["state"],
            "language": agent_result["language"],
        },
    )

    return VoiceAgentResponse(
        session_id=agent_result["session_id"],
        transcript=asr_result.transcript,
        state=agent_result["state"],
        language=agent_result["language"] or asr_result.language,
        is_authenticated=agent_result["is_authenticated"],
        user_id=agent_result["user_id"],
        response_text=agent_result["response_text"],
    )


@router.get("/voice-agent/summary/{session_id}", response_model=DashboardSummaryResponse)
def get_voice_session_summary(session_id: str) -> DashboardSummaryResponse:
    with SessionLocal() as db:
        session = get_session_record(db, session_id)
        if session is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Session not found.",
            )

        user = None
        account = None
        transactions = []

        if session.user_id is not None:
            user = get_user_by_id(db, session.user_id)
            account = get_account_by_user_id(db, session.user_id)
            transactions = list_recent_transactions(db, user_id=session.user_id)

        return DashboardSummaryResponse(
            session_id=session.session_id,
            state=session.state,
            language=session.language,
            is_authenticated=session.is_authenticated,
            user_id=session.user_id,
            user_name=user.name if user else None,
            phone=user.phone if user else None,
            balance=float(account.balance) if account else None,
            currency=account.currency if account else None,
            recent_transactions=[
                DashboardTransaction(
                    id=transaction.id,
                    transaction_type=transaction.transaction_type,
                    amount=float(transaction.amount),
                    recipient=transaction.recipient,
                    reference=transaction.reference,
                    status=transaction.status,
                    balance_after=float(transaction.balance_after),
                    created_at=transaction.created_at,
                )
                for transaction in transactions
            ],
        )


@router.get("/voice-agent/transactions/{session_id}", response_model=TransactionsResponse)
def get_voice_session_transactions(
    session_id: str,
    limit: int = Query(50, ge=1, le=200),
) -> TransactionsResponse:
    with SessionLocal() as db:
        session = get_session_record(db, session_id)
        if session is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Session not found.",
            )

        account = None
        transactions = []
        if session.user_id is not None:
            account = get_account_by_user_id(db, session.user_id)
            transactions = list_recent_transactions(
                db,
                user_id=session.user_id,
                limit=limit,
            )

        return TransactionsResponse(
            session_id=session.session_id,
            is_authenticated=session.is_authenticated,
            user_id=session.user_id,
            currency=account.currency if account else None,
            transactions=[
                DashboardTransaction(
                    id=transaction.id,
                    transaction_type=transaction.transaction_type,
                    amount=float(transaction.amount),
                    recipient=transaction.recipient,
                    reference=transaction.reference,
                    status=transaction.status,
                    balance_after=float(transaction.balance_after),
                    created_at=transaction.created_at,
                )
                for transaction in transactions
            ],
        )


@router.patch(
    "/voice-agent/logs/{voice_log_id}/correction",
    response_model=VoiceLogCorrectionResponse,
)
def update_voice_log_correction(
    voice_log_id: int,
    payload: VoiceLogCorrectionRequest,
) -> VoiceLogCorrectionResponse:
    with SessionLocal() as db:
        try:
            record = apply_transcript_correction(
                db,
                voice_log_id=voice_log_id,
                corrected_transcript=payload.corrected_transcript,
            )
        except ValueError as exc:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail=str(exc),
            ) from exc

        if record is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Voice log not found.",
            )

        manifest_info = export_retraining_manifest(db)
        return VoiceLogCorrectionResponse(
            voice_log_id=record.id,
            session_id=record.session_id,
            transcript=record.transcript,
            corrected_transcript=record.corrected_transcript or "",
            language=record.language,
            ready_for_retraining=manifest_info["ready_for_retraining"],
        )


@router.post(
    "/voice-agent/retraining/export-manifest",
    response_model=RetrainingManifestResponse,
)
def export_voice_retraining_manifest() -> RetrainingManifestResponse:
    with SessionLocal() as db:
        return RetrainingManifestResponse(**export_retraining_manifest(db))


@router.get(
    "/voice-agent/logs/{voice_log_id}/correction",
    response_model=VoiceLogCorrectionResponse,
)
def get_voice_log_correction(voice_log_id: int) -> VoiceLogCorrectionResponse:
    with SessionLocal() as db:
        record = get_voice_log(db, voice_log_id)
        if record is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Voice log not found.",
            )

        manifest_info = export_retraining_manifest(db)
        return VoiceLogCorrectionResponse(
            voice_log_id=record.id,
            session_id=record.session_id,
            transcript=record.transcript,
            corrected_transcript=record.corrected_transcript or "",
            language=record.language,
            ready_for_retraining=manifest_info["ready_for_retraining"],
        )
