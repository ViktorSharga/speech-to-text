import AVFoundation
import Combine

enum AudioRecorderError: LocalizedError {
    case engineStartFailed(Error)
    case noInputNode
    case formatConversionFailed

    var errorDescription: String? {
        switch self {
        case .engineStartFailed(let error):
            return "Audio engine failed to start: \(error.localizedDescription)"
        case .noInputNode:
            return "No audio input device found"
        case .formatConversionFailed:
            return "Failed to convert audio format"
        }
    }
}

class AudioRecorder: ObservableObject {
    private let engine = AVAudioEngine()
    private var audioBuffers: [AVAudioPCMBuffer] = []
    private let bufferQueue = DispatchQueue(label: "app.speechtotext.audioBuffer")

    private let levelSubject = PassthroughSubject<Float, Never>()
    var levelPublisher: AnyPublisher<Float, Never> {
        levelSubject.eraseToAnyPublisher()
    }

    private let targetSampleRate: Double = 16000
    private let targetChannels: AVAudioChannelCount = 1

    func startRecording() throws {
        audioBuffers.removeAll()

        let inputNode = engine.inputNode
        let inputFormat = inputNode.outputFormat(forBus: 0)

        guard inputFormat.sampleRate > 0 else {
            throw AudioRecorderError.noInputNode
        }

        guard let targetFormat = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: targetSampleRate,
            channels: targetChannels,
            interleaved: false
        ) else {
            throw AudioRecorderError.formatConversionFailed
        }

        guard let converter = AVAudioConverter(from: inputFormat, to: targetFormat) else {
            throw AudioRecorderError.formatConversionFailed
        }

        let bufferSize: AVAudioFrameCount = 4096
        inputNode.installTap(onBus: 0, bufferSize: bufferSize, format: inputFormat) { [weak self] buffer, _ in
            guard let self else { return }

            // Calculate RMS level from input buffer
            let level = self.calculateRMS(buffer: buffer)
            self.levelSubject.send(level)

            // Convert to target format
            let frameCapacity = AVAudioFrameCount(
                Double(buffer.frameLength) * self.targetSampleRate / inputFormat.sampleRate
            )
            guard frameCapacity > 0,
                  let convertedBuffer = AVAudioPCMBuffer(pcmFormat: targetFormat, frameCapacity: frameCapacity) else {
                return
            }

            var error: NSError?
            let status = converter.convert(to: convertedBuffer, error: &error) { _, outStatus in
                outStatus.pointee = .haveData
                return buffer
            }

            if status == .haveData {
                self.bufferQueue.sync {
                    self.audioBuffers.append(convertedBuffer)
                }
            }
        }

        do {
            try engine.start()
        } catch {
            throw AudioRecorderError.engineStartFailed(error)
        }
    }

    /// Stops recording and returns WAV-encoded audio data
    func stopRecording() -> Data? {
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        levelSubject.send(0)

        let buffers = bufferQueue.sync { audioBuffers }
        guard !buffers.isEmpty else { return nil }

        return encodeToWAV(buffers: buffers)
    }

    private func calculateRMS(buffer: AVAudioPCMBuffer) -> Float {
        guard let channelData = buffer.floatChannelData else { return 0 }
        let frames = Int(buffer.frameLength)
        let data = channelData[0]

        var sum: Float = 0
        for i in 0..<frames {
            sum += data[i] * data[i]
        }

        let rms = sqrt(sum / Float(max(frames, 1)))
        // Normalize to 0-1 range (typical speech RMS is ~0.01-0.1)
        return min(rms * 10, 1.0)
    }

    private func encodeToWAV(buffers: [AVAudioPCMBuffer]) -> Data {
        // Merge all buffers into a single float array
        var allSamples: [Float] = []
        for buffer in buffers {
            guard let channelData = buffer.floatChannelData else { continue }
            let count = Int(buffer.frameLength)
            let samples = Array(UnsafeBufferPointer(start: channelData[0], count: count))
            allSamples.append(contentsOf: samples)
        }

        // Convert Float32 samples to Int16
        let int16Samples = allSamples.map { sample -> Int16 in
            let clamped = max(-1.0, min(1.0, sample))
            return Int16(clamped * Float(Int16.max))
        }

        // Build WAV header
        let sampleRate = UInt32(targetSampleRate)
        let channels = UInt16(targetChannels)
        let bitsPerSample: UInt16 = 16
        let dataSize = UInt32(int16Samples.count * MemoryLayout<Int16>.size)
        let fileSize = 36 + dataSize

        var data = Data()

        // RIFF header
        data.append(contentsOf: "RIFF".utf8)
        data.append(littleEndian: fileSize)
        data.append(contentsOf: "WAVE".utf8)

        // fmt chunk
        data.append(contentsOf: "fmt ".utf8)
        data.append(littleEndian: UInt32(16))           // chunk size
        data.append(littleEndian: UInt16(1))             // PCM format
        data.append(littleEndian: channels)
        data.append(littleEndian: sampleRate)
        data.append(littleEndian: sampleRate * UInt32(channels) * UInt32(bitsPerSample / 8)) // byte rate
        data.append(littleEndian: UInt16(channels) * UInt16(bitsPerSample / 8))               // block align
        data.append(littleEndian: bitsPerSample)

        // data chunk
        data.append(contentsOf: "data".utf8)
        data.append(littleEndian: dataSize)
        int16Samples.withUnsafeBufferPointer { ptr in
            data.append(UnsafeBufferPointer(start: UnsafeRawPointer(ptr.baseAddress!)
                .assumingMemoryBound(to: UInt8.self), count: Int(dataSize)))
        }

        return data
    }
}

// MARK: - Data helpers for WAV encoding
private extension Data {
    mutating func append(littleEndian value: UInt16) {
        var v = value.littleEndian
        Swift.withUnsafeBytes(of: &v) { append(contentsOf: $0) }
    }

    mutating func append(littleEndian value: UInt32) {
        var v = value.littleEndian
        Swift.withUnsafeBytes(of: &v) { append(contentsOf: $0) }
    }
}
