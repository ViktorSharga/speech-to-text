import Foundation

enum Constants {
    static let appName = "VoiceInk"
    static let modelsDirectory: URL = {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return appSupport.appendingPathComponent("VoiceInk/Models")
    }()

    static let keychainServiceName = "com.viktorsarga.VoiceInk"
    static let keychainAPIKeyAccount = "openai-api-key"

    enum Defaults {
        static let whisperModel = "base"
        static let openAIModel = "whisper-1"
    }
}
