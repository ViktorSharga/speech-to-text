import AppKit
import Combine
import SwiftUI

/// Manages the NSStatusItem in the menu bar.
/// Left-click: toggle recording. Right-click: context menu (settings, quit).
@MainActor
class StatusBarController: NSObject {
    private var statusItem: NSStatusItem
    private weak var appState: AppState?
    private var cancellables = Set<AnyCancellable>()

    init(appState: AppState) {
        self.appState = appState
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        super.init()

        setupButton()
        setupMenu()

        // Observe state changes to update the icon
        appState.$currentState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.updateIcon(for: state)
            }
            .store(in: &cancellables)

        appState.$isPreparingModel
            .receive(on: DispatchQueue.main)
            .sink { [weak self] preparing in
                if preparing {
                    self?.statusItem.button?.toolTip = "VoiceInk — Loading model..."
                } else {
                    self?.statusItem.button?.toolTip = "VoiceInk — Click to record"
                }
            }
            .store(in: &cancellables)
    }

    private func setupButton() {
        guard let button = statusItem.button else { return }
        button.image = NSImage(systemSymbolName: "mic", accessibilityDescription: "VoiceInk")
        button.target = self
        button.action = #selector(statusBarClicked(_:))
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
    }

    private func setupMenu() {
        let menu = NSMenu()

        menu.addItem(NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ","))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit VoiceInk", action: #selector(quitApp), keyEquivalent: "q"))

        for item in menu.items {
            item.target = self
        }

        // Menu is shown on right-click only (see statusBarClicked)
        statusItem.menu = nil
    }

    @objc private func statusBarClicked(_ sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else { return }

        if event.type == .rightMouseUp {
            // Show context menu on right-click
            let menu = NSMenu()
            menu.addItem(NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ","))
            menu.addItem(.separator())
            menu.addItem(NSMenuItem(title: "Quit VoiceInk", action: #selector(quitApp), keyEquivalent: "q"))
            for item in menu.items {
                item.target = self
            }
            statusItem.menu = menu
            statusItem.button?.performClick(nil)
            // Reset so next left-click goes to action, not menu
            DispatchQueue.main.async { [weak self] in
                self?.statusItem.menu = nil
            }
        } else {
            // Left-click: toggle recording
            appState?.toggleRecording()
        }
    }

    @objc private func openSettings() {
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }

    private func updateIcon(for state: AppStateValue) {
        guard let button = statusItem.button else { return }
        let symbolName: String
        switch state {
        case .idle: symbolName = "mic"
        case .recording: symbolName = "mic.fill"
        case .transcribing: symbolName = "ellipsis.circle"
        case .result: symbolName = "text.bubble"
        }
        button.image = NSImage(systemSymbolName: symbolName, accessibilityDescription: "VoiceInk")
    }
}
