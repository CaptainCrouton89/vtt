#!/bin/bash

# Verification script to check if everything is properly set up
set -e

echo "🔍 Verifying Voice-to-Text setup..."

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

ERRORS=0

check_requirement() {
    local name="$1"
    local command="$2"
    local install_hint="$3"
    
    if eval "$command" &> /dev/null; then
        echo -e "${GREEN}✅ $name${NC}"
        return 0
    else
        echo -e "${RED}❌ $name${NC}"
        if [ -n "$install_hint" ]; then
            echo -e "   ${YELLOW}$install_hint${NC}"
        fi
        ((ERRORS++))
        return 1
    fi
}

echo -e "${BLUE}📋 Checking system requirements...${NC}"

check_requirement "ffmpeg" "command -v ffmpeg" "Install: brew install ffmpeg"
check_requirement "Node.js" "command -v node" "Install: brew install node"
check_requirement "Hammerspoon" "[ -d '/Applications/Hammerspoon.app' ]" "Install: brew install --cask hammerspoon"
check_requirement "npm packages" "[ -f 'node_modules/@mistralai/mistralai/package.json' ]" "Run: npm install"

echo ""
echo -e "${BLUE}🔑 Checking environment...${NC}"

if [ -n "$MISTRAL_API_KEY" ]; then
    echo -e "${GREEN}✅ MISTRAL_API_KEY is set${NC}"
else
    echo -e "${RED}❌ MISTRAL_API_KEY is not set${NC}"
    echo -e "   ${YELLOW}Set with: export MISTRAL_API_KEY='your-key-here'${NC}"
    ((ERRORS++))
fi

echo ""
echo -e "${BLUE}📁 Checking file structure...${NC}"

FILES=(
    "transcribe.js:Transcription script"
    "vtt.lua:Hammerspoon configuration"
    "setup.sh:Setup script"
    "package.json:Node.js package file"
)

for file_info in "${FILES[@]}"; do
    file="${file_info%%:*}"
    desc="${file_info##*:}"
    
    if [ -f "$file" ]; then
        echo -e "${GREEN}✅ $desc ($file)${NC}"
    else
        echo -e "${RED}❌ $desc ($file)${NC}"
        ((ERRORS++))
    fi
done

echo ""
echo -e "${BLUE}🎤 Testing audio recording...${NC}"

if ffmpeg -f avfoundation -list_devices true -i "" 2>&1 | grep -q "AVFoundation audio devices:"; then
    echo -e "${GREEN}✅ Audio devices detected${NC}"
else
    echo -e "${YELLOW}⚠️  Could not detect audio devices${NC}"
    echo -e "   ${YELLOW}This might indicate microphone permission issues${NC}"
fi

# Test a quick recording
if ffmpeg -f avfoundation -i ":0" -t 1 -ar 16000 -ac 1 test_verify.wav -y &> /dev/null; then
    echo -e "${GREEN}✅ Audio recording test successful${NC}"
    rm -f test_verify.wav
else
    echo -e "${RED}❌ Audio recording test failed${NC}"
    echo -e "   ${YELLOW}Check microphone permissions for Terminal${NC}"
    ((ERRORS++))
fi

echo ""
echo -e "${BLUE}🤖 Testing Mistral API...${NC}"

if [ -n "$MISTRAL_API_KEY" ]; then
    if node test-api.js &> /dev/null; then
        echo -e "${GREEN}✅ Mistral API connection successful${NC}"
    else
        echo -e "${RED}❌ Mistral API connection failed${NC}"
        echo -e "   ${YELLOW}Run 'node test-api.js' for detailed error info${NC}"
        ((ERRORS++))
    fi
else
    echo -e "${YELLOW}⚠️  Skipping API test (no API key)${NC}"
fi

echo ""
echo -e "${BLUE}🔧 Checking Hammerspoon setup...${NC}"

HAMMERSPOON_DIR="$HOME/.hammerspoon"
VTT_HAMMERSPOON_DIR="$HAMMERSPOON_DIR/vtt"

if [ -d "$HAMMERSPOON_DIR" ]; then
    echo -e "${GREEN}✅ Hammerspoon config directory exists${NC}"
    
    if [ -f "$HAMMERSPOON_DIR/init.lua" ]; then
        if grep -q "require.*vtt" "$HAMMERSPOON_DIR/init.lua"; then
            echo -e "${GREEN}✅ VTT module loaded in init.lua${NC}"
        else
            echo -e "${YELLOW}⚠️  VTT module not found in init.lua${NC}"
            echo -e "   ${YELLOW}Run './setup.sh' to configure${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  No init.lua found${NC}"
        echo -e "   ${YELLOW}Run './setup.sh' to create${NC}"
    fi
    
    if [ -d "$VTT_HAMMERSPOON_DIR" ]; then
        echo -e "${GREEN}✅ VTT Hammerspoon files installed${NC}"
    else
        echo -e "${YELLOW}⚠️  VTT Hammerspoon files not installed${NC}"
        echo -e "   ${YELLOW}Run './setup.sh' to install${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  Hammerspoon config directory not found${NC}"
    echo -e "   ${YELLOW}Start Hammerspoon app first${NC}"
fi

echo ""

if [ $ERRORS -eq 0 ]; then
    echo -e "${GREEN}🎉 All checks passed!${NC}"
    echo ""
    echo -e "${BLUE}Next steps:${NC}"
    echo "1. Make sure Hammerspoon is running"
    echo "2. Grant required permissions in System Settings:"
    echo "   • Microphone access for Hammerspoon"
    echo "   • Accessibility access for Hammerspoon"
    echo "3. Test the system with ⌥\`"
    echo ""
    echo -e "${GREEN}Ready to use! Press and hold ⌥\` to start recording.${NC}"
else
    echo -e "${RED}❌ Found $ERRORS issue(s) that need to be resolved.${NC}"
    echo ""
    echo -e "${BLUE}Recommended actions:${NC}"
    echo "1. Fix the issues listed above"
    echo "2. Run './setup.sh' to complete installation"
    echo "3. Run this verification script again"
    exit 1
fi
