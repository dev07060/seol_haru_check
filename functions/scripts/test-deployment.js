#!/usr/bin/env node

/**
 * Deployment Testing Script
 * Tests Cloud Functions deployment in staging environment
 */

const { execSync } = require('child_process');
const https = require('https');
const { URL } = require('url');

const STAGING_PROJECT = 'seol-haru-check-staging';
const STAGING_REGION = 'asia-northeast3';

async function testHttpFunction(functionName, path = '', method = 'GET', body = null) {
  return new Promise((resolve, reject) => {
    const url = `https://${STAGING_REGION}-${STAGING_PROJECT}.cloudfunctions.net/${functionName}${path}`;
    const urlObj = new URL(url);
    
    const options = {
      hostname: urlObj.hostname,
      port: urlObj.port || 443,
      path: urlObj.pathname + urlObj.search,
      method,
      headers: {
        'Content-Type': 'application/json',
      },
      timeout: 30000,
    };
    
    if (body && method !== 'GET') {
      const bodyStr = JSON.stringify(body);
      options.headers['Content-Length'] = Buffer.byteLength(bodyStr);
    }
    
    const req = https.request(options, (res) => {
      let data = '';
      res.on('data', (chunk) => data += chunk);
      res.on('end', () => {
        try {
          const response = {
            statusCode: res.statusCode,
            headers: res.headers,
            body: data,
            json: null,
          };
          
          try {
            response.json = JSON.parse(data);
          } catch (e) {
            // Not JSON, keep as string
          }
          
          resolve(response);
        } catch (error) {
          reject(error);
        }
      });
    });
    
    req.on('error', reject);
    req.on('timeout', () => {
      req.destroy();
      reject(new Error('Request timeout'));
    });
    
    if (body && method !== 'GET') {
      req.write(JSON.stringify(body));
    }
    
    req.end();
  });
}

async function runTests() {
  console.log('🧪 Starting deployment tests for staging environment...\n');
  
  let passedTests = 0;
  let totalTests = 0;
  
  // Test 1: Health Check
  totalTests++;
  console.log('1. Testing health check endpoint...');
  try {
    const response = await testHttpFunction('healthCheck');
    if (response.statusCode === 200 && response.json?.status) {
      console.log('   ✅ Health check passed');
      console.log(`   📊 Status: ${response.json.status}`);
      console.log(`   🔧 Services: ${JSON.stringify(response.json.services)}`);
      passedTests++;
    } else {
      console.log('   ❌ Health check failed');
      console.log(`   📊 Status Code: ${response.statusCode}`);
      console.log(`   📄 Response: ${response.body}`);
    }
  } catch (error) {
    console.log('   ❌ Health check error:', error.message);
  }
  
  // Test 2: Generate AI Report (with test data)
  totalTests++;
  console.log('\n2. Testing AI report generation...');
  try {
    const testData = {
      userUuid: 'test-user-' + Date.now(),
      weekStartDate: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString(),
      weekEndDate: new Date().toISOString(),
      forceRegenerate: true,
    };
    
    const response = await testHttpFunction('generateAIReport', '', 'POST', testData);
    
    // We expect this to fail with insufficient data, which is correct behavior
    if (response.statusCode === 400 && response.json?.error?.includes('Insufficient data')) {
      console.log('   ✅ AI report generation correctly handles insufficient data');
      passedTests++;
    } else if (response.statusCode === 200) {
      console.log('   ✅ AI report generation successful');
      console.log(`   📊 Report ID: ${response.json?.reportId}`);
      passedTests++;
    } else {
      console.log('   ❌ AI report generation failed unexpectedly');
      console.log(`   📊 Status Code: ${response.statusCode}`);
      console.log(`   📄 Response: ${response.body}`);
    }
  } catch (error) {
    console.log('   ❌ AI report generation error:', error.message);
  }
  
  // Test 3: Check Firebase Functions logs
  totalTests++;
  console.log('\n3. Checking recent function logs...');
  try {
    execSync(`firebase use staging`, { stdio: 'pipe' });
    const logs = execSync(`firebase functions:log --limit 10`, { encoding: 'utf8' });
    
    if (logs.includes('ERROR') || logs.includes('FATAL')) {
      console.log('   ⚠️  Found errors in recent logs');
      console.log('   📄 Recent logs contain errors - check manually');
    } else {
      console.log('   ✅ No critical errors in recent logs');
      passedTests++;
    }
  } catch (error) {
    console.log('   ❌ Failed to check logs:', error.message);
  }
  
  // Test 4: Check function deployment status
  totalTests++;
  console.log('\n4. Checking function deployment status...');
  try {
    const functions = execSync(`firebase functions:list`, { encoding: 'utf8' });
    
    const expectedFunctions = [
      'weeklyAnalysisTrigger',
      'generateAIReport',
      'processAnalysisQueue',
      'healthCheck',
    ];
    
    let deployedFunctions = 0;
    expectedFunctions.forEach(funcName => {
      if (functions.includes(funcName)) {
        deployedFunctions++;
      }
    });
    
    if (deployedFunctions === expectedFunctions.length) {
      console.log('   ✅ All expected functions are deployed');
      passedTests++;
    } else {
      console.log(`   ❌ Only ${deployedFunctions}/${expectedFunctions.length} functions deployed`);
    }
  } catch (error) {
    console.log('   ❌ Failed to check function status:', error.message);
  }
  
  // Test 5: Check monitoring functions
  totalTests++;
  console.log('\n5. Testing monitoring functions...');
  try {
    const monitoringFunctions = [
      'healthCheck',
      'collectMetrics', 
      'checkAlerts',
      'processAlerts'
    ];
    
    const functions = execSync(`firebase functions:list`, { encoding: 'utf8' });
    let monitoringDeployed = 0;
    
    monitoringFunctions.forEach(funcName => {
      if (functions.includes(funcName)) {
        monitoringDeployed++;
      }
    });
    
    if (monitoringDeployed === monitoringFunctions.length) {
      console.log('   ✅ All monitoring functions are deployed');
      passedTests++;
    } else {
      console.log(`   ❌ Only ${monitoringDeployed}/${monitoringFunctions.length} monitoring functions deployed`);
    }
  } catch (error) {
    console.log('   ❌ Failed to check monitoring functions:', error.message);
  }

  // Summary
  console.log('\n' + '='.repeat(50));
  console.log('📊 Test Results Summary');
  console.log('='.repeat(50));
  console.log(`✅ Passed: ${passedTests}/${totalTests}`);
  console.log(`❌ Failed: ${totalTests - passedTests}/${totalTests}`);
  console.log(`📈 Success Rate: ${Math.round((passedTests / totalTests) * 100)}%`);
  
  console.log('\n📋 Deployment Checklist:');
  console.log('- Health check endpoint working');
  console.log('- Core functions deployed');
  console.log('- Monitoring functions active');
  console.log('- No critical errors in logs');
  console.log('- All expected functions available');
  
  if (passedTests === totalTests) {
    console.log('\n🎉 All tests passed! Deployment is healthy and ready for use.');
    console.log('\n📚 Next steps:');
    console.log('- Monitor system metrics');
    console.log('- Check alert configurations');
    console.log('- Verify scheduled functions are running');
    process.exit(0);
  } else {
    console.log('\n⚠️  Some tests failed. Please review the deployment before proceeding.');
    console.log('\n🔧 Troubleshooting:');
    console.log('- Check Firebase project permissions');
    console.log('- Verify environment variables');
    console.log('- Review function logs for errors');
    process.exit(1);
  }
}

async function main() {
  try {
    await runTests();
  } catch (error) {
    console.error('❌ Test execution failed:', error.message);
    process.exit(1);
  }
}

if (require.main === module) {
  main();
}