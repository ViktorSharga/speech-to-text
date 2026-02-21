import Foundation

enum TranscriptionServiceFactory {
    static func create(_ backend: TranscriptionBackend, model: String? = nil) -> any TranscriptionService {
        switch backend {
        case .local:
            let savedModel = UserDefaults.standard.string(forKey: "whisperModel") ?? Constants.Defaults.whisperModel
            return WhisperKitService(modelName: model ?? savedModel)
        case .openai:
            return OpenAIWhisperService(model: model ?? Constants.Defaults.openAIModel)
        }
    }
}
