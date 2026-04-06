import subprocess
from pathlib import Path


def normalize_audio(input_path: str, output_path: str) -> None:
    """Convert audio to 16kHz mono WAV for the Whisper model."""
    Path(output_path).parent.mkdir(parents=True, exist_ok=True)

    cmd = [
        "ffmpeg",
        "-y",
        "-i",
        input_path,
        "-ac",
        "1",
        "-ar",
        "16000",
        output_path,
    ]
    subprocess.run(cmd, check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
