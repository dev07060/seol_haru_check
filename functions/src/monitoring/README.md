# Metadata Extraction Monitoring and Analytics

This directory contains comprehensive monitoring, metrics collection, and analytics for the AI metadata extraction feature.

## Overview

The monitoring system tracks:
- **Success rates** and processing times
- **API usage** and cost tracking
- **Error rates** with breakdown by error type
- **Performance metrics** for optimization
- **Automated alerts** for operational issues

## Components

### 1. MetadataExtractionLogger

Structured logging helper that provides consistent logging across the metadata extraction pipeline.

**Usage:**
```typescript
import { MetadataExtractionLogger } from './monitoring/metadataExtractionMonitoring';

// Log extraction start
MetadataExtractionLogger.logExtractionStart(certificationId, type, photoUrl);

// Log successful extraction
MetadataExtractionLogger.logExtractionSuccess(
    certificationId, 
    type, 
    processingTimeMs, 
    metadata, 
    aiMetadata
);

// Log extraction failure
MetadataExtractionLogger.logExtractionFailure(
    certificationId, 
    type, 
    errorType, 
    errorMessage, 
    processingTimeMs
);

// Log API usage
MetadataExtractionLogger.logApiUsage(
    certificationId, 
    requestType, 
    tokensUsed, 
    responseTimeMs, 
    estimatedCost
);

// Log image processing
MetadataExtractionLogger.logImageProcessing(
    certificationId, 
    originalSizeBytes, 
    processedSizeBytes, 
    processingTimeMs, 
    compressionRatio
);
```

### 2. Metrics Collection

**Function:** `collectMetadataExtractionMetrics`
- **Schedule:** Every 5 minutes
- **Purpose:** Aggregates raw metrics into summary statistics
- **Storage:** `metadataExtractionAggregatedMetrics` collection

**Collected Metrics:**
- Total extractions and success rate
- Processing time averages
- API usage and cost tracking
- Error breakdown by category
- Performance metrics

### 3. Alert System

**Function:** `checkMetadataExtractionAlerts`
- **Trigger:** Automatic after metrics collection
- **Purpose:** Monitor for operational issues and send alerts

**Alert Rules:**
- **High Failure Rate:** Success rate < 70% (High severity)
- **No Extractions:** No processing in 5 minutes (Medium severity)
- **High API Cost:** > $10 in 5 minutes (High severity)
- **Slow Processing:** Average time > 30 seconds (Medium severity)
- **High Image Processing Errors:** > 3 errors (Medium severity)
- **High AI Service Errors:** > 5 errors (High severity)

### 4. Analytics Dashboard

**Endpoint:** `getMetadataExtractionAnalytics`
- **Method:** GET
- **Parameters:** `timeRange` (1h, 6h, 24h, 7d)
- **Purpose:** Provides comprehensive analytics data

**Response Structure:**
```json
{
  "success": true,
  "data": {
    "timeRange": "24h",
    "period": {
      "start": "2024-01-01T00:00:00.000Z",
      "end": "2024-01-02T00:00:00.000Z"
    },
    "summary": {
      "totalExtractions": 150,
      "successfulExtractions": 135,
      "failedExtractions": 15,
      "successRate": 90.0,
      "exerciseExtractions": 90,
      "dietExtractions": 60
    },
    "apiUsage": {
      "totalRequests": 150,
      "totalTokensUsed": 22500,
      "averageTokensPerRequest": 150,
      "estimatedCost": 0.56
    },
    "errorBreakdown": {
      "imageProcessingErrors": 5,
      "aiServiceErrors": 8,
      "parsingErrors": 2,
      "unknownErrors": 0
    },
    "performance": {
      "averageProcessingTime": 2500
    },
    "alerts": {
      "total": 3,
      "critical": 0,
      "high": 1,
      "medium": 2,
      "low": 0,
      "recent": [...]
    },
    "timeSeries": [...]
  }
}
```

### 5. Data Cleanup

**Function:** `cleanupMetadataExtractionMetrics`
- **Schedule:** Daily at 2 AM KST
- **Purpose:** Remove old metrics to prevent storage bloat
- **Retention:** 30 days for detailed metrics, 90 days for aggregated

## Firestore Collections

### Raw Metrics Collections

1. **`metadataExtractionMetrics`**
   - Individual extraction events
   - Success/failure status
   - Processing times
   - Metadata results

2. **`metadataApiUsageMetrics`**
   - API request details
   - Token usage
   - Response times
   - Cost estimates

### Aggregated Collections

3. **`metadataExtractionAggregatedMetrics`**
   - 5-minute aggregated summaries
   - Success rates and averages
   - Error breakdowns
   - Performance metrics

4. **`metadataExtractionAlerts`**
   - Alert events
   - Severity levels
   - Associated metrics
   - Timestamps

5. **`metadataExtractionNotifications`**
   - Notification queue
   - Alert details
   - Delivery status

## Monitoring Dashboard Usage

### 1. Real-time Monitoring

Access current system status:
```bash
curl "https://your-function-url/getMetadataExtractionAnalytics?timeRange=1h"
```

### 2. Historical Analysis

View trends over time:
```bash
curl "https://your-function-url/getMetadataExtractionAnalytics?timeRange=7d"
```

### 3. Alert Investigation

Check recent alerts and their context:
```bash
# Alerts are included in the analytics response
# Look at the "alerts.recent" array for details
```

## Performance Optimization

### Key Metrics to Monitor

1. **Success Rate:** Should be > 90%
2. **Average Processing Time:** Should be < 10 seconds
3. **API Cost per Extraction:** Should be < $0.01
4. **Error Rate by Type:** Image processing < 5%, AI service < 3%

### Optimization Strategies

1. **High Failure Rate:**
   - Check image quality and formats
   - Review AI prompt effectiveness
   - Verify API quotas and limits

2. **Slow Processing:**
   - Optimize image compression settings
   - Review AI model parameters
   - Check network latency

3. **High Costs:**
   - Reduce token usage in prompts
   - Optimize image sizes
   - Implement better caching

4. **Frequent Errors:**
   - Improve error handling
   - Add retry logic with backoff
   - Validate input data quality

## Alert Configuration

### Customizing Alert Rules

Edit `METADATA_EXTRACTION_ALERT_RULES` in `metadataExtractionMonitoring.ts`:

```typescript
{
    name: "custom_alert",
    condition: (metrics) => {
        // Your custom condition
        return metrics.customMetric > threshold;
    },
    severity: "medium",
    message: "Custom alert message",
    cooldownMinutes: 15,
}
```

### Alert Severity Levels

- **Critical:** System-wide failures, immediate attention required
- **High:** Significant issues affecting user experience
- **Medium:** Performance degradation or moderate error rates
- **Low:** Minor issues or informational alerts

## Integration with External Systems

### Slack Notifications

To integrate with Slack, modify `sendMetadataExtractionAlert()`:

```typescript
// Add Slack webhook integration
const slackWebhook = process.env.SLACK_WEBHOOK_URL;
if (slackWebhook) {
    await fetch(slackWebhook, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
            text: `🚨 ${rule.message}`,
            attachments: [{
                color: rule.severity === 'high' ? 'danger' : 'warning',
                fields: [
                    { title: 'Success Rate', value: `${metrics.successRate}%`, short: true },
                    { title: 'Total Extractions', value: metrics.totalExtractions, short: true }
                ]
            }]
        })
    });
}
```

### Email Notifications

For email alerts, integrate with SendGrid or similar:

```typescript
// Add email notification
const sgMail = require('@sendgrid/mail');
sgMail.setApiKey(process.env.SENDGRID_API_KEY);

const msg = {
    to: 'admin@yourapp.com',
    from: 'alerts@yourapp.com',
    subject: `Metadata Extraction Alert: ${rule.name}`,
    text: rule.message,
    html: `<h3>${rule.message}</h3><p>Details: ${JSON.stringify(metrics, null, 2)}</p>`
};

await sgMail.send(msg);
```

## Testing

Run the test suite:

```bash
cd functions
npm test -- monitoring/__tests__/metadataExtractionMonitoring.test.ts
```

The tests cover:
- Logging functionality
- Alert condition logic
- Metrics calculation
- Error categorization
- Cost estimation

## Troubleshooting

### Common Issues

1. **Missing Metrics:**
   - Check Cloud Function execution logs
   - Verify Firestore permissions
   - Ensure proper initialization

2. **Alerts Not Firing:**
   - Review alert conditions
   - Check cooldown periods
   - Verify metrics collection

3. **High Storage Usage:**
   - Confirm cleanup function is running
   - Adjust retention periods
   - Monitor collection sizes

### Debug Commands

```bash
# Check function logs
gcloud functions logs read collectMetadataExtractionMetrics --region=asia-northeast3

# View recent metrics
# Use Firestore console or admin SDK to query collections

# Test analytics endpoint
curl -X GET "https://your-region-your-project.cloudfunctions.net/getMetadataExtractionAnalytics?timeRange=1h"
```

## Future Enhancements

1. **Machine Learning Insights:**
   - Predict failure patterns
   - Optimize processing parameters
   - Anomaly detection

2. **Advanced Visualizations:**
   - Real-time dashboards
   - Trend analysis charts
   - Comparative metrics

3. **Automated Remediation:**
   - Auto-scaling based on load
   - Dynamic parameter adjustment
   - Self-healing mechanisms

4. **Enhanced Cost Tracking:**
   - Per-user cost attribution
   - Budget alerts and limits
   - Cost optimization recommendations