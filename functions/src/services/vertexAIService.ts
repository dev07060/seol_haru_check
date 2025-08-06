/**
 * VertexAI Service
 *
 * This service handles integration with Google Cloud VertexAI for generating
 * AI-powered analysis reports. It includes retry logic, rate limiting, and
 * fallback mechanisms for robust operation.
 */

import { FinishReason, HarmBlockThreshold, HarmCategory, VertexAI } from "@google-cloud/vertexai";
import * as logger from "firebase-functions/logger";

/**
 * Interface for a part of a multimodal prompt
 */
interface Part {
  text?: string;
  inlineData?: {
    mimeType: string;
    data: string;
  };
}

/**
 * Interface for VertexAI request configuration
 */
interface VertexAIRequestConfig {
  prompt: string | Part[];
  temperature?: number;
  maxOutputTokens?: number;
  topP?: number;
  topK?: number;
}

/**
 * Interface for VertexAI response
 */
interface VertexAIResponse {
  text: string;
  finishReason: FinishReason | string;
  safetyRatings?: {
    category: HarmCategory;
    probability: string;
    probabilityScore: number;
    severity: string;
    severityScore: number;
  }[];
}

/**
 * Interface for rate limiting configuration
 */
interface RateLimitConfig {
  maxConcurrentRequests: number;
  requestDelayMs: number;
  maxRetries: number;
  baseBackoffMs: number;
}

/**
 * VertexAI Service Class
 */
export class VertexAIService {
  private vertexAI: VertexAI;
  private model: any;
  private requestQueue: Promise<any>[] = [];
  private rateLimitConfig: RateLimitConfig;

  private static readonly DEFAULT_CONFIG: RateLimitConfig = {
    maxConcurrentRequests: 5,
    requestDelayMs: 1000,
    maxRetries: 3,
    baseBackoffMs: 1000,
  };

  private static readonly DEFAULT_GENERATION_CONFIG = {
    temperature: 0.7,
    maxOutputTokens: 2048,
    topP: 0.8,
    topK: 40,
  };

  constructor(
    projectId: string = process.env.VERTEX_AI_PROJECT_ID || process.env.GCLOUD_PROJECT || "seol-haru-check",
    location: string = process.env.VERTEX_AI_LOCATION || "us-central1",
    modelName: string = process.env.VERTEX_AI_MODEL || "gemini-1.5-pro"
  ) {
    this.rateLimitConfig = { ...VertexAIService.DEFAULT_CONFIG };

    try {
      // Initialize VertexAI client with explicit endpoint configuration
      const vertexAIConfig: any = {
        project: projectId,
        location: location
      };

      // Add explicit API endpoint for specific regions to avoid SDK routing issues
      if (location === "asia-northeast3") {
        vertexAIConfig.apiEndpoint = `${location}-aiplatform.googleapis.com`;
      }

      this.vertexAI = new VertexAI(vertexAIConfig);

      // Get the generative model
      this.model = this.vertexAI.getGenerativeModel({
        model: modelName,
        generationConfig: VertexAIService.DEFAULT_GENERATION_CONFIG,
        safetySettings: [
          {
            category: HarmCategory.HARM_CATEGORY_DANGEROUS_CONTENT,
            threshold: HarmBlockThreshold.BLOCK_MEDIUM_AND_ABOVE,
          },
        ],
      });

      logger.info("VertexAI (Gemini) service initialized successfully", {
        projectId,
        location,
        modelName,
        endpoint: vertexAIConfig.apiEndpoint || "default",
      });
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : String(error);
      logger.error("Failed to initialize VertexAI (Gemini) service", {
        error: errorMessage,
        projectId,
        location,
        modelName,
        stack: error instanceof Error ? error.stack : undefined,
      });

      // Try fallback to us-central1 if original location fails
      if (location !== "us-central1" && (
        errorMessage.includes("location") ||
        errorMessage.includes("endpoint") ||
        errorMessage.includes("INVALID_ARGUMENT")
      )) {
        logger.warn("Retrying VertexAI initialization with us-central1 fallback", {
          originalLocation: location,
          fallbackLocation: "us-central1",
        });

        try {
          this.vertexAI = new VertexAI({
            project: projectId,
            location: "us-central1"
          });

          this.model = this.vertexAI.getGenerativeModel({
            model: modelName,
            generationConfig: VertexAIService.DEFAULT_GENERATION_CONFIG,
            safetySettings: [
              {
                category: HarmCategory.HARM_CATEGORY_DANGEROUS_CONTENT,
                threshold: HarmBlockThreshold.BLOCK_MEDIUM_AND_ABOVE,
              },
            ],
          });

          logger.info("VertexAI service initialized successfully with fallback location", {
            projectId,
            originalLocation: location,
            fallbackLocation: "us-central1",
            modelName,
          });

          return; // Success with fallback
        } catch (fallbackError) {
          logger.error("Fallback initialization also failed", {
            fallbackError: fallbackError instanceof Error ? fallbackError.message : String(fallbackError),
          });
        }
      }

      // Provide more specific error messages for common initialization issues
      let userFriendlyMessage = "Gemini API 서비스 초기화에 실패했습니다.";

      if (errorMessage.includes("API_KEY")) {
        userFriendlyMessage = "Gemini API 키가 설정되지 않았습니다.";
      } else if (errorMessage.includes("permission") || errorMessage.includes("unauthorized")) {
        userFriendlyMessage = "Gemini API 서비스 접근 권한이 없습니다.";
      } else if (errorMessage.includes("quota") || errorMessage.includes("limit")) {
        userFriendlyMessage = "Gemini API 서비스 사용량이 초과되었습니다.";
      } else if (errorMessage.includes("network") || errorMessage.includes("connection")) {
        userFriendlyMessage = "Gemini API 서비스 연결에 실패했습니다.";
      } else if (errorMessage.includes("location") || errorMessage.includes("endpoint")) {
        userFriendlyMessage = `Gemini API 서비스 리전 설정에 문제가 있습니다 (${location}).`;
      }

      throw new Error(`${userFriendlyMessage}: ${errorMessage}`);
    }
  }

  /**
     * Generate AI analysis with retry logic and rate limiting
     * @param {VertexAIRequestConfig} config - Request configuration
     * @return {Promise<VertexAIResponse>} AI response
     */
  async generateAnalysis(config: VertexAIRequestConfig): Promise<VertexAIResponse> {
    return this.processWithRateLimit(async () => {
      return this.generateWithRetry(config);
    });
  }

  /**
     * Generate analysis with retry logic
     * @param {VertexAIRequestConfig} config - Request configuration
     * @param {number} attempt - Current attempt number
     * @return {Promise<VertexAIResponse>} AI response
     */
  private async generateWithRetry(
    config: VertexAIRequestConfig,
    attempt = 1
  ): Promise<VertexAIResponse> {
    try {
      logger.info("Generating AI analysis", {
        attempt,
        promptLength: typeof config.prompt === "string" ? config.prompt.length : JSON.stringify(config.prompt).length,
        temperature: config.temperature,
      });

      // Make the API call with VertexAI
      const result = await this.model.generateContent(config.prompt);
      const response = result.response;

      // Handle cases where the model returns no content, possibly due to safety filters
      if (!response.candidates?.length || !response.candidates[0].content?.parts?.length) {
        const finishReason = response.candidates?.[0]?.finishReason ?? "UNKNOWN";
        const safetyRatings = response.candidates?.[0]?.safetyRatings ?? [];
        logger.warn("AI response is empty or blocked", { finishReason, safetyRatings });
        throw new Error(`Empty or blocked response from VertexAI. Finish reason: ${finishReason}`);
      }

      // Get text from response, handling multimodal responses
      const text = response.candidates[0].content.parts.map((part: any) => part.text).join("");
      if (!text || text.trim().length === 0) {
        throw new Error("Empty text in VertexAI response");
      }

      const finishReason = response.candidates[0].finishReason ?? "STOP";
      const safetyRatings = response.candidates[0].safetyRatings ?? [];

      logger.info("AI analysis generated successfully", {
        attempt,
        responseLength: text.length,
        finishReason: finishReason,
      });

      return {
        text: text.trim(),
        finishReason: finishReason,
        safetyRatings: safetyRatings,
      };
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : String(error);

      logger.warn("VertexAI request failed", {
        attempt,
        maxRetries: this.rateLimitConfig.maxRetries,
        error: errorMessage,
      });

      // Check if we should retry
      if (attempt < this.rateLimitConfig.maxRetries) {
        const shouldRetry = this.shouldRetryError(error);

        if (shouldRetry) {
          // Calculate exponential backoff delay
          const backoffDelay = this.rateLimitConfig.baseBackoffMs * Math.pow(2, attempt - 1);

          logger.info("Retrying VertexAI request after backoff", {
            attempt: attempt + 1,
            backoffDelay,
          });

          // Wait before retrying
          await new Promise((resolve) => setTimeout(resolve, backoffDelay));

          return this.generateWithRetry(config, attempt + 1);
        }
      }

      // Max retries reached or non-retryable error
      logger.error("VertexAI request failed permanently", {
        attempt,
        error: errorMessage,
        stack: error instanceof Error ? error.stack : undefined,
      });

      throw new Error(`VertexAI request failed after ${attempt} attempts: ${errorMessage}`);
    }
  }

  /**
     * Process request with rate limiting
     * @param {Function} operation - Operation to execute
     * @return {Promise<T>} Operation result
     */
  private async processWithRateLimit<T>(operation: () => Promise<T>): Promise<T> {
    // Wait if too many concurrent requests
    if (this.requestQueue.length >= this.rateLimitConfig.maxConcurrentRequests) {
      logger.info("Rate limit reached, waiting for available slot", {
        currentRequests: this.requestQueue.length,
        maxConcurrent: this.rateLimitConfig.maxConcurrentRequests,
      });

      // Wait for any request to complete
      await Promise.race(this.requestQueue);
    }

    // Add delay between requests
    if (this.rateLimitConfig.requestDelayMs > 0) {
      await new Promise((resolve) => setTimeout(resolve, this.rateLimitConfig.requestDelayMs));
    }

    // Execute the operation
    const promise = operation();
    this.requestQueue.push(promise);

    try {
      const result = await promise;
      return result;
    } finally {
      // Remove completed promise from queue
      const index = this.requestQueue.indexOf(promise);
      if (index > -1) {
        this.requestQueue.splice(index, 1);
      }
    }
  }

  /**
     * Check if an error should trigger a retry
     * @param {any} error - Error to check
     * @return {boolean} Whether to retry
     */
  private shouldRetryError(error: any): boolean {
    const errorMessage = error instanceof Error ? error.message.toLowerCase() : String(error).toLowerCase();

    // Retry on rate limiting errors
    if (errorMessage.includes("rate limit") ||
      errorMessage.includes("quota") ||
      errorMessage.includes("too many requests")) {
      return true;
    }

    // Retry on temporary network errors
    if (errorMessage.includes("network") ||
      errorMessage.includes("timeout") ||
      errorMessage.includes("connection") ||
      errorMessage.includes("unavailable")) {
      return true;
    }

    // Retry on 5xx server errors
    if (errorMessage.includes("internal error") ||
      errorMessage.includes("server error") ||
      errorMessage.includes("service unavailable")) {
      return true;
    }

    // Don't retry on client errors (4xx) or content policy violations
    if (errorMessage.includes("invalid") ||
      errorMessage.includes("bad request") ||
      errorMessage.includes("unauthorized") ||
      errorMessage.includes("forbidden") ||
      errorMessage.includes("safety") ||
      errorMessage.includes("policy")) {
      return false;
    }

    // Default to retry for unknown errors
    return true;
  }


  /**
     * Generate fallback report when AI analysis fails
     * @param {any} userData - User data for fallback generation
     * @return {Promise<VertexAIResponse>} Fallback response
     */
  async generateFallbackReport(userData: any): Promise<VertexAIResponse> {
    logger.info("Generating fallback report", {
      userUuid: userData.userUuid,
      totalCertifications: userData.stats?.totalCertifications,
    });

    try {
      const stats = userData.stats || {};
      const exerciseDays = stats.exerciseDays || 0;
      const dietDays = stats.dietDays || 0;
      const totalCertifications = stats.totalCertifications || 0;
      const consistencyScore = stats.consistencyScore || 0;

      // Generate basic analysis based on statistics
      let exerciseInsights = "";
      let dietInsights = "";
      let overallAssessment = "";

      // Exercise insights
      if (exerciseDays >= 5) {
        exerciseInsights = `이번 주 ${exerciseDays}일 동안 운동하셨네요! 정말 훌륭한 꾸준함을 보여주셨습니다. 규칙적인 운동 습관이 잘 자리잡고 있어요.`;
      } else if (exerciseDays >= 3) {
        exerciseInsights = `이번 주 ${exerciseDays}일 동안 운동하셨어요. 좋은 시작이에요! 조금 더 자주 운동해보는 것은 어떨까요?`;
      } else if (exerciseDays > 0) {
        exerciseInsights = `이번 주 ${exerciseDays}일 운동하셨네요. 시작이 반이에요! 다음 주에는 더 자주 운동해보세요.`;
      } else {
        exerciseInsights = "이번 주에는 운동 인증이 없었어요. 규칙적인 운동 습관을 만들어보세요!";
      }

      // Diet insights
      if (dietDays >= 5) {
        dietInsights = `이번 주 ${dietDays}일 동안 식단 관리를 하셨네요! 건강한 식습관을 잘 유지하고 계시는군요.`;
      } else if (dietDays >= 3) {
        dietInsights = `이번 주 ${dietDays}일 동안 식단 관리를 하셨어요. 꾸준히 관리하고 계시네요!`;
      } else if (dietDays > 0) {
        dietInsights = `이번 주 ${dietDays}일 식단 관리하셨네요. 더 자주 건강한 식단을 기록해보세요!`;
      } else {
        dietInsights = "이번 주에는 식단 인증이 없었어요. 건강한 식단 관리도 중요해요!";
      }

      // Overall assessment
      if (consistencyScore >= 80) {
        overallAssessment = `이번 주 총 ${totalCertifications}번의 인증으로 일관성 점수 ${consistencyScore}%를 달성하셨어요! 정말 훌륭한 한 주였습니다.`;
      } else if (consistencyScore >= 60) {
        overallAssessment = `이번 주 총 ${totalCertifications}번의 인증으로 일관성 점수 ${consistencyScore}%예요. 좋은 습관을 만들어가고 계시네요!`;
      } else {
        overallAssessment = `이번 주 총 ${totalCertifications}번의 인증으로 일관성 점수 ${consistencyScore}%예요. 다음 주에는 더 꾸준히 해보세요!`;
      }

      const fallbackText = `## 운동 분석
${exerciseInsights}

## 식단 분석
${dietInsights}

## 종합 평가
${overallAssessment}

## 잘하고 있는 점
- 건강 관리에 대한 의지
- 꾸준히 노력하는 자세
${exerciseDays >= 3 ? "- 규칙적인 운동 습관" : ""}
${dietDays >= 3 ? "- 식단 관리 의식" : ""}

## 개선이 필요한 점
${exerciseDays < 3 ? "- 운동 빈도 증가" : ""}
${dietDays < 3 ? "- 식단 관리 강화" : ""}
${consistencyScore < 70 ? "- 일관성 향상" : ""}
- 꾸준한 습관 형성

## 맞춤형 추천사항
- 매일 최소 1개의 인증을 목표로 해보세요
- 운동과 식단을 균형있게 관리해보세요
- 작은 목표부터 시작해서 점진적으로 늘려가세요
- 규칙적인 시간에 활동하는 습관을 만들어보세요
- 다음 주에는 더 꾸준히 인증해보세요`;

      return {
        text: fallbackText,
        finishReason: "FALLBACK",
        safetyRatings: [],
      };
    } catch (error) {
      logger.error("Failed to generate fallback report", {
        error: error instanceof Error ? error.message : String(error),
        userUuid: userData.userUuid,
      });

      // Ultimate fallback
      return {
        text: `## 운동 분석
이번 주도 건강 관리를 위해 노력해주셔서 감사합니다.

## 식단 분석
건강한 식습관 형성을 위해 계속 노력해보세요.

## 종합 평가
꾸준한 건강 관리가 가장 중요합니다.

## 잘하고 있는 점
- 건강에 대한 관심과 의지

## 개선이 필요한 점
- 꾸준한 활동 패턴 형성

## 맞춤형 추천사항
- 다음 주에는 더 자주 인증해보세요
- 작은 목표부터 시작해보세요`,
        finishReason: "FALLBACK",
        safetyRatings: [],
      };
    }
  }

  /**
     * Update rate limiting configuration
     * @param {Partial<RateLimitConfig>} config - New configuration
     */
  updateRateLimitConfig(config: Partial<RateLimitConfig>): void {
    this.rateLimitConfig = { ...this.rateLimitConfig, ...config };

    logger.info("Rate limit configuration updated", {
      newConfig: this.rateLimitConfig,
    });
  }

  /**
     * Get current rate limiting status
     * @return {object} Rate limiting status
     */
  getRateLimitStatus(): {
    currentRequests: number;
    maxConcurrentRequests: number;
    requestDelayMs: number;
    maxRetries: number;
    requestsInLastMinute?: number;
    maxRequestsPerMinute?: number;
  } {
    return {
      currentRequests: this.requestQueue.length,
      maxConcurrentRequests: this.rateLimitConfig.maxConcurrentRequests,
      requestDelayMs: this.rateLimitConfig.requestDelayMs,
      maxRetries: this.rateLimitConfig.maxRetries,
      // Add placeholder values for monitoring compatibility
      requestsInLastMinute: this.requestQueue.length,
      maxRequestsPerMinute: this.rateLimitConfig.maxConcurrentRequests * 12, // Rough estimate
    };
  }

  /**
     * Test VertexAI connection
     * @return {Promise<boolean>} Whether connection is working
     */
  async testConnection(): Promise<boolean> {
    try {
      logger.info("Testing VertexAI connection", {
        model: this.model?.model || "unknown",
      });

      const testResponse = await this.generateAnalysis({
        prompt: "안녕하세요. 간단한 연결 테스트입니다. '연결 성공'이라고 답해주세요.",
        temperature: 0.1,
        maxOutputTokens: 50,
      });

      const isSuccess = testResponse.text.includes("연결") || testResponse.text.includes("성공");

      logger.info("VertexAI connection test completed", {
        success: isSuccess,
        responseLength: testResponse.text.length,
        finishReason: testResponse.finishReason,
      });

      return isSuccess;
    } catch (error) {
      logger.error("VertexAI connection test failed", {
        error: error instanceof Error ? error.message : String(error),
        stack: error instanceof Error ? error.stack : undefined,
      });
      return false;
    }
  }
}

export const vertexAIService = new VertexAIService();
