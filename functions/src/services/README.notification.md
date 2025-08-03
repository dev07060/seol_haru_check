# Notification Service

The Notification Service handles sending push notifications to users when their weekly AI analysis reports are ready. It includes Korean localization, notification consolidation, retry logic, and status tracking.

## Features

### 🚀 Core Functionality
- **Automatic Notifications**: Triggered when weekly reports are created
- **Korean Localization**: All messages are in Korean with proper formatting
- **Multi-platform Support**: Android, iOS, and Web push notifications
- **Status Tracking**: Complete audit trail of notification delivery

### 📱 Notification Consolidation
- **Smart Grouping**: Multiple reports within 5 minutes are consolidated
- **Reduced Noise**: Users receive one notification for multiple reports
- **Badge Management**: Proper badge counts for consolidated notifications

### 🔄 Retry Logic
- **Exponential Backoff**: Automatic retries with increasing delays
- **Maximum Attempts**: Up to 3 retry attempts per notification
- **Failure Handling**: Graceful degradation when all retries fail

### 📊 Monitoring & Analytics
- **Statistics API**: Track notification success rates
- **Performance Metrics**: Monitor delivery times and failure rates
- **Cleanup Jobs**: Automatic cleanup of old notification records

## Cloud Functions

### 1. `sendReportNotification`
**Trigger**: Firestore document creation in `weeklyReports/{reportId}`
**Purpose**: Automatically sends notifications when reports are created

```typescript
// Triggered automatically when a report is created
// No manual invocation needed
```

### 2. `sendManualNotification`
**Type**: HTTP Function
**Purpose**: Manual notification sending for testing or recovery

```bash
curl -X POST https://asia-northeast3-your-project.cloudfunctions.net/sendManualNotification \
  -H "Content-Type: application/json" \
  -d '{
    "reportId": "report123",
    "userUuid": "user456",
    "weekStartDate": "2024-01-07T00:00:00Z",
    "weekEndDate": "2024-01-13T23:59:59Z",
    "reportType": "ai_analysis",
    "nickname": "김철수"
  }'
```

### 3. `getNotificationStats`
**Type**: HTTP Function
**Purpose**: Get notification statistics for monitoring

```bash
curl "https://asia-northeast3-your-project.cloudfunctions.net/getNotificationStats?startDate=2024-01-01&endDate=2024-01-31"
```

### 4. `cleanupNotifications`
**Trigger**: Scheduled (Daily at 2 AM KST)
**Purpose**: Clean up old notification status records

## Message Types

### AI Analysis Report
```
Title: 주간 분석 리포트가 준비되었습니다! 📊
Body: 1월 7일~1월 13일 운동과 식단 활동을 AI가 분석했어요. 확인해보세요!
```

### Motivational Report
```
Title: 더 꾸준한 인증이 필요해요! 💪
Body: 1월 7일~1월 13일 인증이 부족했어요. 다음 주에는 더 열심히 해보세요!
```

### Basic Report
```
Title: 건강한 습관을 시작해보세요! 🌟
Body: 1월 7일~1월 13일 운동과 식단 인증으로 건강한 라이프스타일을 만들어가요!
```

### Consolidated Reports
```
Title: 새로운 주간 리포트들이 준비되었습니다! 📊
Body: 3개의 주간 분석 리포트를 확인해보세요!
```

## Data Structures

### Notification Payload
```typescript
interface NotificationPayload {
  userUuid: string;
  reportId: string;
  weekStartDate: Date;
  weekEndDate: Date;
  reportType: 'ai_analysis' | 'motivational' | 'basic';
  nickname?: string;
}
```

### Notification Status (Firestore)
```typescript
interface NotificationStatus {
  id: string;
  userUuid: string;
  reportId: string;
  status: 'pending' | 'sent' | 'failed' | 'consolidated';
  createdAt: Date;
  sentAt?: Date;
  error?: string;
  retryCount: number;
  fcmMessageId?: string;
  consolidatedWith?: string[];
}
```

### FCM Message Data
```typescript
{
  type: 'weekly_report',
  reportId: string,
  userUuid: string,
  weekStartDate: string, // ISO string
  weekEndDate: string,   // ISO string
  reportType: string,
}
```

## Configuration

### Android Notification Channel
- **Channel ID**: `weekly_reports`
- **Priority**: High
- **Sound**: Default
- **Icon**: `ic_notification`
- **Color**: `#4CAF50` (Green)

### iOS APNS Configuration
- **Sound**: Default
- **Badge**: Report count
- **Content Available**: True

### Web Push Configuration
- **Icon**: `/icons/Icon-192.png`
- **Badge**: `/icons/Icon-192.png`

## Error Handling

### Common Errors
1. **No FCM Token**: User hasn't granted notification permissions
2. **Invalid Token**: FCM token has expired or is invalid
3. **Rate Limiting**: Too many requests to FCM
4. **Network Issues**: Temporary connectivity problems

### Retry Strategy
- **Attempt 1**: Immediate
- **Attempt 2**: 2 seconds delay
- **Attempt 3**: 4 seconds delay
- **Final**: Mark as failed

### Monitoring
- All errors are logged with context
- Failed notifications are tracked in Firestore
- Statistics API provides failure rates

## Testing

### Unit Tests
```bash
cd functions
npm test -- notificationService.test.ts
```

### Integration Testing
```bash
# Test manual notification
curl -X POST http://localhost:5001/your-project/asia-northeast3/sendManualNotification \
  -H "Content-Type: application/json" \
  -d '{"reportId":"test","userUuid":"test","weekStartDate":"2024-01-07","weekEndDate":"2024-01-13"}'
```

### Emulator Testing
```bash
cd functions
npm run serve
# Functions will be available at http://localhost:5001
```

## Performance Considerations

### Scalability
- Functions are configured with appropriate memory limits
- Batch processing for cleanup operations
- Rate limiting for FCM API calls

### Cost Optimization
- Notification consolidation reduces FCM usage
- Automatic cleanup prevents storage bloat
- Efficient Firestore queries with proper indexing

### Monitoring
- Cloud Functions logs for debugging
- Firestore metrics for performance tracking
- FCM delivery reports for success rates

## Security

### Access Control
- Functions run with Firebase Admin privileges
- User data access is limited to necessary fields
- FCM tokens are securely stored in Firestore

### Data Privacy
- Notification content is localized but generic
- Personal data is not included in notification payloads
- Cleanup jobs remove old tracking data

## Deployment

### Prerequisites
- Firebase project with Cloud Functions enabled
- FCM configured for Android/iOS/Web
- Firestore security rules updated

### Deploy Commands
```bash
cd functions
npm run build
firebase deploy --only functions:sendReportNotification
firebase deploy --only functions:sendManualNotification
firebase deploy --only functions:getNotificationStats
firebase deploy --only functions:cleanupNotifications
```

### Environment Variables
No additional environment variables required. Uses Firebase Admin SDK defaults.

## Troubleshooting

### Common Issues

1. **Notifications not received**
   - Check FCM token in user document
   - Verify notification permissions
   - Check Cloud Functions logs

2. **Korean text not displaying**
   - Ensure UTF-8 encoding
   - Check device language settings
   - Verify FCM message format

3. **Consolidation not working**
   - Check time window configuration
   - Verify Firestore queries
   - Review notification status records

### Debug Commands
```bash
# Check function logs
firebase functions:log --only sendReportNotification

# Test notification manually
curl -X POST [function-url]/sendManualNotification -d '...'

# Get notification statistics
curl "[function-url]/getNotificationStats?startDate=2024-01-01"
```