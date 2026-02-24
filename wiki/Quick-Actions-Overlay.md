# Quick Actions Overlay

## Invocation

- Shortcut: `⌥⌘L`
- Uses global hotkey registration from `AppState` startup.

## UI Surfaces

1. **Quick Action chooser panel** (glass morphism, centered)
2. **Agent reply bubble** (glass bubble, upper-right)

Both are `NSPanel`-based overlays configured for detached behavior across spaces/fullscreen contexts.

## Action Types

- Analyze
- Write
- New (contextually shown for supported frontmost apps)

## Execution Flow

1. User triggers quick action.
2. Lumi captures visual context (screen JPEG).
3. Prompt is constructed (includes app-specific context when available).
4. Response streams in reply bubble.
5. User can continue via inline input in bubble.

## Voice in Reply Bubble

The reply bubble includes:

- vocal mode toggle (`waveform.circle`)
- one-tap mic input (auto-stop + auto-send)
- optional auto-speak of model output

## Screenshot Placeholders

![SP-QA-01 Panel](images/SP-QA-01-quick-action-panel-centered.png)

`SP-QA-01`: Quick Actions selector panel.

![SP-QA-02 Reply Bubble](images/SP-QA-02-reply-bubble-upper-right.png)

`SP-QA-02`: Reply bubble above another app window.

![SP-QA-03 Voice Controls](images/SP-QA-03-reply-bubble-voice-controls.png)

`SP-QA-03`: waveform + mic + send controls in bubble input row.
