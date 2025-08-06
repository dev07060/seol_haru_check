/**
 * Metadata Extraction Monitoring and Analytics
 *
 * This module provides comprehensive monitoring, metrics collection, and analytics
 * for the AI metadata extraction feature. It tracks success rates, processing times,
 * API usage, error rates, and provides alerting for operational issues.
 */

import { getFirestore } from "firebase-admin/firestore";
import * as logger from "firebase-functions/logger";
import { onRequest } from "firebase-functions/v2/https";
import { onSchedule } from "firebase-functions/v2/scheduler";

// Lazy initialization to avoid module loading order issues
let db: any = null;
function getDb() {
    if (!db) {
        db = getFirestore();
    }
    return db;
}

/**
 * Metadata extraction metrics interface
 */
interface MetadataExtractionMetrics {
    timestamp: Date;
    totalExtractions: number;
    successfulExtractions: number;
    failedExtractions: number;
    successRate: number;
    averageProcessingTime: number;
    exerciseExtractions: number;
    dietExtractions: number;
    apiUsage: {
        totalRequests: number;
        totalTokensUsed: number;
        averageTokensPerRequest: number;
        estimatedCost: number;
    };
    errorBreakdown: {
        imageProcessingErrors: number;
        aiServiceErrors: number;
        parsingErrors: number;
        unknownErrors: number;
    };
    performanceMetrics: {
        averageImageProcessingTime: number;
        averageAiResponseTime: number;
        averageParsingTime: number;
    };
}

/**
 * Alert configuration for metadata extraction
 */
interface MetadataExtractionAlert {
    name: string;
    condition: (metrics: MetadataExtractionMetrics) => boolean;
    severity: "low" | "medium" | "high" | "critical";
    message: string;
    cooldownMinutes: number;
}

/**
 * Structured logging helper for metadata extraction events
 */
export class MetadataExtractionLogger {
    /**
     * Log metadata extraction start
     */
    static logExtractionStart(certificationId: string, type: "운동" | "식단", photoUrl: string): void {
        logger.info("Metadata extraction started", {
            event: "metadata_extraction_start",
            certificationId,
            type,
            photoUrl,
            timestamp: new Date().toISOString(),
        });
    }

    /**
     * Log successful metadata extraction
     */
    static logExtractionSuccess(
        certificationId: string,
        type: "운동" | "식단",
        processingTimeMs: number,
        metadata: any,
        aiMetadata?: any
    ): void {
        logger.info("Metadata extraction completed successfully", {
            event: "metadata_extraction_success",
            certificationId,
            type,
            processingTimeMs,
            metadata,
            aiMetadata,
            timestamp: new Date().toISOString(),
        });

        // Store success metrics in Firestore for aggregation
        this.storeExtractionMetric({
            certificationId,
            type,
            status: "success",
            processingTimeMs,
            metadata,
            aiMetadata,
            timestamp: new Date(),
        });
    }

    /**
     * Log failed metadata extraction
     */
    static logExtractionFailure(
        certificationId: string,
        type: "운동" | "식단",
        errorType: "image_processing" | "ai_service" | "parsing" | "unknown",
        errorMessage: string,
        processingTimeMs?: number
    ): void {
        logger.error("Metadata extraction failed", {
            event: "metadata_extraction_failure",
            certificationId,
            type,
            errorType,
            errorMessage,
            processingTimeMs,
            timestamp: new Date().toISOString(),
        });

        // Store failure metrics in Firestore for aggregation
        this.storeExtractionMetric({
            certificationId,
            type,
            status: "failure",
            errorType,
            errorMessage,
            processingTimeMs,
            timestamp: new Date(),
        });
    }

    /**
     * Log API usage metrics
     */
    static logApiUsage(
        certificationId: string,
        requestType: "exercise" | "diet",
        tokensUsed: number,
        responseTimeMs: number,
        estimatedCost: number
    ): void {
        logger.info("AI API usage recorded", {
            event: "api_usage",
            certificationId,
            requestType,
            tokensUsed,
            responseTimeMs,
            estimatedCost,
            timestamp: new Date().toISOString(),
        });

        // Store API usage metrics
        this.storeApiUsageMetric({
            certificationId,
            requestType,
            tokensUsed,
            responseTimeMs,
            estimatedCost,
            timestamp: new Date(),
        });
    }

    /**
     * Log image processing metrics
     */
    static logImageProcessing(
        certificationId: string,
        originalSizeBytes: number,
        processedSizeBytes: number,
        processingTimeMs: number,
        compressionRatio: number
    ): void {
        logger.info("Image processing completed", {
            event: "image_processing",
            certificationId,
            originalSizeBytes,
            processedSizeBytes,
            processingTimeMs,
            compressionRatio,
            timestamp: new Date().toISOString(),
        });
    }

    /**
     * Store extraction metric in Firestore
     */
    private static async storeExtractionMetric(metric: any): Promise<void> {
        try {
            await getDb().collection("metadataExtractionMetrics").add(metric);
        } catch (error) {
            logger.error("Failed to store extraction metric", { error, metric });
        }
    }

    /**
     * Store API usage metric in Firestore
     */
    private static async storeApiUsageMetric(metric: any): Promise<void> {
        try {
            await getDb().collection("metadataApiUsageMetrics").add(metric);
        } catch (error) {
            logger.error("Failed to store API usage metric", { error, metric });
        }
    }
}

/**
 * Metadata Extraction Metrics Collection
 * Runs every 5 minutes to collect and aggregate metrics
 */
export const collectMetadataExtractionMetrics = onSchedule({
    schedule: "*/5 * * * *", // Every 5 minutes
    timeZone: "Asia/Seoul",
    region: "asia-northeast3",
    memory: "256MiB",
    timeoutSeconds: 60,
}, async (): Promise<void> => {
    try {
        const timestamp = new Date();
        const fiveMinutesAgo = new Date(timestamp.getTime() - 5 * 60 * 1000);

        logger.info("Collecting metadata extraction metrics", {
            timestamp: timestamp.toISOString(),
            periodStart: fiveMinutesAgo.toISOString(),
        });

        // Collect extraction metrics from the last 5 minutes
        const extractionMetricsSnapshot = await getDb()
            .collection("metadataExtractionMetrics")
            .where("timestamp", ">=", fiveMinutesAgo)
            .get();

        // Collect API usage metrics from the last 5 minutes
        const apiUsageMetricsSnapshot = await getDb()
            .collection("metadataApiUsageMetrics")
            .where("timestamp", ">=", fiveMinutesAgo)
            .get();

        // Process extraction metrics
        const extractionMetrics = extractionMetricsSnapshot.docs.map(doc => doc.data());
        const totalExtractions = extractionMetrics.length;
        const successfulExtractions = extractionMetrics.filter(m => m.status === "success").length;
        const failedExtractions = totalExtractions - successfulExtractions;
        const successRate = totalExtractions > 0 ? (successfulExtractions / totalExtractions) * 100 : 0;

        // Calculate average processing time
        const processingTimes = extractionMetrics
            .filter(m => m.processingTimeMs)
            .map(m => m.processingTimeMs);
        const averageProcessingTime = processingTimes.length > 0 ?
            processingTimes.reduce((sum, time) => sum + time, 0) / processingTimes.length : 0;

        // Count by type
        const exerciseExtractions = extractionMetrics.filter(m => m.type === "운동").length;
        const dietExtractions = extractionMetrics.filter(m => m.type === "식단").length;

        // Process API usage metrics
        const apiUsageMetrics = apiUsageMetricsSnapshot.docs.map(doc => doc.data());
        const totalApiRequests = apiUsageMetrics.length;
        const totalTokensUsed = apiUsageMetrics.reduce((sum, m) => sum + (m.tokensUsed || 0), 0);
        const averageTokensPerRequest = totalApiRequests > 0 ? totalTokensUsed / totalApiRequests : 0;
        const estimatedCost = apiUsageMetrics.reduce((sum, m) => sum + (m.estimatedCost || 0), 0);

        // Calculate error breakdown
        const errorBreakdown = {
            imageProcessingErrors: extractionMetrics.filter(m => m.errorType === "image_processing").length,
            aiServiceErrors: extractionMetrics.filter(m => m.errorType === "ai_service").length,
            parsingErrors: extractionMetrics.filter(m => m.errorType === "parsing").length,
            unknownErrors: extractionMetrics.filter(m => m.errorType === "unknown").length,
        };

        // Calculate performance metrics (placeholder - would need more detailed timing data)
        const performanceMetrics = {
            averageImageProcessingTime: 0, // Would be calculated from detailed logs
            averageAiResponseTime: apiUsageMetrics.length > 0 ?
                apiUsageMetrics.reduce((sum, m) => sum + (m.responseTimeMs || 0), 0) / apiUsageMetrics.length : 0,
            averageParsingTime: 0, // Would be calculated from detailed logs
        };

        // Create comprehensive metrics object
        const metrics: MetadataExtractionMetrics = {
            timestamp,
            totalExtractions,
            successfulExtractions,
            failedExtractions,
            successRate,
            averageProcessingTime,
            exerciseExtractions,
            dietExtractions,
            apiUsage: {
                totalRequests: totalApiRequests,
                totalTokensUsed,
                averageTokensPerRequest,
                estimatedCost,
            },
            errorBreakdown,
            performanceMetrics,
        };

        // Store aggregated metrics
        await getDb().collection("metadataExtractionAggregatedMetrics").add(metrics);

        logger.info("Metadata extraction metrics collected successfully", {
            metrics,
            period: "5min",
        });

        // Check alert conditions
        await checkMetadataExtractionAlerts(metrics);

    } catch (error) {
        logger.error("Failed to collect metadata extraction metrics", {
            error: error instanceof Error ? error.message : String(error),
            stack: error instanceof Error ? error.stack : undefined,
        });
    }
});

/**
 * Alert rules for metadata extraction monitoring
 */
const METADATA_EXTRACTION_ALERT_RULES: MetadataExtractionAlert[] = [
    {
        name: "high_failure_rate",
        condition: (metrics) => {
            return metrics.totalExtractions > 5 && metrics.successRate < 70;
        },
        severity: "high",
        message: "High failure rate detected in metadata extraction",
        cooldownMinutes: 15,
    },
    {
        name: "no_extractions",
        condition: (metrics) => {
            return metrics.totalExtractions === 0;
        },
        severity: "medium",
        message: "No metadata extractions processed in the last 5 minutes",
        cooldownMinutes: 30,
    },
    {
        name: "high_api_cost",
        condition: (metrics) => {
            return metrics.apiUsage.estimatedCost > 10; // $10 in 5 minutes
        },
        severity: "high",
        message: "High API costs detected for metadata extraction",
        cooldownMinutes: 10,
    },
    {
        name: "slow_processing",
        condition: (metrics) => {
            return metrics.averageProcessingTime > 30000; // 30 seconds
        },
        severity: "medium",
        message: "Slow metadata extraction processing detected",
        cooldownMinutes: 20,
    },
    {
        name: "high_image_processing_errors",
        condition: (metrics) => {
            return metrics.errorBreakdown.imageProcessingErrors > 3;
        },
        severity: "medium",
        message: "High number of image processing errors",
        cooldownMinutes: 15,
    },
    {
        name: "high_ai_service_errors",
        condition: (metrics) => {
            return metrics.errorBreakdown.aiServiceErrors > 5;
        },
        severity: "high",
        message: "High number of AI service errors - possible API quota issues",
        cooldownMinutes: 10,
    },
];

/**
 * Check alert conditions for metadata extraction
 */
async function checkMetadataExtractionAlerts(metrics: MetadataExtractionMetrics): Promise<void> {
    try {
        const now = new Date();

        for (const rule of METADATA_EXTRACTION_ALERT_RULES) {
            if (rule.condition(metrics)) {
                // Check if alert is in cooldown
                const recentAlertSnapshot = await getDb()
                    .collection("metadataExtractionAlerts")
                    .where("ruleName", "==", rule.name)
                    .where("timestamp", ">=", new Date(now.getTime() - rule.cooldownMinutes * 60 * 1000))
                    .limit(1)
                    .get();

                if (recentAlertSnapshot.empty) {
                    // Create new alert
                    await getDb().collection("metadataExtractionAlerts").add({
                        ruleName: rule.name,
                        severity: rule.severity,
                        message: rule.message,
                        timestamp: now,
                        metrics,
                        status: "active",
                    });

                    // Log alert with appropriate level
                    const logLevel = rule.severity === "critical" ? "error" :
                        rule.severity === "high" ? "error" :
                            rule.severity === "medium" ? "warn" : "info";

                    logger[logLevel](`METADATA EXTRACTION ALERT: ${rule.message}`, {
                        ruleName: rule.name,
                        severity: rule.severity,
                        metrics,
                    });

                    // Send notification
                    await sendMetadataExtractionAlert(rule, metrics);
                }
            }
        }
    } catch (error) {
        logger.error("Failed to check metadata extraction alerts", {
            error: error instanceof Error ? error.message : String(error),
        });
    }
}

/**
 * Send metadata extraction alert notification
 */
async function sendMetadataExtractionAlert(
    rule: MetadataExtractionAlert,
    metrics: MetadataExtractionMetrics
): Promise<void> {
    try {
        // Store notification in database
        await getDb().collection("metadataExtractionNotifications").add({
            type: "alert",
            ruleName: rule.name,
            severity: rule.severity,
            message: rule.message,
            timestamp: new Date(),
            metrics,
            sent: false,
        });

        logger.info(`Metadata extraction alert notification queued: ${rule.name}`, {
            severity: rule.severity,
            message: rule.message,
            successRate: metrics.successRate,
            totalExtractions: metrics.totalExtractions,
        });
    } catch (error) {
        logger.error("Failed to send metadata extraction alert notification", {
            error,
            rule,
        });
    }
}

/**
 * Metadata Extraction Analytics Dashboard Endpoint
 * Provides comprehensive analytics data for monitoring dashboard
 */
export const getMetadataExtractionAnalytics = onRequest({
    region: "asia-northeast3",
    memory: "256MiB",
    timeoutSeconds: 30,
}, async (request, response) => {
    try {
        const timeRange = request.query.timeRange as string || "24h";
        const now = new Date();
        let startTime: Date;

        // Calculate time range
        switch (timeRange) {
            case "1h":
                startTime = new Date(now.getTime() - 60 * 60 * 1000);
                break;
            case "6h":
                startTime = new Date(now.getTime() - 6 * 60 * 60 * 1000);
                break;
            case "24h":
                startTime = new Date(now.getTime() - 24 * 60 * 60 * 1000);
                break;
            case "7d":
                startTime = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
                break;
            default:
                startTime = new Date(now.getTime() - 24 * 60 * 60 * 1000);
        }

        // Get aggregated metrics for the time range
        const metricsSnapshot = await getDb()
            .collection("metadataExtractionAggregatedMetrics")
            .where("timestamp", ">=", startTime)
            .orderBy("timestamp", "desc")
            .get();

        const metrics = metricsSnapshot.docs.map(doc => doc.data());

        // Calculate summary statistics
        const totalExtractions = metrics.reduce((sum, m) => sum + m.totalExtractions, 0);
        const totalSuccessful = metrics.reduce((sum, m) => sum + m.successfulExtractions, 0);
        const totalFailed = metrics.reduce((sum, m) => sum + m.failedExtractions, 0);
        const overallSuccessRate = totalExtractions > 0 ? (totalSuccessful / totalExtractions) * 100 : 0;

        const totalApiRequests = metrics.reduce((sum, m) => sum + m.apiUsage.totalRequests, 0);
        const totalTokensUsed = metrics.reduce((sum, m) => sum + m.apiUsage.totalTokensUsed, 0);
        const totalEstimatedCost = metrics.reduce((sum, m) => sum + m.apiUsage.estimatedCost, 0);

        // Get recent alerts
        const alertsSnapshot = await getDb()
            .collection("metadataExtractionAlerts")
            .where("timestamp", ">=", startTime)
            .orderBy("timestamp", "desc")
            .limit(10)
            .get();

        const recentAlerts = alertsSnapshot.docs.map(doc => ({
            id: doc.id,
            ...doc.data(),
        }));

        // Calculate error breakdown
        const errorBreakdown = {
            imageProcessingErrors: metrics.reduce((sum, m) => sum + m.errorBreakdown.imageProcessingErrors, 0),
            aiServiceErrors: metrics.reduce((sum, m) => sum + m.errorBreakdown.aiServiceErrors, 0),
            parsingErrors: metrics.reduce((sum, m) => sum + m.errorBreakdown.parsingErrors, 0),
            unknownErrors: metrics.reduce((sum, m) => sum + m.errorBreakdown.unknownErrors, 0),
        };

        // Prepare analytics response
        const analytics = {
            timeRange,
            period: {
                start: startTime.toISOString(),
                end: now.toISOString(),
            },
            summary: {
                totalExtractions,
                successfulExtractions: totalSuccessful,
                failedExtractions: totalFailed,
                successRate: Math.round(overallSuccessRate * 100) / 100,
                exerciseExtractions: metrics.reduce((sum, m) => sum + m.exerciseExtractions, 0),
                dietExtractions: metrics.reduce((sum, m) => sum + m.dietExtractions, 0),
            },
            apiUsage: {
                totalRequests: totalApiRequests,
                totalTokensUsed,
                averageTokensPerRequest: totalApiRequests > 0 ? Math.round(totalTokensUsed / totalApiRequests) : 0,
                estimatedCost: Math.round(totalEstimatedCost * 100) / 100,
            },
            errorBreakdown,
            performance: {
                averageProcessingTime: metrics.length > 0 ?
                    Math.round(metrics.reduce((sum, m) => sum + m.averageProcessingTime, 0) / metrics.length) : 0,
            },
            alerts: {
                total: recentAlerts.length,
                critical: recentAlerts.filter(a => a.severity === "critical").length,
                high: recentAlerts.filter(a => a.severity === "high").length,
                medium: recentAlerts.filter(a => a.severity === "medium").length,
                low: recentAlerts.filter(a => a.severity === "low").length,
                recent: recentAlerts.slice(0, 5),
            },
            timeSeries: metrics.reverse(), // Chronological order for charts
        };

        response.status(200).json({
            success: true,
            data: analytics,
            timestamp: now.toISOString(),
        });

        logger.info("Metadata extraction analytics retrieved successfully", {
            timeRange,
            totalExtractions,
            successRate: overallSuccessRate,
            alertCount: recentAlerts.length,
        });

    } catch (error) {
        logger.error("Failed to get metadata extraction analytics", {
            error: error instanceof Error ? error.message : String(error),
            stack: error instanceof Error ? error.stack : undefined,
        });

        response.status(500).json({
            success: false,
            error: error instanceof Error ? error.message : String(error),
            timestamp: new Date().toISOString(),
        });
    }
});

/**
 * Cleanup old metrics data
 * Runs daily to remove old metrics data to prevent storage bloat
 */
export const cleanupMetadataExtractionMetrics = onSchedule({
    schedule: "0 2 * * *", // Daily at 2 AM KST
    timeZone: "Asia/Seoul",
    region: "asia-northeast3",
    memory: "256MiB",
    timeoutSeconds: 300,
}, async (): Promise<void> => {
    try {
        const retentionDays = 30; // Keep 30 days of detailed metrics
        const cutoffDate = new Date(Date.now() - retentionDays * 24 * 60 * 60 * 1000);

        logger.info("Starting metadata extraction metrics cleanup", {
            cutoffDate: cutoffDate.toISOString(),
            retentionDays,
        });

        // Cleanup detailed extraction metrics
        const extractionMetricsQuery = getDb()
            .collection("metadataExtractionMetrics")
            .where("timestamp", "<", cutoffDate);

        const extractionMetricsSnapshot = await extractionMetricsQuery.get();
        const extractionBatch = getDb().batch();

        extractionMetricsSnapshot.docs.forEach(doc => {
            extractionBatch.delete(doc.ref);
        });

        if (extractionMetricsSnapshot.size > 0) {
            await extractionBatch.commit();
            logger.info(`Deleted ${extractionMetricsSnapshot.size} old extraction metrics`);
        }

        // Cleanup API usage metrics
        const apiUsageMetricsQuery = getDb()
            .collection("metadataApiUsageMetrics")
            .where("timestamp", "<", cutoffDate);

        const apiUsageMetricsSnapshot = await apiUsageMetricsQuery.get();
        const apiUsageBatch = getDb().batch();

        apiUsageMetricsSnapshot.docs.forEach(doc => {
            apiUsageBatch.delete(doc.ref);
        });

        if (apiUsageMetricsSnapshot.size > 0) {
            await apiUsageBatch.commit();
            logger.info(`Deleted ${apiUsageMetricsSnapshot.size} old API usage metrics`);
        }

        // Keep aggregated metrics longer (90 days)
        const aggregatedCutoffDate = new Date(Date.now() - 90 * 24 * 60 * 60 * 1000);
        const aggregatedMetricsQuery = getDb()
            .collection("metadataExtractionAggregatedMetrics")
            .where("timestamp", "<", aggregatedCutoffDate);

        const aggregatedMetricsSnapshot = await aggregatedMetricsQuery.get();
        const aggregatedBatch = getDb().batch();

        aggregatedMetricsSnapshot.docs.forEach(doc => {
            aggregatedBatch.delete(doc.ref);
        });

        if (aggregatedMetricsSnapshot.size > 0) {
            await aggregatedBatch.commit();
            logger.info(`Deleted ${aggregatedMetricsSnapshot.size} old aggregated metrics`);
        }

        logger.info("Metadata extraction metrics cleanup completed successfully");

    } catch (error) {
        logger.error("Failed to cleanup metadata extraction metrics", {
            error: error instanceof Error ? error.message : String(error),
            stack: error instanceof Error ? error.stack : undefined,
        });
    }
});