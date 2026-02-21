import Foundation
import Security

class OpenAIWhisperService: TranscriptionService {
    let displayName = "OpenAI API"

    private let endpoint = URL(string: "https://api.openai.com/v1/audio/transcriptions")!
    private var apiKey: String?
    private var model: String

    var isAvailable: Bool {
        apiKey != nil && !apiKey!.isEmpty
    }

    init(model: String = Constants.Defaults.openAIModel) {
        self.model = model
        apiKey = Self.loadAPIKey()
    }

    func prepare() async throws {
        apiKey = Self.loadAPIKey()
        if apiKey == nil || apiKey!.isEmpty {
            throw TranscriptionError.apiKeyMissing
        }
    }

    func transcribe(audioData: Data, language: String?) async throws -> String {
        guard let apiKey, !apiKey.isEmpty else {
            throw TranscriptionError.apiKeyMissing
        }

        let boundary = UUID().uuidString
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()

        // file field
        body.appendMultipart(boundary: boundary, name: "file", filename: "audio.wav",
                            contentType: "audio/wav", data: audioData)

        // model field
        body.appendMultipart(boundary: boundary, name: "model", value: model)

        // language field (optional)
        if let language {
            body.appendMultipart(boundary: boundary, name: "language", value: language)
        }

        // prompt field — steers the model for mixed-language speech
        let prompt = Self.prompt(forLanguage: language)
        body.appendMultipart(boundary: boundary, name: "prompt", value: prompt)

        // response_format
        body.appendMultipart(boundary: boundary, name: "response_format", value: "text")

        // closing boundary
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw TranscriptionError.networkError(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw TranscriptionError.apiError("Invalid response")
        }

        guard httpResponse.statusCode == 200 else {
            let errorText = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw TranscriptionError.apiError("HTTP \(httpResponse.statusCode): \(errorText)")
        }

        let text = String(data: data, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return text
    }

    // MARK: - Prompt selection

    private static func prompt(forLanguage language: String?) -> String {
        switch language {
        case "uk":
            return "Транскрипція українською мовою. Мовець говорить українською, але може використовувати англійські та російські слова — технічні терміни, сленг, меми, імена, жаргон. Нецензурна лексика допустима, транскрибувати як є. Приклади: deploy, merge, branch, PR, фіча, продакшн, мітинг, дедлайн, рефакторинг."
        case "en":
            return "Transcription in English. The speaker uses English but may include Ukrainian or Russian words — names, slang, technical jargon. Transcribe foreign words as spoken. Examples: Київ, борщ, вареники."
        default:
            return "The speaker may use Ukrainian, English, or Russian — or mix all three. Transcribe each word in its original language as spoken. Technical terms, slang, memes, names, and offensive language should be transcribed verbatim."
        }
    }

    // MARK: - Keychain

    static func saveAPIKey(_ key: String) {
        let data = key.data(using: .utf8)!
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Constants.keychainServiceName,
            kSecAttrAccount as String: Constants.keychainAPIKeyAccount,
        ]

        SecItemDelete(query as CFDictionary)

        var addQuery = query
        addQuery[kSecValueData as String] = data
        SecItemAdd(addQuery as CFDictionary, nil)
    }

    static func loadAPIKey() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Constants.keychainServiceName,
            kSecAttrAccount as String: Constants.keychainAPIKeyAccount,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func deleteAPIKey() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Constants.keychainServiceName,
            kSecAttrAccount as String: Constants.keychainAPIKeyAccount,
        ]
        SecItemDelete(query as CFDictionary)
    }
}

// MARK: - Multipart helpers
private extension Data {
    mutating func appendMultipart(boundary: String, name: String, filename: String,
                                   contentType: String, data: Data) {
        append("--\(boundary)\r\n".data(using: .utf8)!)
        append("Content-Disposition: form-data; name=\"\(name)\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        append("Content-Type: \(contentType)\r\n\r\n".data(using: .utf8)!)
        append(data)
        append("\r\n".data(using: .utf8)!)
    }

    mutating func appendMultipart(boundary: String, name: String, value: String) {
        append("--\(boundary)\r\n".data(using: .utf8)!)
        append("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n".data(using: .utf8)!)
        append("\(value)\r\n".data(using: .utf8)!)
    }
}
