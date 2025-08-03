/**
 * Unit tests for VertexAI Prompt Service
 */

import { VertexAIPromptService } from "../vertexAIPromptService";

describe("VertexAIPromptService", () => {
    let promptService: VertexAIPromptService;

    // Sample user data for testing
    const sampleUserData = {
        userUuid: "test-uuid-123",
        nickname: "테스트유저",
        weekStartDate: new Date("2024-01-15"), // Monday
        weekEndDate: new Date("2024-01-21"), // Sunday
        certifications: [
            {
                id: "cert1",
                type: "운동" as const,
                content: "헬스장에서 웨이트 트레이닝 1시간",
                createdAt: new Date("2024-01-15T09:00:00Z"),
                dayOfWeek: 1, // Monday
                sanitizedContent: "헬스장에서 웨이트 트레이닝 1시간",
            },
            {
                id: "cert2",
                type: "식단" as const,
                content: "아침: 오트밀과 바나나, 점심: 닭가슴살 샐러드",
                createdAt: new Date("2024-01-15T12:00:00Z"),
                dayOfWeek: 1, // Monday
                sanitizedContent: "아침: 오트밀과 바나나, 점심: 닭가슴살 샐러드",
            },
            {
                id: "cert3",
                type: "운동" as const,
                content: "러닝 30분, 5km 완주",
                createdAt: new Date("2024-01-17T07:00:00Z"),
                dayOfWeek: 3, // Wednesday
                sanitizedContent: "러닝 30분, 5km 완주",
            },
            {
                id: "cert4",
                type: "식단" as const,
                content: "저녁: 현미밥, 된장찌개, 구운 생선",
                createdAt: new Date("2024-01-18T19:00:00Z"),
                dayOfWeek: 4, // Thursday
                sanitizedContent: "저녁: 현미밥, 된장찌개, 구운 생선",
            },
        ],
        stats: {
            totalCertifications: 4,
            exerciseDays: 2,
            dietDays: 2,
            exerciseTypes: {
                "헬스/웨이트": 1,
                "러닝/조깅": 1,
            },
            consistencyScore: 57, // 4 days out of 7
            dailyBreakdown: {
                "1/15(월)": { exercise: 1, diet: 1 },
                "1/16(화)": { exercise: 0, diet: 0 },
                "1/17(수)": { exercise: 1, diet: 0 },
                "1/18(목)": { exercise: 0, diet: 1 },
                "1/19(금)": { exercise: 0, diet: 0 },
                "1/20(토)": { exercise: 0, diet: 0 },
                "1/21(일)": { exercise: 0, diet: 0 },
            },
        },
        hasMinimumData: true,
    };

    const insufficientDataUser = {
        ...sampleUserData,
        certifications: [
            {
                id: "cert1",
                type: "운동" as const,
                content: "짧은 산책",
                createdAt: new Date("2024-01-15T09:00:00Z"),
                dayOfWeek: 1,
                sanitizedContent: "짧은 산책",
            },
        ],
        stats: {
            ...sampleUserData.stats,
            totalCertifications: 1,
            exerciseDays: 1,
            dietDays: 0,
            consistencyScore: 14,
        },
        hasMinimumData: false,
    };

    const noDataUser = {
        ...sampleUserData,
        certifications: [],
        stats: {
            ...sampleUserData.stats,
            totalCertifications: 0,
            exerciseDays: 0,
            dietDays: 0,
            exerciseTypes: {},
            consistencyScore: 0,
        },
        hasMinimumData: false,
    };

    beforeEach(() => {
        promptService = new VertexAIPromptService();
    });

    describe("generateAnalysisPrompt", () => {
        it("should generate comprehensive analysis prompt for sufficient data", () => {
            const prompt = promptService.generateAnalysisPrompt(sampleUserData);

            expect(prompt).toContain("당신은 건강 관리 전문가이자 개인 트레이너입니다");
            expect(prompt).toContain("테스트유저");
            expect(prompt).toContain("2024년 1월 15일 ~ 2024년 1월 21일");
            expect(prompt).toContain("총 인증 수: 4개");
            expect(prompt).toContain("운동 인증 일수: 2일");
            expect(prompt).toContain("식단 인증 일수: 2일");
            expect(prompt).toContain("일관성 점수(57%)");
            expect(prompt).toContain("헬스장에서 웨이트 트레이닝");
            expect(prompt).toContain("러닝 30분, 5km 완주");
            expect(prompt).toContain("## 운동 분석");
            expect(prompt).toContain("## 식단 분석");
            expect(prompt).toContain("## 종합 평가");
            expect(prompt).toContain("## 잘하고 있는 점");
            expect(prompt).toContain("## 개선이 필요한 점");
            expect(prompt).toContain("## 맞춤형 추천사항");
        });

        it("should redirect to insufficient data prompt when hasMinimumData is false", () => {
            const prompt = promptService.generateAnalysisPrompt(insufficientDataUser);

            expect(prompt).toContain("충분한 인증을 하지 못했지만");
            expect(prompt).toContain("격려와 동기부여");
            expect(prompt).toContain("## 긍정적 격려");
        });
    });

    describe("generateExerciseAnalysisPrompt", () => {
        it("should generate exercise-focused analysis prompt", () => {
            const prompt = promptService.generateExerciseAnalysisPrompt(sampleUserData);

            expect(prompt).toContain("당신은 운동 전문가입니다");
            expect(prompt).toContain("테스트유저");
            expect(prompt).toContain("총 2개의 운동 인증");
            expect(prompt).toContain("헬스장에서 웨이트 트레이닝");
            expect(prompt).toContain("러닝 30분, 5km 완주");
            expect(prompt).toContain("## 운동 빈도 및 일관성");
            expect(prompt).toContain("## 운동 다양성 및 균형");
            expect(prompt).toContain("## 개선 방향 제시");
            expect(prompt).toContain("주간 운동 빈도(2일)");
        });

        it("should handle no exercise data", () => {
            const noExerciseData = {
                ...sampleUserData,
                certifications: sampleUserData.certifications.filter(c => c.type === "식단"),
                stats: { ...sampleUserData.stats, exerciseDays: 0, exerciseTypes: {} },
            };

            const prompt = promptService.generateExerciseAnalysisPrompt(noExerciseData);

            expect(prompt).toContain("이번 주 운동 인증이 없습니다");
        });
    });

    describe("generateDietAnalysisPrompt", () => {
        it("should generate diet-focused analysis prompt", () => {
            const prompt = promptService.generateDietAnalysisPrompt(sampleUserData);

            expect(prompt).toContain("당신은 영양 전문가입니다");
            expect(prompt).toContain("테스트유저");
            expect(prompt).toContain("총 2개의 식단 인증");
            expect(prompt).toContain("오트밀과 바나나");
            expect(prompt).toContain("현미밥, 된장찌개");
            expect(prompt).toContain("## 식사 패턴 분석");
            expect(prompt).toContain("## 영양 균형 평가");
            expect(prompt).toContain("## 식품 다양성 검토");
            expect(prompt).toContain("## 영양학적 조언");
        });

        it("should handle no diet data", () => {
            const noDietData = {
                ...sampleUserData,
                certifications: sampleUserData.certifications.filter(c => c.type === "운동"),
                stats: { ...sampleUserData.stats, dietDays: 0 },
            };

            const prompt = promptService.generateDietAnalysisPrompt(noDietData);

            expect(prompt).toContain("이번 주 식단 인증이 없습니다");
        });
    });

    describe("generateRecommendationPrompt", () => {
        it("should generate recommendation-focused prompt", () => {
            const prompt = promptService.generateRecommendationPrompt(sampleUserData);

            expect(prompt).toContain("당신은 개인 건강 코치입니다");
            expect(prompt).toContain("테스트유저");
            expect(prompt).toContain("총 활동: 4개 인증");
            expect(prompt).toContain("운동: 2일, 식단: 2일");
            expect(prompt).toContain("일관성: 57%");
            expect(prompt).toContain("주요 운동: 헬스/웨이트");
            expect(prompt).toContain("## 운동 추천 (3-4개)");
            expect(prompt).toContain("## 식단 추천 (3-4개)");
            expect(prompt).toContain("## 생활 습관 추천 (2-3개)");
        });
    });

    describe("generateInsufficientDataPrompt", () => {
        it("should generate encouraging prompt for insufficient data", () => {
            const prompt = promptService.generateInsufficientDataPrompt(insufficientDataUser);

            expect(prompt).toContain("친근한 건강 관리 코치입니다");
            expect(prompt).toContain("테스트유저");
            expect(prompt).toContain("총 1개의 인증 (최소 3개 필요)");
            expect(prompt).toContain("짧은 산책");
            expect(prompt).toContain("## 긍정적 격려");
            expect(prompt).toContain("## 동기부여 메시지");
            expect(prompt).toContain("## 실천 가능한 제안");
            expect(prompt).toContain("## 응원 메시지");
            expect(prompt).toContain("비판적이거나 부정적인 표현 절대 금지");
        });
    });

    describe("generateNoDataMotivationalPrompt", () => {
        it("should generate motivational prompt for no data", () => {
            const prompt = promptService.generateNoDataMotivationalPrompt(noDataUser);

            expect(prompt).toContain("따뜻하고 친근한 건강 관리 멘토입니다");
            expect(prompt).toContain("테스트유저");
            expect(prompt).toContain("운동이나 식단 인증이 전혀 없었습니다");
            expect(prompt).toContain("## 공감과 이해");
            expect(prompt).toContain("## 새로운 시작 격려");
            expect(prompt).toContain("## 간단한 실천 방안");
            expect(prompt).toContain("## 동반자 의식");
            expect(prompt).toContain("## 다음 주 기대");
            expect(prompt).toContain("절대 비난하거나 죄책감을 주지 않기");
        });
    });

    describe("getGenerationConfig", () => {
        it("should return proper generation configuration", () => {
            const config = promptService.getGenerationConfig();

            expect(config).toEqual({
                temperature: 0.7,
                maxOutputTokens: 2048,
                topP: 0.8,
                topK: 40,
            });
        });
    });

    describe("parseAnalysisResponse", () => {
        it("should parse structured AI response correctly", () => {
            const mockResponse = `
## 운동 분석
이번 주 운동 패턴이 좋습니다. 웨이트와 유산소를 균형있게 하셨네요.

## 식단 분석
영양 균형이 잘 잡혀있습니다. 단백질 섭취가 충분해 보입니다.

## 종합 평가
전반적으로 건강한 생활 패턴을 보이고 있습니다.

## 잘하고 있는 점
- 규칙적인 운동 실천
- 균형잡힌 식단 구성
- 꾸준한 인증 활동

## 개선이 필요한 점
- 운동 빈도 증가 필요
- 수분 섭취 늘리기
- 휴식일 관리

## 맞춤형 추천사항
- 주 3회 이상 운동하기
- 하루 2L 이상 물 마시기
- 충분한 수면 취하기
      `;

            const result = promptService.parseAnalysisResponse(mockResponse);

            expect(result.exerciseInsights).toContain("운동 패턴이 좋습니다");
            expect(result.dietInsights).toContain("영양 균형이 잘 잡혀있습니다");
            expect(result.overallAssessment).toContain("건강한 생활 패턴");
            expect(result.strengthAreas).toEqual([
                "규칙적인 운동 실천",
                "균형잡힌 식단 구성",
                "꾸준한 인증 활동",
            ]);
            expect(result.improvementAreas).toEqual([
                "운동 빈도 증가 필요",
                "수분 섭취 늘리기",
                "휴식일 관리",
            ]);
            expect(result.recommendations).toEqual([
                "주 3회 이상 운동하기",
                "하루 2L 이상 물 마시기",
                "충분한 수면 취하기",
            ]);
        });

        it("should handle malformed response gracefully", () => {
            const malformedResponse = "This is not a properly formatted response";

            const result = promptService.parseAnalysisResponse(malformedResponse);

            expect(result.exerciseInsights).toBe("운동 분석 정보가 없습니다.");
            expect(result.dietInsights).toBe("식단 분석 정보가 없습니다.");
            expect(result.overallAssessment).toBe("종합 평가 정보가 없습니다.");
            expect(result.strengthAreas).toEqual([]);
            expect(result.improvementAreas).toEqual([]);
            expect(result.recommendations).toEqual([]);
        });
    });

    describe("prompt length validation", () => {
        it("should truncate overly long prompts", () => {
            // Create user data with very long content
            const longContentUser = {
                ...sampleUserData,
                certifications: Array.from({ length: 100 }, (_, i) => ({
                    id: `cert${i}`,
                    type: "운동" as const,
                    content: "매우 긴 운동 내용입니다. ".repeat(100),
                    createdAt: new Date("2024-01-15T09:00:00Z"),
                    dayOfWeek: 1,
                    sanitizedContent: "매우 긴 운동 내용입니다. ".repeat(100),
                })),
            };

            const prompt = promptService.generateAnalysisPrompt(longContentUser);

            expect(prompt.length).toBeLessThanOrEqual(8000);
            if (prompt.length >= 7900) {
                expect(prompt).toContain("데이터가 길어 일부 생략되었습니다");
            }
        });
    });

    describe("date formatting", () => {
        it("should format Korean dates correctly", () => {
            const prompt = promptService.generateAnalysisPrompt(sampleUserData);

            expect(prompt).toContain("2024년 1월 15일 ~ 2024년 1월 21일");
        });

        it("should format day names in Korean", () => {
            const prompt = promptService.generateAnalysisPrompt(sampleUserData);

            expect(prompt).toContain("1/15(월)"); // Monday
            expect(prompt).toContain("1/17(수)"); // Wednesday
            expect(prompt).toContain("1/18(목)"); // Thursday
        });
    });

    describe("exercise type categorization", () => {
        it("should include exercise type distribution in prompts", () => {
            const prompt = promptService.generateAnalysisPrompt(sampleUserData);

            expect(prompt).toContain("헬스/웨이트: 1회");
            expect(prompt).toContain("러닝/조깅: 1회");
        });
    });

    describe("consistency score handling", () => {
        it("should include consistency score in analysis", () => {
            const prompt = promptService.generateAnalysisPrompt(sampleUserData);

            expect(prompt).toContain("일관성 점수(57%)");
            expect(prompt).toContain("일관성 점수: 57%");
        });
    });
});