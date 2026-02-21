import Foundation
import WhisperKit

class WhisperKitService: TranscriptionService {
    let displayName = "Local (WhisperKit)"

    private var whisperKit: WhisperKit?
    private var modelName: String

    var isAvailable: Bool {
        whisperKit != nil
    }

    init(modelName: String = Constants.Defaults.whisperModel) {
        self.modelName = modelName
    }

    func prepare() async throws {
        // Create models directory if needed
        let modelsDir = Constants.modelsDirectory
        try FileManager.default.createDirectory(at: modelsDir, withIntermediateDirectories: true)

        // Initialize WhisperKit with specified model
        whisperKit = try await WhisperKit(
            model: modelName,
            downloadBase: modelsDir,
            verbose: false
        )
    }

    func transcribe(audioData: Data, language: String?) async throws -> String {
        guard let whisperKit else {
            throw TranscriptionError.modelNotLoaded
        }

        // Write WAV data to a temporary file for WhisperKit
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("wav")
        try audioData.write(to: tempURL)
        defer { try? FileManager.default.removeItem(at: tempURL) }

        // Configure decoding options
        var options = DecodingOptions()
        if let language {
            options.language = language
        }
        options.verbose = false

        let results = try await whisperKit.transcribe(
            audioPath: tempURL.path,
            decodeOptions: options
        )

        let text = results
            .compactMap { $0.text }
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return text
    }

    func updateModel(_ newModel: String) async throws {
        modelName = newModel
        whisperKit = nil
        try await prepare()
    }
}
