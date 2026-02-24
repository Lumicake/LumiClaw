//
//  GlobalHotkeyManager.swift
//  LumiAgent
//
//  Registers system-wide hotkeys using Carbon's RegisterEventHotKey.
//  This properly *intercepts* the key — it never reaches the frontmost app —
//  unlike NSEvent.addGlobalMonitorForEvents which only observes.
//
//  Primary:   ⌥⌘L  (Option + Command + L)
//  Secondary: ^L   (Control + L)
//

#if os(macOS)
import Carbon.HIToolbox
import Foundation

// MARK: - Carbon key constants (bridged for Swift clarity)

extension GlobalHotkeyManager {
    /// Carbon virtual key codes for common keys.
    enum KeyCode {
        static let L: UInt32     = UInt32(kVK_ANSI_L)
        static let Space: UInt32 = UInt32(kVK_Space)
    }
    /// Carbon modifier flags.
    enum Modifiers {
        static let command: UInt32 = UInt32(cmdKey)      // 256
        static let option: UInt32  = UInt32(optionKey)   // 2048
        static let shift: UInt32   = UInt32(shiftKey)    // 512
        static let control: UInt32 = UInt32(controlKey)  // 4096
    }
}

// MARK: - Manager

final class GlobalHotkeyManager {
    static let shared = GlobalHotkeyManager()

    private var hotKeyRef: EventHotKeyRef?
    private var hotKeyRef2: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?

    /// Called on the main thread when the primary hotkey is pressed.
    var onActivate: (() -> Void)?
    /// Called on the main thread when the secondary hotkey is pressed.
    var onActivate2: (() -> Void)?

    private init() {}

    // MARK: Register / Unregister

    /// Register the primary global hotkey. Safe to call multiple times — re-registers.
    func register(keyCode: UInt32 = KeyCode.L,
                  modifiers: UInt32 = Modifiers.option | Modifiers.command) {
        unregister()

        var spec = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: OSType(kEventHotKeyPressed)
        )

        // Pass a raw pointer to self so the C callback can call back into Swift.
        let selfPtr = Unmanaged.passUnretained(self).toOpaque()

        InstallEventHandler(
            GetApplicationEventTarget(),
            { (_, event, userInfo) -> OSStatus in
                guard let ptr = userInfo, let event = event else { return OSStatus(eventNotHandledErr) }
                let mgr = Unmanaged<GlobalHotkeyManager>
                    .fromOpaque(ptr)
                    .takeUnretainedValue()

                // Determine which hotkey fired by reading the EventHotKeyID
                var hkID = EventHotKeyID()
                let err = GetEventParameter(
                    event,
                    EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &hkID
                )
                guard err == noErr else { return OSStatus(eventNotHandledErr) }

                switch hkID.id {
                case 1:
                    DispatchQueue.main.async { mgr.onActivate?() }
                case 2:
                    DispatchQueue.main.async { mgr.onActivate2?() }
                default:
                    return OSStatus(eventNotHandledErr)
                }
                return noErr
            },
            1,
            &spec,
            selfPtr,
            &eventHandlerRef
        )

        // 'LUMI' as FourCharCode = 0x4C554D49
        var hkID = EventHotKeyID(signature: 0x4C554D49, id: 1)
        RegisterEventHotKey(
            keyCode, modifiers, hkID,
            GetApplicationEventTarget(), 0,
            &hotKeyRef
        )
    }

    /// Register a secondary global hotkey (e.g. Ctrl+L for quick action panel).
    func registerSecondary(keyCode: UInt32 = KeyCode.L,
                           modifiers: UInt32 = Modifiers.control) {
        unregisterSecondary()

        // If the event handler isn't installed yet (e.g. registerSecondary called
        // before register), install it now.
        if eventHandlerRef == nil {
            var spec = EventTypeSpec(
                eventClass: OSType(kEventClassKeyboard),
                eventKind: OSType(kEventHotKeyPressed)
            )
            let selfPtr = Unmanaged.passUnretained(self).toOpaque()
            InstallEventHandler(
                GetApplicationEventTarget(),
                { (_, event, userInfo) -> OSStatus in
                    guard let ptr = userInfo, let event = event else { return OSStatus(eventNotHandledErr) }
                    let mgr = Unmanaged<GlobalHotkeyManager>
                        .fromOpaque(ptr)
                        .takeUnretainedValue()
                    var hkID = EventHotKeyID()
                    let err = GetEventParameter(
                        event,
                        EventParamName(kEventParamDirectObject),
                        EventParamType(typeEventHotKeyID),
                        nil,
                        MemoryLayout<EventHotKeyID>.size,
                        nil,
                        &hkID
                    )
                    guard err == noErr else { return OSStatus(eventNotHandledErr) }
                    switch hkID.id {
                    case 1:  DispatchQueue.main.async { mgr.onActivate?() }
                    case 2:  DispatchQueue.main.async { mgr.onActivate2?() }
                    default: return OSStatus(eventNotHandledErr)
                    }
                    return noErr
                },
                1,
                &spec,
                selfPtr,
                &eventHandlerRef
            )
        }

        // 'LUM2' as FourCharCode = 0x4C554D32
        var hkID = EventHotKeyID(signature: 0x4C554D32, id: 2)
        RegisterEventHotKey(
            keyCode, modifiers, hkID,
            GetApplicationEventTarget(), 0,
            &hotKeyRef2
        )
    }

    func unregister() {
        if let ref = hotKeyRef   { UnregisterEventHotKey(ref); hotKeyRef = nil }
        if let ref = hotKeyRef2  { UnregisterEventHotKey(ref); hotKeyRef2 = nil }
        if let ref = eventHandlerRef { RemoveEventHandler(ref); eventHandlerRef = nil }
    }

    func unregisterSecondary() {
        if let ref = hotKeyRef2  { UnregisterEventHotKey(ref); hotKeyRef2 = nil }
    }
}
#endif
