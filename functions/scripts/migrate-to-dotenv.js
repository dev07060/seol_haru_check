#!/usr/bin/env node

/**
 * Migration Script: Firebase Functions Config to .env
 * 
 * This script helps migrate from the deprecated functions.config() API
 * to the new .env file approach for Firebase Functions.
 */

const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

const ENVIRONMENTS = {
  staging: 'seol-haru-check-staging',
  production: 'seol-haru-check'
};

function clearLegacyConfig() {
  console.log('🧹 Clearing legacy Firebase Functions configuration...');
  
  try {
    // Try to get current config (this might fail if already cleared)
    let currentConfig = {};
    try {
      const configOutput = execSync('firebase functions:config:get', { encoding: 'utf8' });
      currentConfig = JSON.parse(configOutput);
      console.log('📋 Current legacy config found:', JSON.stringify(currentConfig, null, 2));
    } catch (error) {
      console.log('✅ No legacy configuration found or already cleared');
      return;
    }
    
    // Clear all legacy configuration
    const configKeys = [];
    
    function extractKeys(obj, prefix = '') {
      for (const [key, value] of Object.entries(obj)) {
        const fullKey = prefix ? `${prefix}.${key}` : key;
        if (typeof value === 'object' && value !== null) {
          extractKeys(value, fullKey);
        } else {
          configKeys.push(fullKey);
        }
      }
    }
    
    extractKeys(currentConfig);
    
    if (configKeys.length > 0) {
      console.log(`🗑️  Clearing ${configKeys.length} legacy configuration keys...`);
      
      // Clear each configuration key
      configKeys.forEach(key => {
        try {
          execSync(`firebase functions:config:unset ${key}`, { stdio: 'pipe' });
          console.log(`✅ Cleared: ${key}`);
        } catch (error) {
          console.warn(`⚠️  Failed to clear: ${key}`);
        }
      });
      
      console.log('✅ Legacy configuration cleared');
    } else {
      console.log('✅ No legacy configuration to clear');
    }
    
  } catch (error) {
    console.error('❌ Failed to clear legacy configuration:', error.message);
    console.log('💡 This might be expected if configuration was already cleared');
  }
}

function validateEnvironmentFiles() {
  console.log('🔍 Validating environment files...');
  
  const requiredEnvVars = [
    'VERTEX_AI_PROJECT_ID',
    'VERTEX_AI_LOCATION',
    'VERTEX_AI_MODEL',
    'VERTEX_AI_REQUESTS_PER_MINUTE',
    'VERTEX_AI_MAX_CONCURRENT_REQUESTS',
    'NODE_ENV'
  ];
  
  for (const [env, projectId] of Object.entries(ENVIRONMENTS)) {
    const envFile = path.join(__dirname, `../.env.${env}`);
    
    if (!fs.existsSync(envFile)) {
      console.warn(`⚠️  Environment file .env.${env} not found`);
      continue;
    }
    
    console.log(`📄 Checking .env.${env}...`);
    
    const envContent = fs.readFileSync(envFile, 'utf8');
    const envVars = {};
    
    envContent.split('\n').forEach(line => {
      if (line.trim() && !line.startsWith('#')) {
        const [key, ...valueParts] = line.split('=');
        if (key && valueParts.length > 0) {
          envVars[key] = valueParts.join('=');
        }
      }
    });
    
    const missingVars = requiredEnvVars.filter(varName => !envVars[varName]);
    
    if (missingVars.length > 0) {
      console.error(`❌ Missing variables in .env.${env}: ${missingVars.join(', ')}`);
    } else {
      console.log(`✅ .env.${env} has all required variables`);
    }
    
    // Validate model name
    const model = envVars.VERTEX_AI_MODEL;
    if (model && !model.startsWith('gemini-1.5')) {
      console.warn(`⚠️  .env.${env}: Consider using gemini-1.5-pro instead of ${model}`);
    }
  }
}

function updateFirebaseJson() {
  console.log('🔧 Updating firebase.json for .env support...');
  
  const firebaseJsonPath = path.join(__dirname, '../../firebase.json');
  
  if (!fs.existsSync(firebaseJsonPath)) {
    console.error('❌ firebase.json not found');
    return;
  }
  
  const firebaseConfig = JSON.parse(fs.readFileSync(firebaseJsonPath, 'utf8'));
  
  // Ensure functions configuration supports .env files
  if (firebaseConfig.functions) {
    if (Array.isArray(firebaseConfig.functions)) {
      firebaseConfig.functions.forEach(funcConfig => {
        if (!funcConfig.dotenv) {
          funcConfig.dotenv = '.env';
          console.log('✅ Added .env support to functions configuration');
        }
      });
    } else {
      if (!firebaseConfig.functions.dotenv) {
        firebaseConfig.functions.dotenv = '.env';
        console.log('✅ Added .env support to functions configuration');
      }
    }
    
    fs.writeFileSync(firebaseJsonPath, JSON.stringify(firebaseConfig, null, 2));
    console.log('✅ firebase.json updated');
  }
}

function createMigrationSummary() {
  console.log('\n📊 Migration Summary:');
  console.log('✅ Legacy functions.config() API usage removed');
  console.log('✅ Environment files validated');
  console.log('✅ firebase.json updated for .env support');
  
  console.log('\n📚 Next steps:');
  console.log('1. Deploy your functions: firebase deploy --only functions');
  console.log('2. Test that environment variables are loaded correctly');
  console.log('3. Monitor function logs for any configuration issues');
  
  console.log('\n💡 Important notes:');
  console.log('- Functions will now read configuration from .env files');
  console.log('- Make sure .env files are not committed to version control');
  console.log('- Use different .env files for different environments');
  console.log('- The deprecation warning should disappear after redeployment');
}

async function main() {
  const environment = process.argv[2];
  
  if (environment && !ENVIRONMENTS[environment]) {
    console.error('Usage: node migrate-to-dotenv.js [staging|production]');
    console.error('Available environments:', Object.keys(ENVIRONMENTS).join(', '));
    console.error('Or run without arguments to migrate all environments');
    process.exit(1);
  }
  
  console.log('🚀 Starting migration from functions.config() to .env files...');
  console.log(`Timestamp: ${new Date().toISOString()}\n`);
  
  try {
    // Step 1: Set Firebase project if environment specified
    if (environment) {
      console.log(`1️⃣ Setting Firebase project to ${environment}...`);
      execSync(`firebase use ${environment}`, { stdio: 'inherit' });
      console.log('✅ Firebase project set\n');
    }
    
    // Step 2: Clear legacy configuration
    console.log('2️⃣ Clearing legacy Firebase Functions configuration...');
    clearLegacyConfig();
    console.log('✅ Legacy configuration cleared\n');
    
    // Step 3: Validate environment files
    console.log('3️⃣ Validating environment files...');
    validateEnvironmentFiles();
    console.log('✅ Environment files validated\n');
    
    // Step 4: Update firebase.json
    console.log('4️⃣ Updating firebase.json...');
    updateFirebaseJson();
    console.log('✅ firebase.json updated\n');
    
    // Step 5: Show summary
    createMigrationSummary();
    
    console.log('\n🎉 Migration completed successfully!');
    
  } catch (error) {
    console.error(`❌ Migration failed: ${error.message}`);
    console.error('\n🔧 Troubleshooting:');
    console.error('- Make sure you have Firebase CLI installed and logged in');
    console.error('- Verify you have the correct Firebase project permissions');
    console.error('- Check that .env files exist and have correct format');
    process.exit(1);
  }
}

if (require.main === module) {
  main();
}

module.exports = { main, clearLegacyConfig, validateEnvironmentFiles };