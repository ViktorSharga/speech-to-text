import AppKit
import SwiftUI

/// A non-activating floating panel that doesn't steal focus from the active app.
class FloatingPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    init(contentRect: NSRect) {
        super.init(
            contentRect: contentRect,
            styleMask: [.nonactivatingPanel, .titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        level = .floating
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        isMovableByWindowBackground = true
        titlebarAppearsTransparent = true
        titleVisibility = .hidden
        backgroundColor = .clear
        isOpaque = false
        hasShadow = true

        // Remove standard window buttons
        standardWindowButton(.closeButton)?.isHidden = true
        standardWindowButton(.miniaturizeButton)?.isHidden = true
        standardWindowButton(.zoomButton)?.isHidden = true
    }
}

/// Controller that manages the floating panel's lifecycle.
@MainActor
class FloatingPanelController {
    private var panel: FloatingPanel?
    private weak var appState: AppState?

    init(appState: AppState) {
        self.appState = appState
    }

    func show() {
        if panel == nil {
            createPanel()
        }

        guard let panel else { return }

        // Position at top-center of screen
        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let panelWidth: CGFloat = 320
            let panelHeight: CGFloat = 200
            let x = screenFrame.midX - panelWidth / 2
            let y = screenFrame.maxY - panelHeight - 40
            panel.setFrame(NSRect(x: x, y: y, width: panelWidth, height: panelHeight), display: true)
        }

        panel.orderFrontRegardless()
    }

    func hide() {
        panel?.orderOut(nil)
    }

    private func createPanel() {
        guard let appState else { return }

        let panel = FloatingPanel(contentRect: NSRect(x: 0, y: 0, width: 320, height: 200))
        let hostingView = NSHostingView(rootView:
            RecordingView()
                .environmentObject(appState)
        )
        panel.contentView = hostingView
        self.panel = panel
    }
}
