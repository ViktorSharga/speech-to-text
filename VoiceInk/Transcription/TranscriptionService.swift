import Foundation

enum TranscriptionError: LocalizedError {
    case serviceNotReady
    case modelNotLoaded
    case invalidAudioData
    case apiKeyMissing
    case apiError(String)
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .serviceNotReady:
            return "Transcription service is not ready"
        case .modelNotLoaded:
            return "Whisper model is not loaded"
        case .invalidAudioData:
            return "Invalid audio data"
        case .apiKeyMissing:
            return "OpenAI API key is not set. Configure it in Settings."
        case .apiError(let message):
            return "API error: \(message)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}

enum TranscriptionBackend: String, CaseIterable, Identifiable {
    case local = "Local (WhisperKit)"
    case openai = "OpenAI API"

    var id: String { rawValue }
}

protocol TranscriptionService: AnyObject {
    var displayName: String { get }
    var isAvailable: Bool { get }
    func prepare() async throws
    func transcribe(audioData: Data, language: String?) async throws -> String
}
