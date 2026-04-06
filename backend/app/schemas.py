from datetime import datetime

from pydantic import BaseModel, Field


class VoiceAgentResponse(BaseModel):
    session_id: str
    transcript: str
    state: str
    language: str
    is_authenticated: bool
    user_id: int | None = None
    response_text: str


class StartSessionRequest(BaseModel):
    session_id: str = Field(..., min_length=1)


class DashboardTransaction(BaseModel):
    id: int
    transaction_type: str
    amount: float
    recipient: str | None = None
    reference: str | None = None
    status: str
    balance_after: float
    created_at: datetime


class DashboardSummaryResponse(BaseModel):
    session_id: str
    state: str
    language: str
    is_authenticated: bool
    user_id: int | None = None
    user_name: str | None = None
    phone: str | None = None
    balance: float | None = None
    currency: str | None = None
    recent_transactions: list[DashboardTransaction] = Field(default_factory=list)


class TransactionsResponse(BaseModel):
    session_id: str
    is_authenticated: bool
    user_id: int | None = None
    currency: str | None = None
    transactions: list[DashboardTransaction] = Field(default_factory=list)


class VoiceLogCorrectionRequest(BaseModel):
    corrected_transcript: str = Field(..., min_length=1)


class VoiceLogCorrectionResponse(BaseModel):
    voice_log_id: int
    session_id: str
    transcript: str
    corrected_transcript: str
    language: str
    ready_for_retraining: bool


class RetrainingManifestResponse(BaseModel):
    manifest_path: str
    exported_samples: int
    corrected_samples: int
    minimum_recommended_samples: int
    ready_for_retraining: bool
