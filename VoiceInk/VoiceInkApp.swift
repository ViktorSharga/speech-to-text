import SwiftUI

@main
struct VoiceInkApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        MenuBarExtra {
            MenuBarView()
                .environmentObject(appState)
        } label: {
            Image(systemName: appState.currentState == .recording ? "mic.fill" : "mic")
        }

        Settings {
            SettingsView()
                .environmentObject(appState)
        }
    }
}
