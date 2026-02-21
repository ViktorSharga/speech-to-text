import SwiftUI

@main
struct VoiceInkApp: App {
    @StateObject private var appState = AppState()
    @Environment(\.openSettings) private var openSettings

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(openSettings: openSettings)
                .environmentObject(appState)
        } label: {
            Image(systemName: menuBarIcon)
        }

        Settings {
            SettingsView()
                .environmentObject(appState)
        }
    }

    private var menuBarIcon: String {
        switch appState.currentState {
        case .recording: return "mic.fill"
        case .transcribing: return "ellipsis.circle"
        default: return "mic"
        }
    }
}
