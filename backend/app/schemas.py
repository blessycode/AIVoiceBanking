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
