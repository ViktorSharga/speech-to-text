# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Quick Reference
- **Repo**: `~/Documents/VoiceInk` (GitHub: `ViktorSharga/speech-to-text`)
- **Bundle ID**: `app.speechtotext`
- **Installed app**: `/Applications/Speech to Text.app`

## Prerequisites
- macOS 26 (Tahoe)
- Xcode 17+
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)

## Build & Install
```bash
cd ~/Documents/VoiceInk
xcodegen generate
xcodebuild -project SpeechToText.xcodeproj -scheme SpeechToText -configuration Release \
  -derivedDataPath /tmp/SpeechToText-build -destination 'platform=macOS' build
# Install to /Applications:
pkill -f "Speech to Text" 2>/dev/null; sleep 1
rm -rf "/Applications/Speech to Text.app"
cp -R "/tmp/SpeechToText-build/Build/Products/Release/Speech to Text.app" "/Applications/Speech to Text.app"
open "/Applications/Speech to Text.app"
```

**Critical**: Use `/tmp/SpeechToText-build` for derived data — the `~/Documents` folder has iCloud xattrs that break codesigning.

## Project Generation
`project.yml` is the source of truth for the Xcode project. The `.xcodeproj` is gitignored and regenerated via `xcodegen generate`. Always edit `project.yml` for build settings, targets, or dependency changes — never edit the `.xcodeproj` directly.

There is also a `Package.swift` for SPM compatibility, but `project.yml` is what drives the actual build.

## Architecture

### State Machine (AppState.swift)
```
⌘R          ⌘R               ⌘R / Dismiss
  |                |                        |
  v                v                        v
IDLE --> RECORDING --> TRANSCRIBING --> RESULT --> IDLE
```

`AppState` is the central `@MainActor ObservableObject`. It owns the audio recorder, hotkey manager, transcription service, panel controller, and correction service. All state transitions flow through `toggleRecording()` and `dismiss()`.

**Typing Mode** (`typingMode` @AppStorage): When enabled, transcription result is auto-copied to clipboard and the panel is dismissed immediately — skips the result view entirely.

### Transcription (Protocol-based, swappable)
- `TranscriptionService` protocol — `prepare()`, `transcribe(audioData:language:)`
- `WhisperKitService` — local CoreML inference via WhisperKit
- `OpenAIWhisperService` — cloud API with Keychain-stored API key
- `TranscriptionServiceFactory` — creates active backend from settings

### Text Correction (LLM post-processing)
- `TextCorrectionService` — sends transcribed text to an LLM via OpenRouter for error correction
- Two modes: **Casual** (fix transcription errors only) and **Formal** (fix errors + improve grammar)
- Language-aware prompts (Ukrainian/English) with strict rules to preserve language mix, slang, and swearing
- Uses XML tag wrapping + assistant prefill + stop sequence to prevent chatbot behavior
- API key stored in Keychain (separate from OpenAI key), model configurable in Settings
- Default model: `anthropic/claude-haiku-4.5` via OpenRouter (OpenAI-compatible API)
- **Note**: Text correction settings (OpenRouter API key, model picker) are only visible in Settings when the OpenAI cloud backend is selected

### Audio Pipeline
- `AudioRecorder` — AVAudioEngine -> 16kHz mono Float32 -> WAV encoding
- RMS level published via Combine for recording indicator animation

### UI
- `FloatingPanel` (NSPanel) — non-activating, floating, doesn't steal focus
- `RecordingView` — state-driven content (idle / recording / transcribing / result)
- `TranscriptionResultView` — editable TextEditor + correction & copy buttons (Liquid Glass)
- `MenuBarExtra` — menu bar icon with dropdown controls
- `SettingsView` — tabbed: General (language, hotkey, typing mode) and Transcription (backend, model, API keys)

### Hotkey
- HotKey package (Carbon `RegisterEventHotKey`) — ⌘R, no Accessibility permission needed
- During recording: bare Return and Escape are registered as additional hotkeys (installed/removed dynamically)

### Persistence (@AppStorage keys)
| Key | Type | Default | Purpose |
|-----|------|---------|---------|
| `selectedLanguage` | LanguageMode | `.ukrainian` | EN or UA |
| `selectedBackend` | String | `"Local (WhisperKit)"` | Transcription backend |
| `whisperModel` | String | `"base"` | Local WhisperKit model size |
| `correctionModel` | String | `"anthropic/claude-haiku-4.5"` | OpenRouter model for correction |
| `typingMode` | Bool | `false` | Auto-copy & dismiss mode |

### Entitlements
- Sandbox disabled (required for global hotkey registration)
- Audio input (microphone)
- Network client (API calls to OpenAI, OpenRouter)

## File Map
| File | Purpose |
|------|---------|
| SpeechToTextApp.swift | @main, MenuBarExtra + Settings scenes |
| AppState.swift | Central ObservableObject, state machine |
| Transcription/TranscriptionService.swift | Protocol + error types + backend enum |
| Transcription/WhisperKitService.swift | Local WhisperKit backend |
| Transcription/OpenAIWhisperService.swift | OpenAI API backend + Keychain helpers |
| Transcription/TranscriptionServiceFactory.swift | Backend factory |
| Managers/HotkeyManager.swift | ⌘R global hotkey via HotKey package |
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
| scripts/generate-icon.swift | Generates app icon PNGs (run with `swift scripts/generate-icon.swift`) |

## Dependencies (SPM via project.yml)
- WhisperKit >= 0.9.0 — local Whisper inference
- HotKey >= 0.2.1 — global hotkey registration

## Keyboard Shortcuts
| Key | Context | Action |
|-----|---------|--------|
| ⌘R | Global | Toggle recording / dismiss result |
| Return | Recording | Stop recording |
| Escape | Any panel state | Dismiss panel |
| Cmd+C | Result | Copy text |
| Cmd+Return | Result | Copy & close |

## Known Gotchas
- **iCloud xattrs**: Build to `/tmp/SpeechToText-build`, not inside `~/Documents`
- **WhisperKit model download**: First launch downloads ~150MB (base model) — shows "Loading model..." in menu bar
- **16GB Mac**: Stick to `base` or `small` models; `large-v3` uses ~3GB RAM
- **Keychain service**: `app.speechtotext` — API keys from old VoiceInk builds won't carry over
- **No tests**: There are no test targets — no unit or UI tests to run
