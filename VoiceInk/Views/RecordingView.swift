import SwiftUI

struct RecordingView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(spacing: 16) {
            switch appState.currentState {
            case .idle:
                idleView
            case .recording:
                recordingContent
            case .transcribing:
                transcribingContent
            case .result:
                TranscriptionResultView()
                    .environmentObject(appState)
            }

            if let error = appState.errorMessage {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                        .font(.caption)
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
                .padding(.horizontal)

                Button("Dismiss") {
                    appState.dismiss()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .padding()
        .frame(minWidth: 320, maxWidth: 320, minHeight: 200)
        .background(.ultraThinMaterial)
        .onKeyPress(.escape) {
            appState.dismiss()
            return .handled
        }
        .onKeyPress(.return) {
            if appState.currentState == .recording {
                appState.toggleRecording()
                return .handled
            }
            return .ignored
        }
    }

    private var idleView: some View {
        VStack(spacing: 12) {
            Image(systemName: "mic")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            Text("Press F5 to start recording")
                .font(.headline)
                .foregroundColor(.secondary)
        }
    }

    private var recordingContent: some View {
        VStack(spacing: 16) {
            RecordingIndicator(level: appState.audioLevel)

            Text("Recording...")
                .font(.headline)

            LanguageSelector()
                .environmentObject(appState)

            Text("Press F5 or Return to stop")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private var transcribingContent: some View {
        VStack(spacing: 12) {
            ProgressView()
                .controlSize(.large)
            Text("Transcribing...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
    }
}
