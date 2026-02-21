# VoiceInk — Native macOS Speech-to-Text App

## Build Instructions
```bash
cd ~/Documents/VoiceInk
xcodegen generate
xcodebuild -project VoiceInk.xcodeproj -scheme VoiceInk -configuration Debug \
  -derivedDataPath /tmp/VoiceInk-build -destination 'platform=macOS' build
# Run:
open /tmp/VoiceInk-build/Build/Products/Debug/VoiceInk.app
```

**Note**: Use `/tmp/VoiceInk-build` for derived data — the Documents folder has iCloud xattrs that break codesigning.

## Architecture

### State Machine (AppState.swift)
```
F5 press         F5 press              F5 press / Dismiss
  │                │                        │
  ▼                ▼                        ▼
IDLE ──→ RECORDING ──→ TRANSCRIBING ──→ RESULT ──→ IDLE
```

### Transcription (Protocol-based, swappable)
- `TranscriptionService` protocol — `prepare()`, `transcribe(audioData:language:)`
- `WhisperKitService` — local CoreML inference via WhisperKit
- `OpenAIWhisperService` — cloud API with Keychain-stored API key
- `TranscriptionServiceFactory` — creates active backend from settings

### Audio Pipeline
- `AudioRecorder` — AVAudioEngine → 16kHz mono Float32 → WAV encoding
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
| VoiceInkApp.swift | @main, MenuBarExtra + Settings scenes |
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
| Views/TranscriptionResultView.swift | Editable TextEditor + copy button |
| Views/SettingsView.swift | Backend picker, model, API key, language |
| Views/MenuBarView.swift | Menu bar dropdown |
| Utilities/Permissions.swift | Microphone permission check/request |
| Utilities/Constants.swift | App paths, Keychain keys, defaults |

## Dependencies (SPM via project.yml)
- WhisperKit >= 0.9.0 — local Whisper inference
- HotKey >= 0.2.1 — global hotkey registration

## Status
- [x] Phase 1: Project skeleton (build succeeds)
- [x] Phase 2: Floating panel + UI shell
- [x] Phase 3: Global hotkey (F5)
- [x] Phase 4: Audio recording
- [x] Phase 5: Transcription protocol + WhisperKit backend
- [x] Phase 6: OpenAI API backend
- [x] Phase 7: Language selector + Settings
- [ ] Phase 8: Polish — keyboard shortcuts, error handling, icons
