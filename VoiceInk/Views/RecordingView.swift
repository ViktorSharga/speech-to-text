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
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
        .padding()
        .frame(minWidth: 320, maxWidth: 320, minHeight: 200)
        .background(.ultraThinMaterial)
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

            Text("Press F5 to stop")
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
        }
    }
}
