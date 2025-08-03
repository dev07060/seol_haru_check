#!/usr/bin/env node

/**
 * Deployment script for Cloud Functions
 * Handles environment-specific deployments with proper configuration
 */

const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

const ENVIRONMENTS = {
  staging: 'seol-haru-check-staging',
  production: 'seol-haru-check'
};

function main() {
  const environment = process.argv[2];
  
  if (!environment || !ENVIRONMENTS[environment]) {
    console.error('Usage: node deploy.js <staging|production>');
    console.error('Available environments:', Object.keys(ENVIRONMENTS).join(', '));
    process.exit(1);
  }

  const projectId = ENVIRONMENTS[environment];
  
  console.log(`🚀 Starting deployment to ${environment} (${projectId})`);
  
  try {
    // Set Firebase project
    console.log('📋 Setting Firebase project...');
    execSync(`firebase use ${environment}`, { stdio: 'inherit' });
    
    // Load environment variables
    const envFile = path.join(__dirname, `../.env.${environment}`);
    if (fs.existsSync(envFile)) {
      console.log(`🔧 Loading environment variables from .env.${environment}`);
      const envContent = fs.readFileSync(envFile, 'utf8');
      const envVars = envContent
        .split('\n')
        .filter(line => line.trim() && !line.startsWith('#'))
        .map(line => {
          const [key, ...valueParts] = line.split('=');
          return `${key}=${valueParts.join('=')}`;
        });
      
      // Set environment variables for Firebase Functions
      for (const envVar of envVars) {
        const [key, value] = envVar.split('=');
        if (key && value) {
          console.log(`Setting ${key}...`);
          execSync(`firebase functions:config:set ${key.toLowerCase()}="${value}"`, { stdio: 'inherit' });
        }
      }
    }
    
    // Run pre-deployment checks
    console.log('🔍 Running pre-deployment checks...');
    execSync('npm run lint', { stdio: 'inherit' });
    execSync('npm run test', { stdio: 'inherit' });
    execSync('npm run build', { stdio: 'inherit' });
    
    // Deploy functions
    console.log('🚀 Deploying Cloud Functions...');
    execSync('firebase deploy --only functions', { stdio: 'inherit' });
    
    console.log(`✅ Deployment to ${environment} completed successfully!`);
    
    // Show deployment info
    console.log('\n📊 Deployment Summary:');
    console.log(`Environment: ${environment}`);
    console.log(`Project ID: ${projectId}`);
    console.log(`Timestamp: ${new Date().toISOString()}`);
    
  } catch (error) {
    console.error(`❌ Deployment failed: ${error.message}`);
    process.exit(1);
  }
}

if (require.main === module) {
  main();
}

module.exports = { main, ENVIRONMENTS };