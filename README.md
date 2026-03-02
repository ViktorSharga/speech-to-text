# Speech to Text

A native macOS menu bar app for speech-to-text transcription with optional LLM-powered correction.

> Entirely vibe-coded using [Claude Code](https://claude.ai/code)

**Disclaimer**: This software is provided as-is, with no warranty of any kind. Use at your own risk. The author assumes no responsibility for any damages or issues arising from use of this software.

## Features

- Global hotkey (⌘R) to start/stop recording from anywhere
- Floating, non-activating panel that never steals focus
- Two transcription backends: local (WhisperKit) or cloud (OpenAI Whisper API)
- LLM text correction via OpenRouter with Casual and Formal modes
- Typing Mode: auto-copy transcription to clipboard and dismiss (enable in Settings)
- Language-aware prompts (English and Ukrainian) that preserve code-switching, slang, and technical terms
- macOS Liquid Glass UI

## Prerequisites

- macOS 26 (Tahoe)
- Xcode 17+
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)

## API Keys

| Service | Purpose | Approximate Cost |
|---------|---------|-----------------|
| [OpenAI](https://platform.openai.com/api-keys) | Whisper transcription (cloud backend) | ~$0.006/min |
| [OpenRouter](https://openrouter.ai/keys) | LLM text correction (optional) | ~$0.001/use |

Enter API keys in the app's Settings (menu bar icon > Settings).

Local transcription via WhisperKit requires no API key but downloads a ~150MB model on first launch.

## Build & Install

```bash
git clone https://github.com/user/speech-to-text.git
cd speech-to-text
xcodegen generate && xcodebuild -project SpeechToText.xcodeproj -scheme SpeechToText \
  -configuration Debug -derivedDataPath /tmp/SpeechToText-build -destination 'platform=macOS' build
open /tmp/SpeechToText-build/Build/Products/Debug/Speech\ to\ Text.app
```

To generate the app icon (optional, requires running on macOS with SF Symbols):
```bash
swift scripts/generate-icon.swift
```

## Usage

| Key | Context | Action |
|-----|---------|--------|
| ⌘R | Global | Toggle recording / dismiss result |
| Return | Recording | Stop recording |
| Escape | Any state | Dismiss panel |
| Cmd+C | Result | Copy text |
| Cmd+Return | Result | Copy & close |

**Correction modes** (buttons appear in result view):
- **Casual**: Fixes transcription errors only, minimal punctuation
- **Formal**: Fixes errors + improves grammar and punctuation

## License

MIT
