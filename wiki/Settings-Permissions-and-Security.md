# Settings, Permissions, and Security

## Settings Surface

Tabs:

- Account
- API Keys
- Permissions
- Security
- About

Settings are accessible from both:

- in-app sidebar Settings area
- macOS Settings window (`⌘,`)

## Permissions Tab Details

Includes checks/actions for:

- Accessibility
- Screen Recording
- Microphone
- Camera
- Automation (pane shortcut)
- Input Monitoring (pane shortcut)
- Full Disk Access
- Privileged Helper

`Enable Full Access (Guided)` behavior:

- re-checks current states first
- only requests missing permissions
- only opens panes that still require user action

## Security Tab

- Allow sudo toggle
- auto-approve risk threshold (low/medium/high/critical)
- static blocked command list (always blocked)

## Runtime Authorization Model

`AuthorizationManager` evaluates:

- dangerous command signatures
- blacklisted/whitelisted command rules
- sudo policy enforcement
- sensitive path targeting

## Screenshot Placeholders

![SP-SET-01 Settings Tabs](images/SP-SET-01-settings-tabs-overview.png)

`SP-SET-01`: all settings tabs visible.

![SP-SET-02 Permissions Grid](images/SP-SET-02-permissions-tab-complete.png)

`SP-SET-02`: permissions tab with status rows.

![SP-SET-03 Security Policy](images/SP-SET-03-security-tab-policy.png)

`SP-SET-03`: security policy controls and blocked commands list.
