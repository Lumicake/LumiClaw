# Lumi Agent

AI agents for macOS that can chat, use tools, and (optionally) control your desktop.

<p align="left">
  <img width="1211" height="764" alt="Lumi Agent main UI" src="https://github.com/user-attachments/assets/d824314e-019f-47a6-a70a-47c9cd54161b" />
</p>

## Why Lumi

Lumi is built for practical agent workflows on your own machine:

- Multi-agent chat (DM + group conversations)
- Tool-enabled execution (files, shell, web, git, code, clipboard, memory)
- Desktop automation in Agent Mode (mouse/keyboard/screen tools)
- Quick Actions overlay (`⌥⌘L`) for cross-app task execution
- Voice mode with OpenAI transcription + TTS

## Important Safety Notice

Lumi can perform high-impact actions if you allow them.

Depending on enabled tools and settings, an agent may:

- Read/write/delete files
- Run shell commands
- Control UI elements via AppleScript / desktop tools
- Execute privileged operations when sudo is enabled

Use trusted prompts and review settings before enabling elevated access.

---

## Requirements

- macOS 15+
- Xcode / Swift toolchain
- API key(s) for cloud providers you use
- Optional: Ollama for local models

---

## Install and Run

### 1) Clone

```bash
git clone https://github.com/Lumicake/LumiClaw.git
cd LumiClaw
```

### 2) Build

```bash
swift build
```

### 3) Launch

```bash
./run_app.sh
```

Or run from Xcode with the `LumiAgent` scheme.

---

## First-Run Setup (Recommended)

1. Open **Settings -> API Keys** and add your provider key(s)
2. Open **Settings -> Permissions**
3. Click **Enable Full Access (Guided)** and complete required macOS privacy panes
4. Create your first agent
5. Start a DM and send a test task

<p align="left">
  <img width="1392" height="764" alt="Permissions setup" src="https://github.com/user-attachments/assets/4c2d0fc5-16eb-42bc-b286-9fb32db7ccd1" />
</p>

---

## Core Workflows

### Agent Space

- DM with one agent or create group chats
- Mention specific agents with `@AgentName`
- Streamed responses with markdown + code block rendering

<p align="left">
  <img width="1211" height="764" alt="Agent space" src="https://github.com/user-attachments/assets/41604248-863c-4191-b26f-6a0a2bb9b39e" />
</p>

### Agent Mode (Desktop Control)

In a DM, enable **Agent Mode** to allow screen/desktop interaction tools.

- `get_screen_info`
- `move_mouse`, `click_mouse`, `scroll_mouse`
- `type_text`, `press_key`
- `run_applescript`
- `take_screenshot`

If desktop control is disabled, Lumi can still use non-desktop automation paths.

### Quick Actions Overlay

Use `⌥⌘L` to open a floating quick-actions panel.

- Analyze current screen context
- Ask Lumi to write/refine content
- Continue through an upper-right floating reply bubble

### Voice Mode

Voice controls are available in chat composer and quick-action reply bubble.

- One tap starts listening
- Auto-stop via realtime VAD
- Auto-transcribe + auto-send
- Optional spoken replies with OpenAI TTS

---

## Keyboard Shortcuts

- `⌘L` Open Agent Palette
- `⌥⌘L` Open Quick Actions
- `⌘,` Open Settings window
- `⌘N` Create New Agent

---

## Security Model

Lumi includes a configurable policy layer:

- Risk levels: low / medium / high / critical
- Auto-approve threshold
- Always-blocked command list
- Optional sudo enablement
- Tool-call history/audit visibility

Settings live in **Settings -> Security**.

---

## Update / Deploy Script

`auto_update.sh` performs a full local rebuild + deploy cycle:

1. Stop running Lumi
2. Clear `runable/`
3. Remove `/Applications/LumiAgent.app`
4. Rebuild
5. Recreate app bundle in `runable/`
6. Sign
7. Copy to `/Applications`
8. Launch installed app

Run:

```bash
./auto_update.sh
```

---

## Documentation

- In-repo docs: [`wiki/`](/wiki)
- GitHub Wiki: <https://github.com/Lumicake/LumiClaw/wiki>

---

## Architecture (High Level)

```text
LumiAgent/
├── App/                    # App entry, AppState, hotkeys
├── Presentation/           # SwiftUI views
├── Domain/                 # Models, services, protocols
├── Data/                   # Provider/persistence repositories
└── Infrastructure/         # Security, permissions, network, audio
```

---

## Contributing

PRs are welcome. Keep changes focused and include clear validation steps.

---

## License

See [LICENSE](LICENSE).

---

## 繁體中文（Traditional Chinese）

Lumi Agent 是一個可在 macOS 上執行任務的 AI 代理平台，支援多代理聊天、工具呼叫、桌面操作與語音模式。

### 快速開始

1. 安裝並啟動：
```bash
git clone https://github.com/Lumicake/LumiClaw.git
cd LumiClaw
swift build
./run_app.sh
```
2. 到 `Settings -> API Keys` 填入 OpenAI / Anthropic / Gemini 金鑰（依需求）。
3. 到 `Settings -> Permissions` 點選 `Enable Full Access (Guided)`，完成 macOS 權限設定。
4. 建立第一個 Agent，開啟 DM 後即可開始對話與任務執行。

### 主要功能

- 多代理聊天（DM / 群組）
- Agent Mode（可選）啟用螢幕與桌面互動工具
- Quick Actions（`⌥⌘L`）全域浮動面板
- 語音模式：一鍵收音、自動停止、自動轉寫與送出，並可語音朗讀回覆

### 安全提醒

啟用高權限工具後，Agent 可能會修改檔案、執行指令，甚至進行系統層級操作。請僅在信任的情境下啟用相關權限，並在 `Settings -> Security` 調整風險門檻與 sudo 設定。
