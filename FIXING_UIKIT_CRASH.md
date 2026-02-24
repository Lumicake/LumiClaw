# Fixing UIKit Event Fetcher Crash on macOS

## The Problem

You're seeing a crash with this stack trace:
```
com.apple.uikit.eventfetch-thread
__BKSHIDEvent__BUNDLE_IDENTIFIER_FOR_CURRENT_PROCESS_IS_NIL__
UIEventFetcher
```

**This crash indicates UIKit is being loaded instead of AppKit on macOS.**

## Root Causes

### 1. iOS Catalyst or "Designed for iPad" Mode
Your app might be running as an iOS app on macOS instead of a native macOS app.

### 2. Wrong Xcode Target
The build target might be set to iOS or Mac Catalyst instead of macOS.

### 3. Mixed Framework Dependencies
A dependency might be pulling in UIKit.

## Immediate Solutions

### Solution 1: Check Xcode Target Settings

1. Open your project in Xcode
2. Select your LumiAgent target
3. Go to "General" tab
4. Check **"Destination"** dropdown:
   - ✅ Should be: **"macOS"** or **"My Mac"**
   - ❌ NOT: "Any iOS Device", "iPad", "Designed for iPad"
5. Under "Deployment Info":
   - ✅ macOS should be checked
   - ❌ iOS should be UNCHECKED
   - ❌ Mac Catalyst should be UNCHECKED

### Solution 2: Verify Build Settings

1. Select target → Build Settings
2. Search for "Supported Platforms"
   - Should be: `macosx` ONLY
3. Search for "Supports Mac Catalyst"
   - Should be: `NO`
4. Search for "Targeted Device Family"
   - Should be: `2` (macOS only)

### Solution 3: Clean Build Everything

```bash
# In Terminal:
rm -rf ~/Library/Developer/Xcode/DerivedData/*
```

Then in Xcode:
1. Product → Clean Build Folder (⌘⇧K)
2. Restart Xcode
3. Rebuild (⌘B)

### Solution 4: Verify Scheme Settings

1. Product → Scheme → Edit Scheme (⌘<)
2. Select "Run" on left
3. Info tab → Executable
   - Should be: "LumiAgent.app" (not iOS)
4. Options tab → "Debugging"
   - Uncheck "Debug as iPad" or similar

### Solution 5: Check Package.swift (if using SPM)

If building with Swift Package Manager, ensure:

```swift
.target(
    name: "LumiAgent",
    dependencies: [],
    swiftSettings: [
        .define("os(macOS)")
    ]
)
```

## Files Created/Updated

I've created/updated these files to help:

### ✅ `LumiAgent.xcconfig`
- Forces macOS-only platform
- Disables Catalyst
- Sets proper Info.plist and entitlements paths

### ✅ `LumiAgent.entitlements`
- Required entitlements for Accessibility, AppleScript, etc.
- Disables App Sandbox for full system access

### ✅ `Info.plist`
- Proper bundle identifier
- macOS-specific settings
- All required permission descriptions

## Step-by-Step Fix

### 1. Verify Project Configuration
```bash
# Check your Xcode project file
grep -r "UIKit" *.xcodeproj
# Should return nothing or only iOS-related targets
```

### 2. Ensure macOS-Only Target

Open Xcode and verify:
- Scheme → Destination = "My Mac"
- Target → General → Deployment Info = macOS only
- Target → Build Settings → Supported Platforms = `macosx`

### 3. Link Configuration Files

In Xcode:
1. Target → Build Settings tab
2. Search "xcconfig"
3. Set "Debug" and "Release" to use `LumiAgent.xcconfig`

Or add to project:
1. File → Add Files to Project
2. Select `LumiAgent.xcconfig`
3. Target → Build Settings → Base Configuration

### 4. Set Entitlements

In Xcode:
1. Target → Signing & Capabilities
2. Look for "Code Signing Entitlements"
3. Set to: `LumiAgent.entitlements`

### 5. Set Info.plist

In Xcode:
1. Target → Build Settings
2. Search "Info.plist"
3. Set to: `Info.plist`

### 6. Rebuild Completely

```bash
# Terminal
rm -rf ~/Library/Developer/Xcode/DerivedData/*
```

Then in Xcode:
```
Product → Clean Build Folder (⌘⇧K)
Product → Build (⌘B)
```

## Verification

After rebuilding, check:

### 1. Run the app and check console:
```
✅ Bundle identifier: com.lumiagent.app
```

### 2. In debugger, verify frameworks:
```lldb
(lldb) image list
```
Look for:
- ✅ Should see: AppKit.framework
- ❌ Should NOT see: UIKit.framework

### 3. Check the built app:
```bash
otool -L /path/to/LumiAgent.app/Contents/MacOS/LumiAgent | grep -i uikit
# Should return nothing
```

## Common Mistakes

❌ Running scheme set to "Designed for iPad"
❌ Having "Supports Mac Catalyst" enabled
❌ Building for "My Mac (Designed for iPad)"
❌ Having iOS target alongside macOS target with same name
❌ Dependencies that support iOS being linked

✅ Pure macOS target
✅ AppKit only, no UIKit
✅ Proper bundle identifier
✅ Correct entitlements
✅ Info.plist with CFBundleIdentifier

## Still Crashing?

### Check Dependencies
```bash
# If using CocoaPods
pod install --verbose

# If using Swift Package Manager
swift package resolve
swift package show-dependencies
```

Look for any dependencies that mention iOS or UIKit.

### Check Import Statements

Search your codebase:
```bash
grep -r "import UIKit" .
```

Should return ZERO results (except maybe in iOS-specific conditional code).

### Nuclear Option - Recreate Target

If nothing works:
1. Create a new macOS App target from scratch
2. Use the pure macOS template (NOT Catalyst)
3. Copy your source files to new target
4. Apply Info.plist, entitlements, and xcconfig

## Key Takeaway

**This crash means UIKit is being loaded on macOS, which should never happen.**

Your app MUST be:
- Native macOS target
- Using AppKit, not UIKit  
- NOT running via Catalyst
- NOT "Designed for iPad"

The files I've created enforce this. Just configure Xcode to use them!
