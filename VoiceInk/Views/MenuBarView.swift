import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack {
            switch appState.currentState {
            case .idle:
                Button("Start Recording (F5)") {
                    appState.toggleRecording()
                }
            case .recording:
                Button("Stop Recording (F5)") {
                    appState.toggleRecording()
                }
            case .transcribing:
                Text("Transcribing...")
                    .foregroundColor(.secondary)
            case .result:
                Button("Show Result") {
                    // Panel should already be visible
                }
                .disabled(true)
            }

            Divider()

            Button("Settings...") {
                NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
            }
            .keyboardShortcut(",", modifiers: .command)

            Divider()

            Button("Quit VoiceInk") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q", modifiers: .command)
        }
    }
}
