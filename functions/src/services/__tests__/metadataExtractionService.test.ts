/**
 * Tests for MetadataExtractionService parsing and validation functionality
 */

import { MetadataExtractionService } from "../metadataExtractionService";
import { ExerciseMetadata } from "../metadataTypes";

// Mock Firebase Admin and logger
jest.mock("firebase-admin", () => ({
    storage: jest.fn(() => ({
        bucket: jest.fn(() => ({
            file: jest.fn(() => ({
                exists: jest.fn(() => Promise.resolve([true])),
                download: jest.fn(() => Promise.resolve([Buffer.from("mock image data")])),
            })),
        })),
    })),
}));

jest.mock("firebase-functions/logger", () => ({
    info: jest.fn(),
    warn: jest.fn(),
    error: jest.fn(),
}));

jest.mock("../vertexAIService", () => ({
    vertexAIService: {
        generateAnalysis: jest.fn(),
    },
}));

describe("MetadataExtractionService - Parsing and Validation", () => {
    let service: MetadataExtractionService;

    beforeEach(() => {
        service = new MetadataExtractionService();
        jest.clearAllMocks();
    });

    describe("JSON Extraction", () => {
        test("should extract valid JSON from AI response", () => {
            const response = 'Here is the analysis: {"exerciseType":"러닝","duration":30,"timePeriod":"오전","intensity":"보통"}';
            const result = (service as any).extractJsonFromResponse(response);

            expect(result).toBe('{"exerciseType":"러닝","duration":30,"timePeriod":"오전","intensity":"보통"}');
        });

        test("should handle malformed JSON with fallback extraction", () => {
            const response = 'Analysis: "exerciseType":"러닝", "duration":30, "timePeriod":"오전"';
            const result = (service as any).extractJsonFromResponse(response);

            expect(result).toBeTruthy();
            const parsed = JSON.parse(result!);
            expect(parsed.exerciseType).toBe("러닝");
            expect(parsed.duration).toBe(30);
        });

        test("should return null for response without JSON", () => {
            const response = "This is just plain text without any structured data";
            const result = (service as any).extractJsonFromResponse(response);

            expect(result).toBeNull();
        });
    });

    describe("Exercise Metadata Validation", () => {
        test("should validate correct exercise metadata", () => {
            const parsed = {
                exerciseType: "러닝",
                duration: 30,
                timePeriod: "오전",
                intensity: "보통"
            };

            const result = (service as any).validateExerciseMetadata(parsed);

            expect(result.exerciseType).toBe("러닝");
            expect(result.duration).toBe(30);
            expect(result.timePeriod).toBe("오전");
            expect(result.intensity).toBe("보통");
        });

        test("should reject invalid exercise duration", () => {
            const parsed = {
                exerciseType: "러닝",
                duration: 600, // Too long (10 hours)
                timePeriod: "오전",
                intensity: "보통"
            };

            const result = (service as any).validateExerciseMetadata(parsed);

            expect(result.exerciseType).toBe("러닝");
            expect(result.duration).toBeNull(); // Should be rejected
            expect(result.timePeriod).toBe("오전");
            expect(result.intensity).toBe("보통");
        });

        test("should reject invalid time period", () => {
            const parsed = {
                exerciseType: "러닝",
                duration: 30,
                timePeriod: "invalid_time",
                intensity: "보통"
            };

            const result = (service as any).validateExerciseMetadata(parsed);

            expect(result.timePeriod).toBeNull(); // Should be rejected
        });

        test("should handle string duration conversion", () => {
            const parsed = {
                exerciseType: "러닝",
                duration: "45", // String number
                timePeriod: "오전",
                intensity: "보통"
            };

            const result = (service as any).validateExerciseMetadata(parsed);

            expect(result.duration).toBe(45); // Should be converted to number
        });
    });

    describe("Diet Metadata Validation", () => {
        test("should validate correct diet metadata", () => {
            const parsed = {
                foodName: "김치찌개",
                mainIngredients: ["김치", "돼지고기"],
                estimatedCalories: 350
            };

            const result = (service as any).validateDietMetadata(parsed);

            expect(result.foodName).toBe("김치찌개");
            expect(result.mainIngredients).toEqual(["김치", "돼지고기"]);
            expect(result.estimatedCalories).toBe(350);
        });

        test("should limit ingredients to maximum 2", () => {
            const parsed = {
                foodName: "비빔밥",
                mainIngredients: ["밥", "나물", "고추장", "계란", "당근"], // 5 ingredients
                estimatedCalories: 450
            };

            const result = (service as any).validateDietMetadata(parsed);

            expect(result.mainIngredients).toHaveLength(2); // Should be limited to 2
            expect(result.mainIngredients).toEqual(["밥", "나물"]);
        });

        test("should reject unrealistic calorie values", () => {
            const parsed = {
                foodName: "샐러드",
                mainIngredients: ["양상추"],
                estimatedCalories: 10000 // Unrealistic
            };

            const result = (service as any).validateDietMetadata(parsed);

            expect(result.estimatedCalories).toBeNull(); // Should be rejected
        });

        test("should handle string calorie conversion", () => {
            const parsed = {
                foodName: "샐러드",
                mainIngredients: ["양상추"],
                estimatedCalories: "250" // String number
            };

            const result = (service as any).validateDietMetadata(parsed);

            expect(result.estimatedCalories).toBe(250); // Should be converted to number
        });
    });

    describe("Confidence Scoring", () => {
        test("should calculate high confidence for complete exercise metadata", () => {
            const metadata = {
                exerciseType: "러닝",
                duration: 30,
                timePeriod: "오전",
                intensity: "보통"
            };
            const response = "운동 분석 결과입니다";

            const score = (service as any).calculateExerciseConfidenceScore(metadata, response);

            expect(score).toBeGreaterThan(0.8); // Should be high confidence
        });

        test("should calculate low confidence for incomplete exercise metadata", () => {
            const metadata = {
                exerciseType: null,
                duration: null,
                timePeriod: null,
                intensity: null
            };
            const response = "분석 실패";

            const score = (service as any).calculateExerciseConfidenceScore(metadata, response);

            expect(score).toBeLessThan(0.3); // Should be low confidence
        });

        test("should calculate high confidence for complete diet metadata", () => {
            const metadata = {
                foodName: "김치찌개",
                mainIngredients: ["김치", "돼지고기"],
                estimatedCalories: 350
            };
            const response = "음식 분석 결과 칼로리는";

            const score = (service as any).calculateDietConfidenceScore(metadata, response);

            expect(score).toBeGreaterThan(0.8); // Should be high confidence
        });
    });

    describe("Fallback Mechanisms", () => {
        test("should create fallback exercise metadata from text", () => {
            const response = "러닝을 30분 동안 했습니다";

            const result = (service as any).createFallbackExerciseMetadata(response);

            expect(result.exerciseType).toBe("러닝");
            expect(result.duration).toBe(30);
            expect(result.confidenceScore).toBe(0.1); // Low confidence for fallback
        });

        test("should create fallback diet metadata from text", () => {
            const response = "김치찌개 350칼로리 정도입니다";

            const result = (service as any).createFallbackDietMetadata(response);

            expect(result.foodName).toBe("찌개");
            expect(result.estimatedCalories).toBe(350);
            expect(result.confidenceScore).toBe(0.1); // Low confidence for fallback
        });
    });

    describe("Quality Validation", () => {
        test("should pass quality check for good exercise metadata", () => {
            const metadata: ExerciseMetadata = {
                exerciseType: "러닝",
                duration: 30,
                timePeriod: "오전",
                intensity: "보통",
                confidenceScore: 0.8,
                extractedAt: new Date()
            };

            const result = (service as any).validateMetadataQuality(metadata, "exercise");

            expect(result).toBe(true);
        });

        test("should fail quality check for low confidence metadata", () => {
            const metadata: ExerciseMetadata = {
                exerciseType: "러닝",
                duration: 30,
                timePeriod: "오전",
                intensity: "보통",
                confidenceScore: 0.1, // Too low
                extractedAt: new Date()
            };

            const result = (service as any).validateMetadataQuality(metadata, "exercise");

            expect(result).toBe(false);
        });

        test("should fail quality check for missing essential data", () => {
            const metadata: ExerciseMetadata = {
                exerciseType: null, // Missing essential field
                duration: 30,
                timePeriod: "오전",
                intensity: "보통",
                confidenceScore: 0.8,
                extractedAt: new Date()
            };

            const result = (service as any).validateMetadataQuality(metadata, "exercise");

            expect(result).toBe(false);
        });
    });
});