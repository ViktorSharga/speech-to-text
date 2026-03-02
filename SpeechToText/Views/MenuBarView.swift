import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject var appState: AppState
    let openSettings: OpenSettingsAction

    var body: some View {
        Group {
            switch appState.currentState {
            case .idle:
                Button("Start Recording (⌘R)") {
                    appState.toggleRecording()
                }
            case .recording:
                Button("Stop Recording (⌘R)") {
                    appState.toggleRecording()
                }
            case .transcribing:
                Text("Transcribing...")
                    .foregroundColor(.secondary)
            case .result:
                Button("Dismiss Result (⌘R)") {
                    appState.dismiss()
                }
            }

            if appState.isPreparingModel {
                Text("Loading model...")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Divider()

            Button("Settings...") {
                openSettings()
            }
            .keyboardShortcut(",", modifiers: .command)

            Divider()

            Button("Quit Speech to Text") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q", modifiers: .command)
        }
    }
}
