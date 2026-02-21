import SwiftUI

struct CorrectionModelOption: Identifiable {
    let id: String
    let label: String

    static let options: [CorrectionModelOption] = [
        .init(id: "anthropic/claude-haiku-4.5", label: "Haiku 4.5 · $1/$5"),
        .init(id: "anthropic/claude-sonnet-4.5", label: "Sonnet 4.5 · $3/$15"),
        .init(id: "openai/gpt-4o-mini", label: "GPT-4o Mini · $0.15/$0.60"),
        .init(id: "openai/gpt-5-mini", label: "GPT-5 Mini · $0.25/$2"),
        .init(id: "google/gemini-2.5-flash", label: "Gemini 2.5 Flash · $0.30/$2.50"),
    ]
}

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @AppStorage("whisperModel") private var whisperModel = Constants.Defaults.whisperModel
    @State private var apiKeyInput = ""
    @State private var hasAPIKey = false
    @State private var openRouterKeyInput = ""
    @State private var hasOpenRouterKey = false

    private let localModels = ["tiny", "base", "small", "medium", "large-v3"]

    var body: some View {
        TabView {
            generalTab
                .tabItem { Label("General", systemImage: "gear") }

            transcriptionTab
                .tabItem { Label("Transcription", systemImage: "waveform") }
        }
        .frame(width: 450, height: 380)
        .onAppear {
            hasAPIKey = OpenAIWhisperService.loadAPIKey() != nil
            hasOpenRouterKey = TextCorrectionService.loadAPIKey() != nil
        }
    }

    private var generalTab: some View {
        Form {
            Picker("Language", selection: $appState.selectedLanguage) {
                ForEach(LanguageMode.allCases, id: \.self) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }

            Section {
                Text("Press F5 to start/stop recording")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("Make sure to disable system Dictation shortcut in System Settings → Keyboard if it conflicts with F5.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } header: {
                Text("Hotkey")
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    private var transcriptionTab: some View {
        Form {
            Picker("Backend", selection: Binding(
                get: { appState.selectedBackend },
                set: { newValue in
                    appState.selectedBackend = newValue
                    appState.updateTranscriptionService()
                }
            )) {
                ForEach(TranscriptionBackend.allCases) { backend in
                    Text(backend.rawValue).tag(backend)
                }
            }

            if appState.selectedBackend == .local {
                Picker("Model", selection: $whisperModel) {
                    ForEach(localModels, id: \.self) { model in
                        Text(model).tag(model)
                    }
                }
                .onChange(of: whisperModel) {
                    appState.updateTranscriptionService()
                }

                Text("base (~150MB) is fast. small (~500MB) is better for Ukrainian. large-v3 (~3GB) needs significant RAM.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if appState.selectedBackend == .openai {
                Section("API Key (Transcription)") {
                    SecureField("sk-...", text: $apiKeyInput)
                        .onSubmit {
                            saveAPIKey()
                        }

                    HStack {
                        if hasAPIKey {
                            Label("API key saved", systemImage: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.caption)
                        }
                        Spacer()
                        Button("Save") {
                            saveAPIKey()
                        }
                        .disabled(apiKeyInput.isEmpty)
                    }
                }

                Section("Text Correction") {
                    SecureField("sk-or-...", text: $openRouterKeyInput)
                        .onSubmit {
                            saveOpenRouterKey()
                        }

                    HStack {
                        if hasOpenRouterKey {
                            Label("API key saved", systemImage: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.caption)
                        }
                        Spacer()
                        Button("Save") {
                            saveOpenRouterKey()
                        }
                        .disabled(openRouterKeyInput.isEmpty)
                    }

                    Picker("Model", selection: $appState.correctionModel) {
                        ForEach(CorrectionModelOption.options) { option in
                            Text(option.label).tag(option.id)
                        }
                    }
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    private func saveAPIKey() {
        guard !apiKeyInput.isEmpty else { return }
        OpenAIWhisperService.saveAPIKey(apiKeyInput)
        hasAPIKey = true
        apiKeyInput = ""
        appState.updateTranscriptionService()
    }

    private func saveOpenRouterKey() {
        guard !openRouterKeyInput.isEmpty else { return }
        TextCorrectionService.saveAPIKey(openRouterKeyInput)
        hasOpenRouterKey = true
        openRouterKeyInput = ""
    }
}
