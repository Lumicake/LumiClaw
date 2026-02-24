# Troubleshooting

## Guided Permission Button Crash

Check `Info.plist` privacy usage keys:

- `NSMicrophoneUsageDescription`
- `NSCameraUsageDescription`
- `NSScreenCaptureUsageDescription`
- `NSAccessibilityUsageDescription`

## Voice Not Auto-Stopping

Current preferred behavior is OpenAI realtime server VAD; fallback is local silence stop.

If behavior is incorrect:

1. verify mic permission
2. verify OpenAI key
3. verify outbound websocket/network
4. inspect runtime logs for realtime event types

## Quick Action Overlay Not Global

Ensure you are running the latest installed app from `/Applications/LumiAgent.app`, not stale build artifacts.

## Settings Visibility Confusion

Settings can be reached from both in-app navigation and macOS settings scene.

## Wiki Not Updating in GitHub Wiki Tab

Repo files under `wiki/` are not the same as GitHub Wiki.
Use `.wiki.git` remote for the actual Wiki tab content.

## Screenshot Placeholders

![SP-TS-01 Permission Error](images/SP-TS-01-permission-error-banner.png)

`SP-TS-01`: permission error or denied state example.

![SP-TS-02 Voice Error](images/SP-TS-02-voice-error-state.png)

`SP-TS-02`: voice mode error state in composer.
