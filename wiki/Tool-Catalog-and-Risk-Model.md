# Tool Catalog and Risk Model

## Registry Design

All tools are registered in `ToolRegistry` as `RegisteredTool` entries containing:

- name
- description
- category
- risk level
- parameter schema
- async handler

## Tool Categories

- File operations
- System commands
- Network/Web
- Git
- Text/Data
- Clipboard
- Screenshot
- Code execution
- Screen control
- Memory

## Risk Levels

- **Low**: read/query operations
- **Medium**: bounded mutations
- **High**: privileged/system-impacting operations
- **Critical**: destructive signatures and dangerous command patterns

## Desktop-Control Filter

`getToolsForAIWithoutDesktopControl(...)` removes:

- `click_mouse`
- `scroll_mouse`
- `move_mouse`
- `type_text`
- `press_key`
- `open_application`

while preserving non-interactive automation tools.

## Audit and Traceability

Each executed tool call is recorded with:

- agent id/name
- tool name
- input args
- result text
- success status
- timestamp

## Screenshot Placeholders

![SP-TOOLS-01 Tool History](images/SP-TOOLS-01-tool-history-panel.png)

`SP-TOOLS-01`: history view with per-agent tool traces.

![SP-TOOLS-02 Risk Prompt](images/SP-TOOLS-02-risk-approval-example.png)

`SP-TOOLS-02`: medium/high risk action review prompt.
