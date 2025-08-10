#!/usr/bin/env node

// Simple test script to verify Mistral API connectivity
const { Mistral } = require("@mistralai/mistralai");

async function testAPI() {
  // Check for API key
  if (!process.env.MISTRAL_API_KEY) {
    console.error("❌ MISTRAL_API_KEY environment variable is required");
    console.log('Set it with: export MISTRAL_API_KEY="your-key-here"');
    process.exit(1);
  }

  console.log("🔑 API key found");

  // Initialize client
  const client = new Mistral({
    apiKey: process.env.MISTRAL_API_KEY,
  });

  try {
    console.log("🧪 Testing Mistral API connection...");

    // Try to list available models to test connectivity
    const models = await client.models.list();
    console.log("✅ API connection successful");
    console.log(`📋 Found ${models.data.length} available models`);

    // Check if Whisper model is available
    const whisperModels = models.data.filter(
      (model) => model.id.includes("whisper") || model.id.includes("voxtral")
    );

    if (whisperModels.length > 0) {
      console.log("🎤 Available speech models:");
      whisperModels.forEach((model) => {
        console.log(`   - ${model.id}`);
      });
    } else {
      console.log("⚠️  No Whisper/speech models found");
    }

    console.log("");
    console.log("🎉 API test completed successfully!");
    console.log("You can now run ./setup.sh to complete the installation.");
  } catch (error) {
    console.error("❌ API test failed:", error.message);

    if (error.message.includes("401")) {
      console.log("💡 This usually means your API key is invalid");
    } else if (
      error.message.includes("network") ||
      error.message.includes("ENOTFOUND")
    ) {
      console.log("💡 This usually means a network connectivity issue");
    }

    process.exit(1);
  }
}

testAPI();
