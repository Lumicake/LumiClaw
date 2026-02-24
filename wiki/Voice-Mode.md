# Voice Mode (Realtime + Whisper + TTS)

## Where Voice Exists

- Chat composer (Agent Space)
- Quick Action reply bubble

## Input Pipeline

One-tap voice capture path:

1. Request/check mic permission.
2. Start realtime websocket session (`/v1/realtime?model=gpt-realtime`).
3. Stream PCM chunks from `AVAudioEngine`.
4. Use OpenAI server VAD turn detection (`turn_detection: server_vad`).
5. On completed transcript event, auto-send message.

Fallback path:

- Local recording + silence detection + transcription endpoint.

## Output Pipeline

- Agent text can be spoken with OpenAI TTS (`gpt-4o-mini-tts`, `voice: alloy`).

## State Indicators

- `isRecording`: listening state
- `isProcessing`: transcription/TTS in progress
- `lastError`: human-readable failure path

## Common Failure Causes

- Missing OpenAI API key
- microphone permission denied
- network websocket failures

## Screenshot Placeholders

![SP-VOICE-01 Chat Composer Voice](images/SP-VOICE-01-chat-composer-voice-controls.png)

`SP-VOICE-01`: message composer with mic and vocal-mode toggle.

![SP-VOICE-02 Listening State](images/SP-VOICE-02-listening-status-row.png)

`SP-VOICE-02`: listening/processing status banner.

![SP-VOICE-03 Auto Speak](images/SP-VOICE-03-auto-speak-reply.png)

`SP-VOICE-03`: voice mode enabled and reply spoken.
