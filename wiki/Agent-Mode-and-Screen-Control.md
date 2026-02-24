# Agent Mode and Screen Control

## What Agent Mode Changes

When Agent Mode is enabled in a DM:

- The runtime grants broader tool access.
- The agent can execute multi-step workflows with tool chaining.
- Screen-touching actions can trigger post-action screenshots for visual verification.

## Desktop Control Restriction Path

If Agent Mode is on but Desktop Control is off:

- Mouse/keyboard/open-app tools are excluded.
- AppleScript + shell + screenshot tools remain available.

## Screen Tool Lifecycle

- Screen tool call detected (`click_mouse`, `type_text`, `run_applescript`, etc.).
- Screen control overlay can appear for safety visibility.
- Follow-up screenshot is captured and fed to model to continue plan.

## Coordinate Model

Tool guidance uses a top-left origin coordinate system and asks model to use exact pixel positions from screenshots.

## Screenshot Placeholders

![SP-AM-01 Agent Mode On](images/SP-AM-01-agent-mode-enabled.png)

`SP-AM-01`: DM header with Agent Mode active.

![SP-AM-02 Screen Overlay](images/SP-AM-02-screen-control-overlay.png)

`SP-AM-02`: floating overlay shown while agent controls screen.

![SP-AM-03 Post Action Vision](images/SP-AM-03-post-action-screenshot-loop.png)

`SP-AM-03`: timeline showing action -> screenshot -> next action.
