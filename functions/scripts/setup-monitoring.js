#!/usr/bin/env node

/**
 * Monitoring Setup Script for Metadata Extraction
 * Sets up Cloud Monitoring dashboards, alerts, and metrics for the AI metadata extraction feature
 */

const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

const ENVIRONMENTS = {
  staging: 'seol-haru-check-staging',
  production: 'seol-haru-check'
};

function createMonitoringDashboard(environment) {
  const projectId = ENVIRONMENTS[environment];
  
  console.log('📊 Creating monitoring dashboard for metadata extraction...');
  
  // Dashboard configuration
  const dashboardConfig = {
    displayName: `Metadata Extraction Dashboard - ${environment.toUpperCase()}`,
    mosaicLayout: {
      tiles: [
        {
          width: 6,
          height: 4,
          widget: {
            title: "Metadata Extraction Success Rate",
            xyChart: {
              dataSets: [{
                timeSeriesQuery: {
                  timeSeriesFilter: {
                    filter: `resource.type="cloud_function" AND resource.labels.function_name="processMetadataExtraction"`,
                    aggregation: {
                      alignmentPeriod: "300s",
                      perSeriesAligner: "ALIGN_RATE",
                      crossSeriesReducer: "REDUCE_SUM"
                    }
                  }
                },
                plotType: "LINE"
              }]
            }
          }
        },
        {
          width: 6,
          height: 4,
          xPos: 6,
          widget: {
            title: "Metadata Extraction Latency",
            xyChart: {
              dataSets: [{
                timeSeriesQuery: {
                  timeSeriesFilter: {
                    filter: `resource.type="cloud_function" AND resource.labels.function_name="processMetadataExtraction"`,
                    aggregation: {
                      alignmentPeriod: "300s",
                      perSeriesAligner: "ALIGN_MEAN",
                      crossSeriesReducer: "REDUCE_MEAN"
                    }
                  }
                },
                plotType: "LINE"
              }]
            }
          }
        },
        {
          width: 6,
          height: 4,
          yPos: 4,
          widget: {
            title: "AI API Usage",
            xyChart: {
              dataSets: [{
                timeSeriesQuery: {
                  timeSeriesFilter: {
                    filter: `resource.type="cloud_function" AND metric.type="custom.googleapis.com/metadata_extraction/ai_api_calls"`,
                    aggregation: {
                      alignmentPeriod: "300s",
                      perSeriesAligner: "ALIGN_RATE",
                      crossSeriesReducer: "REDUCE_SUM"
                    }
                  }
                },
                plotType: "STACKED_BAR"
              }]
            }
          }
        },
        {
          width: 6,
          height: 4,
          xPos: 6,
          yPos: 4,
          widget: {
            title: "Error Rate by Type",
            xyChart: {
              dataSets: [{
                timeSeriesQuery: {
                  timeSeriesFilter: {
                    filter: `resource.type="cloud_function" AND metric.type="custom.googleapis.com/metadata_extraction/errors"`,
                    aggregation: {
                      alignmentPeriod: "300s",
                      perSeriesAligner: "ALIGN_RATE",
                      crossSeriesReducer: "REDUCE_SUM",
                      groupByFields: ["metric.label.error_type"]
                    }
                  }
                },
                plotType: "STACKED_AREA"
              }]
            }
          }
        }
      ]
    }
  };
  
  // Write dashboard config to temporary file
  const configPath = path.join(__dirname, 'dashboard-config.json');
  fs.writeFileSync(configPath, JSON.stringify(dashboardConfig, null, 2));
  
  try {
    // Create dashboard using gcloud CLI
    const command = `gcloud monitoring dashboards create --config-from-file="${configPath}" --project="${projectId}"`;
    execSync(command, { stdio: 'inherit' });
    
    console.log('✅ Monitoring dashboard created successfully');
    
    // Clean up temporary file
    fs.unlinkSync(configPath);
    
  } catch (error) {
    console.error('❌ Failed to create monitoring dashboard:', error.message);
    
    // Clean up temporary file
    if (fs.existsSync(configPath)) {
      fs.unlinkSync(configPath);
    }
    
    throw error;
  }
}

function createAlertPolicies(environment) {
  const projectId = ENVIRONMENTS[environment];
  
  console.log('🚨 Creating alert policies for metadata extraction...');
  
  const alertPolicies = [
    {
      displayName: `Metadata Extraction High Error Rate - ${environment.toUpperCase()}`,
      conditions: [{
        displayName: "High error rate condition",
        conditionThreshold: {
          filter: `resource.type="cloud_function" AND resource.labels.function_name="processMetadataExtraction" AND metric.type="cloudfunctions.googleapis.com/function/execution_count"`,
          comparison: "COMPARISON_GREATER_THAN",
          thresholdValue: 0.1, // 10% error rate
          duration: "300s",
          aggregations: [{
            alignmentPeriod: "300s",
            perSeriesAligner: "ALIGN_RATE",
            crossSeriesReducer: "REDUCE_MEAN"
          }]
        }
      }],
      alertStrategy: {
        autoClose: "1800s" // 30 minutes
      },
      enabled: true
    },
    {
      displayName: `Metadata Extraction High Latency - ${environment.toUpperCase()}`,
      conditions: [{
        displayName: "High latency condition",
        conditionThreshold: {
          filter: `resource.type="cloud_function" AND resource.labels.function_name="processMetadataExtraction" AND metric.type="cloudfunctions.googleapis.com/function/execution_time"`,
          comparison: "COMPARISON_GREATER_THAN",
          thresholdValue: 30000, // 30 seconds
          duration: "300s",
          aggregations: [{
            alignmentPeriod: "300s",
            perSeriesAligner: "ALIGN_MEAN",
            crossSeriesReducer: "REDUCE_MEAN"
          }]
        }
      }],
      alertStrategy: {
        autoClose: "1800s"
      },
      enabled: true
    },
    {
      displayName: `AI API Quota Exhaustion - ${environment.toUpperCase()}`,
      conditions: [{
        displayName: "API quota condition",
        conditionThreshold: {
          filter: `resource.type="cloud_function" AND metric.type="custom.googleapis.com/metadata_extraction/api_quota_usage"`,
          comparison: "COMPARISON_GREATER_THAN",
          thresholdValue: 0.9, // 90% of quota
          duration: "60s",
          aggregations: [{
            alignmentPeriod: "60s",
            perSeriesAligner: "ALIGN_MEAN",
            crossSeriesReducer: "REDUCE_MEAN"
          }]
        }
      }],
      alertStrategy: {
        autoClose: "3600s" // 1 hour
      },
      enabled: true
    }
  ];
  
  alertPolicies.forEach((policy, index) => {
    const configPath = path.join(__dirname, `alert-policy-${index}.json`);
    fs.writeFileSync(configPath, JSON.stringify(policy, null, 2));
    
    try {
      const command = `gcloud alpha monitoring policies create --policy-from-file="${configPath}" --project="${projectId}"`;
      execSync(command, { stdio: 'inherit' });
      
      console.log(`✅ Alert policy created: ${policy.displayName}`);
      
      // Clean up temporary file
      fs.unlinkSync(configPath);
      
    } catch (error) {
      console.warn(`⚠️  Failed to create alert policy: ${policy.displayName}`);
      
      // Clean up temporary file
      if (fs.existsSync(configPath)) {
        fs.unlinkSync(configPath);
      }
    }
  });
}

function setupCustomMetrics(environment) {
  const projectId = ENVIRONMENTS[environment];
  
  console.log('📈 Setting up custom metrics for metadata extraction...');
  
  const customMetrics = [
    {
      type: "custom.googleapis.com/metadata_extraction/success_rate",
      displayName: "Metadata Extraction Success Rate",
      description: "Rate of successful metadata extractions",
      metricKind: "GAUGE",
      valueType: "DOUBLE",
      labels: [
        {
          key: "certification_type",
          description: "Type of certification (exercise or diet)"
        },
        {
          key: "extraction_method",
          description: "Method used for extraction (ai or fallback)"
        }
      ]
    },
    {
      type: "custom.googleapis.com/metadata_extraction/processing_time",
      displayName: "Metadata Processing Time",
      description: "Time taken to process metadata extraction",
      metricKind: "GAUGE",
      valueType: "DOUBLE",
      labels: [
        {
          key: "certification_type",
          description: "Type of certification"
        },
        {
          key: "image_size_category",
          description: "Category of image size (small, medium, large)"
        }
      ]
    },
    {
      type: "custom.googleapis.com/metadata_extraction/ai_api_calls",
      displayName: "AI API Calls",
      description: "Number of AI API calls made for metadata extraction",
      metricKind: "CUMULATIVE",
      valueType: "INT64",
      labels: [
        {
          key: "api_type",
          description: "Type of AI API used (vertex_ai, gemini)"
        },
        {
          key: "result",
          description: "Result of API call (success, error, timeout)"
        }
      ]
    },
    {
      type: "custom.googleapis.com/metadata_extraction/errors",
      displayName: "Metadata Extraction Errors",
      description: "Number of errors in metadata extraction",
      metricKind: "CUMULATIVE",
      valueType: "INT64",
      labels: [
        {
          key: "error_type",
          description: "Type of error (image_processing, ai_service, parsing, unknown)"
        },
        {
          key: "certification_type",
          description: "Type of certification"
        }
      ]
    }
  ];
  
  customMetrics.forEach(metric => {
    const configPath = path.join(__dirname, `metric-${metric.type.split('/').pop()}.json`);
    fs.writeFileSync(configPath, JSON.stringify(metric, null, 2));
    
    try {
      const command = `gcloud logging metrics create ${metric.type.split('/').pop()} --config-from-file="${configPath}" --project="${projectId}"`;
      execSync(command, { stdio: 'pipe' });
      
      console.log(`✅ Custom metric created: ${metric.displayName}`);
      
      // Clean up temporary file
      fs.unlinkSync(configPath);
      
    } catch (error) {
      console.warn(`⚠️  Failed to create custom metric: ${metric.displayName}`);
      
      // Clean up temporary file
      if (fs.existsSync(configPath)) {
        fs.unlinkSync(configPath);
      }
    }
  });
}

function enableRequiredAPIs(environment) {
  const projectId = ENVIRONMENTS[environment];
  
  console.log('🔧 Enabling required APIs for monitoring...');
  
  const requiredAPIs = [
    'monitoring.googleapis.com',
    'logging.googleapis.com',
    'cloudfunctions.googleapis.com',
    'aiplatform.googleapis.com'
  ];
  
  requiredAPIs.forEach(api => {
    try {
      execSync(`gcloud services enable ${api} --project="${projectId}"`, { stdio: 'pipe' });
      console.log(`✅ Enabled API: ${api}`);
    } catch (error) {
      console.warn(`⚠️  Failed to enable API: ${api}`);
    }
  });
}

async function main() {
  const environment = process.argv[2];
  
  if (!environment || !ENVIRONMENTS[environment]) {
    console.error('Usage: node setup-monitoring.js <staging|production>');
    console.error('Available environments:', Object.keys(ENVIRONMENTS).join(', '));
    process.exit(1);
  }

  const projectId = ENVIRONMENTS[environment];
  
  console.log('📊 Setting up monitoring for metadata extraction...');
  console.log(`Environment: ${environment}`);
  console.log(`Project ID: ${projectId}`);
  console.log(`Timestamp: ${new Date().toISOString()}\n`);
  
  try {
    // Step 1: Enable required APIs
    console.log('1️⃣ Enabling required APIs...');
    enableRequiredAPIs(environment);
    console.log('✅ Required APIs enabled\n');
    
    // Step 2: Set up custom metrics
    console.log('2️⃣ Setting up custom metrics...');
    setupCustomMetrics(environment);
    console.log('✅ Custom metrics configured\n');
    
    // Step 3: Create monitoring dashboard
    console.log('3️⃣ Creating monitoring dashboard...');
    createMonitoringDashboard(environment);
    console.log('✅ Monitoring dashboard created\n');
    
    // Step 4: Create alert policies
    console.log('4️⃣ Creating alert policies...');
    createAlertPolicies(environment);
    console.log('✅ Alert policies created\n');
    
    // Success summary
    console.log('🎉 Monitoring setup completed successfully!');
    console.log('\n📊 Monitoring Summary:');
    console.log(`Environment: ${environment}`);
    console.log(`Project ID: ${projectId}`);
    console.log('Dashboard: Metadata Extraction Dashboard');
    console.log('Alert Policies: 3 policies created');
    console.log('Custom Metrics: 4 metrics configured');
    
    console.log('\n📚 Next steps:');
    console.log('- Access dashboard in Google Cloud Console > Monitoring');
    console.log('- Configure notification channels for alerts');
    console.log('- Test alert policies with simulated failures');
    console.log('- Review and adjust alert thresholds as needed');
    
  } catch (error) {
    console.error(`❌ Monitoring setup failed: ${error.message}`);
    console.error('\n🔧 Troubleshooting:');
    console.error('- Ensure you have monitoring.admin role');
    console.error('- Check if required APIs are enabled');
    console.error('- Verify gcloud CLI is authenticated');
    console.error('- Review project permissions');
    process.exit(1);
  }
}

if (require.main === module) {
  main();
}

module.exports = { main, ENVIRONMENTS };