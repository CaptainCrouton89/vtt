#!/bin/bash

# Voice-to-Text Setup Script for macOS
set -e

echo "🎤 Setting up Voice-to-Text system..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VTT_DIR="$SCRIPT_DIR"

echo -e "${BLUE}📁 Project directory: $VTT_DIR${NC}"

# Check if required API keys are set
if [ -z "$MISTRAL_API_KEY" ]; then
    echo -e "${RED}❌ MISTRAL_API_KEY environment variable is not set${NC}"
    echo -e "${YELLOW}Please set your Mistral API key:${NC}"
    echo "export MISTRAL_API_KEY='your-api-key-here'"
    echo "Add this to your ~/.zshrc or ~/.bash_profile"
    echo ""
    echo "Get your API key from: https://console.mistral.ai/"
    exit 1
else
    echo -e "${GREEN}✅ MISTRAL_API_KEY is set${NC}"
fi

if [ -z "$OPENAI_API_KEY" ]; then
    echo -e "${RED}❌ OPENAI_API_KEY environment variable is not set${NC}"
    echo -e "${YELLOW}Please set your OpenAI API key:${NC}"
    echo "export OPENAI_API_KEY='your-api-key-here'"
    echo "Add this to your ~/.zshrc or ~/.bash_profile"
    echo ""
    echo "Get your API key from: https://platform.openai.com/api-keys"
    exit 1
else
    echo -e "${GREEN}✅ OPENAI_API_KEY is set${NC}"
fi

# Check required tools
echo -e "${BLUE}🔍 Checking required tools...${NC}"

check_tool() {
    if command -v "$1" &> /dev/null; then
        echo -e "${GREEN}✅ $1 found${NC}"
        return 0
    else
        echo -e "${RED}❌ $1 not found${NC}"
        return 1
    fi
}

MISSING_TOOLS=()

if ! check_tool "ffmpeg"; then
    MISSING_TOOLS+=("ffmpeg")
    echo "   Install with: brew install ffmpeg"
fi

if ! check_tool "node"; then
    MISSING_TOOLS+=("node")
    echo "   Install with: brew install node"
fi

if [ ! -d "/Applications/Hammerspoon.app" ]; then
    echo -e "${RED}❌ Hammerspoon not found${NC}"
    MISSING_TOOLS+=("hammerspoon")
    echo "   Install with: brew install --cask hammerspoon"
    echo "   Or download from: https://www.hammerspoon.org/"
fi

if [ ${#MISSING_TOOLS[@]} -ne 0 ]; then
    echo -e "${RED}Please install missing tools and run this script again.${NC}"
    exit 1
fi

# Install Node.js dependencies
echo -e "${BLUE}📦 Installing Node.js dependencies...${NC}"
cd "$VTT_DIR"
npm install

# Test the transcription script
echo -e "${BLUE}🧪 Testing transcription script...${NC}"
if [ -f "test_audio.wav" ]; then
    echo "Testing with existing test_audio.wav..."
    if node transcribe.js test_audio.wav > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Transcription script test passed${NC}"
    else
        echo -e "${YELLOW}⚠️  Transcription script test failed (this might be normal if API key is not configured)${NC}"
    fi
else
    echo "No test audio file found, skipping transcription test"
fi

# Set up Hammerspoon configuration
HAMMERSPOON_CONFIG_DIR="$HOME/.hammerspoon"
VTT_HAMMERSPOON_DIR="$HAMMERSPOON_CONFIG_DIR/vtt"

echo -e "${BLUE}⚙️  Setting up Hammerspoon configuration...${NC}"

# Create Hammerspoon config directory if it doesn't exist
mkdir -p "$HAMMERSPOON_CONFIG_DIR"
mkdir -p "$VTT_HAMMERSPOON_DIR"

# Copy files to Hammerspoon directory
cp "$VTT_DIR/transcribe.js" "$VTT_HAMMERSPOON_DIR/"
cp "$VTT_DIR/package.json" "$VTT_HAMMERSPOON_DIR/"
cp -r "$VTT_DIR/node_modules" "$VTT_HAMMERSPOON_DIR/"

# Update the Lua script paths
sed -e "s|hs.configdir .. \"/vtt/transcribe.js\"|\"$VTT_HAMMERSPOON_DIR/transcribe.js\"|g" \
    -e "s|hs.configdir .. \"/vtt\"|\"$VTT_HAMMERSPOON_DIR\"|g" \
    "$VTT_DIR/vtt.lua" > "$VTT_HAMMERSPOON_DIR/vtt.lua"

# Create or update init.lua
INIT_LUA="$HAMMERSPOON_CONFIG_DIR/init.lua"
VTT_REQUIRE_LINE="require('vtt.vtt')"

if [ -f "$INIT_LUA" ]; then
    if ! grep -q "$VTT_REQUIRE_LINE" "$INIT_LUA"; then
        echo "" >> "$INIT_LUA"
        echo "-- Voice-to-Text module" >> "$INIT_LUA"
        echo "$VTT_REQUIRE_LINE" >> "$INIT_LUA"
        echo -e "${GREEN}✅ Added VTT module to existing init.lua${NC}"
    else
        echo -e "${GREEN}✅ VTT module already in init.lua${NC}"
    fi
else
    echo "-- Hammerspoon Configuration" > "$INIT_LUA"
    echo "" >> "$INIT_LUA"
    echo "-- Voice-to-Text module" >> "$INIT_LUA"
    echo "$VTT_REQUIRE_LINE" >> "$INIT_LUA"
    echo -e "${GREEN}✅ Created new init.lua with VTT module${NC}"
fi

# Check permissions
echo -e "${BLUE}🔒 Checking macOS permissions...${NC}"

echo -e "${YELLOW}Please ensure the following permissions are granted:${NC}"
echo "1. 🎤 Microphone access for Hammerspoon"
echo "   System Settings → Privacy & Security → Microphone"
echo ""
echo "2. ♿ Accessibility access for Hammerspoon" 
echo "   System Settings → Privacy & Security → Accessibility"
echo ""
echo "3. 🤖 Automation permissions (if prompted)"
echo "   System Settings → Privacy & Security → Automation"

# Reload Hammerspoon if it's running
if pgrep -x "Hammerspoon" > /dev/null; then
    echo -e "${BLUE}🔄 Reloading Hammerspoon configuration...${NC}"
    # Try Hammerspoon CLI first, fall back to killing/restarting
    if command -v hs > /dev/null; then
        hs -c "hs.reload()" 2>/dev/null && echo -e "${GREEN}✅ Hammerspoon configuration reloaded${NC}" || {
            echo -e "${YELLOW}⚠️  CLI reload failed. Please manually reload Hammerspoon (Cmd+R)${NC}"
        }
    else
        echo -e "${YELLOW}⚠️  Please manually reload Hammerspoon configuration (Cmd+R)${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  Hammerspoon is not running. Please start it manually.${NC}"
fi

echo ""
echo -e "${GREEN}🎉 Setup complete!${NC}"
echo ""
echo -e "${BLUE}Usage:${NC}"
echo "• Press and hold ⌥\` to start recording"
echo "• Release the keys to stop recording and transcribe"
echo "• The transcribed text will be automatically pasted"
echo ""
echo -e "${BLUE}Troubleshooting:${NC}"
echo "• Check the Hammerspoon console for error messages"
echo "• Ensure all permissions are granted in System Settings"
echo "• Verify both MISTRAL_API_KEY and OPENAI_API_KEY are set in your shell environment"
echo ""
echo -e "${BLUE}Files installed:${NC}"
echo "• $VTT_HAMMERSPOON_DIR/vtt.lua"
echo "• $VTT_HAMMERSPOON_DIR/transcribe.js"
echo "• $HAMMERSPOON_CONFIG_DIR/init.lua (updated)"
