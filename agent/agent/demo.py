from agent.state_machine import VoiceBankingAgent

def main():
    agent = VoiceBankingAgent()
    session_id = "demo-user-1"

    while True:
        text = input("YOU: ").strip()
        if text.lower() in {"exit", "quit"}:
            break

        result = agent.process(session_id, text)
        print("\nAGENT RESPONSE:")
        for k, v in result.items():
            print(f"{k}: {v}")
        print("-" * 60)

if __name__ == "__main__":
    main()