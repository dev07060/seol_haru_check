#!/usr/bin/env node

/**
 * Metadata Extraction Testing Script
 * Tests the deployed metadata extraction functionality with real certification uploads
 */

const { execSync } = require('child_process');
const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

const ENVIRONMENTS = {
  staging: 'seol-haru-check-staging',
  production: 'seol-haru-check'
};

// Test data for certification uploads
const TEST_CERTIFICATIONS = [
  {
    type: '운동',
    content: '오늘 30분 러닝했습니다!',
    testImagePath: null, // Will use a sample exercise image
    expectedMetadata: {
      exerciseType: 'string',
      duration: 'number',
      timePeriod: 'string',
      intensity: 'string'
    }
  },
  {
    type: '식단',
    content: '건강한 샐러드로 점심 식사',
    testImagePath: null, // Will use a sample diet image
    expectedMetadata: {
      mainIngredients: 'array',
      foodCategory: 'string',
      mealTime: 'string',
      estimatedCalories: 'number'
    }
  }
];

class MetadataExtractionTester {
  constructor(environment) {
    this.environment = environment;
    this.projectId = ENVIRONMENTS[environment];
    this.testResults = [];
    this.testUserId = `test-user-${Date.now()}`;
    
    // Initialize Firebase Admin
    if (!admin.apps.length) {
      admin.initializeApp({
        projectId: this.projectId,
        storageBucket: `${this.projectId}.appspot.com`
      });
    }
    
    this.db = admin.firestore();
    this.storage = admin.storage();
  }

  async uploadTestImage(imageBuffer, fileName) {
    console.log(`📤 Uploading test image: ${fileName}`);
    
    try {
      const bucket = this.storage.bucket();
      const file = bucket.file(`certifications/${this.testUserId}/${fileName}`);
      
      await file.save(imageBuffer, {
        metadata: {
          contentType: 'image/jpeg',
          metadata: {
            uploadedBy: 'test-script',
            testRun: new Date().toISOString()
          }
        }
      });
      
      // Make file publicly readable for testing
      await file.makePublic();
      
      const publicUrl = `https://storage.googleapis.com/${bucket.name}/${file.name}`;
      console.log(`✅ Image uploaded: ${publicUrl}`);
      
      return publicUrl;
      
    } catch (error) {
      console.error(`❌ Failed to upload image: ${error.message}`);
      throw error;
    }
  }

  async createTestCertification(certificationData, imageUrl) {
    console.log(`📝 Creating test certification: ${certificationData.type}`);
    
    try {
      const certificationRef = this.db.collection('certifications').doc();
      
      const certificationDoc = {
        uuid: this.testUserId,
        nickname: 'Test User',
        createdAt: admin.firestore.Timestamp.now(),
        type: certificationData.type,
        content: certificationData.content,
        photoUrl: imageUrl,
        metadataProcessed: false,
        testCertification: true,
        testRunId: new Date().toISOString()
      };
      
      await certificationRef.set(certificationDoc);
      
      console.log(`✅ Test certification created: ${certificationRef.id}`);
      
      return {
        id: certificationRef.id,
        data: certificationDoc
      };
      
    } catch (error) {
      console.error(`❌ Failed to create certification: ${error.message}`);
      throw error;
    }
  }

  async waitForMetadataProcessing(certificationId, timeoutMs = 60000) {
    console.log(`⏳ Waiting for metadata processing: ${certificationId}`);
    
    const startTime = Date.now();
    
    while (Date.now() - startTime < timeoutMs) {
      try {
        const doc = await this.db.collection('certifications').doc(certificationId).get();
        const data = doc.data();
        
        if (data && data.metadataProcessed === true) {
          console.log(`✅ Metadata processing completed for: ${certificationId}`);
          return data;
        }
        
        // Wait 2 seconds before checking again
        await new Promise(resolve => setTimeout(resolve, 2000));
        
      } catch (error) {
        console.warn(`⚠️  Error checking processing status: ${error.message}`);
      }
    }
    
    throw new Error(`Timeout waiting for metadata processing: ${certificationId}`);
  }

  validateMetadata(metadata, expectedStructure, certificationType) {
    console.log(`🔍 Validating ${certificationType} metadata...`);
    
    const validationResults = {
      isValid: true,
      errors: [],
      warnings: []
    };
    
    if (!metadata) {
      validationResults.isValid = false;
      validationResults.errors.push('No metadata found');
      return validationResults;
    }
    
    // Check required fields based on certification type
    if (certificationType === '운동') {
      const requiredFields = ['exerciseType', 'duration', 'timePeriod', 'intensity', 'extractedAt'];
      
      requiredFields.forEach(field => {
        if (!(field in metadata)) {
          validationResults.errors.push(`Missing required field: ${field}`);
          validationResults.isValid = false;
        }
      });
      
      // Validate data types
      if (metadata.duration !== null && typeof metadata.duration !== 'number') {
        validationResults.warnings.push('Duration should be a number or null');
      }
      
    } else if (certificationType === '식단') {
      const requiredFields = ['mainIngredients', 'foodCategory', 'mealTime', 'estimatedCalories', 'extractedAt'];
      
      requiredFields.forEach(field => {
        if (!(field in metadata)) {
          validationResults.errors.push(`Missing required field: ${field}`);
          validationResults.isValid = false;
        }
      });
      
      // Validate data types
      if (metadata.mainIngredients && !Array.isArray(metadata.mainIngredients)) {
        validationResults.errors.push('mainIngredients should be an array');
        validationResults.isValid = false;
      }
      
      if (metadata.estimatedCalories !== null && typeof metadata.estimatedCalories !== 'number') {
        validationResults.warnings.push('estimatedCalories should be a number or null');
      }
    }
    
    // Check extractedAt timestamp
    if (metadata.extractedAt && !(metadata.extractedAt instanceof admin.firestore.Timestamp)) {
      validationResults.warnings.push('extractedAt should be a Firestore Timestamp');
    }
    
    if (validationResults.isValid) {
      console.log(`✅ Metadata validation passed for ${certificationType}`);
    } else {
      console.log(`❌ Metadata validation failed for ${certificationType}`);
      validationResults.errors.forEach(error => console.log(`   Error: ${error}`));
    }
    
    if (validationResults.warnings.length > 0) {
      validationResults.warnings.forEach(warning => console.log(`   Warning: ${warning}`));
    }
    
    return validationResults;
  }

  async testSingleCertification(certificationData) {
    console.log(`\n🧪 Testing ${certificationData.type} certification...`);
    
    const testResult = {
      type: certificationData.type,
      success: false,
      certificationId: null,
      processingTime: 0,
      metadata: null,
      validationResults: null,
      error: null
    };
    
    try {
      const startTime = Date.now();
      
      // Create a simple test image (1x1 pixel JPEG)
      const testImageBuffer = Buffer.from('/9j/4AAQSkZJRgABAQEAYABgAAD/2wBDAAEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQH/2wBDAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQH/wAARCAABAAEDASIAAhEBAxEB/8QAFQABAQAAAAAAAAAAAAAAAAAAAAv/xAAUEAEAAAAAAAAAAAAAAAAAAAAA/8QAFQEBAQAAAAAAAAAAAAAAAAAAAAX/xAAUEQEAAAAAAAAAAAAAAAAAAAAA/9oADAMBAAIRAxEAPwA/8A', 'base64');
      
      // Upload test image
      const imageUrl = await this.uploadTestImage(
        testImageBuffer,
        `test-${certificationData.type}-${Date.now()}.jpg`
      );
      
      // Create certification document
      const certification = await this.createTestCertification(certificationData, imageUrl);
      testResult.certificationId = certification.id;
      
      // Wait for metadata processing
      const processedData = await this.waitForMetadataProcessing(certification.id);
      
      testResult.processingTime = Date.now() - startTime;
      
      // Extract metadata based on certification type
      if (certificationData.type === '운동') {
        testResult.metadata = processedData.exerciseMetadata;
      } else if (certificationData.type === '식단') {
        testResult.metadata = processedData.dietMetadata;
      }
      
      // Validate metadata structure
      testResult.validationResults = this.validateMetadata(
        testResult.metadata,
        certificationData.expectedMetadata,
        certificationData.type
      );
      
      // Check for processing errors
      if (processedData.metadataError) {
        console.log(`⚠️  Processing error found: ${JSON.stringify(processedData.metadataError)}`);
        testResult.error = processedData.metadataError;
      }
      
      testResult.success = testResult.validationResults.isValid && !processedData.metadataError;
      
      console.log(`${testResult.success ? '✅' : '❌'} Test completed for ${certificationData.type}`);
      console.log(`   Processing time: ${testResult.processingTime}ms`);
      console.log(`   Metadata extracted: ${testResult.metadata ? 'Yes' : 'No'}`);
      
    } catch (error) {
      testResult.error = error.message;
      testResult.success = false;
      console.log(`❌ Test failed for ${certificationData.type}: ${error.message}`);
    }
    
    return testResult;
  }

  async runAllTests() {
    console.log(`🚀 Starting metadata extraction tests for ${this.environment}...`);
    console.log(`Project ID: ${this.projectId}`);
    console.log(`Test User ID: ${this.testUserId}\n`);
    
    // Run tests for each certification type
    for (const certificationData of TEST_CERTIFICATIONS) {
      const result = await this.testSingleCertification(certificationData);
      this.testResults.push(result);
    }
    
    // Generate test report
    this.generateTestReport();
    
    // Cleanup test data
    await this.cleanupTestData();
  }

  generateTestReport() {
    console.log('\n' + '='.repeat(60));
    console.log('📊 METADATA EXTRACTION TEST REPORT');
    console.log('='.repeat(60));
    
    const totalTests = this.testResults.length;
    const passedTests = this.testResults.filter(r => r.success).length;
    const failedTests = totalTests - passedTests;
    
    console.log(`Environment: ${this.environment}`);
    console.log(`Project ID: ${this.projectId}`);
    console.log(`Test Run: ${new Date().toISOString()}`);
    console.log(`Total Tests: ${totalTests}`);
    console.log(`Passed: ${passedTests}`);
    console.log(`Failed: ${failedTests}`);
    console.log(`Success Rate: ${Math.round((passedTests / totalTests) * 100)}%`);
    
    console.log('\n📋 Test Details:');
    this.testResults.forEach((result, index) => {
      console.log(`\n${index + 1}. ${result.type} Certification:`);
      console.log(`   Status: ${result.success ? '✅ PASSED' : '❌ FAILED'}`);
      console.log(`   Processing Time: ${result.processingTime}ms`);
      console.log(`   Certification ID: ${result.certificationId}`);
      
      if (result.metadata) {
        console.log(`   Metadata Fields: ${Object.keys(result.metadata).length}`);
      } else {
        console.log(`   Metadata: None extracted`);
      }
      
      if (result.error) {
        console.log(`   Error: ${result.error}`);
      }
      
      if (result.validationResults && result.validationResults.errors.length > 0) {
        console.log(`   Validation Errors: ${result.validationResults.errors.join(', ')}`);
      }
    });
    
    console.log('\n📈 Performance Metrics:');
    const avgProcessingTime = this.testResults.reduce((sum, r) => sum + r.processingTime, 0) / totalTests;
    console.log(`   Average Processing Time: ${Math.round(avgProcessingTime)}ms`);
    
    const maxProcessingTime = Math.max(...this.testResults.map(r => r.processingTime));
    console.log(`   Max Processing Time: ${maxProcessingTime}ms`);
    
    console.log('\n🎯 Recommendations:');
    if (failedTests > 0) {
      console.log('- Review failed test logs for specific error patterns');
      console.log('- Check AI service configuration and API keys');
      console.log('- Verify Firebase Storage permissions');
      console.log('- Monitor function execution logs');
    }
    
    if (avgProcessingTime > 30000) {
      console.log('- Consider optimizing image processing pipeline');
      console.log('- Review AI API response times');
      console.log('- Check function memory allocation');
    }
    
    if (passedTests === totalTests) {
      console.log('- All tests passed! Metadata extraction is working correctly');
      console.log('- Monitor production metrics for ongoing performance');
      console.log('- Consider adding more comprehensive test cases');
    }
    
    console.log('\n' + '='.repeat(60));
  }

  async cleanupTestData() {
    console.log('\n🧹 Cleaning up test data...');
    
    try {
      // Delete test certifications
      const testCertifications = await this.db.collection('certifications')
        .where('testCertification', '==', true)
        .where('uuid', '==', this.testUserId)
        .get();
      
      const batch = this.db.batch();
      testCertifications.docs.forEach(doc => {
        batch.delete(doc.ref);
      });
      
      if (!testCertifications.empty) {
        await batch.commit();
        console.log(`✅ Deleted ${testCertifications.size} test certifications`);
      }
      
      // Delete test images from Storage
      const bucket = this.storage.bucket();
      const [files] = await bucket.getFiles({
        prefix: `certifications/${this.testUserId}/`
      });
      
      if (files.length > 0) {
        await Promise.all(files.map(file => file.delete()));
        console.log(`✅ Deleted ${files.length} test images`);
      }
      
    } catch (error) {
      console.warn(`⚠️  Cleanup failed: ${error.message}`);
    }
  }
}

async function main() {
  const environment = process.argv[2];
  
  if (!environment || !ENVIRONMENTS[environment]) {
    console.error('Usage: node test-metadata-extraction.js <staging|production>');
    console.error('Available environments:', Object.keys(ENVIRONMENTS).join(', '));
    process.exit(1);
  }
  
  try {
    const tester = new MetadataExtractionTester(environment);
    await tester.runAllTests();
    
    const passedTests = tester.testResults.filter(r => r.success).length;
    const totalTests = tester.testResults.length;
    
    if (passedTests === totalTests) {
      console.log('\n🎉 All tests passed! Metadata extraction is working correctly.');
      process.exit(0);
    } else {
      console.log(`\n⚠️  ${totalTests - passedTests} tests failed. Please review the results.`);
      process.exit(1);
    }
    
  } catch (error) {
    console.error(`❌ Test execution failed: ${error.message}`);
    process.exit(1);
  }
}

if (require.main === module) {
  main();
}

module.exports = { MetadataExtractionTester, ENVIRONMENTS };