/**
 * Alert and Notification System for Cloud Functions
 */

import { getFirestore } from "firebase-admin/firestore";
import * as logger from "firebase-functions/logger";
import { onSchedule } from "firebase-functions/v2/scheduler";

// Lazy initialization to avoid module loading order issues
let db: any = null;
function getDb() {
    if (!db) {
        db = getFirestore();
    }
    return db;
}

interface AlertRule {
    name: string;
    condition: (metrics: any) => boolean;
    severity: "low" | "medium" | "high" | "critical";
    message: string;
    cooldownMinutes: number;
}

interface AlertDocument {
    id: string;
    ruleName: string;
    severity: "low" | "medium" | "high" | "critical";
    message: string;
    timestamp: Date;
    status: string;
    metrics?: any;
}

const ALERT_RULES: AlertRule[] = [
    {
        name: "high_failure_rate",
        condition: (metrics) => {
            const total = metrics.queue.total;
            const failed = metrics.queue.failed;
            return total > 10 && (failed / total) > 0.3;
        },
        severity: "high",
        message: "High failure rate detected in analysis queue",
        cooldownMinutes: 30,
    },
    {
        name: "queue_backlog",
        condition: (metrics) => metrics.queue.pending > 50,
        severity: "medium",
        message: "Large backlog in analysis queue",
        cooldownMinutes: 15,
    },
    {
        name: "vertexai_rate_limit",
        condition: (metrics) => {
            const usage = metrics.vertexAI.requestsInLastMinute;
            const limit = metrics.vertexAI.maxRequestsPerMinute;
            return usage > limit * 0.9;
        },
        severity: "medium",
        message: "VertexAI rate limit approaching",
        cooldownMinutes: 10,
    },
    {
        name: "no_reports_generated",
        condition: (metrics) => {
            const recentReports = metrics.reports.total;
            return recentReports === 0;
        },
        severity: "low",
        message: "No reports generated in the last hour",
        cooldownMinutes: 60,
    },
];

/**
 * Alert Processing Function
 * Runs every 5 minutes to check alert conditions
 */
export const processAlerts = onSchedule({
    schedule: "*/5 * * * *", // Every 5 minutes
    timeZone: "Asia/Seoul",
    region: "asia-northeast3",
    memory: "256MiB",
}, async () => {
    try {
        // Get latest metrics
        const metricsSnapshot = await getDb().collection("systemMetrics")
            .orderBy("timestamp", "desc")
            .limit(1)
            .get();

        if (metricsSnapshot.empty) {
            logger.warn("No system metrics found for alert processing");
            return;
        }

        const latestMetrics = metricsSnapshot.docs[0].data();
        const now = new Date();

        // Check each alert rule
        for (const rule of ALERT_RULES) {
            try {
                if (rule.condition(latestMetrics)) {
                    // Check if alert is in cooldown
                    const recentAlertSnapshot = await getDb().collection("alerts")
                        .where("ruleName", "==", rule.name)
                        .where("timestamp", ">=", new Date(now.getTime() - rule.cooldownMinutes * 60 * 1000))
                        .limit(1)
                        .get();

                    if (recentAlertSnapshot.empty) {
                        // Create new alert
                        await getDb().collection("alerts").add({
                            ruleName: rule.name,
                            severity: rule.severity,
                            message: rule.message,
                            timestamp: now,
                            metrics: latestMetrics,
                            status: "active",
                        });

                        // Log alert
                        const logLevel = rule.severity === "critical" ? "error" :
                            rule.severity === "high" ? "error" :
                                rule.severity === "medium" ? "warn" : "info";

                        logger[logLevel](`ALERT: ${rule.message}`, {
                            ruleName: rule.name,
                            severity: rule.severity,
                            metrics: latestMetrics,
                        });

                        // TODO: Send notification (email, Slack, etc.)
                        await sendAlertNotification(rule, latestMetrics);
                    }
                }
            } catch (error) {
                logger.error(`Failed to process alert rule: ${rule.name}`, { error });
            }
        }
    } catch (error) {
        logger.error("Alert processing failed", { error });
    }
});

/**
 * Send alert notification
 */
async function sendAlertNotification(rule: AlertRule, metrics: any): Promise<void> {
    try {
        // Store notification in database for now
        // In production, this would send to Slack, email, etc.
        await getDb().collection("notifications").add({
            type: "alert",
            ruleName: rule.name,
            severity: rule.severity,
            message: rule.message,
            timestamp: new Date(),
            metrics,
            sent: false,
        });

        logger.info(`Alert notification queued: ${rule.name}`, {
            severity: rule.severity,
            message: rule.message,
        });
    } catch (error) {
        logger.error("Failed to send alert notification", { error, rule });
    }
}

/**
 * Alert Dashboard Data
 * Provides alert summary for monitoring dashboard
 */
export const getAlertSummary = async (): Promise<any> => {
    try {
        const last24Hours = new Date(Date.now() - 24 * 60 * 60 * 1000);

        const alertsSnapshot = await getDb().collection("alerts")
            .where("timestamp", ">=", last24Hours)
            .orderBy("timestamp", "desc")
            .get();

        const alerts: AlertDocument[] = alertsSnapshot.docs.map((doc: any) => ({
            id: doc.id,
            ...doc.data(),
        } as AlertDocument));

        const summary = {
            total: alerts.length,
            critical: alerts.filter((a) => a.severity === "critical").length,
            high: alerts.filter((a) => a.severity === "high").length,
            medium: alerts.filter((a) => a.severity === "medium").length,
            low: alerts.filter((a) => a.severity === "low").length,
            active: alerts.filter((a) => a.status === "active").length,
            recent: alerts.slice(0, 10),
        };

        return summary;
    } catch (error) {
        logger.error("Failed to get alert summary", { error });
        throw error;
    }
};
