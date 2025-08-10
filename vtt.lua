-- Voice-to-Text Hammerspoon Script
-- Global hotkey: Option+` (press and hold)

local vtt = {}

-- Configuration
local config = {
    hotkey = {"alt"}, -- Modifier keys
    key = "`",        -- Main key
    audioFile = "/tmp/vtt_recording.wav",
    scriptPath = hs.configdir .. "/vtt/transcribe.js", -- Adjust this path as needed
    sampleRate = 16000,
    channels = 1,
    maxDuration = 30 -- Maximum recording duration in seconds
}

-- State variables
local isRecording = false
local recordingProcess = nil
local recordingTimer = nil
local statusMenubar = nil

-- Initialize menubar indicator
function vtt.initMenubar()
    statusMenubar = hs.menubar.new()
    if statusMenubar then
        statusMenubar:setTitle("🎤")
        statusMenubar:setTooltip("Voice-to-Text Ready")
        statusMenubar:setMenu({
            {title = "Voice-to-Text Status: Ready", disabled = true},
            {title = "-"},
            {title = "Hotkey: ⌥` (hold)", disabled = true},
            {title = "Reload Config", fn = function() hs.reload() end}
        })
    end
end

-- Update menubar status
function vtt.updateMenubar(status, color)
    if statusMenubar then
        local icon = status == "recording" and "🔴" or 
                    status == "processing" and "⚡" or "🎤"
        statusMenubar:setTitle(icon)
        
        local menu = {
            {title = "Voice-to-Text Status: " .. (status or "Ready"), disabled = true},
            {title = "-"},
            {title = "Hotkey: ⌥` (hold)", disabled = true},
            {title = "Reload Config", fn = function() hs.reload() end}
        }
        statusMenubar:setMenu(menu)
    end
end

-- Play system sound for feedback
function vtt.playSound(soundName)
    hs.sound.getByName(soundName):play()
end

-- Show notification
function vtt.showNotification(title, message, duration)
    hs.notify.new({
        title = title,
        informativeText = message,
        withdrawAfter = duration or 3
    }):send()
end

-- Start recording
function vtt.startRecording()
    if isRecording then return end
    
    print("Starting voice recording...")
    isRecording = true
    
    -- Update UI
    vtt.updateMenubar("recording")
    
    -- Remove any existing audio file
    os.execute("rm -f " .. config.audioFile)
    
    -- Build ffmpeg command for recording
    local ffmpegCmd = string.format(
        'ffmpeg -f avfoundation -i ":1" -ar %d -ac %d -t %d "%s" > /dev/null 2>&1 &',
        config.sampleRate,
        config.channels,
        config.maxDuration,
        config.audioFile
    )
    
    -- Start recording process
    recordingProcess = hs.task.new("/bin/sh", function(exitCode, stdOut, stdErr)
        print("Recording process finished with exit code:", exitCode)
    end, {"-c", ffmpegCmd})
    
    if recordingProcess then
        recordingProcess:start()
        
        -- Set maximum duration timer
        recordingTimer = hs.timer.doAfter(config.maxDuration, function()
            if isRecording then
                print("Maximum recording duration reached")
                vtt.stopRecording()
            end
        end)
    else
        print("Failed to start recording process")
        vtt.resetState()
    end
end

-- Stop recording and process
function vtt.stopRecording()
    if not isRecording then return end
    
    print("Stopping voice recording...")
    
    -- Update UI
    vtt.updateMenubar("processing")
    
    -- Stop the recording timer
    if recordingTimer then
        recordingTimer:stop()
        recordingTimer = nil
    end
    
    -- Kill ffmpeg process
    os.execute("pkill -f 'ffmpeg.*avfoundation.*" .. config.audioFile .. "'")
    
    -- Wait a moment for file to be written
    hs.timer.doAfter(0.5, function()
        vtt.processAudio()
    end)
end

-- Process the recorded audio
function vtt.processAudio()
    print("Processing recorded audio...")
    
    -- Check if audio file exists and has content
    local fileExists = hs.fs.attributes(config.audioFile)
    if not fileExists or fileExists.size == 0 then
        print("No audio file found or file is empty")
        vtt.resetState()
        return
    end
    
    print("Audio file size:", fileExists.size, "bytes")
    
    -- Call transcription script
    local transcribeCmd = string.format('cd "%s" && node transcribe.js "%s"', 
                                      hs.configdir .. "/vtt", config.audioFile)
    
    hs.task.new("/bin/sh", function(exitCode, stdOut, stdErr)
        print("Transcription finished with exit code:", exitCode)
        print("StdOut:", stdOut)
        print("StdErr:", stdErr)
        
        if exitCode == 0 and stdOut and stdOut:len() > 0 then
            -- Clean up the transcription text
            local transcription = stdOut:gsub("^%s*(.-)%s*$", "%1") -- trim whitespace
            
            if transcription:len() > 0 then
                print("Transcription result:", transcription)
                vtt.pasteText(transcription)
            else
                print("Empty transcription result")
            end
        else
            local errorMsg = "Transcription failed"
            if stdErr and stdErr:len() > 0 then
                errorMsg = errorMsg .. ": " .. stdErr:match("[^\n]*") -- First line of error
            end
            print("Transcription error:", errorMsg)
        end
        
        vtt.resetState()
        
    end, {"-c", transcribeCmd}):start()
end

-- Paste transcribed text
function vtt.pasteText(text)
    print("Pasting text:", text)
    
    -- Copy to clipboard
    hs.pasteboard.setContents(text)
    
    -- Simulate Cmd+V to paste
    hs.timer.doAfter(0.1, function()
        hs.eventtap.keyStroke({"cmd"}, "v")
    end)
end

-- Reset state
function vtt.resetState()
    isRecording = false
    recordingProcess = nil
    
    if recordingTimer then
        recordingTimer:stop()
        recordingTimer = nil
    end
    
    -- Clean up audio file (disabled for debugging)
    -- os.execute("rm -f " .. config.audioFile)
    
    -- Update UI
    vtt.updateMenubar("ready")
end

-- Initialize the module
function vtt.init()
    print("Initializing Voice-to-Text...")
    
    -- Initialize menubar
    vtt.initMenubar()
    
    -- Set up global hotkey (press and hold)
    hs.hotkey.bind(config.hotkey, config.key, 
        function() vtt.startRecording() end,  -- Key down
        function() vtt.stopRecording() end,   -- Key up
        function() vtt.startRecording() end   -- Key repeat (optional)
    )
    
    print("Voice-to-Text initialized. Hotkey: Option+` (hold)")
end

-- Start the module
vtt.init()

return vtt
