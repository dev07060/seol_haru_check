# AI Metadata Extraction - Production Deployment Guide

This guide covers the complete deployment process for the AI metadata extraction feature in production.

## Prerequisites

Before deploying, ensure you have:

1. **Firebase CLI** installed and authenticated
2. **Google Cloud SDK** installed and authenticated
3. **Node.js 22** or later
4. **Required permissions**:
   - Firebase Admin
   - Cloud Functions Admin
   - Storage Admin
   - Monitoring Admin
   - IAM Admin

## Environment Setup

### 1. Configure Environment Variables

Ensure your production environment file is properly configured:

```bash
# Check if .env.production exists and has all required variables
cat functions/.env.production
```

Required variables:
- `GOOGLE_CLOUD_PROJECT`
- `FIREBASE_PROJECT_ID`
- `VERTEX_AI_PROJECT_ID`
- `VERTEX_AI_LOCATION`
- `VERTEX_AI_MODEL`
- `VERTEX_AI_REQUESTS_PER_MINUTE`
- `VERTEX_AI_MAX_CONCURRENT_REQUESTS`
- `NODE_ENV=production`

### 2. Enable Required APIs

```bash
# Enable required Google Cloud APIs
gcloud services enable cloudfunctions.googleapis.com
gcloud services enable storage.googleapis.com
gcloud services enable aiplatform.googleapis.com
gcloud services enable monitoring.googleapis.com
gcloud services enable logging.googleapis.com
```

## Deployment Steps

### Step 1: Deploy Cloud Functions

Deploy the metadata extraction functions with proper configuration:

```bash
cd functions
npm run deploy:metadata-extraction:production
```

This script will:
- Validate environment configuration
- Set Firebase project to production
- Configure Firebase Functions environment variables
- Set up IAM permissions
- Deploy metadata extraction functions
- Verify deployment

### Step 2: Configure Firebase Storage Security Rules

Deploy the updated storage security rules:

```bash
firebase deploy --only storage
```

The storage rules include:
- Proper access controls for certification images
- Cloud Functions access for metadata processing
- User-specific image upload permissions
- Temporary processing folder access

### Step 3: Set Up Monitoring and Alerts

Configure monitoring dashboards and alert policies:

```bash
cd functions
npm run setup:monitoring:production
```

This will create:
- Custom metrics for metadata extraction
- Monitoring dashboard with key metrics
- Alert policies for error rates and latency
- API usage tracking

### Step 4: Test Production Deployment

Run comprehensive tests to verify the deployment:

```bash
cd functions
npm run test:metadata-extraction:production
```

This test suite will:
- Upload test certification images
- Verify metadata extraction functionality
- Validate extracted metadata structure
- Check processing times and error handling
- Clean up test data

## Verification Checklist

After deployment, verify the following:

### ✅ Cloud Functions
- [ ] `processMetadataExtraction` function deployed
- [ ] `collectMetadataExtractionMetrics` function deployed
- [ ] `getMetadataExtractionAnalytics` function deployed
- [ ] `cleanupMetadataExtractionMetrics` function deployed
- [ ] Functions have proper memory allocation (512MiB)
- [ ] Functions have appropriate timeout (60s)

### ✅ Storage Security Rules
- [ ] Storage rules deployed successfully
- [ ] Users can upload certification images
- [ ] Cloud Functions can read images for processing
- [ ] Proper access controls in place

### ✅ Monitoring Setup
- [ ] Custom metrics created
- [ ] Monitoring dashboard accessible
- [ ] Alert policies configured
- [ ] Notification channels set up

### ✅ Functionality Tests
- [ ] Exercise certification metadata extraction works
- [ ] Diet certification metadata extraction works
- [ ] Error handling works properly
- [ ] Processing times are acceptable (<30s)
- [ ] Fallback mechanisms work

## Monitoring and Maintenance

### Access Monitoring Dashboard

1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Navigate to Monitoring > Dashboards
3. Find "Metadata Extraction Dashboard - PRODUCTION"

### Key Metrics to Monitor

- **Success Rate**: Should be >95%
- **Processing Time**: Should be <30 seconds average
- **Error Rate**: Should be <5%
- **API Usage**: Monitor quota consumption

### Alert Policies

The following alerts are configured:
- High error rate (>10%)
- High latency (>30 seconds)
- API quota exhaustion (>90%)

### Log Analysis

View function logs:
```bash
firebase functions:log --only processMetadataExtraction
```

Filter for errors:
```bash
firebase functions:log --only processMetadataExtraction | grep ERROR
```

## Troubleshooting

### Common Issues

1. **Function Deployment Fails**
   - Check Firebase project permissions
   - Verify environment variables
   - Ensure all required APIs are enabled

2. **Metadata Extraction Not Working**
   - Check Gemini API key validity
   - Verify Vertex AI permissions
   - Review function logs for errors

3. **Storage Access Issues**
   - Verify storage rules deployment
   - Check IAM permissions for service account
   - Ensure bucket exists and is accessible

4. **High Processing Times**
   - Check image sizes (should be <10MB)
   - Monitor AI API response times
   - Consider increasing function memory

5. **Alert Policies Not Triggering**
   - Verify custom metrics are being written
   - Check alert policy conditions
   - Ensure notification channels are configured

### Emergency Rollback

If issues occur, you can quickly disable metadata extraction:

```bash
# Disable the trigger function
gcloud functions deploy processMetadataExtraction --no-trigger

# Or delete the function entirely
gcloud functions delete processMetadataExtraction
```

## Performance Optimization

### Cost Optimization
- Monitor AI API usage and costs
- Implement image compression if needed
- Use batch processing for high volumes

### Performance Tuning
- Adjust function memory based on usage patterns
- Optimize image preprocessing
- Implement caching for repeated requests

## Security Considerations

- API keys are stored securely in Firebase Functions config
- Storage rules prevent unauthorized access
- Function execution is logged for audit purposes
- Error messages don't expose sensitive information

## Support and Maintenance

### Regular Tasks
- Review monitoring dashboards weekly
- Check error logs for patterns
- Update AI models as needed
- Optimize based on usage patterns

### Quarterly Reviews
- Analyze cost and performance metrics
- Update alert thresholds based on actual usage
- Review and update security rules
- Plan capacity for growth

## Contact Information

For deployment issues or questions:
- Check function logs first
- Review monitoring dashboards
- Consult this deployment guide
- Contact the development team with specific error messages and timestamps