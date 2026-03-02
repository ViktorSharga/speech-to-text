import SwiftUI
import Combine
import HotKey

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
    case english = "EN"
    case ukrainian = "UA"

    var whisperCode: String? {
        switch self {
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
    @Published var isCorrecting: Bool = false

    @AppStorage("selectedLanguage") var selectedLanguage: LanguageMode = .ukrainian
    @AppStorage("correctionModel") var correctionModel: String = Constants.Defaults.defaultCorrectionModel
    @AppStorage("selectedBackend") var selectedBackendRaw: String = TranscriptionBackend.local.rawValue
    @AppStorage("typingMode") var typingMode: Bool = false

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
    private var correctionService = TextCorrectionService()
    private var enterHotKey: HotKey?
    private var numpadEnterHotKey: HotKey?
    private var escapeHotKey: HotKey?

    init() {
        // Defer setup to avoid issues during SwiftUI initialization
        DispatchQueue.main.async { [weak self] in
            self?.setup()
        }
    }

    private func setup() {
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
        installRecordingHotKeys()
        panelController?.show()

        do {
            try audioRecorder?.startRecording()
        } catch {
            errorMessage = "Failed to start recording: \(error.localizedDescription)"
            currentState = .idle
            removeRecordingHotKeys()
            panelController?.hide()
        }
    }

    private func stopRecording() {
        removeRecordingHotKeys()
        currentState = .transcribing

        guard let audioData = audioRecorder?.stopRecording(), !audioData.isEmpty else {
            errorMessage = "No audio captured. Make sure your microphone is working."
            currentState = .idle
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
                    return
                }

                transcribedText = trimmed

                if self.typingMode {
                    self.copyToClipboard()
                    self.dismiss()
                } else {
                    currentState = .result(trimmed)
                }
            } catch {
                errorMessage = "Transcription failed: \(error.localizedDescription)"
                currentState = .idle
            }
        }
    }

    func dismiss() {
        if case .recording = currentState {
            _ = audioRecorder?.stopRecording()
        }
        removeRecordingHotKeys()
        currentState = .idle
        transcribedText = ""
        errorMessage = nil
        panelController?.hide()
    }

    private func installRecordingHotKeys() {
        guard enterHotKey == nil else { return }
        enterHotKey = HotKey(key: .return, modifiers: [])
        enterHotKey?.keyDownHandler = { [weak self] in
            Task { @MainActor in self?.toggleRecording() }
        }
        numpadEnterHotKey = HotKey(key: .keypadEnter, modifiers: [])
        numpadEnterHotKey?.keyDownHandler = { [weak self] in
            Task { @MainActor in self?.toggleRecording() }
        }
        escapeHotKey = HotKey(key: .escape, modifiers: [])
        escapeHotKey?.keyDownHandler = { [weak self] in
            Task { @MainActor in self?.dismiss() }
        }
    }

    private func removeRecordingHotKeys() {
        enterHotKey = nil
        numpadEnterHotKey = nil
        escapeHotKey = nil
    }

    func copyToClipboard() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(transcribedText, forType: .string)
    }

    func copyAndDismiss() {
        copyToClipboard()
        dismiss()
    }

    func correctText(mode: CorrectionMode) {
        isCorrecting = true
        Task {
            do {
                let corrected = try await correctionService.correct(
                    text: transcribedText,
                    language: selectedLanguage.whisperCode,
                    mode: mode
                )
                transcribedText = corrected
                currentState = .result(corrected)
            } catch {
                errorMessage = "Correction failed: \(error.localizedDescription)"
            }
            isCorrecting = false
        }
    }
}
