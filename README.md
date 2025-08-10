# Voice-to-Text for macOS

A global voice-to-text system for macOS that uses Mistral's Whisper API for transcription. Press and hold `⌥`` to record audio, release to transcribe and automatically paste the result.

## Features

- 🎤 **Global hotkey**: Press and hold `⌥`` to record, release to transcribe
- 🤖 **Mistral AI**: Uses Mistral's `whisper-large-v3` model for high-quality transcription
- 📋 **Auto-paste**: Automatically copies and pastes transcribed text at cursor position
- 🔔 **Visual feedback**: Menubar indicator and notifications show recording/processing status
- 🎵 **Audio cues**: System sounds for start/stop recording
- ⏱️ **Smart timing**: Maximum 30-second recordings with automatic timeout
- 🛡️ **Privacy-focused**: Audio files are automatically cleaned up after transcription

## Prerequisites

### 1. Install Required Tools

```bash
# Install ffmpeg for audio recording
brew install ffmpeg

# Install Node.js for the transcription script
brew install node

# Install Hammerspoon for global hotkeys
brew install --cask hammerspoon
# Or download from: https://www.hammerspoon.org/
```

### 2. Get Mistral API Key

1. Sign up at [Mistral Console](https://console.mistral.ai/)
2. Create an API key
3. Add it to your shell environment:

```bash
# Add to ~/.zshrc or ~/.bash_profile
export MISTRAL_API_KEY='your-api-key-here'

# Reload your shell
source ~/.zshrc
```

### 3. Configure macOS Permissions

Grant the following permissions in **System Settings → Privacy & Security**:

- **Microphone**: Allow Hammerspoon to access the microphone
- **Accessibility**: Allow Hammerspoon to control your computer (for pasting)
- **Automation**: Allow Hammerspoon to control System Events (if prompted)

## Installation

1. **Clone or download** this repository
2. **Run the setup script**:

```bash
cd vtt
./setup.sh
```

The setup script will:

- Install Node.js dependencies
- Test the transcription system
- Copy files to Hammerspoon's configuration directory
- Set up the global hotkey
- Reload Hammerspoon configuration

## Usage

### Basic Operation

1. **Start recording**: Press and hold `⌥``
2. **Speak clearly** into your microphone
3. **Stop recording**: Release the keys
4. **Wait for transcription**: The system will process your audio and automatically paste the result

### Visual Indicators

- **🎤 Ready**: System is ready to record
- **🔴 Recording**: Currently recording audio
- **⚡ Processing**: Transcribing audio via Mistral API

### Tips for Best Results

- **Speak clearly** and at a normal pace
- **Minimize background noise** when possible
- **Keep recordings under 30 seconds** (automatic timeout)
- **Wait for the processing indicator** before speaking again

## Configuration

### Customizing the Hotkey

Edit `~/.hammerspoon/vtt/vtt.lua` and modify the `config` section:

```lua
local config = {
    hotkey = {"cmd", "shift"}, -- Modifier keys
    key = "v",                 -- Main key
    -- ... other settings
}
```

### Audio Settings

You can adjust audio quality in the config:

```lua
local config = {
    sampleRate = 16000,  -- 16kHz recommended for speech
    channels = 1,        -- Mono audio
    maxDuration = 30,    -- Maximum recording length
    -- ...
}
```

## Troubleshooting

### Common Issues

**"No audio recorded"**

- Check microphone permissions for Hammerspoon
- Ensure your microphone is working in other apps
- Try speaking louder or closer to the microphone

**"Transcription failed"**

- Verify your `MISTRAL_API_KEY` is set correctly
- Check your internet connection
- Look at the Hammerspoon console for detailed error messages

**"Text not pasting"**

- Grant Accessibility permissions to Hammerspoon
- Ensure the target app can receive text input
- Try clicking in a text field before using the hotkey

### Debug Information

1. **Open Hammerspoon Console**: Click the Hammerspoon menubar icon → Console
2. **Check logs**: Look for error messages when using the voice-to-text feature
3. **Test components**:

   ```bash
   # Test audio recording
   ffmpeg -f avfoundation -i ":0" -t 3 -ar 16000 -ac 1 test.wav

   # Test transcription (with MISTRAL_API_KEY set)
   node transcribe.js test.wav
   ```

### Resetting the System

If you encounter persistent issues:

```bash
# Remove Hammerspoon configuration
rm -rf ~/.hammerspoon/vtt

# Re-run setup
./setup.sh
```

## File Structure

```
vtt/
├── transcribe.js      # Node.js script for Mistral API calls
├── vtt.lua           # Hammerspoon configuration
├── setup.sh          # Installation script
├── package.json      # Node.js dependencies
└── README.md         # This file
```

## Privacy & Security

- **Audio files** are temporarily stored in `/tmp/` and automatically deleted
- **API calls** are made directly to Mistral's servers (your audio is processed by Mistral)
- **No persistent storage** of audio or transcriptions
- **Local processing** for all other operations

## API Costs

Mistral charges for audio transcription API usage. Check their [pricing page](https://mistral.ai/pricing/) for current rates. Typical costs are very low for personal use.

## License

MIT License - feel free to modify and distribute as needed.

## Contributing

Issues and pull requests welcome! This project aims to be simple, reliable, and privacy-focused.
