/**
 * Simplified metadata types for AI-powered certification analysis
 * Optimized for cost-effective API usage with minimal essential fields
 */

/**
 * Exercise metadata extracted from fitness app screenshots and workout images
 * Contains only 4 essential fields to minimize API costs
 */
export interface ExerciseMetadata {
    /** Type of exercise performed (e.g., "러닝", "웨이트 트레이닝", "요가") */
    exerciseType: string | null;

    /** Duration of exercise in minutes */
    duration: number | null;

    /** Time period when exercise was performed ("오전", "오후", "저녁") */
    timePeriod: string | null;

    /** Exercise intensity level ("낮음", "보통", "높음") */
    intensity: string | null;

    /** Confidence score for the extracted data (0-1) */
    confidenceScore?: number;

    /** Timestamp when metadata was extracted */
    extractedAt: Date;
}

/**
 * Diet metadata extracted from food photos and meal images
 * Simplified to focus on essential food identification only
 */
export interface DietMetadata {
    /** Name of the food/dish (e.g., "김치찌개", "햄버거", "샐러드") */
    foodName: string | null;

    /** 1-2 main ingredients identified in the food */
    mainIngredients: string[];

    /** Estimated calories for the meal/food item */
    estimatedCalories: number | null;

    /** Confidence score for the extracted data (0-1) */
    confidenceScore?: number;

    /** Timestamp when metadata was extracted */
    extractedAt: Date;
}

/**
 * Error information for failed metadata extraction attempts
 */
export interface MetadataError {
    /** Type of error that occurred during extraction */
    errorType: "image_processing" | "ai_service" | "parsing" | "unknown";

    /** Human-readable error message */
    errorMessage: string;

    /** Number of retry attempts made */
    retryCount: number;

    /** Timestamp of last retry attempt */
    lastRetryAt: Date;

    /** Whether this extraction can be retried */
    canRetry: boolean;
}

/**
 * Enhanced certification document structure with optional metadata fields
 * Maintains backward compatibility with existing certifications
 */
export interface CertificationDocument {
    [x: string]: any;
    // Existing fields
    uuid: string;
    nickname: string;
    createdAt: FirebaseFirestore.Timestamp;
    type: "운동" | "식단";
    content: string;
    photoUrl: string;
    userUuid: string;

    // New optional metadata fields
    exerciseMetadata?: ExerciseMetadata;
    dietMetadata?: DietMetadata;
    metadataProcessed: boolean;
    metadataError?: MetadataError;
}
