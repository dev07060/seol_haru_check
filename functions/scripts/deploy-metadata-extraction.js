#!/usr/bin/env node

/**
 * Metadata Extraction Deployment Script
 * Deploys Cloud Functions with proper environment variables and permissions
 * for the AI metadata extraction feature
 */

const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

const ENVIRONMENTS = {
  staging: 'seol-haru-check-staging',
  production: 'seol-haru-check'
};

const REQUIRED_ENV_VARS = [
  'VERTEX_AI_PROJECT_ID',
  'VERTEX_AI_LOCATION',
  'VERTEX_AI_MODEL',
  'VERTEX_AI_REQUESTS_PER_MINUTE',
  'VERTEX_AI_MAX_CONCURRENT_REQUESTS',
  'NODE_ENV'
];

const METADATA_EXTRACTION_FUNCTIONS = [
  'processMetadataExtraction',
  'collectMetadataExtractionMetrics',
  'getMetadataExtractionAnalytics',
  'cleanupMetadataExtractionMetrics'
];

function validateEnvironment(environment) {
  const envFile = path.join(__dirname, `../.env.${environment}`);
  
  if (!fs.existsSync(envFile)) {
    throw new Error(`Environment file .env.${environment} not found`);
  }

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

  // Check required environment variables
  const missingVars = REQUIRED_ENV_VARS.filter(varName => !envVars[varName]);
  if (missingVars.length > 0) {
    throw new Error(`Missing required environment variables: ${missingVars.join(', ')}`);
  }

  return envVars;
}

function validateEnvironmentFile(environment) {
  console.log('🔧 Validating environment file configuration...');
  
  const envFile = path.join(__dirname, `../.env.${environment}`);
  
  if (!fs.existsSync(envFile)) {
    throw new Error(`Environment file .env.${environment} not found`);
  }
  
  console.log(`✅ Environment file .env.${environment} found and will be used by Firebase Functions`);
  console.log('📝 Note: Firebase Functions will automatically load environment variables from .env files');
}

function deployFunctions(environment) {
  console.log('🚀 Deploying metadata extraction functions...');
  
  try {
    // Deploy only metadata extraction related functions
    const functionsList = METADATA_EXTRACTION_FUNCTIONS.join(',');
    execSync(`firebase deploy --only functions:${functionsList}`, { stdio: 'inherit' });
    
    console.log('✅ Metadata extraction functions deployed successfully');
  } catch (error) {
    console.error('❌ Function deployment failed:', error.message);
    throw error;
  }
}

function verifyDeployment(environment) {
  console.log('🔍 Verifying deployment...');
  
  try {
    // List deployed functions
    const functions = execSync('firebase functions:list', { encoding: 'utf8' });
    
    let deployedCount = 0;
    METADATA_EXTRACTION_FUNCTIONS.forEach(funcName => {
      if (functions.includes(funcName)) {
        console.log(`✅ ${funcName} deployed`);
        deployedCount++;
      } else {
        console.log(`❌ ${funcName} not found`);
      }
    });
    
    if (deployedCount === METADATA_EXTRACTION_FUNCTIONS.length) {
      console.log('✅ All metadata extraction functions deployed successfully');
    } else {
      throw new Error(`Only ${deployedCount}/${METADATA_EXTRACTION_FUNCTIONS.length} functions deployed`);
    }
    
    // Check recent logs for errors
    console.log('📋 Checking recent function logs...');
    const logs = execSync('firebase functions:log --limit 5', { encoding: 'utf8' });
    
    if (logs.includes('ERROR') || logs.includes('FATAL')) {
      console.warn('⚠️  Found errors in recent logs - please review manually');
    } else {
      console.log('✅ No critical errors in recent logs');
    }
    
  } catch (error) {
    console.error('❌ Deployment verification failed:', error.message);
    throw error;
  }
}

function setIAMPermissions(environment) {
  console.log('🔐 Setting IAM permissions for metadata extraction...');
  
  const projectId = ENVIRONMENTS[environment];
  
  try {
    // Grant necessary permissions for metadata extraction functions
    const permissions = [
      // Storage permissions for image access
      `gcloud projects add-iam-policy-binding ${projectId} --member="serviceAccount:${projectId}@appspot.gserviceaccount.com" --role="roles/storage.objectViewer"`,
      
      // Vertex AI permissions
      `gcloud projects add-iam-policy-binding ${projectId} --member="serviceAccount:${projectId}@appspot.gserviceaccount.com" --role="roles/aiplatform.user"`,
      
      // Firestore permissions (should already exist)
      `gcloud projects add-iam-policy-binding ${projectId} --member="serviceAccount:${projectId}@appspot.gserviceaccount.com" --role="roles/datastore.user"`,
      
      // Cloud Functions permissions
      `gcloud projects add-iam-policy-binding ${projectId} --member="serviceAccount:${projectId}@appspot.gserviceaccount.com" --role="roles/cloudfunctions.invoker"`,
    ];
    
    permissions.forEach(command => {
      try {
        execSync(command, { stdio: 'pipe' });
        const role = command.split('--role="')[1].split('"')[0];
        console.log(`✅ Granted: ${role}`);
      } catch (error) {
        console.warn(`⚠️  Failed to grant permission: ${command}`);
      }
    });
    
  } catch (error) {
    console.error('❌ IAM permission setup failed:', error.message);
    throw error;
  }
}

async function main() {
  const environment = process.argv[2];
  
  if (!environment || !ENVIRONMENTS[environment]) {
    console.error('Usage: node deploy-metadata-extraction.js <staging|production>');
    console.error('Available environments:', Object.keys(ENVIRONMENTS).join(', '));
    process.exit(1);
  }

  const projectId = ENVIRONMENTS[environment];
  
  console.log('🚀 Starting metadata extraction deployment...');
  console.log(`Environment: ${environment}`);
  console.log(`Project ID: ${projectId}`);
  console.log(`Timestamp: ${new Date().toISOString()}\n`);
  
  try {
    // Step 1: Validate environment configuration
    console.log('1️⃣ Validating environment configuration...');
    const envVars = validateEnvironment(environment);
    console.log('✅ Environment configuration validated\n');
    
    // Step 2: Set Firebase project
    console.log('2️⃣ Setting Firebase project...');
    execSync(`firebase use ${environment}`, { stdio: 'inherit' });
    console.log('✅ Firebase project set\n');
    
    // Step 3: Validate environment file
    console.log('3️⃣ Validating environment file...');
    validateEnvironmentFile(environment);
    console.log('✅ Environment file validated\n');
    
    // Step 4: Run pre-deployment checks
    console.log('4️⃣ Running pre-deployment checks...');
    execSync('npm run lint', { stdio: 'inherit' });
    execSync('npm run test', { stdio: 'inherit' });
    execSync('npm run build', { stdio: 'inherit' });
    console.log('✅ Pre-deployment checks passed\n');
    
    // Step 5: Set IAM permissions
    console.log('5️⃣ Setting IAM permissions...');
    setIAMPermissions(environment);
    console.log('✅ IAM permissions configured\n');
    
    // Step 6: Deploy functions
    console.log('6️⃣ Deploying Cloud Functions...');
    deployFunctions(environment);
    console.log('✅ Cloud Functions deployed\n');
    
    // Step 7: Verify deployment
    console.log('7️⃣ Verifying deployment...');
    verifyDeployment(environment);
    console.log('✅ Deployment verified\n');
    
    // Success summary
    console.log('🎉 Metadata extraction deployment completed successfully!');
    console.log('\n📊 Deployment Summary:');
    console.log(`Environment: ${environment}`);
    console.log(`Project ID: ${projectId}`);
    console.log(`Functions deployed: ${METADATA_EXTRACTION_FUNCTIONS.length}`);
    console.log(`Timestamp: ${new Date().toISOString()}`);
    
    console.log('\n📚 Next steps:');
    console.log('- Test metadata extraction with real certification uploads');
    console.log('- Monitor function logs and metrics');
    console.log('- Set up alerting for extraction failures');
    console.log('- Review Firebase Storage security rules');
    
  } catch (error) {
    console.error(`❌ Deployment failed: ${error.message}`);
    console.error('\n🔧 Troubleshooting:');
    console.error('- Check Firebase project permissions');
    console.error('- Verify environment variables are correct');
    console.error('- Review function logs for specific errors');
    console.error('- Ensure all required APIs are enabled');
    process.exit(1);
  }
}

if (require.main === module) {
  main();
}

module.exports = { main, ENVIRONMENTS, METADATA_EXTRACTION_FUNCTIONS };