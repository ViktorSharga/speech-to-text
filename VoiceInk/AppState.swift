import SwiftUI
import Combine

enum AppStateValue: Equatable {
    case idle
    case recording
    case transcribing
    case result(String)

    static func == (lhs: AppStateValue, rhs: AppStateValue) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.recording, .recording), (.transcribing, .transcribing):
            return true
        case (.result(let a), .result(let b)):
            return a == b
        default:
            return false
        }
    }
}

enum LanguageMode: String, CaseIterable {
    case auto = "Auto"
    case english = "EN"
    case ukrainian = "UA"

    var whisperCode: String? {
        switch self {
        case .auto: return nil
        case .english: return "en"
        case .ukrainian: return "uk"
        }
    }
}

@MainActor
class AppState: ObservableObject {
    @Published var currentState: AppStateValue = .idle
    @Published var audioLevel: Float = 0.0
    @Published var transcribedText: String = ""
    @Published var errorMessage: String?
    @Published var isPreparingModel: Bool = false

    @AppStorage("selectedLanguage") var selectedLanguage: LanguageMode = .auto
    @AppStorage("selectedBackend") var selectedBackendRaw: String = TranscriptionBackend.local.rawValue

    var selectedBackend: TranscriptionBackend {
        get { TranscriptionBackend(rawValue: selectedBackendRaw) ?? .local }
        set {
            selectedBackendRaw = newValue.rawValue
            objectWillChange.send()
        }
    }

    private var audioRecorder: AudioRecorder?
    private var hotkeyManager: HotkeyManager?
    private var transcriptionService: (any TranscriptionService)?
    private var panelController: FloatingPanelController?
    private var levelCancellable: AnyCancellable?

    func setup() {
        audioRecorder = AudioRecorder()
        levelCancellable = audioRecorder?.levelPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] level in
                self?.audioLevel = level
            }

        hotkeyManager = HotkeyManager { [weak self] in
            Task { @MainActor in
                self?.toggleRecording()
            }
        }

        updateTranscriptionService()
        panelController = FloatingPanelController(appState: self)
    }

    func updateTranscriptionService() {
        transcriptionService = TranscriptionServiceFactory.create(selectedBackend)
        isPreparingModel = true
        Task {
            do {
                try await transcriptionService?.prepare()
                isPreparingModel = false
            } catch {
                isPreparingModel = false
                // Don't show API key errors at startup for OpenAI — user will configure later
                if selectedBackend == .local {
                    errorMessage = "Failed to prepare model: \(error.localizedDescription)"
                }
            }
        }
    }

    func toggleRecording() {
        switch currentState {
        case .idle:
            startRecording()
        case .recording:
            stopRecording()
        case .result:
            dismiss()
        case .transcribing:
            break
        }
    }

    private func startRecording() {
        guard Permissions.hasMicrophoneAccess else {
            Permissions.requestMicrophoneAccess { [weak self] granted in
                Task { @MainActor in
                    if granted {
                        self?.startRecording()
                    } else {
                        self?.errorMessage = "Microphone access denied. Enable in System Settings → Privacy → Microphone."
                        self?.panelController?.show()
                    }
                }
            }
            return
        }

        errorMessage = nil
        currentState = .recording
        panelController?.show()

        do {
            try audioRecorder?.startRecording()
        } catch {
            errorMessage = "Failed to start recording: \(error.localizedDescription)"
            currentState = .idle
            panelController?.hide()
        }
    }

    private func stopRecording() {
        currentState = .transcribing

        guard let audioData = audioRecorder?.stopRecording(), !audioData.isEmpty else {
            errorMessage = "No audio captured. Make sure your microphone is working."
            currentState = .idle
            panelController?.hide()
            return
        }

        Task {
            do {
                guard let service = transcriptionService else {
                    throw TranscriptionError.serviceNotReady
                }
                let text = try await service.transcribe(
                    audioData: audioData,
                    language: selectedLanguage.whisperCode
                )

                let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else {
                    errorMessage = "No speech detected. Try speaking louder or closer to the mic."
                    currentState = .idle
                    panelController?.hide()
                    return
                }

                transcribedText = trimmed
                currentState = .result(trimmed)
            } catch {
                errorMessage = "Transcription failed: \(error.localizedDescription)"
                currentState = .idle
                panelController?.hide()
            }
        }
    }

    func dismiss() {
        currentState = .idle
        transcribedText = ""
        errorMessage = nil
        panelController?.hide()
    }

    func copyToClipboard() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(transcribedText, forType: .string)
    }

    /// Copy text and dismiss panel in one action
    func copyAndDismiss() {
        copyToClipboard()
        dismiss()
    }
}
