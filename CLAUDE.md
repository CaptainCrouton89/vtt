# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a macOS voice-to-text system that uses Mistral's Whisper API for transcription. Users press and hold `⌥`` to record audio, release to transcribe, and the result is automatically pasted at cursor position.

## Architecture

The system consists of three main components:

1. **Hammerspoon Integration** (`vtt.lua`): Handles global hotkey binding, audio recording coordination, and system integration (menubar, notifications, clipboard)
2. **Transcription Service** (`transcribe.js`): Node.js script that interfaces with Mistral's `voxtral-mini-latest` model
3. **Setup/Verification** (`setup.sh`, `verify-setup.sh`): Installation and configuration automation

### Key Technical Details

- **Audio Recording**: Uses `ffmpeg` with AVFoundation to capture 16kHz mono audio to `/tmp/vtt_recording.wav`
- **API Integration**: Uses `@mistralai/mistralai` NPM package to call Mistral's audio transcription API
- **Global Hotkey**: Hammerspoon binds Alt+backtick with press-and-hold behavior
- **System Integration**: Automatic clipboard paste via `hs.eventtap.keyStroke`

## Development Commands

### Setup and Installation

```bash
./setup.sh              # Complete system setup
./verify-setup.sh        # Verify all components are working
npm install              # Install Node.js dependencies (called by setup.sh)
```

### Testing and Development

```bash
# Test Mistral API connection
node test-api.js

# Test transcription with audio file
node transcribe.js <audio-file-path>

# Test audio recording manually
ffmpeg -f avfoundation -i ":0" -t 3 -ar 16000 -ac 1 test.wav

# Debug Hammerspoon (check console in Hammerspoon app)
# Reload configuration: Cmd+R in Hammerspoon console
```

## Environment Requirements

- **MISTRAL_API_KEY**: Required environment variable for API access
- **macOS Permissions**: Microphone, Accessibility, and Automation permissions for Hammerspoon
- **Dependencies**: ffmpeg, Node.js, Hammerspoon app

## File Structure

```
vtt/
├── transcribe.js           # Mistral API client for audio transcription
├── vtt.lua                # Hammerspoon configuration and hotkey logic
├── setup.sh              # Automated installation script (installs files in directory)
├── verify-setup.sh       # System verification and troubleshooting
├── package.json          # Node.js dependencies (@mistralai/mistralai)
└── test-*.js             # Development testing utilities
```

## Configuration

The system installs to `~/.hammerspoon/vtt/` with the following structure:

- `vtt.lua` - Main Hammerspoon module
- `transcribe.js` - Transcription script with dependencies
- `node_modules/` - NPM packages

Configuration options in `vtt.lua`:

- Hotkey combination (default: `{"alt"}` + "`")
- Audio settings (16kHz, mono, 30s max duration)
- File paths for temporary audio storage

## Development Notes

- Audio files are automatically cleaned up after transcription
- Maximum recording duration is 30 seconds with automatic timeout
- The system provides visual feedback via menubar icons and notifications
- Error handling includes API failures, permission issues, and audio capture problems
- All audio processing happens in temporary files with automatic cleanup for privacy
