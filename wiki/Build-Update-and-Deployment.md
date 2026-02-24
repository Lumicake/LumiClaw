# Build, Update, and Deployment

## Local Build

```bash
swift build
```

## App Update Script

`auto_update.sh` performs a full local deploy cycle.

Current sequence:

1. stop running Lumi process
2. clear `runable/`
3. remove `/Applications/LumiAgent.app`
4. rebuild debug target
5. reconstruct `.app` in `runable/`
6. codesign (developer cert when present; ad-hoc fallback)
7. copy app to `/Applications` (with sudo fallback)
8. launch installed app

## Why Permissions May Re-prompt

Reinstall + signature change can invalidate prior TCC trust linkage, causing renewed macOS privacy prompts.

## Recommended Stable Setup

- fixed bundle ID (`com.lumiagent.app`)
- consistent signing identity
- avoid unnecessary destructive reinstall loops when not needed

## Screenshot Placeholders

![SP-DEPLOY-01 Script Output](images/SP-DEPLOY-01-auto-update-terminal.png)

`SP-DEPLOY-01`: successful update script output including copy to `/Applications`.

![SP-DEPLOY-02 Installed App](images/SP-DEPLOY-02-applications-install.png)

`SP-DEPLOY-02`: installed `LumiAgent.app` in `/Applications`.
