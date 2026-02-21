import Foundation

enum TranscriptionServiceFactory {
    static func create(_ backend: TranscriptionBackend, model: String? = nil) -> any TranscriptionService {
        switch backend {
        case .local:
            return WhisperKitService(modelName: model ?? Constants.Defaults.whisperModel)
        case .openai:
            return OpenAIWhisperService(model: model ?? Constants.Defaults.openAIModel)
        }
    }
}
