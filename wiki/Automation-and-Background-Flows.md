# Automation and Background Flows

## Automation Engine

`AutomationEngine` can trigger rules based on system events. Rules are persisted and can be manually invoked.

## Rule Lifecycle

1. Create automation rule
2. Configure trigger + target agent
3. Enable/disable rule
4. Runtime trigger fires
5. Lumi dispatches automation prompt through agent execution path

## AppState Integration

- rules stored in `automations`
- serialized to user defaults
- engine updated as rules change
- manual run path available in UI

## Screenshot Placeholders

![SP-AUTO-01 Automation List](images/SP-AUTO-01-automation-list.png)

`SP-AUTO-01`: automation list and enable states.

![SP-AUTO-02 Rule Detail](images/SP-AUTO-02-automation-rule-editor.png)

`SP-AUTO-02`: rule trigger and target agent configuration.
