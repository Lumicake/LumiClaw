//
//  QuickActionPanelController.swift
//  LumiAgent
//
//  A floating Quick Actions toolbar on the right edge of the screen (Ctrl+L).
//  Styled as a vertical sidebar strip with labeled icon buttons.
//  Actions capture a screenshot and dispatch to the default agent
//  without stealing focus or showing the screen-control overlay.
//

#if os(macOS)
import AppKit
import SwiftUI

// MARK: - Quick Action Types

enum QuickActionType: String, CaseIterable {
    case analyzePage
    case thinkAndWrite
    case writeNew

    var icon: String {
        switch self {
        case .analyzePage:   return "eye.fill"
        case .thinkAndWrite: return "pencil.line"
        case .writeNew:      return "doc.badge.plus"
        }
    }

    var label: String {
        switch self {
        case .analyzePage:   return "Analyze"
        case .thinkAndWrite: return "Write"
        case .writeNew:      return "New"
        }
    }

    var prompt: String {
        switch self {
        case .analyzePage:
            return "Describe what's on this screen"
        case .thinkAndWrite:
            return "Look at this screen, find the active text field, and write an appropriate response using type_text"
        case .writeNew:
            return "Look at this page and write appropriate new content using type_text"
        }
    }
}

// MARK: - Toolbar Controller

final class QuickActionPanelController: NSObject {
    static let shared = QuickActionPanelController()

    private var panel: NSPanel?
    private var onAction: ((QuickActionType) -> Void)?

    var isVisible: Bool { panel?.isVisible ?? false }

    // MARK: Public API

    func show(onAction: @escaping (QuickActionType) -> Void) {
        guard panel == nil else { return }
        self.onAction = onAction
        createPanel()
    }

    func hide() {
        guard let panel else { return }
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.12
            panel.animator().alphaValue = 0
        } completionHandler: { [weak self] in
            self?.panel?.orderOut(nil)
            self?.panel = nil
            self?.onAction = nil
        }
    }

    func toggle(onAction: @escaping (QuickActionType) -> Void) {
        if isVisible {
            hide()
        } else {
            show(onAction: onAction)
        }
    }

    func triggerAction(_ type: QuickActionType) {
        onAction?(type)
    }

    // MARK: Private

    private func createPanel() {
        let panelWidth: CGFloat = 320
        let panelHeight: CGFloat = 280

        let view = QuickActionToolbar(controller: self)
        let hosting = NSHostingView(rootView: view)
        hosting.setFrameSize(NSSize(width: panelWidth, height: panelHeight))

        let p = NSPanel(
            contentRect: NSRect(origin: .zero, size: NSSize(width: panelWidth, height: panelHeight)),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        p.contentView = hosting
        p.level = .floating
        p.backgroundColor = .clear
        p.isOpaque = false
        p.hasShadow = false
        p.isMovableByWindowBackground = true
        p.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        p.isReleasedWhenClosed = false

        // Center of screen
        guard let screen = NSScreen.main else { return }
        let sf = screen.visibleFrame
        let origin = NSPoint(
            x: sf.midX - panelWidth / 2,
            y: sf.midY - panelHeight / 2
        )

        p.setFrameOrigin(origin)
        p.alphaValue = 0
        p.orderFrontRegardless()

        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.15
            p.animator().alphaValue = 1
        }

        panel = p
    }
}

// MARK: - Toolbar View

struct QuickActionToolbar: View {
    let controller: QuickActionPanelController

    var body: some View {
        VStack(spacing: 0) {
            Text("Quick Actions")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.secondary)
                .padding(.top, 16)
                .padding(.bottom, 12)

            ForEach(Array(QuickActionType.allCases.enumerated()), id: \.element) { index, action in
                if index > 0 {
                    Divider().padding(.horizontal, 16)
                }
                QuickActionToolbarButton(action: action) {
                    controller.triggerAction(action)
                }
            }

            Spacer(minLength: 8)
        }
        .frame(width: 320, height: 280)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(NSColor.windowBackgroundColor))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.5), radius: 20, x: 0, y: 8)
        )
    }
}

struct QuickActionToolbarButton: View {
    let action: QuickActionType
    let onTap: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                Image(systemName: action.icon)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(isHovering ? .white : .accentColor)
                    .frame(width: 44, height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(isHovering ? Color.accentColor : Color.accentColor.opacity(0.1))
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(action.label)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.primary)
                    Text(action.prompt.prefix(45) + "...")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .contentShape(Rectangle())
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(isHovering ? Color.primary.opacity(0.06) : .clear)
                    .padding(.horizontal, 8)
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.1)) {
                isHovering = hovering
            }
        }
    }
}
#endif
