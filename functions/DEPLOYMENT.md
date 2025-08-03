# Cloud Functions Deployment Guide

## Overview

This document describes the deployment process for the Weekly AI Analysis Cloud Functions.

## Prerequisites

- Node.js 22.x
- Firebase CLI installed globally
- Appropriate Firebase project permissions
- Environment variables configured

## Environment Setup

### Local Development
1. Copy environment template:
   ```bash
   cp .env.example .env.local
   ```

2. Configure local environment variables in `.env.local`

### Staging Environment
- Project: `seol-haru-check-staging`
- Configuration: `.env.staging`

### Production Environment
- Project: `seol-haru-check`
- Configuration: `.env.production`

## Deployment Commands

### Manual Deployment

#### Staging
```bash
# Deploy to staging
npm run deploy:staging:full

# Test staging deployment
npm run test:deployment
```

#### Production
```bash
# Deploy to production
npm run deploy:production:full

# Test production deployment
npm run test:deployment
```

### Automated Deployment (CI/CD)

Deployments are automatically triggered via GitHub Actions:

- **Staging**: Triggered on push to `develop` branch
- **Production**: Triggered on push to `main` branch

## Deployment Pipeline

1. **Code Quality Checks**
   - ESLint linting
   - TypeScript compilation
   - Unit tests with coverage

2. **Build Process**
   - TypeScript compilation to JavaScript
   - Environment-specific configuration

3. **Deployment**
   - Firebase Functions deployment
   - Environment variable configuration
   - Function runtime settings

4. **Post-Deployment Testing**
   - Health check endpoint verification
   - Function availability testing
   - Log analysis

## Monitoring and Alerts

### Health Check Endpoint
- URL: `https://asia-northeast3-{project-id}.cloudfunctions.net/healthCheck`
- Monitors: Firestore, VertexAI connectivity
- Response: JSON with service status

### System Metrics
- Collection interval: Every 5 minutes
- Metrics stored in `systemMetrics` collection
- Includes: queue status, report generation, VertexAI usage

### Alert Rules
- **High Failure Rate**: >30% failures in analysis queue
- **Queue Backlog**: >50 pending items
- **VertexAI Rate Limit**: >90% of rate limit usage
- **No Reports**: No reports generated in last hour

### Alert Processing
- Check interval: Every 5 minutes
- Cooldown periods prevent spam
- Alerts stored in `alerts` collection

## Troubleshooting

### Common Issues

1. **Deployment Fails**
   - Check Firebase project permissions
   - Verify environment variables
   - Review build logs

2. **Functions Not Responding**
   - Check function logs: `firebase functions:log`
   - Verify health check endpoint
   - Review system metrics

3. **VertexAI Errors**
   - Check API quotas and limits
   - Verify service account permissions
   - Review rate limiting configuration

### Log Analysis
```bash
# View recent logs
firebase functions:log --limit 50

# Filter by function
firebase functions:log --only generateAIReport

# View specific time range
firebase functions:log --since 1h
```

## Security Considerations

- Environment variables are managed through Firebase Functions config
- Service account keys are not stored in code
- HTTPS-only endpoints
- Input validation on all functions
- Rate limiting implemented

## Performance Optimization

- Function memory allocation optimized per function type
- Concurrent execution limits set
- Connection pooling for external services
- Efficient Firestore queries with proper indexing

## Rollback Procedure

If deployment issues occur:

1. **Immediate Rollback**
   ```bash
   # Switch to previous version
   firebase functions:log --limit 1
   # Deploy previous working version
   ```

2. **Gradual Rollback**
   - Deploy to staging first
   - Test thoroughly
   - Deploy to production

## Maintenance

### Regular Tasks
- Monitor system metrics weekly
- Review alert patterns monthly
- Update dependencies quarterly
- Performance optimization as needed

### Capacity Planning
- Monitor VertexAI usage trends
- Scale function memory/timeout as needed
- Review Firestore read/write patterns
- Plan for user growth

## Support

For deployment issues:
1. Check this documentation
2. Review function logs
3. Check system health dashboard
4. Contact development team