import logging

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from .config import CORS_ALLOW_ORIGINS
from .database.init_db import init_db
from .routes.voice_agent import router as voice_agent_router
from .services.asr_service import warmup_asr_async


logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)s [%(name)s] %(message)s",
)

app = FastAPI(title="AI Voice Banking System", version="1.0.0")

allow_any_origin = CORS_ALLOW_ORIGINS == ["*"]

app.add_middleware(
    CORSMiddleware,
    allow_origins=CORS_ALLOW_ORIGINS,
    allow_credentials=not allow_any_origin,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.on_event("startup")
def on_startup() -> None:
    init_db()
    warmup_asr_async()


@app.get("/health")
def health() -> dict:
    return {"status": "ok"}


app.include_router(voice_agent_router)
