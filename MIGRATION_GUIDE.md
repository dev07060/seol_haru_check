# Migration Guide: Fix VertexAI Issues and Deprecated functions.config()

This guide will help you resolve both the VertexAI model error and the deprecated Firebase Functions configuration warning.

## Issues Fixed

1. **VertexAI Model Error**: `gemini-1.0-pro-vision` not found
2. **Deprecated API Warning**: `functions.config()` API deprecation

## Quick Fix Steps

### 1. Run the Migration Script

```bash
cd functions
node scripts/migrate-to-dotenv.js production
```

This will:
- Clear any legacy Firebase Functions configuration
- Validate your .env files
- Update firebase.json for proper .env support

### 2. Verify Environment Files

Make sure your environment files have the correct model names:

**functions/.env.production**:
```env
VERTEX_AI_MODEL=gemini-1.5-pro
```

**functions/.env.staging**:
```env
VERTEX_AI_MODEL=gemini-1.5-pro
```

**functions/.env.local**:
```env
VERTEX_AI_MODEL=gemini-1.5-pro
```

### 3. Deploy Functions

```bash
firebase deploy --only functions
```

## What Was Changed

### Environment Files Updated
- ✅ Fixed `gemini-1.5-pro-preview-0409` → `gemini-1.5-pro`
- ✅ Fixed `gemini-2.5-pro` → `gemini-1.5-pro`

### VertexAI Service Updated
- ✅ Now reads model name from `VERTEX_AI_MODEL` environment variable
- ✅ Falls back to `gemini-1.5-pro` if not set

### Deployment Script Updated
- ✅ Removed deprecated `functions:config:set` commands
- ✅ Now validates .env files instead

### Migration Script Created
- ✅ `functions/scripts/migrate-to-dotenv.js` - clears legacy config

## Available Gemini Models

Use one of these stable models in your .env files:

- `gemini-1.5-pro` (recommended) - Latest stable version
- `gemini-1.5-flash` - Faster, lighter version
- `gemini-1.0-pro` - Legacy version (not recommended)

## Troubleshooting

### If you still see the deprecation warning:

1. Clear any remaining legacy config:
   ```bash
   firebase functions:config:get
   firebase functions:config:unset vertex_ai
   firebase functions:config:unset app
   ```

2. Redeploy functions:
   ```bash
   firebase deploy --only functions
   ```

### If VertexAI still fails:

1. Check your Google Cloud project has Vertex AI API enabled
2. Verify your service account has `roles/aiplatform.user` permission
3. Ensure you're using the correct project ID and location
4. **Region Issues**: If you get location/endpoint errors:
   - The service now defaults to `us-central1` (most stable)
   - Has automatic fallback from other regions to `us-central1`
   - `asia-northeast3` may have SDK compatibility issues

### Test Your Configuration

You can test the VertexAI service with this simple function call:

```typescript
import { vertexAIService } from './services/vertexAIService';

// Test connection
const isWorking = await vertexAIService.testConnection();
console.log('VertexAI working:', isWorking);
```

## Environment Variable Reference

Required variables in your .env files:

```env
# Note: GOOGLE_CLOUD_PROJECT and FIREBASE_PROJECT_ID are automatically provided by Firebase
VERTEX_AI_PROJECT_ID=your-project-id
VERTEX_AI_LOCATION=us-central1
VERTEX_AI_MODEL=gemini-1.5-pro
VERTEX_AI_REQUESTS_PER_MINUTE=60
VERTEX_AI_MAX_CONCURRENT_REQUESTS=5
NODE_ENV=production
LOG_LEVEL=info
ENABLE_DETAILED_LOGGING=false
```

## Next Steps

1. ✅ Run migration script
2. ✅ Deploy functions
3. ✅ Test VertexAI functionality
4. ✅ Monitor logs for any issues
5. ✅ Update any CI/CD pipelines to use .env files

The deprecation warning should disappear after redeployment, and VertexAI should work with the correct model.