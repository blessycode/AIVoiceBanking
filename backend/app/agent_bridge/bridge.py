import sys
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[3]
repo_root_str = str(REPO_ROOT)
if repo_root_str not in sys.path:
    sys.path.insert(0, repo_root_str)

from agent.state_machine import VoiceBankingAgent


_agent = VoiceBankingAgent()


def start_session(session_id: str) -> dict:
    return _agent.process(session_id, "")


def process_turn(session_id: str, transcript: str) -> dict:
    return _agent.process(session_id, transcript)
