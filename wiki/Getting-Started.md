# Getting Started

## Prerequisites

- macOS 14+
- Swift toolchain / Xcode
- API key(s) for provider(s) you plan to use

## Clone and Build

```bash
git clone https://github.com/Lumicake/LumiClaw.git
cd LumiClaw
swift build
```

## Run

Option A:

```bash
./run_app.sh
```

Option B: open in Xcode and run `LumiAgent` target.

## First-Run Setup Checklist

1. Open **Settings -> API Keys**.
2. Save OpenAI / Anthropic / Gemini key(s) as needed.
3. Open **Settings -> Permissions**.
4. Run **Enable Full Access (Guided)** and complete each pane.
5. Create your first agent.
6. Open a DM and send a test message.

## Minimal Smoke Test

1. Create agent `Test Assistant`.
2. Send: `Create ~/Desktop/lumi_smoke.txt with today's date`.
3. Confirm file exists.

## Screenshot Placeholders

![SP-START-01 API Keys](images/SP-START-01-settings-api-keys.png)

`SP-START-01`: API keys tab with populated fields.

![SP-START-02 Permission Guided](images/SP-START-02-permissions-guided-button.png)

`SP-START-02`: Permissions tab with guided access button.

![SP-START-03 First Agent](images/SP-START-03-new-agent-form.png)

`SP-START-03`: New agent creation flow.
