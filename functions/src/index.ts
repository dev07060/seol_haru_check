/**
 * Weekly AI Analysis Cloud Functions
 *
 * This module contains Cloud Functions for generating weekly AI analysis
 * reports for users based on their exercise and diet certification data.
 */

import type { Request, Response } from "express";
import * as admin from "firebase-admin";
import { initializeApp } from "firebase-admin/app";
import { getFirestore } from "firebase-admin/firestore";
import * as logger from "firebase-functions/logger";
import type { CloudEvent } from "firebase-functions/v2";
import type { FirestoreEvent, QueryDocumentSnapshot } from "firebase-functions/v2/firestore";
import { onDocumentCreated } from "firebase-functions/v2/firestore";
import { onRequest } from "firebase-functions/v2/https";
import type { MessagePublishedData } from "firebase-functions/v2/pubsub";
import { onMessagePublished } from "firebase-functions/v2/pubsub";
import { onSchedule } from "firebase-functions/v2/scheduler";
// Services will be imported inside functions to avoid initialization issues
import { config } from "dotenv";
import * as path from "path"; // 'path' 모듈을 import 합니다.
import { metadataExtractionService } from "./services/metadataExtractionService";
import type { CertificationDocument } from "./services/metadataTypes";
import { NotificationService } from "./services/notificationService";
import { userDataAggregationService } from "./services/userDataAggregationService";
import { vertexAIPromptService } from "./services/vertexAIPromptService";
import { vertexAIService } from "./services/vertexAIService";
// Import monitoring functions
export { processAlerts } from "./monitoring/alerts";
export { checkAlerts, collectMetrics, healthCheck } from "./monitoring/healthCheck";
export {
  cleanupMetadataExtractionMetrics, collectMetadataExtractionMetrics,
  getMetadataExtractionAnalytics
} from "./monitoring/metadataExtractionMonitoring";

// Load environment variables based on NODE_ENV or default to local
const nodeEnv = process.env.NODE_ENV || 'development';
if (nodeEnv === 'production') {
  config({ path: path.resolve(__dirname, "../.env.production") });
} else if (nodeEnv === 'staging') {
  config({ path: path.resolve(__dirname, "../.env.staging") });
} else {
  config({ path: path.resolve(__dirname, "../.env.local") });
}
// Initialize Firebase Admin
initializeApp();
const db = getFirestore();

/**
 * Weekly Analysis Trigger - Scheduled Function
 *
 * Runs every Sunday at 6 PM KST (9 AM UTC) to trigger weekly analysis
 * for all active users who have sufficient certification data.
 */
export const weeklyAnalysisTrigger = onSchedule({
  schedule: "0 9 * * 0", // Every Sunday at 9 AM UTC (6 PM KST)
  timeZone: "Asia/Seoul",
  region: "asia-northeast3",
  memory: "256MiB",
  timeoutSeconds: 540, // 9 minutes
}, async (): Promise<void> => {
  logger.info("Weekly analysis trigger started", {
    timestamp: new Date().toISOString(),
    timezone: "Asia/Seoul",
  });

  try {
    // Calculate the week range (Sunday to Saturday)
    const now = new Date();
    const weekEndDate = new Date(now);
    weekEndDate.setHours(23, 59, 59, 999);

    // Go back to the previous Sunday (start of the week we're analyzing)
    const weekStartDate = new Date(weekEndDate);
    weekStartDate.setDate(weekStartDate.getDate() - 6);
    weekStartDate.setHours(0, 0, 0, 0);

    logger.info("Analyzing week range", {
      weekStartDate: weekStartDate.toISOString(),
      weekEndDate: weekEndDate.toISOString(),
    });

    // Get all users who have certifications in the past week
    const usersWithCertifications = await userDataAggregationService
      .getUsersWithCertifications(weekStartDate, weekEndDate);

    logger.info(`Found ${usersWithCertifications.length} users with ` +
      "certifications this week");

    // Aggregate data for all users to determine eligibility
    const userDataList = await userDataAggregationService
      .batchAggregateUserData(
        usersWithCertifications,
        weekStartDate,
        weekEndDate
      );

    // Filter users who have minimum required data for analysis
    const eligibleUsers = userDataList.filter((userData) =>
      userData.hasMinimumData);

    logger.info(`${eligibleUsers.length} users eligible for AI analysis`);

    // Create analysis queue items for eligible users
    const batch = db.batch();
    let queuedCount = 0;

    for (const userData of eligibleUsers) {
      // Check if report already exists for this week
      const existingReportSnapshot = await db.collection("weeklyReports")
        .where("userUuid", "==", userData.userUuid)
        .where("weekStartDate", "==", weekStartDate)
        .limit(1)
        .get();

      if (existingReportSnapshot.empty) {
        // Create queue item for analysis
        const queueRef = db.collection("analysisQueue").doc();
        batch.set(queueRef, {
          userUuid: userData.userUuid,
          weekStartDate,
          weekEndDate,
          status: "pending",
          createdAt: new Date(),
          retryCount: 0,
          certificationCount: userData.stats.totalCertifications,
          exerciseDays: userData.stats.exerciseDays,
          dietDays: userData.stats.dietDays,
        });
        queuedCount++;
      } else {
        logger.info(`Report already exists for user ${userData.userUuid} ` +
          `for week ${weekStartDate.toISOString()}`);
      }
    }

    // Commit the batch
    if (queuedCount > 0) {
      await batch.commit();
      logger.info(`Queued ${queuedCount} users for weekly analysis`);
    } else {
      logger.info("No new reports to generate");
    }

    // Also handle users with insufficient data
    const insufficientDataUsers = userDataList.filter((userData) =>
      !userData.hasMinimumData && userData.stats.totalCertifications > 0);

    if (insufficientDataUsers.length > 0) {
      logger.info(`${insufficientDataUsers.length} users with insufficient ` +
        "data for analysis");

      // Create motivational reports for users with some but insufficient data
      const motivationalBatch = db.batch();

      for (const userData of insufficientDataUsers) {
        const existingReportSnapshot = await db.collection("weeklyReports")
          .where("userUuid", "==", userData.userUuid)
          .where("weekStartDate", "==", weekStartDate)
          .limit(1)
          .get();

        if (existingReportSnapshot.empty) {
          const reportRef = db.collection("weeklyReports").doc();
          motivationalBatch.set(reportRef, {
            userUuid: userData.userUuid,
            weekStartDate,
            weekEndDate,
            generatedAt: new Date(),
            stats: userData.stats,
            analysis: {
              exerciseInsights: userData.stats.exerciseDays === 0 ?
                "이번 주 운동 인증이 부족했어요. 꾸준한 운동 습관을 만들어보세요!" :
                `이번 주 ${userData.stats.exerciseDays}일 운동하셨네요. 더 자주 운동해보세요!`,
              dietInsights: userData.stats.dietDays === 0 ?
                "식단 관리를 더 신경써보세요. 매일 건강한 식단을 기록해보는 것은 어떨까요?" :
                `이번 주 ${userData.stats.dietDays}일 식단 관리하셨어요. ` +
                "더 꾸준히 해보세요!",
              overallAssessment: "이번 주에는 " +
                `${userData.stats.totalCertifications}번의 ` +
                "인증을 하셨네요. 더 꾸준히 인증해보세요!",
              strengthAreas: ["시작하는 의지"],
              improvementAreas: ["일관성", "꾸준함"],
            },
            recommendations: [
              "매일 최소 1개의 인증을 목표로 해보세요",
              "운동과 식단을 균형있게 관리해보세요",
              "작은 목표부터 시작해서 점진적으로 늘려가세요",
            ],
            status: "completed",
            type: "motivational",
          });
        }
      }

      if (insufficientDataUsers.length > 0) {
        await motivationalBatch.commit();
        logger.info(`Created ${insufficientDataUsers.length} ` +
          "motivational reports");
      }
    }

    logger.info("Weekly analysis trigger completed successfully", {
      totalUsers: usersWithCertifications.length,
      processedUsers: userDataList.length,
      eligibleUsers: eligibleUsers.length,
      queuedForAnalysis: queuedCount,
      motivationalReports: insufficientDataUsers.length,
    });
  } catch (error) {
    logger.error("Weekly analysis trigger failed", {
      error: error instanceof Error ? error.message : String(error),
      stack: error instanceof Error ? error.stack : undefined,
    });

    throw error;
  }
});

/**
 * Weekly Analysis Pub/Sub Handler
 *
 * Handles Pub/Sub messages for weekly analysis processing.
 * This can be used for manual triggers or batch processing.
 */
export const weeklyAnalysisPubSubHandler = onMessagePublished({
  topic: "weekly-analysis-trigger",
  region: "asia-northeast3",
  memory: "256MiB",
  timeoutSeconds: 540,
}, async (event: CloudEvent<MessagePublishedData>): Promise<void> => {
  logger.info("Weekly analysis Pub/Sub handler triggered", {
    messageId: event.data.message.messageId,
    publishTime: event.data.message.publishTime,
    data: event.data.message.data ?
      Buffer.from(event.data.message.data, "base64").toString() : null,
  });

  try {
    // Parse message data if provided
    let messageData: any = {};
    if (event.data.message.data) {
      const dataString = Buffer.from(event.data.message.data, "base64")
        .toString();
      try {
        messageData = JSON.parse(dataString);
      } catch (parseError) {
        logger.warn("Failed to parse message data as JSON", { dataString });
      }
    }

    // Extract parameters from message or use defaults
    const {
      weekStartDate: providedStartDate,
      weekEndDate: providedEndDate,
      userUuid: specificUser,
      forceRegenerate = false,
    } = messageData;

    // Calculate week range
    let weekStartDate: Date;
    let weekEndDate: Date;

    if (providedStartDate && providedEndDate) {
      weekStartDate = new Date(providedStartDate);
      weekEndDate = new Date(providedEndDate);
    } else {
      // Default to current week
      const now = new Date();
      weekEndDate = new Date(now);
      weekEndDate.setHours(23, 59, 59, 999);

      weekStartDate = new Date(weekEndDate);
      weekStartDate.setDate(weekStartDate.getDate() - 6);
      weekStartDate.setHours(0, 0, 0, 0);
    }

    logger.info("Processing week range via Pub/Sub", {
      weekStartDate: weekStartDate.toISOString(),
      weekEndDate: weekEndDate.toISOString(),
      specificUser,
      forceRegenerate,
    });

    // Get users with certifications for the specified period
    let usersWithCertifications: string[];

    if (specificUser) {
      // If specific user is provided, just use that user
      usersWithCertifications = [specificUser];
    } else {
      // Get all users with certifications in the period
      usersWithCertifications = await userDataAggregationService
        .getUsersWithCertifications(weekStartDate, weekEndDate);
    }

    logger.info(`Found ${usersWithCertifications.length} users with ` +
      "certifications for the specified period");

    // Aggregate data for users to determine eligibility
    const userDataList = await userDataAggregationService
      .batchAggregateUserData(
        usersWithCertifications,
        weekStartDate,
        weekEndDate
      );

    // Process users with sufficient data
    const eligibleUsers = userDataList.filter((userData) =>
      userData.hasMinimumData);

    const batch = db.batch();
    let queuedCount = 0;

    for (const userData of eligibleUsers) {
      // Check if report already exists (unless force regenerate is true)
      if (!forceRegenerate) {
        const existingReportSnapshot = await db.collection("weeklyReports")
          .where("userUuid", "==", userData.userUuid)
          .where("weekStartDate", "==", weekStartDate)
          .limit(1)
          .get();

        if (!existingReportSnapshot.empty) {
          logger.info(`Report already exists for user ${userData.userUuid}, ` +
            "skipping");
          continue;
        }
      }

      // Create or update queue item
      const queueRef = db.collection("analysisQueue").doc();
      batch.set(queueRef, {
        userUuid: userData.userUuid,
        weekStartDate,
        weekEndDate,
        status: "pending",
        createdAt: new Date(),
        retryCount: 0,
        certificationCount: userData.stats.totalCertifications,
        exerciseDays: userData.stats.exerciseDays,
        dietDays: userData.stats.dietDays,
        triggeredBy: "pubsub",
        forceRegenerate,
      });
      queuedCount++;
    }

    if (queuedCount > 0) {
      await batch.commit();
      logger.info(`Queued ${queuedCount} users for analysis via Pub/Sub`);
    }
  } catch (error) {
    logger.error("Weekly analysis Pub/Sub handler failed", {
      error: error instanceof Error ? error.message : String(error),
      stack: error instanceof Error ? error.stack : undefined,
      messageId: event.data.message.messageId,
    });

    throw error;
  }
});

/**
 * Generate AI Report Cloud Function
 *
 * Dedicated function for generating AI reports with advanced queue processing,
 * retry logic, and rate limiting. This function can be called directly or
 * triggered by queue items.
 */
export const generateAIReport = onRequest({
  region: "asia-northeast3",
  memory: "1GiB",
  timeoutSeconds: 540,
  concurrency: 5, // Limit concurrent executions for rate limiting
}, async (request: Request, response: Response): Promise<void> => {
  logger.info("Generate AI Report function triggered", {
    method: request.method,
    contentType: request.headers["content-type"],
    timestamp: new Date().toISOString(),
  });

  try {
    // Parse request body
    const {
      userUuid,
      weekStartDate,
      weekEndDate,
      queueId,
      forceRegenerate = false,
    } = request.body;

    // Validate required parameters
    if (!userUuid || !weekStartDate || !weekEndDate) {
      response.status(400).json({
        success: false,
        error: "Missing required parameters: userUuid, weekStartDate, weekEndDate",
      });
      return;
    }

    // Convert date strings to Date objects
    const startDate = new Date(weekStartDate);
    const endDate = new Date(weekEndDate);

    logger.info("Processing AI report generation request", {
      userUuid,
      weekStartDate: startDate.toISOString(),
      weekEndDate: endDate.toISOString(),
      queueId,
      forceRegenerate,
    });

    // Update queue status if queueId is provided
    if (queueId) {
      await db.collection("analysisQueue").doc(queueId).update({
        status: "processing",
        processedAt: new Date(),
      });
    }

    // Check if report already exists (unless force regenerate)
    if (!forceRegenerate) {
      const existingReportSnapshot = await db.collection("weeklyReports")
        .where("userUuid", "==", userUuid)
        .where("weekStartDate", "==", startDate)
        .limit(1)
        .get();

      if (!existingReportSnapshot.empty) {
        const existingReport = existingReportSnapshot.docs[0];

        if (queueId) {
          await db.collection("analysisQueue").doc(queueId).update({
            status: "completed",
            reportId: existingReport.id,
            completedAt: new Date(),
            note: "Report already exists",
          });
        }

        response.status(200).json({
          success: true,
          reportId: existingReport.id,
          message: "Report already exists",
          data: existingReport.data(),
        });
        return;
      }
    }

    // Aggregate user data
    const userData = await userDataAggregationService.aggregateUserWeekData(
      userUuid,
      startDate,
      endDate
    );

    logger.info("User data aggregated", {
      userUuid,
      totalCertifications: userData.stats.totalCertifications,
      hasMinimumData: userData.hasMinimumData,
      exerciseDays: userData.stats.exerciseDays,
      dietDays: userData.stats.dietDays,
    });

    // Check minimum data requirement
    if (!userData.hasMinimumData) {
      const error = "Insufficient data for AI analysis (minimum 3 certifications across 3 days required)";

      if (queueId) {
        await db.collection("analysisQueue").doc(queueId).update({
          status: "failed",
          error,
          completedAt: new Date(),
        });
      }

      response.status(400).json({
        success: false,
        error,
        userData: {
          totalCertifications: userData.stats.totalCertifications,
          exerciseDays: userData.stats.exerciseDays,
          dietDays: userData.stats.dietDays,
        },
      });
      return;
    }

    // Generate AI analysis
    let analysis: any;
    let recommendations: string[];
    let generatedBy = "vertexai";
    let aiMetadata: any = {};

    try {
      // Test VertexAI connection first
      const connectionTest = await vertexAIService.testConnection();
      if (!connectionTest) {
        throw new Error("VertexAI connection test failed");
      }

      // Generate comprehensive analysis prompt
      const analysisPrompt = vertexAIPromptService.generateAnalysisPrompt(userData);

      logger.info("Generating AI analysis with VertexAI", {
        userUuid,
        promptLength: analysisPrompt.length,
        rateLimitStatus: vertexAIService.getRateLimitStatus(),
      });

      // Call VertexAI for analysis
      const aiResponse = await vertexAIService.generateAnalysis({
        prompt: analysisPrompt,
        temperature: 0.7,
        maxOutputTokens: 2048,
      });

      // Parse the AI response into structured format
      const parsedAnalysis = vertexAIPromptService.parseAnalysisResponse(aiResponse.text);

      analysis = {
        exerciseInsights: parsedAnalysis.exerciseInsights,
        dietInsights: parsedAnalysis.dietInsights,
        overallAssessment: parsedAnalysis.overallAssessment,
        strengthAreas: parsedAnalysis.strengthAreas,
        improvementAreas: parsedAnalysis.improvementAreas,
      };

      recommendations = parsedAnalysis.recommendations;
      aiMetadata = {
        finishReason: aiResponse.finishReason,
        responseLength: aiResponse.text.length,
        promptLength: analysisPrompt.length,
      };

      logger.info("AI analysis generated successfully", {
        userUuid,
        responseLength: aiResponse.text.length,
        finishReason: aiResponse.finishReason,
      });
    } catch (aiError) {
      logger.warn("VertexAI analysis failed, using fallback", {
        userUuid,
        error: aiError instanceof Error ? aiError.message : String(aiError),
      });

      // Generate fallback report
      try {
        const fallbackResponse = await vertexAIService.generateFallbackReport(userData);
        const parsedFallback = vertexAIPromptService.parseAnalysisResponse(fallbackResponse.text);

        analysis = {
          exerciseInsights: parsedFallback.exerciseInsights,
          dietInsights: parsedFallback.dietInsights,
          overallAssessment: parsedFallback.overallAssessment,
          strengthAreas: parsedFallback.strengthAreas,
          improvementAreas: parsedFallback.improvementAreas,
        };

        recommendations = parsedFallback.recommendations;
        generatedBy = "fallback";
        aiMetadata = {
          fallbackReason: aiError instanceof Error ? aiError.message : String(aiError),
          responseLength: fallbackResponse.text.length,
        };
      } catch (fallbackError) {
        logger.error("Fallback report generation also failed", {
          userUuid,
          aiError: aiError instanceof Error ? aiError.message : String(aiError),
          fallbackError: fallbackError instanceof Error ? fallbackError.message : String(fallbackError),
        });

        if (queueId) {
          await db.collection("analysisQueue").doc(queueId).update({
            status: "failed",
            error: `AI analysis failed: ${aiError instanceof Error ? aiError.message : String(aiError)}`,
            completedAt: new Date(),
          });
        }

        response.status(500).json({
          success: false,
          error: "Failed to generate AI analysis and fallback report",
          details: {
            aiError: aiError instanceof Error ? aiError.message : String(aiError),
            fallbackError: fallbackError instanceof Error ? fallbackError.message : String(fallbackError),
          },
        });
        return;
      }
    }

    // Create the weekly report
    const reportRef = db.collection("weeklyReports").doc();
    await reportRef.set({
      userUuid,
      weekStartDate: startDate,
      weekEndDate: endDate,
      generatedAt: new Date(),
      stats: userData.stats,
      analysis,
      recommendations,
      status: "completed",
      type: "ai_analysis",
      generatedBy,
      nickname: userData.nickname,
      aiMetadata,
      queueId: queueId || null,
    });

    // Update queue status if queueId is provided
    if (queueId) {
      await db.collection("analysisQueue").doc(queueId).update({
        status: "completed",
        reportId: reportRef.id,
        completedAt: new Date(),
      });
    }

    logger.info("AI report generated successfully", {
      userUuid,
      reportId: reportRef.id,
      generatedBy,
      queueId,
    });

    response.status(200).json({
      success: true,
      reportId: reportRef.id,
      generatedBy,
      stats: userData.stats,
      aiMetadata,
      message: "AI report generated successfully",
    });
  } catch (error) {
    logger.error("Generate AI Report function failed", {
      error: error instanceof Error ? error.message : String(error),
      stack: error instanceof Error ? error.stack : undefined,
      body: request.body,
    });

    // Update queue status if queueId is provided
    const queueId = request.body?.queueId;
    if (queueId) {
      try {
        await db.collection("analysisQueue").doc(queueId).update({
          status: "failed",
          error: error instanceof Error ? error.message : String(error),
          completedAt: new Date(),
        });
      } catch (updateError) {
        logger.error("Failed to update queue status", {
          queueId,
          updateError: updateError instanceof Error ? updateError.message : String(updateError),
        });
      }
    }

    response.status(500).json({
      success: false,
      error: error instanceof Error ? error.message : String(error),
      timestamp: new Date().toISOString(),
    });
  }
});

/**
 * Analysis Queue Processor
 *
 * Processes items from the analysis queue when they are created.
 * This function will be triggered when new items are added to the
 * analysisQueue collection.
 */
export const processAnalysisQueue = onDocumentCreated({
  document: "analysisQueue/{queueId}",
  region: "asia-northeast3",
  memory: "512MiB",
  timeoutSeconds: 540,
}, async (event: FirestoreEvent<any>): Promise<void> => {
  const queueData = event.data?.data();
  const queueId = event.params.queueId;

  if (!queueData) {
    logger.error("No queue data found", { queueId });
    return;
  }

  logger.info("Processing analysis queue item", {
    queueId,
    userUuid: queueData.userUuid,
    weekStartDate: queueData.weekStartDate?.toDate?.()?.toISOString(),
    status: queueData.status,
  });

  try {
    // Update status to processing
    await event.data?.ref.update({
      status: "processing",
      processedAt: new Date(),
    });

    const {
      userUuid,
      weekStartDate,
      weekEndDate,
    } = queueData;

    // Convert Firestore timestamps to Date objects
    const startDate = weekStartDate?.toDate ?
      weekStartDate.toDate() : new Date(weekStartDate);
    const endDate = weekEndDate?.toDate ?
      weekEndDate.toDate() : new Date(weekEndDate);

    // Use the aggregation service to fetch and process user data
    const userData = await userDataAggregationService.aggregateUserWeekData(
      userUuid,
      startDate,
      endDate
    );

    logger.info(`Aggregated data for user ${userUuid}`, {
      totalCertifications: userData.stats.totalCertifications,
      hasMinimumData: userData.hasMinimumData,
      exerciseDays: userData.stats.exerciseDays,
      dietDays: userData.stats.dietDays,
    });

    if (!userData.hasMinimumData) {
      logger.warn(`Insufficient data for user ${userUuid}`, {
        totalCertifications: userData.stats.totalCertifications,
        hasMinimumData: userData.hasMinimumData,
      });

      // Update queue status to failed
      await event.data?.ref.update({
        status: "failed",
        error: "Insufficient data for analysis",
        completedAt: new Date(),
      });

      return;
    }

    // Generate AI analysis using VertexAI
    let analysis: any;
    let recommendations: string[];
    let generatedBy = "vertexai";

    try {
      // Generate comprehensive analysis prompt
      const analysisPrompt = vertexAIPromptService.generateAnalysisPrompt(userData);

      logger.info("Generating AI analysis with VertexAI", {
        userUuid,
        promptLength: analysisPrompt.length,
      });

      // Call VertexAI for analysis
      const aiResponse = await vertexAIService.generateAnalysis({
        prompt: analysisPrompt,
        temperature: 0.7,
        maxOutputTokens: 2048,
      });

      // Parse the AI response into structured format
      const parsedAnalysis = vertexAIPromptService.parseAnalysisResponse(aiResponse.text);

      analysis = {
        exerciseInsights: parsedAnalysis.exerciseInsights,
        dietInsights: parsedAnalysis.dietInsights,
        overallAssessment: parsedAnalysis.overallAssessment,
        strengthAreas: parsedAnalysis.strengthAreas,
        improvementAreas: parsedAnalysis.improvementAreas,
      };

      recommendations = parsedAnalysis.recommendations;

      logger.info("AI analysis generated successfully", {
        userUuid,
        responseLength: aiResponse.text.length,
        finishReason: aiResponse.finishReason,
      });
    } catch (aiError) {
      logger.warn("VertexAI analysis failed, using fallback", {
        userUuid,
        error: aiError instanceof Error ? aiError.message : String(aiError),
      });

      // Generate fallback report
      try {
        const fallbackResponse = await vertexAIService.generateFallbackReport(userData);
        const parsedFallback = vertexAIPromptService.parseAnalysisResponse(fallbackResponse.text);

        analysis = {
          exerciseInsights: parsedFallback.exerciseInsights,
          dietInsights: parsedFallback.dietInsights,
          overallAssessment: parsedFallback.overallAssessment,
          strengthAreas: parsedFallback.strengthAreas,
          improvementAreas: parsedFallback.improvementAreas,
        };

        recommendations = parsedFallback.recommendations;
        generatedBy = "fallback";
      } catch (fallbackError) {
        logger.error("Fallback report generation also failed, using basic analysis", {
          userUuid,
          aiError: aiError instanceof Error ? aiError.message : String(aiError),
          fallbackError: fallbackError instanceof Error ? fallbackError.message : String(fallbackError),
        });

        // Use basic analysis as last resort
        const exerciseCertifications = userData.certifications.filter(
          (cert) => cert.type === "운동"
        );
        const dietCertifications = userData.certifications.filter(
          (cert) => cert.type === "식단"
        );

        analysis = {
          exerciseInsights: generateBasicExerciseInsights(exerciseCertifications, userData.stats),
          dietInsights: generateBasicDietInsights(dietCertifications, userData.stats),
          overallAssessment: generateOverallAssessment(userData.stats),
          strengthAreas: generateStrengthAreas(userData.stats),
          improvementAreas: generateImprovementAreas(userData.stats),
        };

        recommendations = generateRecommendations(userData.stats);
        generatedBy = "basic";
      }
    }

    // Create the weekly report
    const reportRef = db.collection("weeklyReports").doc();
    await reportRef.set({
      userUuid,
      weekStartDate: startDate,
      weekEndDate: endDate,
      generatedAt: new Date(),
      stats: userData.stats,
      analysis,
      recommendations,
      status: "completed",
      type: "ai_analysis",
      generatedBy,
      nickname: userData.nickname,
    });

    // Update queue status to completed
    await event.data?.ref.update({
      status: "completed",
      reportId: reportRef.id,
      completedAt: new Date(),
    });

    logger.info("Successfully generated weekly report", {
      queueId,
      userUuid,
      reportId: reportRef.id,
      stats: userData.stats,
    });
  } catch (error) {
    logger.error("Failed to process analysis queue item", {
      queueId,
      userUuid: queueData.userUuid,
      error: error instanceof Error ? error.message : String(error),
      stack: error instanceof Error ? error.stack : undefined,
    });

    // Update retry count and status
    const newRetryCount = (queueData.retryCount || 0) + 1;
    const maxRetries = 3;

    if (newRetryCount >= maxRetries) {
      await event.data?.ref.update({
        status: "failed",
        error: error instanceof Error ? error.message : String(error),
        retryCount: newRetryCount,
        completedAt: new Date(),
      });
    } else {
      await event.data?.ref.update({
        status: "pending",
        retryCount: newRetryCount,
        lastError: error instanceof Error ? error.message : String(error),
        nextRetryAt: new Date(Date.now() + Math.pow(2, newRetryCount) * 1000),
      });
    }

    throw error;
  }
});

/**
 * Process Metadata Extraction Cloud Function
 *
 * Triggered when a new certification document is created in Firestore.
 * Extracts metadata from certification images using AI analysis.
 */
export const processMetadataExtraction = onDocumentCreated(
  {
    document: "certifications/{certificationId}",
    region: "asia-northeast3",
    memory: "512MiB",
    timeoutSeconds: 60,
    secrets: ["GEMINI_API_KEY"],
  },
  // 1. 핸들러 함수의 시그니처를 올바른 타입으로 수정합니다.
  // FirestoreEvent<CertificationDocument> 대신 FirestoreEvent<QueryDocumentSnapshot | undefined, { ... }>를 사용해야 합니다.
  async (event: FirestoreEvent<QueryDocumentSnapshot | undefined, { certificationId: string }>): Promise<void> => {
    const { certificationId } = event.params;

    // 2. event.data가 undefined일 수 있으므로, 먼저 snapshot 변수에 할당하고 존재 여부를 확인합니다.
    const snapshot = event.data;
    if (!snapshot) {
      logger.error("No data associated with the event.", { certificationId });
      return;
    }

    // 3. snapshot에서 데이터를 가져온 후, 직접 정의한 타입으로 캐스팅합니다.
    // 이 시점에서 데이터가 없을 경우도 처리합니다.
    const certificationData = snapshot.data() as CertificationDocument; // CertificationDocument는 직접 정의한 타입이어야 합니다.
    if (!certificationData) {
      logger.error("No certification data found", { certificationId });
      return;
    }

    logger.info("Processing metadata extraction for certification", {
      certificationId,
      userUuid: certificationData.userUuid,
      type: certificationData.type,
      photoUrl: certificationData.photoUrl,
      timestamp: new Date().toISOString(),
    });

    try {
      // --- 기존 로직은 대부분 그대로 사용 가능합니다 ---
      let metadata: any;

      if (certificationData.type === "운동") {
        metadata = await metadataExtractionService.extractExerciseMetadata(
          certificationData.photoUrl,
          certificationId
        );
      } else if (certificationData.type === "식단") {
        metadata = await metadataExtractionService.extractDietMetadata(
          certificationData.photoUrl,
          certificationId
        );
      } else {
        logger.warn("Unknown certification type", {
          certificationId,
          type: certificationData.type,
        });
        return;
      }

      const metadataField = certificationData.type === "운동" ? "exerciseMetadata" : "dietMetadata";

      // 4. 문서를 업데이트할 때, 'snapshot.ref'를 사용하면 더 안전합니다.
      await snapshot.ref.update({
        [metadataField]: metadata,
        metadataExtractedAt: new Date(),
        metadataExtractionStatus: "completed",
      });

      logger.info("Metadata extraction completed successfully", {
        certificationId,
        type: certificationData.type,
        metadataField,
        hasValidMetadata: metadata && Object.keys(metadata).length > 0,
      });

    } catch (error) {
      logger.error("Failed to extract metadata", {
        certificationId,
        error: error instanceof Error ? error.message : String(error),
        stack: error instanceof Error ? error.stack : undefined,
      });

      // 4. 오류 발생 시에도 'snapshot.ref'를 사용합니다.
      await snapshot.ref.update({
        metadataExtractionStatus: "failed",
        metadataExtractionError: error instanceof Error ? error.message : String(error),
        metadataExtractedAt: new Date(),
      });
    }
  }
);

/**
 * Retry Metadata Extraction Cloud Function
 *
 * HTTP function to manually retry failed metadata extractions.
 * Can be called by admin interface or scheduled jobs.
 */
export const retryMetadataExtraction = onRequest({
  region: "asia-northeast3",
  memory: "512MiB",
  timeoutSeconds: 60,
}, async (request: Request, response: Response): Promise<void> => {
  logger.info("Retry metadata extraction function triggered", {
    method: request.method,
    body: request.body,
  });

  try {
    const { certificationId, forceRetry = false } = request.body;

    if (!certificationId) {
      response.status(400).json({
        success: false,
        error: "Missing required parameter: certificationId",
      });
      return;
    }

    // Get the certification document
    const certificationRef = db.collection("certifications").doc(certificationId);
    const certificationDoc = await certificationRef.get();

    if (!certificationDoc.exists) {
      response.status(404).json({
        success: false,
        error: "Certification not found",
      });
      return;
    }

    const certificationData = certificationDoc.data() as CertificationDocument;

    // Check if retry is allowed
    if (!forceRetry && certificationData.metadataError && !certificationData.metadataError.canRetry) {
      response.status(400).json({
        success: false,
        error: "Metadata extraction cannot be retried for this certification",
        metadataError: certificationData.metadataError,
      });
      return;
    }

    logger.info("Retrying metadata extraction", {
      certificationId,
      type: certificationData.type,
      previousError: certificationData.metadataError,
      forceRetry,
    });

    // Reset processing status
    await certificationRef.update({
      metadataProcessed: false,
      metadataProcessingStartedAt: new Date(),
      metadataError: admin.firestore.FieldValue.delete(),
    });

    // Determine certification type and extract metadata
    let extractedMetadata: any = null;
    let metadataField: string;

    if (certificationData.type === "운동") {
      metadataField = "exerciseMetadata";
      extractedMetadata = await metadataExtractionService.extractExerciseMetadata(
        certificationData.photoUrl
      );
    } else if (certificationData.type === "식단") {
      metadataField = "dietMetadata";
      extractedMetadata = await metadataExtractionService.extractDietMetadata(
        certificationData.photoUrl
      );
    } else {
      throw new Error(`Unknown certification type: ${certificationData.type}`);
    }

    // Update the certification document
    const updateData: any = {
      [metadataField]: extractedMetadata,
      metadataProcessed: true,
      metadataProcessingCompletedAt: new Date(),
    };

    await certificationRef.update(updateData);

    logger.info("Metadata extraction retry completed successfully", {
      certificationId,
      type: certificationData.type,
      metadataField,
    });

    response.status(200).json({
      success: true,
      certificationId,
      type: certificationData.type,
      extractedMetadata,
      message: "Metadata extraction retry completed successfully",
    });
  } catch (error) {
    const errorMessage = error instanceof Error ? error.message : String(error);
    logger.error("Retry metadata extraction failed", {
      error: errorMessage,
      stack: error instanceof Error ? error.stack : undefined,
      body: request.body,
    });

    response.status(500).json({
      success: false,
      error: errorMessage,
      timestamp: new Date().toISOString(),
    });
  }
});

/**
 * Generate basic exercise insights
 * @param {any[]} exerciseCertifications - Exercise certifications
 * @param {any} stats - Statistics object
 * @return {string} Exercise insights
 */
function generateBasicExerciseInsights(exerciseCertifications: any[],
  stats: any): string {
  const exerciseDays = stats.exerciseDays || 0;
  const exerciseTypes = Object.keys(stats.exerciseTypes || {});

  if (exerciseCertifications.length === 0) {
    return "이번 주에는 운동 인증이 없었어요. 규칙적인 운동 습관을 만들어보세요!";
  }

  let insight = "";

  if (exerciseDays >= 5) {
    insight = `이번 주 ${exerciseDays}일 동안 ` +
      `${exerciseCertifications.length}번의 운동을 하셨네요! ` +
      "정말 훌륭합니다. 꾸준한 운동 습관이 잘 자리잡고 있어요.";
  } else if (exerciseDays >= 3) {
    insight = `이번 주 ${exerciseDays}일 동안 ` +
      `${exerciseCertifications.length}번의 운동을 하셨어요. ` +
      "좋은 시작이에요! 조금 더 자주 운동해보는 것은 어떨까요?";
  } else {
    insight = `이번 주 운동 일수가 ${exerciseDays}일로 아쉬워요. ` +
      "다음 주에는 더 자주 운동해보세요!";
  }

  // Add exercise variety insight
  if (exerciseTypes.length > 2) {
    insight += ` 다양한 운동(${exerciseTypes.join(", ")})을 시도하신 점이 좋아요!`;
  } else if (exerciseTypes.length === 1) {
    insight += ` 다음에는 ${exerciseTypes[0]} 외에 다른 운동도 시도해보세요.`;
  }

  return insight;
}

/**
 * Generate basic diet insights
 * @param {any[]} dietCertifications - Diet certifications
 * @param {any} stats - Statistics object
 * @return {string} Diet insights
 */
function generateBasicDietInsights(dietCertifications: any[],
  stats: any): string {
  const dietDays = stats.dietDays || 0;

  if (dietCertifications.length === 0) {
    return "이번 주에는 식단 인증이 없었어요. 건강한 식단 관리도 중요해요!";
  }

  let insight = "";

  if (dietDays >= 5) {
    insight = `이번 주 ${dietDays}일 동안 ` +
      `${dietCertifications.length}번의 식단 인증을 하셨네요! ` +
      "건강한 식단 관리를 잘 하고 계시는군요.";
  } else if (dietDays >= 3) {
    insight = `이번 주 ${dietDays}일 동안 ` +
      `${dietCertifications.length}번의 식단 관리를 하셨어요. ` +
      "꾸준히 관리하고 계시네요!";
  } else {
    insight = `이번 주 식단 관리 일수가 ${dietDays}일이에요. ` +
      "더 자주 건강한 식단을 기록해보세요!";
  }

  // Add consistency insight
  if (dietDays === dietCertifications.length) {
    insight += " 매일 한 번씩 꾸준히 기록하신 점이 좋아요!";
  } else if (dietCertifications.length > dietDays) {
    insight += " 하루에 여러 번 식단을 기록하신 점이 인상적이에요!";
  }

  return insight;
}

/**
 * Generate overall assessment
 * @param {any} stats - Statistics object
 * @return {string} Overall assessment
 */
function generateOverallAssessment(stats: any): string {
  const { totalCertifications, consistencyScore } = stats;

  if (consistencyScore >= 80) {
    return `이번 주 총 ${totalCertifications}번의 인증으로 일관성 점수 ` +
      `${consistencyScore}%를 달성하셨어요! 정말 훌륭한 한 주였습니다.`;
  } else if (consistencyScore >= 60) {
    return `이번 주 총 ${totalCertifications}번의 인증으로 일관성 점수 ` +
      `${consistencyScore}%예요. 좋은 습관을 만들어가고 계시네요!`;
  } else {
    return `이번 주 총 ${totalCertifications}번의 인증으로 일관성 점수 ` +
      `${consistencyScore}%예요. 다음 주에는 더 꾸준히 해보세요!`;
  }
}

/**
 * Generate strength areas
 * @param {any} stats - Statistics object
 * @return {string[]} Strength areas
 */
function generateStrengthAreas(stats: any): string[] {
  const strengths: string[] = [];

  if (stats.exerciseDays >= 3) {
    strengths.push("꾸준한 운동 습관");
  }

  if (stats.dietDays >= 3) {
    strengths.push("식단 관리 의식");
  }

  if (stats.consistencyScore >= 70) {
    strengths.push("높은 일관성");
  }

  if (Object.keys(stats.exerciseTypes).length > 1) {
    strengths.push("다양한 운동 시도");
  }

  return strengths.length > 0 ? strengths : ["건강 관리 시작"];
}

/**
 * Generate improvement areas
 * @param {any} stats - Statistics object
 * @return {string[]} Improvement areas
 */
function generateImprovementAreas(stats: any): string[] {
  const improvements: string[] = [];

  if (stats.exerciseDays < 3) {
    improvements.push("운동 빈도 증가");
  }

  if (stats.dietDays < 3) {
    improvements.push("식단 관리 강화");
  }

  if (stats.consistencyScore < 50) {
    improvements.push("일관성 향상");
  }

  if (stats.totalCertifications < 5) {
    improvements.push("전반적인 활동량 증가");
  }

  return improvements.length > 0 ? improvements : ["현재 수준 유지"];
}

/**
 * Generate recommendations
 * @param {any} stats - Statistics object
 * @return {string[]} Recommendations
 */
function generateRecommendations(stats: any): string[] {
  const recommendations: string[] = [];

  if (stats.exerciseDays < 3) {
    recommendations.push("주 3회 이상 운동을 목표로 해보세요");
  }

  if (stats.dietDays < 3) {
    recommendations.push("건강한 식단을 더 자주 기록해보세요");
  }

  if (Object.keys(stats.exerciseTypes).length <= 1) {
    recommendations.push("다양한 종류의 운동을 시도해보세요");
  }

  if (stats.consistencyScore < 70) {
    recommendations.push("매일 최소 1개의 인증을 목표로 해보세요");
  }

  recommendations.push("작은 목표부터 시작해서 점진적으로 늘려가세요");

  return recommendations;
}

/**
 * Batch AI Report Generator
 *
 * Processes multiple AI report generation requests with rate limiting
 * and concurrent request management. This function is designed to handle
 * large batches of users efficiently.
 */
export const batchGenerateAIReports = onRequest({
  region: "asia-northeast3",
  memory: "2GiB",
  timeoutSeconds: 540,
  concurrency: 1, // Single instance to manage rate limiting globally
}, async (request: Request, response: Response): Promise<void> => {
  logger.info("Batch AI Report Generator triggered", {
    method: request.method,
    timestamp: new Date().toISOString(),
  });

  try {
    const {
      userUuids = [],
      weekStartDate,
      weekEndDate,
      batchSize = 5,
      delayBetweenBatches = 2000,
      forceRegenerate = false,
    } = request.body;

    // Validate required parameters
    if (!weekStartDate || !weekEndDate) {
      response.status(400).json({
        success: false,
        error: "Missing required parameters: weekStartDate, weekEndDate",
      });
      return;
    }

    const startDate = new Date(weekStartDate);
    const endDate = new Date(weekEndDate);

    logger.info("Processing batch AI report generation", {
      userCount: userUuids.length,
      weekStartDate: startDate.toISOString(),
      weekEndDate: endDate.toISOString(),
      batchSize,
      delayBetweenBatches,
      forceRegenerate,
    });

    // If no specific users provided, get all users with certifications
    let targetUsers = userUuids;
    if (targetUsers.length === 0) {
      targetUsers = await userDataAggregationService.getUsersWithCertifications(
        startDate,
        endDate
      );
      logger.info(`Found ${targetUsers.length} users with certifications`);
    }

    const results = {
      totalUsers: targetUsers.length,
      processedUsers: 0,
      successfulReports: 0,
      failedReports: 0,
      skippedReports: 0,
      errors: [] as any[],
      reports: [] as any[],
    };

    // Process users in batches to manage rate limiting
    for (let i = 0; i < targetUsers.length; i += batchSize) {
      const batch = targetUsers.slice(i, i + batchSize);

      logger.info(`Processing batch ${Math.floor(i / batchSize) + 1}/${Math.ceil(targetUsers.length / batchSize)}`, {
        batchStart: i,
        batchSize: batch.length,
      });

      // Process batch concurrently but with limited concurrency
      const batchPromises = batch.map(async (userUuid: string) => {
        try {
          // Check if report already exists (unless force regenerate)
          if (!forceRegenerate) {
            const existingReportSnapshot = await db.collection("weeklyReports")
              .where("userUuid", "==", userUuid)
              .where("weekStartDate", "==", startDate)
              .limit(1)
              .get();

            if (!existingReportSnapshot.empty) {
              results.skippedReports++;
              return {
                userUuid,
                status: "skipped",
                reason: "Report already exists",
                reportId: existingReportSnapshot.docs[0].id,
              };
            }
          }

          // Create a mock request for generateAIReport
          const reportRequest = {
            body: {
              userUuid,
              weekStartDate: startDate.toISOString(),
              weekEndDate: endDate.toISOString(),
              forceRegenerate,
            },
          };

          // Create mock response to capture result
          let responseData: any = null;
          let responseStatus = 200;

          const mockResponse = {
            status: (code: number) => {
              responseStatus = code;
              return mockResponse;
            },
            json: (data: any) => {
              responseData = data;
              return mockResponse;
            },
          };

          // Call generateAIReport function
          await generateAIReport(reportRequest as any, mockResponse as any);

          if (responseStatus === 200) {
            results.successfulReports++;
            return {
              userUuid,
              status: "success",
              reportId: responseData?.reportId,
              generatedBy: responseData?.generatedBy,
            };
          } else {
            results.failedReports++;
            return {
              userUuid,
              status: "failed",
              error: responseData?.error || "Unknown error",
            };
          }
        } catch (error) {
          results.failedReports++;
          const errorMessage = error instanceof Error ? error.message : String(error);

          results.errors.push({
            userUuid,
            error: errorMessage,
          });

          return {
            userUuid,
            status: "failed",
            error: errorMessage,
          };
        }
      });

      // Wait for batch to complete
      const batchResults = await Promise.all(batchPromises);
      results.reports.push(...batchResults);
      results.processedUsers += batch.length;

      // Add delay between batches to respect rate limits
      if (i + batchSize < targetUsers.length && delayBetweenBatches > 0) {
        logger.info(`Waiting ${delayBetweenBatches}ms before next batch`);
        await new Promise((resolve) => setTimeout(resolve, delayBetweenBatches));
      }

      // Log progress
      logger.info("Batch completed", {
        batchNumber: Math.floor(i / batchSize) + 1,
        processedUsers: results.processedUsers,
        successfulReports: results.successfulReports,
        failedReports: results.failedReports,
        skippedReports: results.skippedReports,
      });
    }

    logger.info("Batch AI report generation completed", {
      totalUsers: results.totalUsers,
      processedUsers: results.processedUsers,
      successfulReports: results.successfulReports,
      failedReports: results.failedReports,
      skippedReports: results.skippedReports,
      errorCount: results.errors.length,
    });

    response.status(200).json({
      success: true,
      message: "Batch AI report generation completed",
      results,
      timestamp: new Date().toISOString(),
    });
  } catch (error) {
    logger.error("Batch AI Report Generator failed", {
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
 * Test Function for Weekly Analysis
 *
 * This function can be called manually to test the weekly analysis
 * functionality without waiting for the scheduled trigger.
 */
export const testWeeklyAnalysis = onRequest({
  region: "asia-northeast3",
  memory: "256MiB",
  timeoutSeconds: 540,
}, async (request: Request, response: Response): Promise<void> => {
  logger.info("Test weekly analysis triggered", {
    method: request.method,
    query: request.query,
    timestamp: new Date().toISOString(),
  });

  try {
    // Parse query parameters
    const {
      userUuid,
      weekOffset = "0",
      forceRegenerate = "false",
    } = request.query as { [key: string]: string };

    // Calculate week range based on offset
    const weekOffsetNum = parseInt(weekOffset, 10);
    const now = new Date();

    // Adjust for week offset (0 = current week, -1 = last week, etc.)
    const targetDate = new Date(now);
    targetDate.setDate(targetDate.getDate() + (weekOffsetNum * 7));

    const weekEndDate = new Date(targetDate);
    weekEndDate.setHours(23, 59, 59, 999);

    const weekStartDate = new Date(weekEndDate);
    weekStartDate.setDate(weekStartDate.getDate() - 6);
    weekStartDate.setHours(0, 0, 0, 0);

    logger.info("Test analysis parameters", {
      userUuid: userUuid || "all",
      weekOffset: weekOffsetNum,
      weekStartDate: weekStartDate.toISOString(),
      weekEndDate: weekEndDate.toISOString(),
      forceRegenerate: forceRegenerate === "true",
      timezone: "Asia/Seoul",
    });

    // Get users with certifications for the test period
    let usersWithCertifications: string[];

    if (userUuid) {
      usersWithCertifications = [userUuid];
    } else {
      usersWithCertifications = await userDataAggregationService
        .getUsersWithCertifications(weekStartDate, weekEndDate);
    }

    // Aggregate data for users
    const userDataList = await userDataAggregationService
      .batchAggregateUserData(
        usersWithCertifications,
        weekStartDate,
        weekEndDate
      );

    // Process eligible users
    const eligibleUsers = userDataList.filter((userData) =>
      userData.hasMinimumData);

    const results = {
      success: true,
      testParameters: {
        userUuid: userUuid || "all",
        weekOffset: weekOffsetNum,
        weekRange: {
          start: weekStartDate.toISOString(),
          end: weekEndDate.toISOString(),
        },
        forceRegenerate: forceRegenerate === "true",
        timezone: "Asia/Seoul",
      },
      statistics: {
        totalUsers: usersWithCertifications.length,
        processedUsers: userDataList.length,
        eligibleUsers: eligibleUsers.length,
        userBreakdown: userDataList.map((userData) => ({
          userUuid: userData.userUuid,
          certificationCount: userData.stats.totalCertifications,
          eligible: userData.hasMinimumData,
          exerciseCount: userData.stats.exerciseDays,
          dietCount: userData.stats.dietDays,
          consistencyScore: userData.stats.consistencyScore,
        })),
      },
      queuedForAnalysis: 0,
    };

    // If this is not just a dry run, actually queue the analysis
    if (request.method === "POST") {
      const batch = db.batch();
      let queuedCount = 0;

      for (const userData of eligibleUsers) {
        // Check existing reports unless force regenerate
        if (forceRegenerate !== "true") {
          const existingReport = await db.collection("weeklyReports")
            .where("userUuid", "==", userData.userUuid)
            .where("weekStartDate", "==", weekStartDate)
            .limit(1)
            .get();

          if (!existingReport.empty) {
            continue;
          }
        }

        const queueRef = db.collection("analysisQueue").doc();
        batch.set(queueRef, {
          userUuid: userData.userUuid,
          weekStartDate,
          weekEndDate,
          status: "pending",
          createdAt: new Date(),
          retryCount: 0,
          certificationCount: userData.stats.totalCertifications,
          exerciseDays: userData.stats.exerciseDays,
          dietDays: userData.stats.dietDays,
          triggeredBy: "test_function",
          forceRegenerate: forceRegenerate === "true",
        });
        queuedCount++;
      }

      if (queuedCount > 0) {
        await batch.commit();
        results.queuedForAnalysis = queuedCount;
        logger.info(`Test function queued ${queuedCount} users for analysis`);
      }
    }

    response.status(200).json(results);
  } catch (error) {
    logger.error("Test weekly analysis failed", {
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
 * Test VertexAI Connection and Rate Limiting
 *
 * This function tests the VertexAI service connection, rate limiting,
 * and retry mechanisms. Useful for debugging and monitoring.
 */
export const testVertexAI = onRequest({
  region: "asia-northeast3",
  memory: "512MiB",
  timeoutSeconds: 300,
}, async (request: Request, response: Response): Promise<void> => {
  logger.info("Test VertexAI function triggered", {
    method: request.method,
    timestamp: new Date().toISOString(),
  });

  try {
    const {
      testType = "connection",
      concurrentRequests = "3",
      testPrompt = "안녕하세요. 간단한 테스트입니다. '테스트 성공'이라고 답해주세요.",
    } = request.query as { [key: string]: string };

    const results: any = {
      testType,
      timestamp: new Date().toISOString(),
      rateLimitStatus: vertexAIService.getRateLimitStatus(),
    };

    switch (testType) {
      case "connection":
        logger.info("Testing VertexAI connection");

        const connectionResult = await vertexAIService.testConnection();
        results.connectionTest = {
          success: connectionResult,
          message: connectionResult ? "Connection successful" : "Connection failed",
        };
        break;

      case "rate_limiting":
        logger.info("Testing rate limiting with concurrent requests", {
          concurrentRequests: parseInt(concurrentRequests),
        });

        const concurrentCount = Math.min(parseInt(concurrentRequests) || 3, 10);
        const concurrentPromises = Array.from({ length: concurrentCount }, async (_, index) => {
          const startTime = Date.now();
          try {
            const response = await vertexAIService.generateAnalysis({
              prompt: `${testPrompt} (요청 번호: ${index + 1})`,
              temperature: 0.1,
              maxOutputTokens: 100,
            });

            return {
              requestIndex: index + 1,
              success: true,
              responseLength: response.text.length,
              duration: Date.now() - startTime,
              finishReason: response.finishReason,
            };
          } catch (error) {
            return {
              requestIndex: index + 1,
              success: false,
              error: error instanceof Error ? error.message : String(error),
              duration: Date.now() - startTime,
            };
          }
        });

        const concurrentResults = await Promise.all(concurrentPromises);
        results.rateLimitingTest = {
          concurrentRequests: concurrentCount,
          results: concurrentResults,
          successCount: concurrentResults.filter((r) => r.success).length,
          failureCount: concurrentResults.filter((r) => !r.success).length,
          averageDuration: concurrentResults.reduce((sum, r) => sum + r.duration, 0) / concurrentResults.length,
        };
        break;

      case "retry_logic":
        logger.info("Testing retry logic with intentional failures");

        // Temporarily reduce max retries for testing
        const originalConfig = vertexAIService.getRateLimitStatus();
        vertexAIService.updateRateLimitConfig({ maxRetries: 2 });

        try {
          // This should trigger retry logic due to invalid prompt
          const retryResult = await vertexAIService.generateAnalysis({
            prompt: "", // Empty prompt should cause an error
            temperature: 0.1,
            maxOutputTokens: 50,
          });

          results.retryTest = {
            success: true,
            message: "Unexpected success with empty prompt",
            response: retryResult.text.substring(0, 100),
          };
        } catch (error) {
          results.retryTest = {
            success: false,
            expectedFailure: true,
            error: error instanceof Error ? error.message : String(error),
            message: "Retry logic working as expected",
          };
        }

        // Restore original configuration
        vertexAIService.updateRateLimitConfig(originalConfig as any);
        break;

      case "fallback":
        logger.info("Testing fallback report generation");

        const mockUserData = {
          userUuid: "test-user",
          nickname: "테스트 사용자",
          stats: {
            totalCertifications: 5,
            exerciseDays: 3,
            dietDays: 2,
            consistencyScore: 71,
            exerciseTypes: { "헬스": 2, "러닝": 1 },
          },
        };

        const fallbackResult = await vertexAIService.generateFallbackReport(mockUserData);
        results.fallbackTest = {
          success: true,
          responseLength: fallbackResult.text.length,
          finishReason: fallbackResult.finishReason,
          preview: fallbackResult.text.substring(0, 200) + "...",
        };
        break;

      default:
        results.error = `Unknown test type: ${testType}`;
        break;
    }

    results.finalRateLimitStatus = vertexAIService.getRateLimitStatus();

    logger.info("VertexAI test completed", {
      testType,
      success: !results.error,
    });

    response.status(200).json({
      success: !results.error,
      results,
    });
  } catch (error) {
    logger.error("Test VertexAI function failed", {
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
 * Send Report Notification Cloud Function
 *
 * Triggered when a new weekly report is created in Firestore.
 * Sends push notifications to users about their new weekly reports.
 */
export const sendReportNotification = onDocumentCreated({
  document: "weeklyReports/{reportId}",
  region: "asia-northeast3",
  memory: "256MiB",
  timeoutSeconds: 60,
}, async (event: FirestoreEvent<any>): Promise<void> => {
  const reportData = event.data?.data();
  const reportId = event.params.reportId;

  if (!reportData) {
    logger.error("No report data found", { reportId });
    return;
  }

  logger.info("Processing report notification", {
    reportId,
    userUuid: reportData.userUuid,
    reportType: reportData.type,
    status: reportData.status,
  });

  try {
    // Only send notifications for completed reports
    if (reportData.status !== "completed") {
      logger.info("Report not completed, skipping notification", {
        reportId,
        status: reportData.status,
      });
      return;
    }

    // Extract report information
    const {
      userUuid,
      weekStartDate,
      weekEndDate,
      type: reportType,
      nickname,
    } = reportData;

    // Convert Firestore timestamps to Date objects
    const startDate = weekStartDate?.toDate ?
      weekStartDate.toDate() : new Date(weekStartDate);
    const endDate = weekEndDate?.toDate ?
      weekEndDate.toDate() : new Date(weekEndDate);

    // Prepare notification payload
    const notificationPayload = {
      userUuid,
      reportId,
      weekStartDate: startDate,
      weekEndDate: endDate,
      reportType: reportType || "ai_analysis",
      nickname,
    };

    // Send notification using the notification service
    const notificationId = await NotificationService.sendReportNotification(
      notificationPayload
    );

    logger.info("Report notification sent successfully", {
      reportId,
      userUuid,
      notificationId,
      reportType: reportType || "ai_analysis",
    });
  } catch (error) {
    logger.error("Failed to send report notification", {
      reportId,
      userUuid: reportData.userUuid,
      error: error instanceof Error ? error.message : String(error),
      stack: error instanceof Error ? error.stack : undefined,
    });

    // Don't throw the error to avoid retries, as notification failures
    // shouldn't block the report creation process
  }
});

/**
 * Manual Notification Sender Cloud Function
 *
 * HTTP function for manually sending notifications or testing notification functionality.
 * Can be used for debugging or sending notifications for existing reports.
 */
export const sendManualNotification = onRequest({
  region: "asia-northeast3",
  memory: "256MiB",
  timeoutSeconds: 60,
}, async (request: Request, response: Response): Promise<void> => {
  logger.info("Manual notification sender triggered", {
    method: request.method,
    body: request.body,
  });

  try {
    // Validate request method
    if (request.method !== "POST") {
      response.status(405).json({
        success: false,
        error: "Method not allowed. Use POST.",
      });
      return;
    }

    // Parse request body
    const {
      reportId,
      userUuid,
      weekStartDate,
      weekEndDate,
      reportType = "ai_analysis",
      nickname,
    } = request.body;

    // Validate required parameters
    if (!reportId || !userUuid || !weekStartDate || !weekEndDate) {
      response.status(400).json({
        success: false,
        error: "Missing required parameters: reportId, userUuid, weekStartDate, weekEndDate",
      });
      return;
    }

    // Convert date strings to Date objects
    const startDate = new Date(weekStartDate);
    const endDate = new Date(weekEndDate);

    // Prepare notification payload
    const notificationPayload = {
      userUuid,
      reportId,
      weekStartDate: startDate,
      weekEndDate: endDate,
      reportType,
      nickname,
    };

    // Send notification
    const notificationId = await NotificationService.sendReportNotification(
      notificationPayload
    );

    logger.info("Manual notification sent successfully", {
      reportId,
      userUuid,
      notificationId,
      reportType,
    });

    response.status(200).json({
      success: true,
      notificationId,
      message: "Notification sent successfully",
    });
  } catch (error) {
    logger.error("Manual notification failed", {
      error: error instanceof Error ? error.message : String(error),
      stack: error instanceof Error ? error.stack : undefined,
      body: request.body,
    });

    response.status(500).json({
      success: false,
      error: error instanceof Error ? error.message : String(error),
    });
  }
});

/**
 * Notification Statistics Cloud Function
 *
 * HTTP function for getting notification statistics and monitoring.
 */
export const getNotificationStats = onRequest({
  region: "asia-northeast3",
  memory: "256MiB",
  timeoutSeconds: 30,
}, async (request: Request, response: Response): Promise<void> => {
  try {
    // Parse query parameters
    const startDateParam = request.query.startDate as string;
    const endDateParam = request.query.endDate as string;

    // Default to last 7 days if no dates provided
    const endDate = endDateParam ? new Date(endDateParam) : new Date();
    const startDate = startDateParam ?
      new Date(startDateParam) :
      new Date(endDate.getTime() - 7 * 24 * 60 * 60 * 1000);

    // Get notification statistics
    const stats = await NotificationService.getNotificationStats(startDate, endDate);

    logger.info("Notification statistics retrieved", {
      startDate: startDate.toISOString(),
      endDate: endDate.toISOString(),
      stats,
    });

    response.status(200).json({
      success: true,
      period: {
        startDate: startDate.toISOString(),
        endDate: endDate.toISOString(),
      },
      stats,
    });
  } catch (error) {
    logger.error("Failed to get notification statistics", {
      error: error instanceof Error ? error.message : String(error),
    });

    response.status(500).json({
      success: false,
      error: error instanceof Error ? error.message : String(error),
    });
  }
});

/**
 * Notification Cleanup Cloud Function
 *
 * Scheduled function to clean up old notification status records.
 * Runs daily at 2 AM KST to maintain database performance.
 */
export const cleanupNotifications = onSchedule({
  schedule: "0 17 * * *", // Daily at 2 AM KST (17:00 UTC)
  timeZone: "Asia/Seoul",
  region: "asia-northeast3",
  memory: "256MiB",
  timeoutSeconds: 300,
}, async (): Promise<void> => {
  logger.info("Notification cleanup started");

  try {
    const deletedCount = await NotificationService.cleanupOldNotifications(30);

    logger.info("Notification cleanup completed", {
      deletedCount,
    });
  } catch (error) {
    logger.error("Notification cleanup failed", {
      error: error instanceof Error ? error.message : String(error),
    });
    throw error;
  }
});
