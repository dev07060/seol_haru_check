/**
 * Notification Service
 *
 * Handles FCM notification sending, message composition, and notification
 * status tracking for weekly AI analysis reports.
 */

import { getFirestore } from "firebase-admin/firestore";
import { getMessaging } from "firebase-admin/messaging";
import * as logger from "firebase-functions/logger";

// Lazy initialization to avoid module loading order issues
let db: any = null;
let messaging: any = null;

function getDb() {
  if (!db) {
    db = getFirestore();
  }
  return db;
}

function getMessagingInstance() {
  if (!messaging) {
    messaging = getMessaging();
  }
  return messaging;
}

/**
 * Interface for notification payload
 */
export interface NotificationPayload {
  userUuid: string;
  reportId: string;
  weekStartDate: Date;
  weekEndDate: Date;
  reportType: "ai_analysis" | "motivational" | "basic";
  nickname?: string;
}

/**
 * Interface for notification status tracking
 */
export interface NotificationStatus {
  id: string;
  userUuid: string;
  reportId: string;
  status: "pending" | "sent" | "failed" | "consolidated";
  createdAt: Date;
  sentAt?: Date;
  error?: string;
  retryCount: number;
  fcmMessageId?: string;
  consolidatedWith?: string[];
}

/**
 * Interface for FCM message composition
 */
export interface FCMMessageComposition {
  title: string;
  body: string;
  data: Record<string, string>;
  android?: {
    priority: "normal" | "high";
    notification: {
      icon: string;
      color: string;
      sound: string;
      channelId: string;
    };
  };
  apns?: {
    payload: {
      aps: {
        sound: string;
        badge?: number;
      };
    };
  };
  webpush?: {
    notification: {
      icon: string;
      badge: string;
    };
  };
}

/**
 * Notification Service Class
 */
export class NotificationService {
  private static readonly MAX_RETRIES = 3;
  private static readonly RETRY_DELAY_BASE = 1000; // 1 second
  private static readonly CONSOLIDATION_WINDOW = 5 * 60 * 1000; // 5 minutes

  /**
     * Send notification for a weekly report
     */
  static async sendReportNotification(payload: NotificationPayload): Promise<string> {
    logger.info("Sending report notification", {
      userUuid: payload.userUuid,
      reportId: payload.reportId,
      reportType: payload.reportType,
    });

    try {
      // Check for existing pending notifications for consolidation
      const consolidationResult = await this.checkForConsolidation(payload);

      if (consolidationResult.shouldConsolidate) {
        logger.info("Consolidating notification", {
          userUuid: payload.userUuid,
          reportId: payload.reportId,
          consolidatedWith: consolidationResult.existingNotifications,
        });

        return await this.sendConsolidatedNotification(
          payload,
          consolidationResult.existingNotifications
        );
      }

      // Create notification status record
      const notificationId = await this.createNotificationStatus(payload);

      // Get user's FCM token
      const fcmToken = await this.getUserFCMToken(payload.userUuid);

      if (!fcmToken) {
        const errorMessage = `사용자 ${payload.userUuid}의 FCM 토큰을 찾을 수 없습니다.`;
        await this.updateNotificationStatus(notificationId, {
          status: "failed",
          error: errorMessage,
        });
        logger.warn("FCM token not found", {
          userUuid: payload.userUuid,
          reportId: payload.reportId,
        });
        throw new Error(errorMessage);
      }

      // Compose FCM message
      const message = await this.composeFCMMessage(payload, fcmToken);

      // Send notification with retry logic
      const messageId = await this.sendWithRetry(message, notificationId);

      // Update notification status
      await this.updateNotificationStatus(notificationId, {
        status: "sent",
        sentAt: new Date(),
        fcmMessageId: messageId,
      });

      logger.info("Report notification sent successfully", {
        userUuid: payload.userUuid,
        reportId: payload.reportId,
        notificationId,
        messageId,
      });

      return notificationId;
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : String(error);
      logger.error("Failed to send report notification", {
        userUuid: payload.userUuid,
        reportId: payload.reportId,
        error: errorMessage,
        stack: error instanceof Error ? error.stack : undefined,
      });

      // Provide user-friendly error messages
      let userFriendlyMessage = "알림 전송에 실패했습니다.";

      if (errorMessage.includes("token") || errorMessage.includes("registration")) {
        userFriendlyMessage = "알림 토큰이 유효하지 않습니다.";
      } else if (errorMessage.includes("quota") || errorMessage.includes("limit")) {
        userFriendlyMessage = "알림 전송 한도가 초과되었습니다.";
      } else if (errorMessage.includes("network") || errorMessage.includes("connection")) {
        userFriendlyMessage = "네트워크 연결 문제로 알림 전송에 실패했습니다.";
      } else if (errorMessage.includes("permission")) {
        userFriendlyMessage = "알림 전송 권한이 없습니다.";
      }

      const enhancedError = new Error(`${userFriendlyMessage}: ${errorMessage}`);
      enhancedError.name = "NotificationError";
      throw enhancedError;
    }
  }

  /**
     * Check if notification should be consolidated with existing pending notifications
     */
  private static async checkForConsolidation(
    payload: NotificationPayload
  ): Promise<{
    shouldConsolidate: boolean;
    existingNotifications: string[];
  }> {
    const cutoffTime = new Date(Date.now() - this.CONSOLIDATION_WINDOW);

    const pendingNotifications = await getDb()
      .collection("notificationStatus")
      .where("userUuid", "==", payload.userUuid)
      .where("status", "==", "pending")
      .where("createdAt", ">", cutoffTime)
      .get();

    const existingNotifications = pendingNotifications.docs.map((doc: any) => doc.id);

    return {
      shouldConsolidate: existingNotifications.length > 0,
      existingNotifications,
    };
  }

  /**
     * Send consolidated notification for multiple reports
     */
  private static async sendConsolidatedNotification(
    payload: NotificationPayload,
    existingNotificationIds: string[]
  ): Promise<string> {
    // Create new consolidated notification status
    const notificationId = await this.createNotificationStatus(payload);

    // Get user's FCM token
    const fcmToken = await this.getUserFCMToken(payload.userUuid);

    if (!fcmToken) {
      await this.updateNotificationStatus(notificationId, {
        status: "failed",
        error: "No FCM token found for user",
      });
      throw new Error(`No FCM token found for user ${payload.userUuid}`);
    }

    // Compose consolidated message
    const message = await this.composeConsolidatedFCMMessage(
      payload,
      fcmToken,
      existingNotificationIds.length + 1
    );

    // Send notification
    const messageId = await this.sendWithRetry(message, notificationId);

    // Update all notification statuses
    const batch = getDb().batch();

    // Update new notification
    batch.update(getDb().collection("notificationStatus").doc(notificationId), {
      status: "sent",
      sentAt: new Date(),
      fcmMessageId: messageId,
      consolidatedWith: existingNotificationIds,
    });

    // Mark existing notifications as consolidated
    for (const existingId of existingNotificationIds) {
      batch.update(getDb().collection("notificationStatus").doc(existingId), {
        status: "consolidated",
        consolidatedWith: [notificationId],
      });
    }

    await batch.commit();

    return notificationId;
  }

  /**
     * Create notification status record
     */
  private static async createNotificationStatus(
    payload: NotificationPayload
  ): Promise<string> {
    const notificationRef = getDb().collection("notificationStatus").doc();

    const status: Omit<NotificationStatus, "id"> = {
      userUuid: payload.userUuid,
      reportId: payload.reportId,
      status: "pending",
      createdAt: new Date(),
      retryCount: 0,
    };

    await notificationRef.set(status);
    return notificationRef.id;
  }

  /**
     * Update notification status
     */
  private static async updateNotificationStatus(
    notificationId: string,
    updates: Partial<NotificationStatus>
  ): Promise<void> {
    await getDb().collection("notificationStatus").doc(notificationId).update(updates);
  }

  /**
     * Get user's FCM token from Firestore
     */
  private static async getUserFCMToken(userUuid: string): Promise<string | null> {
    try {
      const userDoc = await getDb().collection("users").doc(userUuid).get();

      if (!userDoc.exists) {
        logger.warn("User document not found", { userUuid });
        return null;
      }

      const userData = userDoc.data();
      return userData?.fcmToken || null;
    } catch (error) {
      logger.error("Failed to get user FCM token", {
        userUuid,
        error: error instanceof Error ? error.message : String(error),
      });
      return null;
    }
  }

  /**
     * Compose FCM message with Korean localization
     */
  private static async composeFCMMessage(
    payload: NotificationPayload,
    fcmToken: string
  ): Promise<any> {
    const { title, body } = this.getLocalizedMessages(payload);

    const message: FCMMessageComposition = {
      title,
      body,
      data: {
        type: "weekly_report",
        reportId: payload.reportId,
        userUuid: payload.userUuid,
        weekStartDate: payload.weekStartDate.toISOString(),
        weekEndDate: payload.weekEndDate.toISOString(),
        reportType: payload.reportType,
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

    return {
      token: fcmToken,
      notification: {
        title: message.title,
        body: message.body,
      },
      data: message.data,
      android: message.android,
      apns: message.apns,
      webpush: message.webpush,
    };
  }

  /**
     * Compose consolidated FCM message for multiple reports
     */
  private static async composeConsolidatedFCMMessage(
    payload: NotificationPayload,
    fcmToken: string,
    reportCount: number
  ): Promise<any> {
    const title = "새로운 주간 리포트들이 준비되었습니다! 📊";
    const body = `${reportCount}개의 주간 분석 리포트를 확인해보세요!`;

    return {
      token: fcmToken,
      notification: {
        title,
        body,
      },
      data: {
        type: "weekly_report_consolidated",
        reportId: payload.reportId,
        userUuid: payload.userUuid,
        reportCount: reportCount.toString(),
        weekStartDate: payload.weekStartDate.toISOString(),
        weekEndDate: payload.weekEndDate.toISOString(),
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
            badge: reportCount,
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
  }

  /**
     * Get localized messages based on report type
     */
  private static getLocalizedMessages(payload: NotificationPayload): {
    title: string;
    body: string;
  } {
    const weekStart = payload.weekStartDate.toLocaleDateString("ko-KR", {
      month: "long",
      day: "numeric",
    });
    const weekEnd = payload.weekEndDate.toLocaleDateString("ko-KR", {
      month: "long",
      day: "numeric",
    });

    switch (payload.reportType) {
      case "ai_analysis":
        return {
          title: "주간 분석 리포트가 준비되었습니다! 📊",
          body: `${weekStart}~${weekEnd} 운동과 식단 활동을 AI가 분석했어요. 확인해보세요!`,
        };

      case "motivational":
        return {
          title: "더 꾸준한 인증이 필요해요! 💪",
          body: `${weekStart}~${weekEnd} 인증이 부족했어요. 다음 주에는 더 열심히 해보세요!`,
        };

      case "basic":
        return {
          title: "건강한 습관을 시작해보세요! 🌟",
          body: `${weekStart}~${weekEnd} 운동과 식단 인증으로 건강한 라이프스타일을 만들어가요!`,
        };

      default:
        return {
          title: "주간 리포트가 준비되었습니다! 📊",
          body: `${weekStart}~${weekEnd} 활동 리포트를 확인해보세요!`,
        };
    }
  }

  /**
     * Send FCM message with retry logic
     */
  private static async sendWithRetry(
    message: any,
    notificationId: string
  ): Promise<string> {
    let lastError: Error | null = null;

    for (let attempt = 1; attempt <= this.MAX_RETRIES; attempt++) {
      try {
        logger.info("Attempting to send FCM message", {
          notificationId,
          attempt,
          maxRetries: this.MAX_RETRIES,
        });

        const response = await getMessagingInstance().send(message);

        logger.info("FCM message sent successfully", {
          notificationId,
          messageId: response,
          attempt,
        });

        return response;
      } catch (error) {
        lastError = error instanceof Error ? error : new Error(String(error));

        logger.warn("FCM message send attempt failed", {
          notificationId,
          attempt,
          error: lastError.message,
        });

        // Update retry count
        await this.updateNotificationStatus(notificationId, {
          retryCount: attempt,
        });

        // If this is not the last attempt, wait before retrying
        if (attempt < this.MAX_RETRIES) {
          const delay = this.RETRY_DELAY_BASE * Math.pow(2, attempt - 1);
          await new Promise((resolve) => setTimeout(resolve, delay));
        }
      }
    }

    // All retries failed
    await this.updateNotificationStatus(notificationId, {
      status: "failed",
      error: lastError?.message || "Unknown error",
    });

    throw lastError || new Error("Failed to send FCM message after all retries");
  }

  /**
     * Get notification statistics for monitoring
     */
  static async getNotificationStats(
    startDate: Date,
    endDate: Date
  ): Promise<{
    total: number;
    sent: number;
    failed: number;
    consolidated: number;
    pending: number;
  }> {
    const snapshot = await getDb()
      .collection("notificationStatus")
      .where("createdAt", ">=", startDate)
      .where("createdAt", "<=", endDate)
      .get();

    const stats = {
      total: snapshot.size,
      sent: 0,
      failed: 0,
      consolidated: 0,
      pending: 0,
    };

    snapshot.docs.forEach((doc: any) => {
      const data = doc.data();
      switch (data.status) {
        case "sent":
          stats.sent++;
          break;
        case "failed":
          stats.failed++;
          break;
        case "consolidated":
          stats.consolidated++;
          break;
        case "pending":
          stats.pending++;
          break;
      }
    });

    return stats;
  }

  /**
     * Cleanup old notification status records
     */
  static async cleanupOldNotifications(olderThanDays = 30): Promise<number> {
    const cutoffDate = new Date();
    cutoffDate.setDate(cutoffDate.getDate() - olderThanDays);

    const snapshot = await getDb()
      .collection("notificationStatus")
      .where("createdAt", "<", cutoffDate)
      .limit(500) // Process in batches
      .get();

    if (snapshot.empty) {
      return 0;
    }

    const batch = getDb().batch();
    snapshot.docs.forEach((doc: any) => {
      batch.delete(doc.ref);
    });

    await batch.commit();

    logger.info("Cleaned up old notification records", {
      count: snapshot.size,
      cutoffDate: cutoffDate.toISOString(),
    });

    return snapshot.size;
  }
}
