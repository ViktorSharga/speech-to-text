# Speech to Text — Native macOS Speech-to-Text App

## Build Instructions
```bash
cd ~/Documents/speech-to-text
xcodegen generate
xcodebuild -project SpeechToText.xcodeproj -scheme SpeechToText -configuration Debug \
  -derivedDataPath /tmp/SpeechToText-build -destination 'platform=macOS' build
# Run:
open /tmp/SpeechToText-build/Build/Products/Debug/Speech\ to\ Text.app
```

**Note**: Use `/tmp/SpeechToText-build` for derived data — the Documents folder has iCloud xattrs that break codesigning.

## Architecture

### State Machine (AppState.swift)
```
F5 press         F5 press              F5 press / Dismiss
  |                |                        |
  v                v                        v
IDLE --> RECORDING --> TRANSCRIBING --> RESULT --> IDLE
```

### Transcription (Protocol-based, swappable)
- `TranscriptionService` protocol — `prepare()`, `transcribe(audioData:language:)`
- `WhisperKitService` — local CoreML inference via WhisperKit
- `OpenAIWhisperService` — cloud API with Keychain-stored API key
- `TranscriptionServiceFactory` — creates active backend from settings

### Text Correction (LLM post-processing)
- `TextCorrectionService` — sends transcribed text to an LLM via OpenRouter for error correction
- Two modes: **Casual** (fix transcription errors only) and **Formal** (fix errors + improve grammar)
- Language-aware prompts (Ukrainian/English) with strict rules to preserve language mix, slang, and swearing
- API key stored in Keychain (separate from OpenAI key), model configurable in Settings
- Default model: `anthropic/claude-haiku-4.5` via OpenRouter (OpenAI-compatible API)

### Audio Pipeline
- `AudioRecorder` — AVAudioEngine -> 16kHz mono Float32 -> WAV encoding
- RMS level published via Combine for recording indicator animation

### UI
- `FloatingPanel` (NSPanel) — non-activating, floating, doesn't steal focus
- `RecordingView` — state-driven content (idle / recording / transcribing / result)
- `MenuBarExtra` — menu bar icon with dropdown controls
- `SettingsView` — backend picker, model picker, API key, language

### Hotkey
- HotKey package (Carbon `RegisterEventHotKey`) — F5, no Accessibility permission needed

## File Map
| File | Purpose |
|------|---------|
| SpeechToTextApp.swift | @main, MenuBarExtra + Settings scenes |
| AppState.swift | Central ObservableObject, state machine |
| Transcription/TranscriptionService.swift | Protocol + error types + backend enum |
| Transcription/WhisperKitService.swift | Local WhisperKit backend |
| Transcription/OpenAIWhisperService.swift | OpenAI API backend + Keychain helpers |
| Transcription/TranscriptionServiceFactory.swift | Backend factory |
| Managers/HotkeyManager.swift | F5 global hotkey via HotKey package |
| Managers/AudioRecorder.swift | AVAudioEngine recording + WAV encoding |
| Views/FloatingPanel.swift | NSPanel subclass + controller |
| Views/RecordingView.swift | Main panel content (state-driven) |
| Views/RecordingIndicator.swift | Pulsing mic + audio level ring |
| Views/LanguageSelector.swift | Auto / EN / UA pill toggle |
| Views/TranscriptionResultView.swift | Editable TextEditor + correction & copy buttons (Liquid Glass) |
| Views/SettingsView.swift | Backend picker, model, API key, language, OpenRouter settings |
| Views/MenuBarView.swift | Menu bar dropdown |
| Utilities/Permissions.swift | Microphone permission check/request |
| Services/TextCorrectionService.swift | LLM text correction via OpenRouter + Keychain helpers |
| Utilities/Constants.swift | App paths, Keychain keys, defaults |

## Dependencies (SPM via project.yml)
- WhisperKit >= 0.9.0 — local Whisper inference
- HotKey >= 0.2.1 — global hotkey registration

## Keyboard Shortcuts
| Key | Context | Action |
|-----|---------|--------|
| F5 | Global | Toggle recording / dismiss result |
| Return | Recording | Stop recording |
| Escape | Any panel state | Dismiss panel |
| Cmd+C | Result | Copy text |
| Cmd+Return | Result | Copy & close |

## Known Gotchas
- **iCloud xattrs**: Build to `/tmp/SpeechToText-build`, not inside `~/Documents`
- **F5 conflict**: User must disable system Dictation shortcut (System Settings -> Keyboard -> Dictation)
- **WhisperKit model download**: First launch downloads ~150MB (base model) — shows "Loading model..." in menu bar
- **16GB Mac**: Stick to `base` or `small` models; `large-v3` uses ~3GB RAM
