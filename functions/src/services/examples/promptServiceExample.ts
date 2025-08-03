/**
 * Example usage of VertexAI Prompt Service
 * 
 * This file demonstrates how to use the different prompt generation methods
 * for various scenarios in the weekly AI analysis system.
 */

import { vertexAIPromptService } from "../vertexAIPromptService";

// Example user data with sufficient certifications
const sufficientDataUser = {
    userUuid: "user-123",
    nickname: "김건강",
    weekStartDate: new Date("2024-01-15"),
    weekEndDate: new Date("2024-01-21"),
    certifications: [
        {
            id: "cert1",
            type: "운동" as const,
            content: "헬스장에서 벤치프레스 3세트, 스쿼트 3세트 진행",
            createdAt: new Date("2024-01-15T09:00:00Z"),
            dayOfWeek: 1,
            sanitizedContent: "헬스장에서 벤치프레스 3세트, 스쿼트 3세트 진행",
        },
        {
            id: "cert2",
            type: "식단" as const,
            content: "아침: 귀리죽과 블루베리, 점심: 현미밥과 닭가슴살 샐러드",
            createdAt: new Date("2024-01-15T12:00:00Z"),
            dayOfWeek: 1,
            sanitizedContent: "아침: 귀리죽과 블루베리, 점심: 현미밥과 닭가슴살 샐러드",
        },
        {
            id: "cert3",
            type: "운동" as const,
            content: "한강에서 러닝 40분, 약 6km 완주",
            createdAt: new Date("2024-01-17T07:00:00Z"),
            dayOfWeek: 3,
            sanitizedContent: "한강에서 러닝 40분, 약 6km 완주",
        },
        {
            id: "cert4",
            type: "식단" as const,
            content: "저녁: 연어구이, 브로콜리, 고구마",
            createdAt: new Date("2024-01-18T19:00:00Z"),
            dayOfWeek: 4,
            sanitizedContent: "저녁: 연어구이, 브로콜리, 고구마",
        },
        {
            id: "cert5",
            type: "운동" as const,
            content: "요가 클래스 60분 참여",
            createdAt: new Date("2024-01-19T18:00:00Z"),
            dayOfWeek: 5,
            sanitizedContent: "요가 클래스 60분 참여",
        },
    ],
    stats: {
        totalCertifications: 5,
        exerciseDays: 3,
        dietDays: 2,
        exerciseTypes: {
            "헬스/웨이트": 1,
            "러닝/조깅": 1,
            "요가/필라테스": 1,
        },
        consistencyScore: 71,
        dailyBreakdown: {
            "1/15(월)": { exercise: 1, diet: 1 },
            "1/16(화)": { exercise: 0, diet: 0 },
            "1/17(수)": { exercise: 1, diet: 0 },
            "1/18(목)": { exercise: 0, diet: 1 },
            "1/19(금)": { exercise: 1, diet: 0 },
            "1/20(토)": { exercise: 0, diet: 0 },
            "1/21(일)": { exercise: 0, diet: 0 },
        },
    },
    hasMinimumData: true,
};

// Example user data with insufficient certifications
const insufficientDataUser = {
    userUuid: "user-456",
    nickname: "박시작",
    weekStartDate: new Date("2024-01-15"),
    weekEndDate: new Date("2024-01-21"),
    certifications: [
        {
            id: "cert1",
            type: "운동" as const,
            content: "집 근처 산책 20분",
            createdAt: new Date("2024-01-16T10:00:00Z"),
            dayOfWeek: 2,
            sanitizedContent: "집 근처 산책 20분",
        },
        {
            id: "cert2",
            type: "식단" as const,
            content: "점심: 샐러드와 닭가슴살",
            createdAt: new Date("2024-01-18T12:30:00Z"),
            dayOfWeek: 4,
            sanitizedContent: "점심: 샐러드와 닭가슴살",
        },
    ],
    stats: {
        totalCertifications: 2,
        exerciseDays: 1,
        dietDays: 1,
        exerciseTypes: {
            "걷기/산책": 1,
        },
        consistencyScore: 29,
        dailyBreakdown: {
            "1/15(월)": { exercise: 0, diet: 0 },
            "1/16(화)": { exercise: 1, diet: 0 },
            "1/17(수)": { exercise: 0, diet: 0 },
            "1/18(목)": { exercise: 0, diet: 1 },
            "1/19(금)": { exercise: 0, diet: 0 },
            "1/20(토)": { exercise: 0, diet: 0 },
            "1/21(일)": { exercise: 0, diet: 0 },
        },
    },
    hasMinimumData: false,
};

// Example user data with no certifications
const noDataUser = {
    userUuid: "user-789",
    nickname: "이다시",
    weekStartDate: new Date("2024-01-15"),
    weekEndDate: new Date("2024-01-21"),
    certifications: [],
    stats: {
        totalCertifications: 0,
        exerciseDays: 0,
        dietDays: 0,
        exerciseTypes: {},
        consistencyScore: 0,
        dailyBreakdown: {
            "1/15(월)": { exercise: 0, diet: 0 },
            "1/16(화)": { exercise: 0, diet: 0 },
            "1/17(수)": { exercise: 0, diet: 0 },
            "1/18(목)": { exercise: 0, diet: 0 },
            "1/19(금)": { exercise: 0, diet: 0 },
            "1/20(토)": { exercise: 0, diet: 0 },
            "1/21(일)": { exercise: 0, diet: 0 },
        },
    },
    hasMinimumData: false,
};

/**
 * Example function demonstrating comprehensive analysis prompt
 */
export function demonstrateAnalysisPrompt() {
    console.log("=== 종합 분석 프롬프트 예시 ===");
    const prompt = vertexAIPromptService.generateAnalysisPrompt(sufficientDataUser);
    console.log(prompt);
    console.log("\n");
}

/**
 * Example function demonstrating exercise-focused analysis
 */
export function demonstrateExerciseAnalysis() {
    console.log("=== 운동 분석 프롬프트 예시 ===");
    const prompt = vertexAIPromptService.generateExerciseAnalysisPrompt(sufficientDataUser);
    console.log(prompt);
    console.log("\n");
}

/**
 * Example function demonstrating diet-focused analysis
 */
export function demonstrateDietAnalysis() {
    console.log("=== 식단 분석 프롬프트 예시 ===");
    const prompt = vertexAIPromptService.generateDietAnalysisPrompt(sufficientDataUser);
    console.log(prompt);
    console.log("\n");
}

/**
 * Example function demonstrating recommendation generation
 */
export function demonstrateRecommendations() {
    console.log("=== 추천사항 프롬프트 예시 ===");
    const prompt = vertexAIPromptService.generateRecommendationPrompt(sufficientDataUser);
    console.log(prompt);
    console.log("\n");
}

/**
 * Example function demonstrating insufficient data handling
 */
export function demonstrateInsufficientData() {
    console.log("=== 데이터 부족 시 격려 프롬프트 예시 ===");
    const prompt = vertexAIPromptService.generateInsufficientDataPrompt(insufficientDataUser);
    console.log(prompt);
    console.log("\n");
}

/**
 * Example function demonstrating no data motivational prompt
 */
export function demonstrateNoDataMotivation() {
    console.log("=== 데이터 없음 시 동기부여 프롬프트 예시 ===");
    const prompt = vertexAIPromptService.generateNoDataMotivationalPrompt(noDataUser);
    console.log(prompt);
    console.log("\n");
}

/**
 * Example function demonstrating AI response parsing
 */
export function demonstrateResponseParsing() {
    console.log("=== AI 응답 파싱 예시 ===");

    const mockAIResponse = `
## 운동 분석
이번 주 운동 패턴이 매우 좋습니다. 헬스, 러닝, 요가를 골고루 하셔서 균형잡힌 운동을 하고 계십니다.

## 식단 분석
영양 균형이 잘 잡혀있고, 단백질과 복합탄수화물을 적절히 섭취하고 계십니다.

## 종합 평가
전반적으로 건강한 생활 패턴을 유지하고 계시며, 71%의 일관성 점수는 매우 우수합니다.

## 잘하고 있는 점
- 다양한 운동 종목 실천
- 균형잡힌 영양 섭취
- 꾸준한 인증 활동
- 규칙적인 운동 패턴

## 개선이 필요한 점
- 주말 활동 늘리기
- 수분 섭취 증가
- 스트레칭 추가

## 맞춤형 추천사항
- 주말에도 가벼운 운동하기
- 하루 2L 이상 물 마시기
- 운동 전후 스트레칭 필수
- 충분한 수면 취하기
- 간식 대신 견과류 섭취
  `;

    const parsedResult = vertexAIPromptService.parseAnalysisResponse(mockAIResponse);

    console.log("파싱된 결과:");
    console.log("운동 분석:", parsedResult.exerciseInsights);
    console.log("식단 분석:", parsedResult.dietInsights);
    console.log("종합 평가:", parsedResult.overallAssessment);
    console.log("강점:", parsedResult.strengthAreas);
    console.log("개선점:", parsedResult.improvementAreas);
    console.log("추천사항:", parsedResult.recommendations);
    console.log("\n");
}

/**
 * Example function demonstrating generation configuration
 */
export function demonstrateGenerationConfig() {
    console.log("=== VertexAI 생성 설정 예시 ===");
    const config = vertexAIPromptService.getGenerationConfig();
    console.log("생성 설정:", JSON.stringify(config, null, 2));
    console.log("\n");
}

/**
 * Run all examples
 */
export function runAllExamples() {
    console.log("VertexAI 프롬프트 서비스 사용 예시\n");

    demonstrateAnalysisPrompt();
    demonstrateExerciseAnalysis();
    demonstrateDietAnalysis();
    demonstrateRecommendations();
    demonstrateInsufficientData();
    demonstrateNoDataMotivation();
    demonstrateResponseParsing();
    demonstrateGenerationConfig();
}

// Uncomment to run examples
// runAllExamples();