FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    APP_STORAGE_ROOT=/tmp/voice-banking

WORKDIR /opt/app

RUN apt-get update \
    && apt-get install -y --no-install-recommends ffmpeg libsndfile1 \
    && rm -rf /var/lib/apt/lists/*

COPY ["backend/requirements.txt", "/tmp/requirements.txt"]
COPY ["backend/requirements-render.txt", "/tmp/backend-requirements-render.txt"]

RUN pip install --upgrade pip \
    && pip install -r /tmp/backend-requirements-render.txt

COPY [".", "/opt/app"]

RUN mkdir -p /tmp/voice-banking

CMD ["sh", "-c", "uvicorn backend.app.main:app --host 0.0.0.0 --port ${PORT:-10000}"]
