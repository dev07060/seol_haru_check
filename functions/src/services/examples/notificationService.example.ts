/**
 * Notification Service Usage Examples
 *
 * This file demonstrates how to use the NotificationService for sending
 * weekly report notifications with Korean localization and consolidation.
 */

import {NotificationService} from "../notificationService";

/**
 * Example 1: Send notification for AI analysis report
 */
export async function sendAIAnalysisNotification() {
  const payload = {
    userUuid: "user123",
    reportId: "report456",
    weekStartDate: new Date("2024-01-07"), // Sunday
    weekEndDate: new Date("2024-01-13"), // Saturday
    reportType: "ai_analysis" as const,
    nickname: "김철수",
  };

  try {
    const notificationId = await NotificationService.sendReportNotification(payload);
    console.log("Notification sent:", notificationId);
  } catch (error) {
    console.error("Failed to send notification:", error);
  }
}

/**
 * Example 2: Send notification for motivational report
 */
export async function sendMotivationalNotification() {
  const payload = {
    userUuid: "user123",
    reportId: "report789",
    weekStartDate: new Date("2024-01-07"),
    weekEndDate: new Date("2024-01-13"),
    reportType: "motivational" as const,
    nickname: "이영희",
  };

  try {
    const notificationId = await NotificationService.sendReportNotification(payload);
    console.log("Motivational notification sent:", notificationId);
  } catch (error) {
    console.error("Failed to send motivational notification:", error);
  }
}

/**
 * Example 3: Get notification statistics
 */
export async function getWeeklyNotificationStats() {
  const endDate = new Date();
  const startDate = new Date(endDate.getTime() - 7 * 24 * 60 * 60 * 1000);

  try {
    const stats = await NotificationService.getNotificationStats(startDate, endDate);
    console.log("Weekly notification stats:", stats);
    /*
        Output example:
        {
          total: 150,
          sent: 142,
          failed: 3,
          consolidated: 4,
          pending: 1
        }
        */
  } catch (error) {
    console.error("Failed to get notification stats:", error);
  }
}

/**
 * Example 4: Cleanup old notifications
 */
export async function cleanupOldNotifications() {
  try {
    const deletedCount = await NotificationService.cleanupOldNotifications(30);
    console.log(`Cleaned up ${deletedCount} old notification records`);
  } catch (error) {
    console.error("Failed to cleanup notifications:", error);
  }
}

/**
 * Example FCM Message Structure
 *
 * This is what the FCM message looks like when sent to the client:
 */
export const exampleFCMMessage = {
  token: "user_fcm_token_here",
  notification: {
    title: "주간 분석 리포트가 준비되었습니다! 📊",
    body: "1월 7일~1월 13일 운동과 식단 활동을 AI가 분석했어요. 확인해보세요!",
  },
  data: {
    type: "weekly_report",
    reportId: "report456",
    userUuid: "user123",
    weekStartDate: "2024-01-07T00:00:00.000Z",
    weekEndDate: "2024-01-13T23:59:59.999Z",
    reportType: "ai_analysis",
  },
  android: {
    priority: "high",
    notification: {
      icon: "ic_notification",
      color: "#4CAF50",
      sound: "default",
      channelId: "weekly_reports",
    },
  },
  apns: {
    payload: {
      aps: {
        sound: "default",
        badge: 1,
      },
    },
  },
  webpush: {
    notification: {
      icon: "/icons/Icon-192.png",
      badge: "/icons/Icon-192.png",
    },
  },
};

/**
 * Example Consolidated FCM Message
 *
 * When multiple reports are ready within the consolidation window:
 */
export const exampleConsolidatedFCMMessage = {
  token: "user_fcm_token_here",
  notification: {
    title: "새로운 주간 리포트들이 준비되었습니다! 📊",
    body: "3개의 주간 분석 리포트를 확인해보세요!",
  },
  data: {
    type: "weekly_report_consolidated",
    reportId: "latest_report_id",
    userUuid: "user123",
    reportCount: "3",
    weekStartDate: "2024-01-07T00:00:00.000Z",
    weekEndDate: "2024-01-13T23:59:59.999Z",
  },
  android: {
    priority: "high",
    notification: {
      icon: "ic_notification",
      color: "#4CAF50",
      sound: "default",
      channelId: "weekly_reports",
    },
  },
  apns: {
    payload: {
      aps: {
        sound: "default",
        badge: 3,
      },
    },
  },
};

/**
 * Example Notification Status Record
 *
 * This is stored in Firestore for tracking notification delivery:
 */
export const exampleNotificationStatus = {
  id: "notification123",
  userUuid: "user123",
  reportId: "report456",
  status: "sent", // 'pending' | 'sent' | 'failed' | 'consolidated'
  createdAt: new Date("2024-01-14T09:00:00Z"),
  sentAt: new Date("2024-01-14T09:00:05Z"),
  retryCount: 0,
  fcmMessageId: "fcm_message_id_from_firebase",
  // Optional fields for consolidated notifications:
  consolidatedWith: ["notification124", "notification125"],
};
