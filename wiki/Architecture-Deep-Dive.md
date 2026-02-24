# Architecture Deep Dive

## Top-Level Layout

- `LumiAgent/App`: app entry, state orchestration, hotkeys, command menus
- `LumiAgent/Presentation/Views`: SwiftUI UI surfaces
- `LumiAgent/Domain`: models, services, protocols
- `LumiAgent/Data`: provider repos and persistence adapters
- `LumiAgent/Infrastructure`: security, network, DB, voice, system permissions

## App Lifecycle and State

`LumiAgentApp` creates a shared `AppState` and injects it into the main window and Settings scene.

`AppState` orchestrates:

- selected sidebar items and detail context
- agent list and selected agent
- conversation state and routing
- automation rules and execution triggers
- tool call history
- quick action / command palette dispatch
- streaming response tool loop

## Message Execution Pipeline

1. User sends message in DM/group.
2. `AppState.sendMessage(...)` appends user message and resolves target agents.
3. For each target, `streamResponse(...)` builds provider messages.
4. AI returns text/tool calls.
5. Tool calls execute via `ToolRegistry` handlers.
6. Tool results are appended back into message context.
7. Loop continues until no more tool calls or iteration cap reached.

## Group Delegation Model

- Group messages are transformed to per-agent context using `[AgentName]:` prefixes.
- Delegation occurs by parsing `@AgentName` mentions in final agent output.
- Delegation executes sequentially to preserve context order.

## Screenshot Placeholders

![SP-ARCH-01 AppState Flow](images/SP-ARCH-01-appstate-message-flow.png)

`SP-ARCH-01`: Sequence diagram from user message to tool execution loop.

![SP-ARCH-02 Module Map](images/SP-ARCH-02-module-map.png)

`SP-ARCH-02`: Folder-level architecture map.
