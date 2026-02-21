import Foundation

enum Constants {
    static let appName = "SpeechToText"
    static let modelsDirectory: URL = {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return appSupport.appendingPathComponent("SpeechToText/Models")
    }()

    static let keychainServiceName = "app.speechtotext"
    static let keychainAPIKeyAccount = "openai-api-key"
    static let keychainOpenRouterAPIKeyAccount = "openrouter-api-key"

    enum Defaults {
        static let whisperModel = "base"
        static let openAIModel = "gpt-4o-transcribe"
        static let defaultCorrectionModel = "anthropic/claude-haiku-4.5"
    }
}
