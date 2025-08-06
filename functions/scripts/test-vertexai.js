#!/usr/bin/env node

/**
 * VertexAI Connection Test Script
 * 
 * This script tests the VertexAI service connection and configuration
 */

const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '../.env.local') });

// Import after dotenv config
const { vertexAIService } = require('../lib/services/vertexAIService');

async function testVertexAI() {
  console.log('🧪 Testing VertexAI Service Connection...');
  console.log(`Timestamp: ${new Date().toISOString()}\n`);
  
  // Display configuration
  console.log('📋 Configuration:');
  console.log(`Project ID: ${process.env.VERTEX_AI_PROJECT_ID || process.env.GOOGLE_CLOUD_PROJECT || 'seol-haru-check'}`);
  console.log(`Location: ${process.env.VERTEX_AI_LOCATION || 'asia-northeast3'}`);
  console.log(`Model: ${process.env.VERTEX_AI_MODEL || 'gemini-1.5-flash-001'}`);
  console.log('');
  
  try {
    // Test basic connection
    console.log('1️⃣ Testing basic connection...');
    const isConnected = await vertexAIService.testConnection();
    
    if (isConnected) {
      console.log('✅ VertexAI connection successful!');
    } else {
      console.log('❌ VertexAI connection failed');
      return;
    }
    
    // Test rate limiting status
    console.log('\n2️⃣ Checking rate limiting status...');
    const rateLimitStatus = vertexAIService.getRateLimitStatus();
    console.log('📊 Rate Limit Status:', JSON.stringify(rateLimitStatus, null, 2));
    
    // Test simple analysis
    console.log('\n3️⃣ Testing simple analysis...');
    const analysisResult = await vertexAIService.generateAnalysis({
      prompt: "간단한 테스트입니다. '테스트 완료'라고 답해주세요.",
      temperature: 0.1,
      maxOutputTokens: 100,
    });
    
    console.log('✅ Analysis test successful!');
    console.log('📝 Response:', analysisResult.text.substring(0, 100) + '...');
    console.log('🏁 Finish Reason:', analysisResult.finishReason);
    
    console.log('\n🎉 All tests passed! VertexAI service is working correctly.');
    
  } catch (error) {
    console.error('❌ VertexAI test failed:', error.message);
    console.error('\n🔧 Troubleshooting:');
    console.error('- Check your .env.local file has correct values');
    console.error('- Verify Google Cloud project permissions');
    console.error('- Ensure Vertex AI API is enabled');
    console.error('- Try changing VERTEX_AI_LOCATION to us-central1');
    
    if (error.stack) {
      console.error('\n📋 Full error stack:');
      console.error(error.stack);
    }
    
    process.exit(1);
  }
}

if (require.main === module) {
  testVertexAI();
}

module.exports = { testVertexAI };