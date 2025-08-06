/**
 * VertexAI Prompt Engineering Service
 *
 * This service provides Korean-language prompts for AI analysis of user
 * exercise and diet data. It includes specialized prompts for different
 * scenarios and fallback options for insufficient data.
 */

import * as logger from "firebase-functions/logger";
import {DietMetadata, ExerciseMetadata} from "./metadataTypes";

/**
 * Interface for user week data used in prompts
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
 * Interface for processed certification data
 */
interface ProcessedCertificationData {
    id: string;
    type: "운동" | "식단";
    content: string;
    createdAt: Date;
    dayOfWeek: number;
    sanitizedContent: string;
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
 * Interface for AI analysis result
 */
interface AIAnalysisResult {
    exerciseInsights: string;
    dietInsights: string;
    overallAssessment: string;
    strengthAreas: string[];
    improvementAreas: string[];
    recommendations: string[];
}

/**
 * VertexAI Prompt Engineering Service Class
 */
export class VertexAIPromptService {
  private static readonly MAX_PROMPT_LENGTH = 8000;
  private static readonly ANALYSIS_TEMPERATURE = 0.7;
  private static readonly MAX_OUTPUT_TOKENS = 2048;

  /**
     * Generate comprehensive analysis prompt for users with sufficient data
     * @param {UserWeekData} userData - User's weekly data
     * @return {string} Formatted prompt for VertexAI
     */
  generateAnalysisPrompt(userData: UserWeekData): string {
    if (!userData.hasMinimumData) {
      return this.generateInsufficientDataPrompt(userData);
    }

    const exerciseData = this.formatExerciseData(userData);
    const dietData = this.formatDietData(userData);
    const statsData = this.formatStatsData(userData.stats);

    const prompt = `당신은 건강 관리 전문가이자 개인 트레이너입니다. 사용자의 일주일간 운동과 식단 인증 데이터를 분석하여 개인화된 피드백을 제공해주세요.

**분석 대상 기간**: ${this.formatDateRange(userData.weekStartDate, userData.weekEndDate)}
**사용자**: ${userData.nickname}

**주간 통계**:
${statsData}

**운동 데이터**:
${exerciseData}

**식단 데이터**:
${dietData}

다음 형식으로 분석 결과를 제공해주세요:

## 운동 분석
- 이번 주 운동 패턴과 특징을 분석해주세요
- 운동 빈도, 일관성, 다양성을 평가해주세요
- 운동 타입별 분포와 균형을 검토해주세요

## 식단 분석
- 이번 주 식단 패턴과 특징을 분석해주세요
- 식사 시간, 다양성, 영양 균형을 평가해주세요
- 건강한 식습관 여부를 검토해주세요

## 종합 평가
- 전반적인 건강 관리 상태를 평가해주세요
- 운동과 식단의 조화와 균형을 분석해주세요
- 일관성 점수(${userData.stats.consistencyScore}%)에 대한 의견을 제시해주세요

## 잘하고 있는 점
- 칭찬할 만한 부분들을 구체적으로 나열해주세요 (3-5개)

## 개선이 필요한 점
- 보완이 필요한 영역들을 구체적으로 나열해주세요 (3-5개)

## 맞춤형 추천사항
- 다음 주를 위한 구체적이고 실행 가능한 조언을 제공해주세요 (5-7개)
- 운동과 식단 모두에 대한 균형잡힌 추천을 포함해주세요

**분석 시 고려사항**:
- 격려적이고 동기부여가 되는 톤으로 작성해주세요
- 한국인의 생활 패턴과 식문화를 고려해주세요
- 구체적이고 실행 가능한 조언을 제공해주세요
- 개인의 노력을 인정하고 긍정적인 변화를 강조해주세요`;

    return this.validateAndTruncatePrompt(prompt);
  }

  /**
     * Generate exercise-focused analysis prompt
     * @param {UserWeekData} userData - User's weekly data
     * @return {string} Exercise analysis prompt
     */
  generateExerciseAnalysisPrompt(userData: UserWeekData): string {
    const exerciseData = this.formatExerciseData(userData);
    const exerciseStats = this.formatExerciseStats(userData.stats);

    const prompt = `당신은 운동 전문가입니다. 사용자의 일주일간 운동 인증 데이터를 분석하여 전문적인 피드백을 제공해주세요.

**분석 기간**: ${this.formatDateRange(userData.weekStartDate, userData.weekEndDate)}
**사용자**: ${userData.nickname}

**운동 통계**:
${exerciseStats}

**운동 상세 데이터**:
${exerciseData}

다음 관점에서 분석해주세요:

## 운동 빈도 및 일관성
- 주간 운동 빈도(${userData.stats.exerciseDays}일)에 대한 평가
- 운동 패턴의 일관성과 규칙성 분석
- 휴식일과 운동일의 균형 검토

## 운동 다양성 및 균형
- 운동 종류의 다양성 평가
- 유산소와 근력운동의 균형
- 운동 강도와 지속시간 분석

## 개선 방향 제시
- 운동 효과 극대화를 위한 구체적 조언
- 부상 예방을 위한 주의사항
- 다음 주 운동 계획 제안

격려적이고 전문적인 톤으로 작성하되, 한국인의 운동 문화와 환경을 고려해주세요.`;

    return this.validateAndTruncatePrompt(prompt);
  }

  /**
     * Generate diet-focused analysis prompt with nutritional insights
     * @param {UserWeekData} userData - User's weekly data
     * @return {string} Diet analysis prompt
     */
  generateDietAnalysisPrompt(userData: UserWeekData): string {
    const dietData = this.formatDietData(userData);
    const dietStats = this.formatDietStats(userData.stats);

    const prompt = `당신은 영양 전문가입니다. 사용자의 일주일간 식단 인증 데이터를 분석하여 영양학적 관점에서 피드백을 제공해주세요.

**분석 기간**: ${this.formatDateRange(userData.weekStartDate, userData.weekEndDate)}
**사용자**: ${userData.nickname}

**식단 통계**:
${dietStats}

**식단 상세 데이터**:
${dietData}

다음 관점에서 분석해주세요:

## 식사 패턴 분석
- 식사 빈도와 시간대 분석
- 규칙적인 식사 여부 평가
- 식사량과 포션 크기 검토

## 영양 균형 평가
- 탄수화물, 단백질, 지방의 균형
- 비타민과 미네랄 섭취 추정
- 식이섬유와 수분 섭취 평가

## 식품 다양성 검토
- 식품군별 섭취 다양성
- 가공식품 vs 자연식품 비율
- 한국 전통 식단의 활용도

## 영양학적 조언
- 부족한 영양소 보충 방안
- 과다 섭취 주의 영양소
- 건강한 식습관 형성을 위한 구체적 제안

한국인의 식문화와 생활 패턴을 고려하여 실용적이고 따라하기 쉬운 조언을 제공해주세요.`;

    return this.validateAndTruncatePrompt(prompt);
  }

  /**
     * Generate recommendation-focused prompt
     * @param {UserWeekData} userData - User's weekly data
     * @return {string} Recommendation prompt
     */
  generateRecommendationPrompt(userData: UserWeekData): string {
    const summaryData = this.formatSummaryData(userData);

    const prompt = `당신은 개인 건강 코치입니다. 사용자의 일주일간 활동 데이터를 바탕으로 다음 주를 위한 구체적이고 실행 가능한 추천사항을 제공해주세요.

**사용자**: ${userData.nickname}
**분석 기간**: ${this.formatDateRange(userData.weekStartDate, userData.weekEndDate)}

**주간 활동 요약**:
${summaryData}

다음 카테고리별로 추천사항을 제공해주세요:

## 운동 추천 (3-4개)
- 현재 운동 패턴을 고려한 개선 방안
- 새로 시도해볼 만한 운동 종목
- 운동 빈도나 강도 조절 제안
- 부상 예방을 위한 주의사항

## 식단 추천 (3-4개)
- 영양 균형 개선을 위한 구체적 방안
- 건강한 식습관 형성 팁
- 간편하게 실천할 수 있는 식단 조절법
- 수분 섭취나 간식 관리 방법

## 생활 습관 추천 (2-3개)
- 일상 생활에서 실천할 수 있는 건강 습관
- 스트레스 관리나 수면 개선 방안
- 꾸준한 건강 관리를 위한 동기부여 방법

**추천사항 작성 원칙**:
- 구체적이고 측정 가능한 목표 제시
- 사용자의 현재 수준에서 실현 가능한 내용
- 단계적으로 발전할 수 있는 방향 제시
- 긍정적이고 격려적인 톤 유지

한국인의 생활 환경과 문화를 고려하여 실용적인 조언을 제공해주세요.`;

    return this.validateAndTruncatePrompt(prompt);
  }

  /**
     * Generate fallback prompt for insufficient data scenarios
     * @param {UserWeekData} userData - User's weekly data
     * @return {string} Fallback prompt
     */
  generateInsufficientDataPrompt(userData: UserWeekData): string {
    const availableData = this.formatLimitedData(userData);

    const prompt = `당신은 친근한 건강 관리 코치입니다. 사용자가 이번 주에 충분한 인증을 하지 못했지만, 격려와 동기부여를 통해 다음 주부터 꾸준히 활동할 수 있도록 도와주세요.

**사용자**: ${userData.nickname}
**분석 기간**: ${this.formatDateRange(userData.weekStartDate, userData.weekEndDate)}

**이번 주 활동 현황**:
${availableData}

다음 내용으로 격려 메시지를 작성해주세요:

## 긍정적 격려
- 작은 시작도 의미있다는 점 강조
- 건강 관리 의지를 보인 것에 대한 칭찬
- 완벽하지 않아도 괜찮다는 위로

## 동기부여 메시지
- 꾸준함의 중요성과 효과 설명
- 작은 변화가 가져올 큰 결과 강조
- 다른 사용자들의 성공 사례나 일반적인 효과 소개

## 실천 가능한 제안
- 다음 주를 위한 간단하고 실현 가능한 목표 제시
- 하루 10-15분으로 시작할 수 있는 운동 추천
- 간단한 식단 개선 방법 제안
- 인증 습관 형성을 위한 팁

## 응원 메시지
- 개인적이고 따뜻한 응원의 말
- 다음 주에 대한 기대와 믿음 표현
- 함께 건강해지자는 동반자 의식 강조

**작성 원칙**:
- 비판적이거나 부정적인 표현 절대 금지
- 따뜻하고 이해심 있는 톤 유지
- 구체적이고 실행하기 쉬운 조언 제공
- 사용자의 상황을 공감하고 격려하는 내용

한국인의 정서와 문화를 고려하여 진심이 담긴 격려 메시지를 작성해주세요.`;

    return this.validateAndTruncatePrompt(prompt);
  }

  /**
     * Generate motivational prompt for users with no data
     * @param {UserWeekData} userData - User's weekly data
     * @return {string} Motivational prompt
     */
  generateNoDataMotivationalPrompt(userData: UserWeekData): string {
    const prompt = `당신은 따뜻하고 친근한 건강 관리 멘토입니다. 이번 주에 활동 인증을 하지 못한 사용자에게 부담스럽지 않으면서도 동기부여가 되는 메시지를 전달해주세요.

**사용자**: ${userData.nickname}
**분석 기간**: ${this.formatDateRange(userData.weekStartDate, userData.weekEndDate)}

**상황**: 이번 주에 운동이나 식단 인증이 전혀 없었습니다.

다음 내용으로 동기부여 메시지를 작성해주세요:

## 공감과 이해
- 바쁜 일상으로 인한 어려움에 대한 이해
- 건강 관리가 쉽지 않다는 점 공감
- 완벽하지 않아도 괜찮다는 위로

## 새로운 시작 격려
- 언제든 다시 시작할 수 있다는 희망적 메시지
- 작은 변화부터 시작하는 것의 가치 강조
- 건강 관리의 장기적 관점 제시

## 간단한 실천 방안
- 하루 5-10분으로 시작할 수 있는 간단한 운동
- 특별한 준비 없이 할 수 있는 건강 습관
- 일상 속에서 자연스럽게 실천할 수 있는 방법

## 동반자 의식
- 혼자가 아니라는 느낌 전달
- 함께 건강해지는 커뮤니티의 일원임을 강조
- 다른 사용자들도 비슷한 경험을 한다는 점 언급

## 다음 주 기대
- 새로운 한 주에 대한 긍정적 전망
- 작은 목표 설정의 중요성
- 성취감을 느낄 수 있는 현실적 목표 제안

**작성 원칙**:
- 절대 비난하거나 죄책감을 주지 않기
- 따뜻하고 격려적인 톤 유지
- 부담스럽지 않은 수준의 제안
- 희망적이고 긍정적인 메시지

한국인의 정서에 맞는 따뜻하고 진심어린 격려 메시지를 작성해주세요.`;

    return this.validateAndTruncatePrompt(prompt);
  }

  /**
     * Format exercise data for prompt inclusion
     * @param {UserWeekData} userData - User's weekly data
     * @return {string} Formatted exercise data
     */
  private formatExerciseData(userData: UserWeekData): string {
    const exerciseCerts = userData.certifications.filter(
      (cert) => cert.type === "운동"
    );

    if (exerciseCerts.length === 0) {
      return "이번 주 운동 인증이 없습니다.";
    }

    const dayNames = ["일", "월", "화", "수", "목", "금", "토"];
    let formatted = `총 ${exerciseCerts.length}개의 운동 인증:\n`;

    exerciseCerts.forEach((cert, index) => {
      const dayName = dayNames[cert.dayOfWeek];
      const dateStr = `${cert.createdAt.getMonth() + 1}/${cert.createdAt.getDate()}(${dayName})`;
      formatted += `${index + 1}. [${dateStr}] ${cert.sanitizedContent}\n`;
    });

    return formatted;
  }

  /**
     * Format diet data for prompt inclusion
     * @param {UserWeekData} userData - User's weekly data
     * @return {string} Formatted diet data
     */
  private formatDietData(userData: UserWeekData): string {
    const dietCerts = userData.certifications.filter(
      (cert) => cert.type === "식단"
    );

    if (dietCerts.length === 0) {
      return "이번 주 식단 인증이 없습니다.";
    }

    const dayNames = ["일", "월", "화", "수", "목", "금", "토"];
    let formatted = `총 ${dietCerts.length}개의 식단 인증:\n`;

    dietCerts.forEach((cert, index) => {
      const dayName = dayNames[cert.dayOfWeek];
      const dateStr = `${cert.createdAt.getMonth() + 1}/${cert.createdAt.getDate()}(${dayName})`;
      formatted += `${index + 1}. [${dateStr}] ${cert.sanitizedContent}\n`;
    });

    return formatted;
  }

  /**
     * Format weekly statistics for prompt inclusion
     * @param {WeeklyStats} stats - Weekly statistics
     * @return {string} Formatted statistics
     */
  private formatStatsData(stats: WeeklyStats): string {
    let formatted = `- 총 인증 수: ${stats.totalCertifications}개\n`;
    formatted += `- 운동 인증 일수: ${stats.exerciseDays}일\n`;
    formatted += `- 식단 인증 일수: ${stats.dietDays}일\n`;
    formatted += `- 일관성 점수: ${stats.consistencyScore}%\n`;

    if (Object.keys(stats.exerciseTypes).length > 0) {
      formatted += "- 운동 종류별 분포:\n";
      Object.entries(stats.exerciseTypes).forEach(([type, count]) => {
        formatted += `  * ${type}: ${count}회\n`;
      });
    }

    formatted += "- 일별 활동 현황:\n";
    Object.entries(stats.dailyBreakdown).forEach(([day, counts]) => {
      formatted += `  * ${day}: 운동 ${counts.exercise}회, 식단 ${counts.diet}회\n`;
    });

    return formatted;
  }

  /**
     * Format exercise-specific statistics
     * @param {WeeklyStats} stats - Weekly statistics
     * @return {string} Formatted exercise statistics
     */
  private formatExerciseStats(stats: WeeklyStats): string {
    const exerciseCerts = Object.values(stats.exerciseTypes).reduce((a, b) => a + b, 0);
    let formatted = `- 총 운동 인증: ${exerciseCerts}개\n`;
    formatted += `- 운동 실시 일수: ${stats.exerciseDays}일\n`;

    if (Object.keys(stats.exerciseTypes).length > 0) {
      formatted += "- 운동 종류별 분포:\n";
      Object.entries(stats.exerciseTypes).forEach(([type, count]) => {
        formatted += `  * ${type}: ${count}회\n`;
      });
    }

    return formatted;
  }

  /**
     * Format diet-specific statistics
     * @param {WeeklyStats} stats - Weekly statistics
     * @return {string} Formatted diet statistics
     */
  private formatDietStats(stats: WeeklyStats): string {
    const dietCerts = stats.totalCertifications - Object.values(stats.exerciseTypes).reduce((a, b) => a + b, 0);
    let formatted = `- 총 식단 인증: ${dietCerts}개\n`;
    formatted += `- 식단 인증 일수: ${stats.dietDays}일\n`;

    return formatted;
  }

  /**
     * Format summary data for recommendations
     * @param {UserWeekData} userData - User's weekly data
     * @return {string} Formatted summary data
     */
  private formatSummaryData(userData: UserWeekData): string {
    let formatted = `- 총 활동: ${userData.stats.totalCertifications}개 인증\n`;
    formatted += `- 운동: ${userData.stats.exerciseDays}일, 식단: ${userData.stats.dietDays}일\n`;
    formatted += `- 일관성: ${userData.stats.consistencyScore}%\n`;

    if (Object.keys(userData.stats.exerciseTypes).length > 0) {
      const topExercise = Object.entries(userData.stats.exerciseTypes)
        .sort(([, a], [, b]) => b - a)[0];
      formatted += `- 주요 운동: ${topExercise[0]} (${topExercise[1]}회)\n`;
    }

    return formatted;
  }

  /**
     * Format limited data for insufficient data scenarios
     * @param {UserWeekData} userData - User's weekly data
     * @return {string} Formatted limited data
     */
  private formatLimitedData(userData: UserWeekData): string {
    if (userData.certifications.length === 0) {
      return "이번 주에는 인증 활동이 없었습니다.";
    }

    let formatted = `총 ${userData.certifications.length}개의 인증 (최소 3개 필요):\n`;

    userData.certifications.forEach((cert, index) => {
      const dayNames = ["일", "월", "화", "수", "목", "금", "토"];
      const dayName = dayNames[cert.dayOfWeek];
      const dateStr = `${cert.createdAt.getMonth() + 1}/${cert.createdAt.getDate()}(${dayName})`;
      formatted += `${index + 1}. [${dateStr}] ${cert.type}: ${cert.sanitizedContent}\n`;
    });

    return formatted;
  }

  /**
     * Format date range for display
     * @param {Date} startDate - Week start date
     * @param {Date} endDate - Week end date
     * @return {string} Formatted date range
     */
  private formatDateRange(startDate: Date, endDate: Date): string {
    const formatDate = (date: Date) => {
      return `${date.getFullYear()}년 ${date.getMonth() + 1}월 ${date.getDate()}일`;
    };

    return `${formatDate(startDate)} ~ ${formatDate(endDate)}`;
  }

  /**
     * Validate and truncate prompt if necessary
     * @param {string} prompt - Original prompt
     * @return {string} Validated and potentially truncated prompt
     */
  private validateAndTruncatePrompt(prompt: string): string {
    if (prompt.length <= VertexAIPromptService.MAX_PROMPT_LENGTH) {
      return prompt;
    }

    logger.warn("Prompt exceeds maximum length, truncating", {
      originalLength: prompt.length,
      maxLength: VertexAIPromptService.MAX_PROMPT_LENGTH,
    });

    // Truncate while trying to preserve the structure
    const truncated = prompt.substring(0, VertexAIPromptService.MAX_PROMPT_LENGTH - 100);
    return truncated + "\n\n[데이터가 길어 일부 생략되었습니다. 위 정보를 바탕으로 분석해주세요.]";
  }

  /**
     * Get generation configuration for VertexAI
     * @return {object} Generation configuration
     */
  getGenerationConfig(): object {
    return {
      temperature: VertexAIPromptService.ANALYSIS_TEMPERATURE,
      maxOutputTokens: VertexAIPromptService.MAX_OUTPUT_TOKENS,
      topP: 0.8,
      topK: 40,
    };
  }

  /**
     * Generate ultra-short Korean prompt for exercise image analysis
     * Optimized for minimal token usage and cost efficiency
     * @param {string} imageData - Base64 encoded image data
     * @return {string} Cost-optimized exercise analysis prompt
     */
  generateExerciseImageAnalysisPrompt(imageData: string): string {
    return `운동 이미지 분석. JSON만 응답:
{"exerciseType":"운동종류","duration":분,"timePeriod":"오전/오후/저녁","intensity":"낮음/보통/높음"}
불명확시 null. 설명 없이 JSON만.`;
  }

  /**
     * Generate ultra-short Korean prompt for diet image analysis
     * Optimized for minimal token usage and cost efficiency
     * @param {string} imageData - Base64 encoded image data
     * @return {string} Cost-optimized diet analysis prompt
     */
  generateDietImageAnalysisPrompt(imageData: string): string {
    return `음식 이미지를 분석하여 JSON 형식으로 응답하세요.

응답 형식 (JSON만):
{"foodName":"음식 이름","mainIngredients":["재료1","재료2","재료3","재료4","재료5"],"estimatedCalories":칼로리숫자}

주의사항:
- 음식과 재료의 이름은 가능한 정확히 선택
- 설명 없이 JSON만 출력`;
  }

  /**
     * Parse AI response for exercise metadata with minimal error handling
     * @param {string} aiResponse - Raw AI response containing JSON
     * @return {ExerciseMetadata} Parsed exercise metadata
     */
  parseExerciseMetadata(aiResponse: string): ExerciseMetadata {
    try {
      // Extract JSON from response (handle cases where AI adds extra text)
      const jsonMatch = aiResponse.match(/\{[\s\S]*\}/);
      if (!jsonMatch) {
        throw new Error("No JSON found in AI response");
      }

      const jsonStr = jsonMatch[0];
      const parsed = JSON.parse(jsonStr);

      // Validate and normalize the response
      const metadata: ExerciseMetadata = {
        exerciseType: this.normalizeString(parsed.exerciseType),
        duration: this.normalizeNumber(parsed.duration),
        timePeriod: this.normalizeTimePeriod(parsed.timePeriod),
        intensity: this.normalizeIntensity(parsed.intensity),
        extractedAt: new Date(),
      };

      logger.info("Exercise metadata parsed successfully", {
        exerciseType: metadata.exerciseType,
        duration: metadata.duration,
        timePeriod: metadata.timePeriod,
        intensity: metadata.intensity,
      });

      return metadata;
    } catch (error) {
      logger.error("Failed to parse exercise metadata", {
        error: error instanceof Error ? error.message : String(error),
        aiResponse: aiResponse.substring(0, 200),
      });

      // Return fallback metadata
      return {
        exerciseType: null,
        duration: null,
        timePeriod: null,
        intensity: null,
        extractedAt: new Date(),
      };
    }
  }

  /**
     * Parse AI response for diet metadata with minimal error handling
     * @param {string} aiResponse - Raw AI response containing JSON
     * @return {DietMetadata} Parsed diet metadata
     */
  parseDietMetadata(aiResponse: string): DietMetadata {
    try {
      // Extract JSON from response (handle cases where AI adds extra text)
      const jsonMatch = aiResponse.match(/\{[\s\S]*\}/);
      if (!jsonMatch) {
        throw new Error("No JSON found in AI response");
      }

      const jsonStr = jsonMatch[0];
      const parsed = JSON.parse(jsonStr);

      // Validate and normalize the response
      const metadata: DietMetadata = {
        foodName: this.normalizeString(parsed.foodName),
        mainIngredients: this.normalizeIngredientsLimited(parsed.mainIngredients),
        estimatedCalories: this.normalizeNumber(parsed.estimatedCalories),
        extractedAt: new Date(),
      };

      logger.info("Diet metadata parsed successfully", {
        foodName: metadata.foodName,
        mainIngredients: metadata.mainIngredients,
        estimatedCalories: metadata.estimatedCalories,
      });

      return metadata;
    } catch (error) {
      logger.error("Failed to parse diet metadata", {
        error: error instanceof Error ? error.message : String(error),
        aiResponse: aiResponse.substring(0, 200),
      });

      // Return fallback metadata
      return {
        foodName: null,
        mainIngredients: [],
        estimatedCalories: null,
        extractedAt: new Date(),
      };
    }
  }

  /**
     * Normalize string values from AI response
     * @param {any} value - Value to normalize
     * @return {string | null} Normalized string or null
     */
  private normalizeString(value: any): string | null {
    if (value === null || value === undefined || value === "") {
      return null;
    }
    if (typeof value === "string") {
      return value.trim();
    }
    return String(value).trim() || null;
  }

  /**
     * Normalize number values from AI response
     * @param {any} value - Value to normalize
     * @return {number | null} Normalized number or null
     */
  private normalizeNumber(value: any): number | null {
    if (value === null || value === undefined || value === "") {
      return null;
    }
    const num = Number(value);
    return isNaN(num) ? null : num;
  }

  /**
     * Normalize time period values to expected format
     * @param {any} value - Value to normalize
     * @return {string | null} Normalized time period or null
     */
  private normalizeTimePeriod(value: any): string | null {
    const normalized = this.normalizeString(value);
    if (!normalized) return null;

    const lower = normalized.toLowerCase();
    if (lower.includes("오전") || lower.includes("morning")) return "오전";
    if (lower.includes("오후") || lower.includes("afternoon")) return "오후";
    if (lower.includes("저녁") || lower.includes("evening") || lower.includes("night")) return "저녁";

    return normalized; // Return as-is if no match
  }

  /**
     * Normalize intensity values to expected format
     * @param {any} value - Value to normalize
     * @return {string | null} Normalized intensity or null
     */
  private normalizeIntensity(value: any): string | null {
    const normalized = this.normalizeString(value);
    if (!normalized) return null;

    const lower = normalized.toLowerCase();
    if (lower.includes("낮음") || lower.includes("low") || lower.includes("light")) return "낮음";
    if (lower.includes("보통") || lower.includes("medium") || lower.includes("moderate")) return "보통";
    if (lower.includes("높음") || lower.includes("high") || lower.includes("intense")) return "높음";

    return normalized; // Return as-is if no match
  }

  /**
     * Normalize ingredients array from AI response (limited to 2 items for simplified diet metadata)
     * @param {any} value - Value to normalize
     * @return {string[]} Normalized ingredients array (max 2 items)
     */
  private normalizeIngredientsLimited(value: any): string[] {
    if (!Array.isArray(value)) {
      return [];
    }

    return value
      .map((item) => this.normalizeString(item))
      .filter((item) => item !== null)
      .slice(0, 2) as string[]; // Limit to 2 ingredients for simplified metadata
  }

  /**
     * Parse AI response into structured analysis result
     * @param {string} aiResponse - Raw AI response
     * @return {AIAnalysisResult} Parsed analysis result
     */
  parseAnalysisResponse(aiResponse: string): AIAnalysisResult {
    try {
      // Extract sections using regex patterns
      const exerciseMatch = aiResponse.match(/## 운동 분석\s*([\s\S]*?)(?=##|$)/);
      const dietMatch = aiResponse.match(/## 식단 분석\s*([\s\S]*?)(?=##|$)/);
      const overallMatch = aiResponse.match(/## 종합 평가\s*([\s\S]*?)(?=##|$)/);
      const strengthMatch = aiResponse.match(/## 잘하고 있는 점\s*([\s\S]*?)(?=##|$)/);
      const improvementMatch = aiResponse.match(/## 개선이 필요한 점\s*([\s\S]*?)(?=##|$)/);
      const recommendationMatch = aiResponse.match(/## 맞춤형 추천사항\s*([\s\S]*?)(?=##|$)/);

      // Parse list items from sections
      const parseListItems = (text: string): string[] => {
        if (!text) return [];
        return text.split("\n")
          .filter((line) => line.trim().startsWith("-") || line.trim().match(/^\d+\./))
          .map((line) => line.replace(/^[-\d.]\s*/, "").trim())
          .filter((item) => item.length > 0);
      };

      return {
        exerciseInsights: exerciseMatch ? exerciseMatch[1].trim() : "운동 분석 정보가 없습니다.",
        dietInsights: dietMatch ? dietMatch[1].trim() : "식단 분석 정보가 없습니다.",
        overallAssessment: overallMatch ? overallMatch[1].trim() : "종합 평가 정보가 없습니다.",
        strengthAreas: parseListItems(strengthMatch ? strengthMatch[1] : ""),
        improvementAreas: parseListItems(improvementMatch ? improvementMatch[1] : ""),
        recommendations: parseListItems(recommendationMatch ? recommendationMatch[1] : ""),
      };
    } catch (error) {
      logger.error("Failed to parse AI analysis response", {
        error: error instanceof Error ? error.message : String(error),
        responseLength: aiResponse.length,
      });

      // Return fallback structure
      return {
        exerciseInsights: "분석 결과를 처리하는 중 오류가 발생했습니다.",
        dietInsights: "분석 결과를 처리하는 중 오류가 발생했습니다.",
        overallAssessment: "이번 주도 건강 관리를 위해 노력해주셔서 감사합니다.",
        strengthAreas: ["꾸준한 건강 관리 의지"],
        improvementAreas: ["규칙적인 활동 패턴 형성"],
        recommendations: ["다음 주에도 꾸준히 활동해보세요"],
      };
    }
  }
}

// Export singleton instance
export const vertexAIPromptService = new VertexAIPromptService();
