# Agent Space and Conversation Model

## Conversation Types

- **DM**: single agent participant
- **Group**: multiple agents, peer-style collaboration

## Header Controls (DM)

- Agent Mode toggle
- Desktop Control toggle (enabled only when Agent Mode is on)

## Message Rendering

- User bubbles on right
- Agent bubbles on left with avatar label
- Inline markdown rendering
- Code block segmentation with language chips and horizontal scroll
- Mention highlighting for `@AgentName`

## Mention Routing

- If message has one/more `@AgentName`, only mentioned agents respond.
- If no mention in group, all participants may respond in turn.

## Conversation Persistence

Conversations and automations are serialized to `UserDefaults` using app-managed keys (`lumiagent.conversations`, `lumiagent.automations`).

## Screenshot Placeholders

![SP-CHAT-01 DM Header](images/SP-CHAT-01-dm-header-controls.png)

`SP-CHAT-01`: DM header with Agent Mode and Desktop toggles.

![SP-CHAT-02 Group Mention](images/SP-CHAT-02-group-mention-routing.png)

`SP-CHAT-02`: Group chat with mention-based routing example.

![SP-CHAT-03 Markdown Code](images/SP-CHAT-03-markdown-code-rendering.png)

`SP-CHAT-03`: Agent response containing prose + fenced code block.
