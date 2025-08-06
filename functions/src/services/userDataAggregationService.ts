/**
 * User Data Aggregation Service
 *
 * This service handles fetching, validating, and aggregating user certification
 * data for weekly AI analysis. It includes data sanitization and privacy
 * protection measures.
 */

import { getFirestore, Timestamp } from "firebase-admin/firestore";
import * as logger from "firebase-functions/logger";

// Lazy initialization to avoid module loading order issues
let db: any = null;
function getDb() {
  if (!db) {
    db = getFirestore();
  }
  return db;
}

/**
 * Interface for raw certification data from Firestore
 */
interface RawCertificationData {
  id: string;
  uuid: string;
  nickname: string;
  createdAt: Timestamp;
  type: string; // '운동' | '식단'
  content: string;
  photoUrl: string;
}

/**
 * Interface for processed certification data
 */
interface ProcessedCertificationData {
  id: string;
  type: "운동" | "식단";
  content: string;
  createdAt: Date;
  dayOfWeek: number; // 0 = Sunday, 1 = Monday, etc.
  sanitizedContent: string;
}

/**
 * Interface for user week data aggregation
 */
interface UserWeekData {
  userUuid: string;
  nickname: string;
  weekStartDate: Date;
  weekEndDate: Date;
  certifications: ProcessedCertificationData[];
  stats: WeeklyStats;
  hasMinimumData: boolean;
}

/**
 * Interface for weekly statistics
 */
interface WeeklyStats {
  totalCertifications: number;
  exerciseDays: number;
  dietDays: number;
  exerciseTypes: { [key: string]: number };
  consistencyScore: number;
  dailyBreakdown: { [day: string]: { exercise: number; diet: number } };
}

/**
 * User Data Aggregation Service Class
 */
export class UserDataAggregationService {
  private static readonly MINIMUM_DAYS_REQUIRED = 3;
  private static readonly MAX_CONTENT_LENGTH = 500;
  private static readonly SENSITIVE_PATTERNS = [
    /\b\d{3}-\d{4}-\d{4}\b/g, // Phone numbers
    /\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b/g, // Email
    /\b\d{6}-\d{7}\b/g, // Korean resident registration numbers
  ];

  /**
   * Fetch and aggregate user certification data for a specific week
   * @param {string} userUuid - User identifier
   * @param {Date} weekStartDate - Start of the week (Monday)
   * @param {Date} weekEndDate - End of the week (Sunday)
   * @return {Promise<UserWeekData>} Aggregated user data
   */
  async aggregateUserWeekData(
    userUuid: string,
    weekStartDate: Date,
    weekEndDate: Date
  ): Promise<UserWeekData> {
    logger.info("Starting user data aggregation", {
      userUuid,
      weekStartDate: weekStartDate.toISOString(),
      weekEndDate: weekEndDate.toISOString(),
    });

    try {
      // Validate input parameters
      this.validateDateRange(weekStartDate, weekEndDate);

      // Fetch user certifications for the week
      const rawCertifications = await this.fetchUserCertifications(
        userUuid,
        weekStartDate,
        weekEndDate
      );

      logger.info(`Found ${rawCertifications.length} certifications for user`, {
        userUuid,
        count: rawCertifications.length,
      });

      // Process and sanitize certification data
      const processedCertifications = rawCertifications.map((cert) =>
        this.processCertificationData(cert)
      );

      // Calculate weekly statistics
      const stats = this.calculateWeeklyStats(
        processedCertifications,
        weekStartDate
      );

      // Determine if user has minimum required data
      const hasMinimumData = this.validateMinimumDataRequirement(
        processedCertifications
      );

      // Get user nickname (use first certification's nickname or fetch from
      // users collection)
      const nickname = rawCertifications.length > 0 ?
        rawCertifications[0].nickname :
        await this.fetchUserNickname(userUuid);

      const result: UserWeekData = {
        userUuid,
        nickname,
        weekStartDate,
        weekEndDate,
        certifications: processedCertifications,
        stats,
        hasMinimumData,
      };

      logger.info("User data aggregation completed", {
        userUuid,
        totalCertifications: stats.totalCertifications,
        hasMinimumData,
        consistencyScore: stats.consistencyScore,
      });

      return result;
    } catch (error) {
      logger.error("Failed to aggregate user week data", {
        userUuid,
        weekStartDate: weekStartDate.toISOString(),
        weekEndDate: weekEndDate.toISOString(),
        error: error instanceof Error ? error.message : String(error),
        stack: error instanceof Error ? error.stack : undefined,
      });

      throw new Error(`Failed to aggregate user data: ${error instanceof Error ? error.message : String(error)
        }`);
    }
  }

  /**
   * Fetch user certifications from Firestore for the specified date range
   * @param {string} userUuid - User identifier
   * @param {Date} weekStartDate - Start date
   * @param {Date} weekEndDate - End date
   * @return {Promise<RawCertificationData[]>} Raw certification data
   */
  private async fetchUserCertifications(
    userUuid: string,
    weekStartDate: Date,
    weekEndDate: Date
  ): Promise<RawCertificationData[]> {
    try {
      const certificationsSnapshot = await getDb()
        .collection("certifications")
        .where("uuid", "==", userUuid)
        .where("createdAt", ">=", Timestamp.fromDate(weekStartDate))
        .where("createdAt", "<=", Timestamp.fromDate(weekEndDate))
        .orderBy("createdAt", "asc")
        .get();

      return certificationsSnapshot.docs.map((doc: any) => ({
        id: doc.id,
        ...doc.data(),
      } as RawCertificationData));
    } catch (error) {
      logger.error("Failed to fetch user certifications", {
        userUuid,
        weekStartDate: weekStartDate.toISOString(),
        weekEndDate: weekEndDate.toISOString(),
        error: error instanceof Error ? error.message : String(error),
      });

      throw new Error("Failed to fetch certifications from database");
    }
  }

  /**
   * Fetch user nickname from users collection
   * @param {string} userUuid - User identifier
   * @return {Promise<string>} User nickname
   */
  private async fetchUserNickname(userUuid: string): Promise<string> {
    try {
      const userDoc = await getDb().collection("users").doc(userUuid).get();
      return userDoc.exists ?
        userDoc.data()?.nickname || "Unknown User" : "Unknown User";
    } catch (error) {
      logger.warn("Failed to fetch user nickname", {
        userUuid,
        error: error instanceof Error ? error.message : String(error),
      });
      return "Unknown User";
    }
  }

  /**
   * Process and sanitize raw certification data
   * @param {RawCertificationData} rawCert - Raw certification data
   * @return {ProcessedCertificationData} Processed certification data
   */
  private processCertificationData(
    rawCert: RawCertificationData
  ): ProcessedCertificationData {
    const createdAt = rawCert.createdAt.toDate();
    const dayOfWeek = createdAt.getDay();

    // Sanitize content for privacy protection
    const sanitizedContent = this.sanitizeContent(rawCert.content);

    return {
      id: rawCert.id,
      type: rawCert.type as "운동" | "식단",
      content: rawCert.content, // Keep original for analysis
      createdAt,
      dayOfWeek,
      sanitizedContent, // Use sanitized version for external APIs
    };
  }

  /**
   * Sanitize content to remove sensitive information
   * @param {string} content - Original content
   * @return {string} Sanitized content
   */
  private sanitizeContent(content: string): string {
    if (!content) return "";

    let sanitized = content;

    // Remove sensitive patterns
    UserDataAggregationService.SENSITIVE_PATTERNS.forEach((pattern) => {
      sanitized = sanitized.replace(pattern, "[REDACTED]");
    });

    // Limit content length
    if (sanitized.length > UserDataAggregationService.MAX_CONTENT_LENGTH) {
      sanitized = sanitized.substring(
        0, UserDataAggregationService.MAX_CONTENT_LENGTH
      ) + "...";
    }

    // Remove excessive whitespace
    sanitized = sanitized.replace(/\s+/g, " ").trim();

    return sanitized;
  }

  /**
   * Calculate weekly statistics from processed certifications
   * @param {ProcessedCertificationData[]} certifications - Processed certs
   * @param {Date} weekStartDate - Week start date
   * @param {Date} weekEndDate - Week end date
   * @return {WeeklyStats} Weekly statistics
   */
  private calculateWeeklyStats(
    certifications: ProcessedCertificationData[],
    weekStartDate: Date
  ): WeeklyStats {
    const exerciseCertifications = certifications.filter(
      (cert) => cert.type === "운동"
    );
    const dietCertifications = certifications.filter(
      (cert) => cert.type === "식단"
    );

    // Calculate exercise types
    const exerciseTypes: { [key: string]: number } = {};
    exerciseCertifications.forEach((cert) => {
      const exerciseType = this.categorizeExerciseType(cert.content);
      exerciseTypes[exerciseType] = (exerciseTypes[exerciseType] || 0) + 1;
    });

    // Calculate daily breakdown
    const dailyBreakdown: { [day: string]: { exercise: number; diet: number } } =
      {};
    const dayNames = ["일", "월", "화", "수", "목", "금", "토"];

    // Initialize all days of the week
    for (let i = 0; i < 7; i++) {
      const date = new Date(weekStartDate);
      date.setDate(date.getDate() + i);
      const dayKey = `${date.getMonth() + 1}/${date.getDate()}(${dayNames[date.getDay()]
        })`;
      dailyBreakdown[dayKey] = { exercise: 0, diet: 0 };
    }

    // Count certifications by day
    certifications.forEach((cert) => {
      const date = cert.createdAt;
      const dayKey = `${date.getMonth() + 1}/${date.getDate()}(${dayNames[date.getDay()]
        })`;
      if (dailyBreakdown[dayKey]) {
        if (cert.type === "운동") {
          dailyBreakdown[dayKey].exercise++;
        } else {
          dailyBreakdown[dayKey].diet++;
        }
      }
    });

    // Calculate unique days with certifications
    const uniqueExerciseDays = new Set(
      exerciseCertifications.map((cert) => cert.createdAt.toDateString())
    ).size;

    const uniqueDietDays = new Set(
      dietCertifications.map((cert) => cert.createdAt.toDateString())
    ).size;

    // Calculate consistency score (percentage of days with at least one
    // certification)
    const uniqueCertificationDays = new Set(
      certifications.map((cert) => cert.createdAt.toDateString())
    ).size;
    const consistencyScore = Math.round((uniqueCertificationDays / 7) * 100);

    return {
      totalCertifications: certifications.length,
      exerciseDays: uniqueExerciseDays,
      dietDays: uniqueDietDays,
      exerciseTypes,
      consistencyScore,
      dailyBreakdown,
    };
  }

  /**
   * Categorize exercise type based on content
   * @param {string} content - Exercise content
   * @return {string} Exercise category
   */
  private categorizeExerciseType(content: string): string {
    const lowerContent = content.toLowerCase();

    if (lowerContent.includes("러닝") || lowerContent.includes("달리기") ||
      lowerContent.includes("조깅")) {
      return "러닝/조깅";
    } else if (lowerContent.includes("헬스") || lowerContent.includes("웨이트") ||
      lowerContent.includes("근력")) {
      return "헬스/웨이트";
    } else if (lowerContent.includes("요가") || lowerContent.includes("필라테스")) {
      return "요가/필라테스";
    } else if (lowerContent.includes("수영")) {
      return "수영";
    } else if (lowerContent.includes("자전거") || lowerContent.includes("사이클")) {
      return "자전거/사이클";
    } else if (lowerContent.includes("걷기") || lowerContent.includes("산책")) {
      return "걷기/산책";
    } else if (lowerContent.includes("축구") || lowerContent.includes("농구") ||
      lowerContent.includes("배구") || lowerContent.includes("테니스")) {
      return "구기종목";
    } else if (lowerContent.includes("등산") || lowerContent.includes("하이킹")) {
      return "등산/하이킹";
    } else {
      return "기타";
    }
  }

  /**
   * Validate minimum data requirement for analysis
   * @param {ProcessedCertificationData[]} certifications - Processed certs
   * @return {boolean} Whether minimum data requirement is met
   */
  private validateMinimumDataRequirement(
    certifications: ProcessedCertificationData[]
  ): boolean {
    // Check if user has at least 3 certifications total
    if (certifications.length <
      UserDataAggregationService.MINIMUM_DAYS_REQUIRED) {
      return false;
    }

    // Check if certifications are spread across at least 3 different days
    const uniqueDays = new Set(
      certifications.map((cert) => cert.createdAt.toDateString())
    );

    return uniqueDays.size >=
      UserDataAggregationService.MINIMUM_DAYS_REQUIRED;
  }

  /**
   * Validate date range parameters
   * @param {Date} weekStartDate - Week start date
   * @param {Date} weekEndDate - Week end date
   */
  private validateDateRange(weekStartDate: Date, weekEndDate: Date): void {
    if (!(weekStartDate instanceof Date) || !(weekEndDate instanceof Date)) {
      throw new Error("Invalid date parameters");
    }

    if (weekStartDate >= weekEndDate) {
      throw new Error("Week start date must be before end date");
    }

    const daysDifference = Math.ceil(
      (weekEndDate.getTime() - weekStartDate.getTime()) / (1000 * 60 * 60 * 24)
    );

    if (daysDifference !== 6) {
      throw new Error(
        "Week range must be exactly 7 days (6 days difference)"
      );
    }
  }

  /**
   * Get all users with certifications in the specified week
   * @param {Date} weekStartDate - Week start date
   * @param {Date} weekEndDate - Week end date
   * @return {Promise<string[]>} Array of user UUIDs
   */
  async getUsersWithCertifications(
    weekStartDate: Date,
    weekEndDate: Date
  ): Promise<string[]> {
    try {
      const certificationsSnapshot = await getDb()
        .collection("certifications")
        .where("createdAt", ">=", Timestamp.fromDate(weekStartDate))
        .where("createdAt", "<=", Timestamp.fromDate(weekEndDate))
        .get();

      const userUuids = new Set<string>();
      certificationsSnapshot.docs.forEach((doc: any) => {
        const data = doc.data();
        if (data.uuid) {
          userUuids.add(data.uuid);
        }
      });

      return Array.from(userUuids);
    } catch (error) {
      logger.error("Failed to get users with certifications", {
        weekStartDate: weekStartDate.toISOString(),
        weekEndDate: weekEndDate.toISOString(),
        error: error instanceof Error ? error.message : String(error),
      });

      throw new Error("Failed to fetch users with certifications");
    }
  }

  /**
   * Batch aggregate data for multiple users
   * @param {string[]} userUuids - Array of user UUIDs
   * @param {Date} weekStartDate - Week start date
   * @param {Date} weekEndDate - Week end date
   * @return {Promise<UserWeekData[]>} Array of aggregated user data
   */
  async batchAggregateUserData(
    userUuids: string[],
    weekStartDate: Date,
    weekEndDate: Date
  ): Promise<UserWeekData[]> {
    logger.info("Starting batch user data aggregation", {
      userCount: userUuids.length,
      weekStartDate: weekStartDate.toISOString(),
      weekEndDate: weekEndDate.toISOString(),
    });

    const results: UserWeekData[] = [];
    const errors: { userUuid: string; error: string }[] = [];

    // Process users in batches to avoid overwhelming the system
    const batchSize = 10;
    for (let i = 0; i < userUuids.length; i += batchSize) {
      const batch = userUuids.slice(i, i + batchSize);
      const batchPromises = batch.map(async (userUuid) => {
        try {
          return await this.aggregateUserWeekData(
            userUuid,
            weekStartDate,
            weekEndDate
          );
        } catch (error) {
          errors.push({
            userUuid,
            error: error instanceof Error ? error.message : String(error),
          });
          return null;
        }
      });

      const batchResults = await Promise.all(batchPromises);
      results.push(
        ...batchResults.filter((result) => result !== null) as UserWeekData[]
      );

      // Add small delay between batches to avoid rate limiting
      if (i + batchSize < userUuids.length) {
        await new Promise((resolve) => setTimeout(resolve, 100));
      }
    }

    if (errors.length > 0) {
      logger.warn("Some users failed during batch aggregation", {
        errorCount: errors.length,
        errors: errors.slice(0, 5), // Log first 5 errors
      });
    }

    logger.info("Batch user data aggregation completed", {
      totalUsers: userUuids.length,
      successfulUsers: results.length,
      failedUsers: errors.length,
    });

    return results;
  }
}

// Export singleton instance
export const userDataAggregationService = new UserDataAggregationService();
