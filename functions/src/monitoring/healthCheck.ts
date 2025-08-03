/**
 * Health Check and Monitoring Functions
 */

import { getFirestore } from "firebase-admin/firestore";
import * as logger from "firebase-functions/logger";
import { onRequest } from "firebase-functions/v2/https";
import { onSchedule } from "firebase-functions/v2/scheduler";
import { vertexAIService } from "../services/vertexAIService";

const db = getFirestore();

/**
 * Health Check Endpoint
 * Provides system health status for monitoring
 */
export const healthCheck = onRequest({
    region: "asia-northeast3",
    memory: "256MiB",
    timeoutSeconds: 30,
}, async (request, response) => {
    const startTime = Date.now();

    try {
        const healthStatus = {
            status: "healthy",
            timestamp: new Date().toISOString(),
            services: {} as any,
            performance: {} as any,
        };

        // Check Firestore connectivity
        try {
            await db.collection("health").doc("test").get();
            healthStatus.services.firestore = "healthy";
        } catch (error) {
            healthStatus.services.firestore = "unhealthy";
            healthStatus.status = "degraded";
            logger.warn("Firestore health check failed", { error });
        }

        // Check VertexAI connectivity
        try {
            const vertexAIHealth = await vertexAIService.testConnection();
            healthStatus.services.vertexai = vertexAIHealth ? "healthy" : "unhealthy";
            if (!vertexAIHealth) {
                healthStatus.status = "degraded";
            }
        } catch (error) {
            healthStatus.services.vertexai = "unhealthy";
            healthStatus.status = "degraded";
            logger.warn("VertexAI health check failed", { error });
        }

        // Performance metrics
        const responseTime = Date.now() - startTime;
        healthStatus.performance = {
            responseTimeMs: responseTime,
            memoryUsage: process.memoryUsage(),
        };

        // Set appropriate HTTP status
        const httpStatus = healthStatus.status === "healthy" ? 200 : 503;

        response.status(httpStatus).json(healthStatus);

        logger.info("Health check completed", {
            status: healthStatus.status,
            responseTime,
            services: healthStatus.services,
        });

    } catch (error) {
        logger.error("Health check failed", { error });
        response.status(500).json({
            status: "unhealthy",
            timestamp: new Date().toISOString(),
            error: error instanceof Error ? error.message : String(error),
        });
    }
});

/**
 * System Metrics Collection
 * Collects and stores system metrics for monitoring
 */
export const collectMetrics = onSchedule({
    schedule: "*/5 * * * *", // Every 5 minutes
    timeZone: "Asia/Seoul",
    region: "asia-northeast3",
    memory: "256MiB",
}, async () => {
    try {
        const timestamp = new Date();

        // Collect queue metrics
        const queueSnapshot = await db.collection("analysisQueue")
            .where("createdAt", ">=", new Date(Date.now() - 24 * 60 * 60 * 1000))
            .get();

        const queueMetrics = {
            total: queueSnapshot.size,
            pending: 0,
            processing: 0,
            completed: 0,
            failed: 0,
        };

        queueSnapshot.docs.forEach(doc => {
            const status = doc.data().status;
            if (status in queueMetrics) {
                queueMetrics[status as keyof typeof queueMetrics]++;
            }
        });

        // Collect report metrics
        const reportsSnapshot = await db.collection("weeklyReports")
            .where("generatedAt", ">=", new Date(Date.now() - 24 * 60 * 60 * 1000))
            .get();

        const reportMetrics = {
            total: reportsSnapshot.size,
            aiGenerated: 0,
            fallbackGenerated: 0,
            motivational: 0,
        };

        reportsSnapshot.docs.forEach(doc => {
            const data = doc.data();
            if (data.generatedBy === "vertexai") reportMetrics.aiGenerated++;
            else if (data.generatedBy === "fallback") reportMetrics.fallbackGenerated++;
            else if (data.type === "motivational") reportMetrics.motivational++;
        });

        // Get VertexAI rate limit status
        const rateLimitStatus = vertexAIService.getRateLimitStatus();

        // Store metrics
        await db.collection("systemMetrics").add({
            timestamp,
            queue: queueMetrics,
            reports: reportMetrics,
            vertexAI: rateLimitStatus,
            memoryUsage: process.memoryUsage(),
        });

        logger.info("System metrics collected", {
            queue: queueMetrics,
            reports: reportMetrics,
            vertexAI: rateLimitStatus,
        });

    } catch (error) {
        logger.error("Failed to collect metrics", { error });
    }
});

/**
 * Alert Check Function
 * Monitors system health and sends alerts when issues are detected
 */
export const checkAlerts = onSchedule({
    schedule: "*/10 * * * *", // Every 10 minutes
    timeZone: "Asia/Seoul",
    region: "asia-northeast3",
    memory: "256MiB",
}, async () => {
    try {
        const now = new Date();
        const tenMinutesAgo = new Date(now.getTime() - 10 * 60 * 1000);

        // Check for stuck queue items
        const stuckQueueSnapshot = await db.collection("analysisQueue")
            .where("status", "==", "processing")
            .where("processedAt", "<=", tenMinutesAgo)
            .get();

        if (!stuckQueueSnapshot.empty) {
            logger.warn(`Found ${stuckQueueSnapshot.size} stuck queue items`, {
                count: stuckQueueSnapshot.size,
                items: stuckQueueSnapshot.docs.map(doc => ({
                    id: doc.id,
                    userUuid: doc.data().userUuid,
                    processedAt: doc.data().processedAt?.toDate?.()?.toISOString(),
                })),
            });

            // Reset stuck items to pending
            const batch = db.batch();
            stuckQueueSnapshot.docs.forEach(doc => {
                batch.update(doc.ref, {
                    status: "pending",
                    processedAt: null,
                    retryCount: (doc.data().retryCount || 0) + 1,
                });
            });
            await batch.commit();
        }

        // Check for high failure rate
        const recentQueueSnapshot = await db.collection("analysisQueue")
            .where("createdAt", ">=", new Date(now.getTime() - 60 * 60 * 1000))
            .get();

        if (recentQueueSnapshot.size > 0) {
            const failedCount = recentQueueSnapshot.docs.filter(
                doc => doc.data().status === "failed"
            ).length;

            const failureRate = failedCount / recentQueueSnapshot.size;

            if (failureRate > 0.5) {
                logger.error("High failure rate detected", {
                    total: recentQueueSnapshot.size,
                    failed: failedCount,
                    failureRate: Math.round(failureRate * 100),
                });
            }
        }

        // Check VertexAI rate limits
        const rateLimitStatus = vertexAIService.getRateLimitStatus();
        if (rateLimitStatus.requestsInLastMinute > rateLimitStatus.maxRequestsPerMinute * 0.9) {
            logger.warn("VertexAI rate limit approaching", rateLimitStatus);
        }

    } catch (error) {
        logger.error("Alert check failed", { error });
    }
});