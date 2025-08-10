#!/usr/bin/env node

const { Mistral } = require("@mistralai/mistralai");
const OpenAI = require("openai");
const fs = require("fs");
const path = require("path");

// Check for required environment variables
if (!process.env.MISTRAL_API_KEY) {
  console.error("Error: MISTRAL_API_KEY environment variable is required");
  process.exit(1);
}

if (!process.env.OPENAI_API_KEY) {
  console.error("Error: OPENAI_API_KEY environment variable is required");
  process.exit(1);
}

// Initialize clients
const mistralClient = new Mistral({
  apiKey: process.env.MISTRAL_API_KEY,
});

const openaiClient = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY,
});

async function transcribeAudio(audioFilePath) {
  try {
    // Validate audio file exists
    if (!fs.existsSync(audioFilePath)) {
      throw new Error(`Audio file not found: ${audioFilePath}`);
    }

    // Get file stats for validation
    const stats = fs.statSync(audioFilePath);
    console.error(
      `Processing audio file: ${audioFilePath} (${(
        stats.size /
        1024 /
        1024
      ).toFixed(2)} MB)`
    );

    // Check if file is too small (likely silent or very short)
    if (stats.size < 1000) {
      throw new Error(
        "Audio file is too small - likely silent or no audio recorded"
      );
    }

    // Read audio file
    const audioBuffer = fs.readFileSync(audioFilePath);

    // Create a File object from the buffer
    const audioFile = new File([audioBuffer], path.basename(audioFilePath), {
      type: getAudioMimeType(audioFilePath),
    });

    // Call Mistral transcription API
    console.error("Sending transcription request to Mistral...");
    const response = await mistralClient.audio.transcriptions.complete({
      file: audioFile,
      model: "voxtral-mini-latest",
      language: "en",
      response_format: "text",
    });

    // Return the transcribed text
    const transcription = response.text || "";
    console.error(
      `Transcription completed: ${transcription.length} characters`
    );
    return transcription;
  } catch (error) {
    console.error("Transcription error:", error.message);
    throw error;
  }
}

async function cleanupText(rawText, useGPT5 = false) {
  try {
    const model = useGPT5 ? "gpt-5-mini" : "gpt-5-nano";
    const systemPrompt = useGPT5
      ? "You are a helpful assistant who gives brief, information dense answers."
      : "You are a text cleanup assistant. Remove filler words (um, uh, like, you know, etc.), fix grammar, improve readability, and format the text nicely while preserving the original meaning and tone. Keep the text concise but natural. Do not add content that wasn't in the original text. Respond with only the cleaned text.";

    console.error(`Cleaning up text with ${model}...`);

    const response = await openaiClient.chat.completions.create({
      model: model,
      messages: [
        {
          role: "system",
          content: systemPrompt,
        },
        {
          role: "user",
          content: useGPT5
            ? rawText
            : `Please clean up and format this transcribed text:\n\n${rawText}`,
        },
      ],
      temperature: useGPT5 ? 1 : 0.3,
    });

    const cleanedText = response.choices[0]?.message?.content || rawText;
    console.error(
      `Text cleanup completed: ${rawText.length} → ${cleanedText.length} characters`
    );
    return cleanedText;
  } catch (error) {
    console.error("Text cleanup error:", error.message);
    console.error("Falling back to original transcription");
    return rawText;
  }
}

function getAudioMimeType(filePath) {
  const ext = path.extname(filePath).toLowerCase();
  const mimeTypes = {
    ".wav": "audio/wav",
    ".mp3": "audio/mpeg",
    ".m4a": "audio/mp4",
    ".flac": "audio/flac",
    ".ogg": "audio/ogg",
    ".webm": "audio/webm",
  };
  return mimeTypes[ext] || "audio/wav";
}

// Main execution
async function main() {
  // Parse command line arguments
  const args = process.argv.slice(2);
  const useGPT5 = args.includes("--gpt5");
  const audioFilePath = args.find((arg) => !arg.startsWith("--"));

  if (!audioFilePath) {
    console.error("Usage: node transcribe.js [--gpt5] <audio-file-path>");
    process.exit(1);
  }

  try {
    const transcription = await transcribeAudio(audioFilePath);
    const cleanedText = await cleanupText(transcription, useGPT5);

    // Output only the cleaned text to stdout (for piping)
    console.log(cleanedText);
  } catch (error) {
    console.error("Failed to transcribe audio:", error.message);
    process.exit(1);
  }
}

// Run if called directly
if (require.main === module) {
  main();
}

module.exports = { transcribeAudio };
