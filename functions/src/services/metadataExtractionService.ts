/**
 * Metadata Extraction Service
 *
 * This service handles the extraction of structured metadata from certification images
 * using AI analysis. It includes image processing, compression, and integration with
 * the VertexAI service for cost-effective metadata extraction.
 */

import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";
import sharp from "sharp";
import { MetadataExtractionLogger } from "../monitoring/metadataExtractionMonitoring";
import { DietMetadata, ExerciseMetadata, MetadataError } from "./metadataTypes";
import { vertexAIService } from "./vertexAIService";

/**
 * Configuration for image processing
 */
interface ImageProcessingConfig {
    maxWidth: number;
    maxHeight: number;
    quality: number;
    format: "jpeg" | "png" | "webp";
    maxSizeBytes: number;
}

/**
 * Result of image processing operation
 */
interface ProcessedImage {
    buffer: Buffer;
    contentType: string;
    sizeBytes: number;
    base64Data: string;
}

/**
 * Configuration for metadata extraction
 */
interface ExtractionConfig {
    maxRetries: number;
    retryDelayMs: number;
    timeoutMs: number;
}

/**
 * Metadata Extraction Service Class
 */
export class MetadataExtractionService {
    private storage: admin.storage.Storage;
    private imageConfig: ImageProcessingConfig;
    private extractionConfig: ExtractionConfig;

    private static readonly DEFAULT_IMAGE_CONFIG: ImageProcessingConfig = {
        maxWidth: 800,
        maxHeight: 800,
        quality: 80,
        format: "jpeg",
        maxSizeBytes: 1 * 1024 * 1024, // 1MB
    };

    private static readonly DEFAULT_EXTRACTION_CONFIG: ExtractionConfig = {
        maxRetries: 3,
        retryDelayMs: 1000,
        timeoutMs: 30000,
    };

    constructor(
        imageConfig?: Partial<ImageProcessingConfig>,
        extractionConfig?: Partial<ExtractionConfig>
    ) {
        // Initialize storage lazily to avoid Firebase Admin initialization issues
        this.storage = null as any;
        this.imageConfig = { ...MetadataExtractionService.DEFAULT_IMAGE_CONFIG, ...imageConfig };
        this.extractionConfig = { ...MetadataExtractionService.DEFAULT_EXTRACTION_CONFIG, ...extractionConfig };

        logger.info("MetadataExtractionService initialized", {
            imageConfig: this.imageConfig,
            extractionConfig: this.extractionConfig,
        });
    }

    /**
     * Get Firebase Storage instance with lazy initialization
     * @return {admin.storage.Storage} Storage instance
     */
    private getStorage(): admin.storage.Storage {
        if (!this.storage) {
            this.storage = admin.storage();
        }
        return this.storage;
    }

    /**
       * Extract exercise metadata from certification image
       * @param {string} imageUrl - Firebase Storage URL of the image
       * @return {Promise<ExerciseMetadata>} Extracted exercise metadata
       */
    async extractExerciseMetadata(imageUrl: string, certificationId?: string): Promise<ExerciseMetadata> {
        const startTime = Date.now();

        try {
            logger.info("Starting exercise metadata extraction", { imageUrl, certificationId });

            // Process the image
            const processedImage = await this.processImage(imageUrl);
            const imageProcessingTime = Date.now() - startTime;

            // Log image processing metrics
            if (certificationId) {
                MetadataExtractionLogger.logImageProcessing(
                    certificationId,
                    processedImage.buffer.length, // Original size would need to be tracked separately
                    processedImage.sizeBytes,
                    imageProcessingTime,
                    0 // Compression ratio would need to be calculated
                );
            }

            // Generate AI prompt for exercise analysis
            const prompt = this.generateExerciseAnalysisPrompt();
            const aiStartTime = Date.now();

            // Prepare multimodal request
            const requestParts = [
                { text: prompt },
                { inlineData: { mimeType: processedImage.contentType, data: processedImage.base64Data } },
            ];

            // Call VertexAI with image data
            const aiResponse = await vertexAIService.generateAnalysis({
                prompt: requestParts,
                temperature: 0.1, // Low temperature for consistent JSON output
                maxOutputTokens: 200, // Minimal tokens for cost optimization
            });

            const aiResponseTime = Date.now() - aiStartTime;

            // Log API usage metrics
            if (certificationId) {
                MetadataExtractionLogger.logApiUsage(
                    certificationId,
                    "exercise",
                    aiResponse.text.length, // Approximate token count
                    aiResponseTime,
                    this.estimateApiCost(aiResponse.text.length)
                );
            }

            // Parse the AI response
            const metadata = this.parseExerciseMetadata(aiResponse.text);
            const totalProcessingTime = Date.now() - startTime;

            logger.info("Exercise metadata extracted successfully", {
                imageUrl,
                certificationId,
                metadata,
                responseLength: aiResponse.text.length,
                processingTimeMs: totalProcessingTime,
            });

            // Log successful extraction
            if (certificationId) {
                MetadataExtractionLogger.logExtractionSuccess(
                    certificationId,
                    "운동",
                    totalProcessingTime,
                    metadata,
                    {
                        responseLength: aiResponse.text.length,
                        finishReason: aiResponse.finishReason,
                    }
                );
            }

            return metadata;
        } catch (error) {
            const errorMessage = error instanceof Error ? error.message : String(error);
            const processingTime = Date.now() - startTime;

            logger.error("Failed to extract exercise metadata", {
                imageUrl,
                certificationId,
                error: errorMessage,
                stack: error instanceof Error ? error.stack : undefined,
                processingTimeMs: processingTime,
            });

            // Log extraction failure
            if (certificationId) {
                const errorType = this.categorizeError(error);
                MetadataExtractionLogger.logExtractionFailure(
                    certificationId,
                    "운동",
                    errorType,
                    errorMessage,
                    processingTime
                );
            }

            // Return empty metadata with error indication
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
       * Extract diet metadata from certification image
       * @param {string} imageUrl - Firebase Storage URL of the image
       * @return {Promise<DietMetadata>} Extracted diet metadata
       */
    async extractDietMetadata(imageUrl: string, certificationId?: string): Promise<DietMetadata> {
        const startTime = Date.now();

        try {
            logger.info("Starting diet metadata extraction", { imageUrl, certificationId });

            // Process the image
            const processedImage = await this.processImage(imageUrl);
            const imageProcessingTime = Date.now() - startTime;

            // Log image processing metrics
            if (certificationId) {
                MetadataExtractionLogger.logImageProcessing(
                    certificationId,
                    processedImage.buffer.length, // Original size would need to be tracked separately
                    processedImage.sizeBytes,
                    imageProcessingTime,
                    0 // Compression ratio would need to be calculated
                );
            }

            // Generate AI prompt for diet analysis
            const prompt = this.generateDietAnalysisPrompt();
            const aiStartTime = Date.now();

            // Prepare multimodal request
            const requestParts = [
                { text: prompt },
                { inlineData: { mimeType: processedImage.contentType, data: processedImage.base64Data } },
            ];

            // Call VertexAI with image data
            const aiResponse = await vertexAIService.generateAnalysis({
                prompt: requestParts,
                temperature: 0.1, // Low temperature for consistent JSON output
                maxOutputTokens: 200, // Minimal tokens for cost optimization
            });

            const aiResponseTime = Date.now() - aiStartTime;

            // Log API usage metrics
            if (certificationId) {
                MetadataExtractionLogger.logApiUsage(
                    certificationId,
                    "diet",
                    aiResponse.text.length, // Approximate token count
                    aiResponseTime,
                    this.estimateApiCost(aiResponse.text.length)
                );
            }

            // Parse the AI response
            const metadata = this.parseDietMetadata(aiResponse.text);
            const totalProcessingTime = Date.now() - startTime;

            logger.info("Diet metadata extracted successfully", {
                imageUrl,
                certificationId,
                metadata,
                responseLength: aiResponse.text.length,
                processingTimeMs: totalProcessingTime,
            });

            // Log successful extraction
            if (certificationId) {
                MetadataExtractionLogger.logExtractionSuccess(
                    certificationId,
                    "식단",
                    totalProcessingTime,
                    metadata,
                    {
                        responseLength: aiResponse.text.length,
                        finishReason: aiResponse.finishReason,
                    }
                );
            }

            return metadata;
        } catch (error) {
            const errorMessage = error instanceof Error ? error.message : String(error);
            const processingTime = Date.now() - startTime;

            logger.error("Failed to extract diet metadata", {
                imageUrl,
                certificationId,
                error: errorMessage,
                stack: error instanceof Error ? error.stack : undefined,
                processingTimeMs: processingTime,
            });

            // Log extraction failure
            if (certificationId) {
                const errorType = this.categorizeError(error);
                MetadataExtractionLogger.logExtractionFailure(
                    certificationId,
                    "식단",
                    errorType,
                    errorMessage,
                    processingTime
                );
            }

            // Return empty metadata with error indication
            return {
                foodName: null,
                mainIngredients: [],
                estimatedCalories: null,
                extractedAt: new Date(),
            };
        }
    }

    /**
       * Process and optimize image for AI analysis
       * @param {string} imageUrl - Firebase Storage URL of the image
       * @return {Promise<ProcessedImage>} Processed image data
       */
    async processImage(imageUrl: string): Promise<ProcessedImage> {
        try {
            logger.info("Starting image processing", {
                imageUrl,
                config: this.imageConfig,
            });

            // Download image from Firebase Storage
            const imageBuffer = await this.downloadImageFromStorage(imageUrl);

            // Process and compress the image
            const processedBuffer = await this.compressAndResizeImage(imageBuffer);

            // Convert to base64 for AI analysis
            const base64Data = processedBuffer.toString("base64");

            const result: ProcessedImage = {
                buffer: processedBuffer,
                contentType: `image/${this.imageConfig.format}`,
                sizeBytes: processedBuffer.length,
                base64Data,
            };

            logger.info("Image processing completed", {
                imageUrl,
                originalSize: imageBuffer.length,
                processedSize: result.sizeBytes,
                compressionRatio: ((imageBuffer.length - result.sizeBytes) / imageBuffer.length * 100).toFixed(1),
            });

            return result;
        } catch (error) {
            const errorMessage = error instanceof Error ? error.message : String(error);
            logger.error("Failed to process image", {
                imageUrl,
                error: errorMessage,
                stack: error instanceof Error ? error.stack : undefined,
            });

            throw new Error(`Image processing failed: ${errorMessage}`);
        }
    }

    /**
       * Download image from Firebase Storage
       * @param {string} imageUrl - Firebase Storage URL
       * @return {Promise<Buffer>} Image buffer
       */
    private async downloadImageFromStorage(imageUrl: string): Promise<Buffer> {
        try {
            // Extract bucket and file path from URL
            const { bucket, filePath } = this.parseStorageUrl(imageUrl);

            // Get reference to the file
            const file = this.getStorage().bucket(bucket).file(filePath);

            // Check if file exists
            const [exists] = await file.exists();
            if (!exists) {
                throw new Error(`File does not exist: ${filePath}`);
            }

            // Download the file
            const [buffer] = await file.download();

            logger.info("Image downloaded successfully", {
                imageUrl,
                bucket,
                filePath,
                sizeBytes: buffer.length,
            });

            return buffer;
        } catch (error) {
            const errorMessage = error instanceof Error ? error.message : String(error);
            logger.error("Failed to download image from storage", {
                imageUrl,
                error: errorMessage,
            });

            throw new Error(`Storage download failed: ${errorMessage}`);
        }
    }

    /**
       * Parse Firebase Storage URL to extract bucket and file path
       * @param {string} imageUrl - Firebase Storage URL
       * @return {object} Parsed URL components
       */
    private parseStorageUrl(imageUrl: string): { bucket: string; filePath: string } {
        try {
            // Handle different Firebase Storage URL formats
            let bucket: string;
            let filePath: string;

            if (imageUrl.startsWith("gs://")) {
                // Format: gs://bucket-name/path/to/file
                const urlWithoutProtocol = imageUrl.substring(5); // Remove 'gs://'
                const firstSlashIndex = urlWithoutProtocol.indexOf("/");

                if (firstSlashIndex === -1) {
                    throw new Error("Invalid gs:// URL format - no file path found");
                }

                bucket = urlWithoutProtocol.substring(0, firstSlashIndex);
                filePath = urlWithoutProtocol.substring(firstSlashIndex + 1);
            } else if (imageUrl.includes("firebasestorage.googleapis.com")) {
                // Format: https://firebasestorage.googleapis.com/v0/b/bucket/o/path%2Fto%2Ffile?alt=media&token=...
                const url = new URL(imageUrl);
                const pathParts = url.pathname.split("/");
                // Path structure: /v0/b/{bucket}/o/{filePath}
                const bucketIndex = pathParts.indexOf("b") + 1;
                const fileIndex = pathParts.indexOf("o") + 1;
                bucket = pathParts[bucketIndex]; // Extract bucket name
                filePath = decodeURIComponent(pathParts[fileIndex]); // Extract and decode file path
            } else if (imageUrl.includes("storage.googleapis.com")) {
                // Format: https://storage.googleapis.com/bucket/path/to/file
                const url = new URL(imageUrl);
                const pathParts = url.pathname.split("/");
                bucket = pathParts[1];
                filePath = pathParts.slice(2).join("/");
            } else {
                throw new Error("Unsupported storage URL format");
            }

            logger.info("Storage URL parsed successfully", {
                imageUrl,
                bucket,
                filePath,
            });

            return { bucket, filePath };
        } catch (error) {
            const errorMessage = error instanceof Error ? error.message : String(error);
            logger.error("Failed to parse storage URL", {
                imageUrl,
                error: errorMessage,
            });

            throw new Error(`Invalid storage URL: ${errorMessage}`);
        }
    }

    /**
       * Compress and resize image for optimal AI processing
       * @param {Buffer} imageBuffer - Original image buffer
       * @return {Promise<Buffer>} Processed image buffer
       */
    private async compressAndResizeImage(imageBuffer: Buffer): Promise<Buffer> {
        try {
            logger.info("Starting image compression and resize", {
                originalSize: imageBuffer.length,
                targetConfig: this.imageConfig,
            });

            // Get image metadata
            const metadata = await sharp(imageBuffer).metadata();

            logger.info("Original image metadata", {
                width: metadata.width,
                height: metadata.height,
                format: metadata.format,
                size: metadata.size,
            });

            // Calculate new dimensions while maintaining aspect ratio
            const { width: originalWidth, height: originalHeight } = metadata;
            let newWidth = originalWidth || this.imageConfig.maxWidth;
            let newHeight = originalHeight || this.imageConfig.maxHeight;

            if (newWidth > this.imageConfig.maxWidth || newHeight > this.imageConfig.maxHeight) {
                const aspectRatio = newWidth / newHeight;

                if (newWidth > newHeight) {
                    newWidth = this.imageConfig.maxWidth;
                    newHeight = Math.round(newWidth / aspectRatio);
                } else {
                    newHeight = this.imageConfig.maxHeight;
                    newWidth = Math.round(newHeight * aspectRatio);
                }
            }

            // Process the image with Sharp
            let sharpInstance = sharp(imageBuffer)
                .resize(newWidth, newHeight, {
                    fit: "inside",
                    withoutEnlargement: true,
                });

            // Convert to target format with quality settings
            switch (this.imageConfig.format) {
                case "jpeg":
                    sharpInstance = sharpInstance.jpeg({
                        quality: this.imageConfig.quality,
                        progressive: true,
                        mozjpeg: true,
                    });
                    break;
                case "png":
                    sharpInstance = sharpInstance.png({
                        quality: this.imageConfig.quality,
                        compressionLevel: 9,
                    });
                    break;
                case "webp":
                    sharpInstance = sharpInstance.webp({
                        quality: this.imageConfig.quality,
                        effort: 6,
                    });
                    break;
            }

            // Generate the processed image
            const processedBuffer = await sharpInstance.toBuffer();

            // Check if the processed image is still too large
            if (processedBuffer.length > this.imageConfig.maxSizeBytes) {
                logger.warn("Processed image still exceeds max size, applying additional compression", {
                    processedSize: processedBuffer.length,
                    maxSize: this.imageConfig.maxSizeBytes,
                });

                // Apply more aggressive compression
                const aggressiveQuality = Math.max(30, this.imageConfig.quality - 20);
                const reprocessedBuffer = await sharp(imageBuffer)
                    .resize(Math.round(newWidth * 0.8), Math.round(newHeight * 0.8), {
                        fit: "inside",
                        withoutEnlargement: true,
                    })
                    .jpeg({ quality: aggressiveQuality })
                    .toBuffer();

                logger.info("Applied aggressive compression", {
                    originalSize: processedBuffer.length,
                    reprocessedSize: reprocessedBuffer.length,
                    quality: aggressiveQuality,
                });

                return reprocessedBuffer;
            }

            logger.info("Image compression completed successfully", {
                originalSize: imageBuffer.length,
                processedSize: processedBuffer.length,
                compressionRatio: ((imageBuffer.length - processedBuffer.length) / imageBuffer.length * 100).toFixed(1),
                newDimensions: `${newWidth}x${newHeight}`,
            });

            return processedBuffer;
        } catch (error) {
            const errorMessage = error instanceof Error ? error.message : String(error);
            logger.error("Failed to compress and resize image", {
                error: errorMessage,
                originalSize: imageBuffer.length,
                stack: error instanceof Error ? error.stack : undefined,
            });

            // Return original buffer as fallback
            logger.warn("Using original image buffer as fallback");
            return imageBuffer;
        }
    }

    /**
       * Generate improved Korean prompt for exercise analysis with better accuracy
       * @return {string} Exercise analysis prompt
       */
    private generateExerciseAnalysisPrompt(): string {
        return `운동 이미지를 정확하게 분석하세요. JSON만 응답:
{
  "exerciseType": "운동종류",
  "duration": 예상시간(분),
  "timePeriod": "시간대",
  "intensity": "강도"
}

운동 종류 예시:
- 헬스/근력운동 (웨이트 트레이닝, 근력 운동)
- 유산소 운동 (러닝, 사이클링, 수영)
- 요가/필라테스
- 배드민턴/테니스 등 구기 운동
- 축구/농구 등 구기 운동
- 등산/하이킹
- 무술/방어
- 기타 스포츠 활동

시간대: 오전/오후/저녁
강도: 낮음/보통/높음

주의사항:
- 운동 장비나 환경을 보고 정확한 운동 종류 판단
- 불분명하면 null 사용
- 설명 없이 JSON만 출력`;
    }

    /**
       * Generate improved Korean prompt for diet analysis with better accuracy
       * @return {string} Diet analysis prompt
       */
    private generateDietAnalysisPrompt(): string {
        return `이미지의 음식을 정확하게 분석하여 JSON 형식으로 응답하세요.

한국 음식 구분 가이드:
- 떡볶이: 빨간 고추장 소스, 흰 떡, 어묵, 치즈 토핑 가능
- 짜장면: 검은 춘장 소스, 면, 양파, 돼지고기
- 김치찌개: 빨간 국물, 김치, 돼지고기, 두부
- 된장찌개: 갈색 국물, 된장, 두부, 호박
- 비빔밥: 여러 나물, 고추장, 밥
- 불고기: 달콤한 간장 양념, 소고기
- 삼겹살: 구운 돼지고기, 쌈채소
- 치킨: 튀긴 닭고기, 양념 또는 후라이드

응답 형식 (JSON만):
{
  "foodName": "정확한 음식 이름",
  "mainIngredients": ["주재료1", "주재료2", "주재료3"],
  "estimatedCalories": 칼로리숫자
}

주의사항:
1. 이미지를 자세히 관찰하여 색깔, 모양, 재료를 정확히 파악
2. 빨간 소스 = 고추장(떡볶이, 김치찌개) vs 검은 소스 = 춘장(짜장면) 구분
3. 면 종류와 소스 색깔로 면 요리 구분
4. 주재료는 최대 3개, 핵심 재료만 포함
5. 칼로리는 일반적인 1인분 기준
6. 불확실하면 가장 유사한 음식으로 판단
7. 설명 없이 JSON만 출력`;
    }

    /**
       * Parse AI response for exercise metadata with robust validation and confidence scoring
       * @param {string} aiResponse - Raw AI response
       * @return {ExerciseMetadata} Parsed exercise metadata with validation
       */
    private parseExerciseMetadata(aiResponse: string): ExerciseMetadata {
        try {
            logger.info("Starting exercise metadata parsing", {
                responseLength: aiResponse.length,
                responsePreview: aiResponse.substring(0, 100)
            });

            // Extract JSON from response with multiple fallback strategies
            const extractedJson = this.extractJsonFromResponse(aiResponse);
            if (!extractedJson) {
                throw new Error("No valid JSON found in AI response");
            }

            const parsed = JSON.parse(extractedJson);

            // Validate and clean the parsed data
            const validatedMetadata = this.validateExerciseMetadata(parsed);

            // Calculate confidence score based on data completeness and validity
            const confidenceScore = this.calculateExerciseConfidenceScore(validatedMetadata, aiResponse);

            logger.info("Exercise metadata parsed successfully", {
                metadata: validatedMetadata,
                confidenceScore,
                originalResponse: aiResponse.substring(0, 200)
            });

            return {
                ...validatedMetadata,
                confidenceScore,
                extractedAt: new Date(),
            };
        } catch (error) {
            logger.error("Failed to parse exercise metadata", {
                aiResponse: aiResponse.substring(0, 500),
                error: error instanceof Error ? error.message : String(error),
                stack: error instanceof Error ? error.stack : undefined,
            });

            // Return fallback metadata with error indication
            return this.createFallbackExerciseMetadata(aiResponse);
        }
    }

    /**
       * Parse AI response for diet metadata with robust validation and confidence scoring
       * @param {string} aiResponse - Raw AI response
       * @return {DietMetadata} Parsed diet metadata with validation
       */
    private parseDietMetadata(aiResponse: string): DietMetadata {
        try {
            logger.info("Starting diet metadata parsing", {
                responseLength: aiResponse.length,
                responsePreview: aiResponse.substring(0, 100)
            });

            // Extract JSON from response with multiple fallback strategies
            const extractedJson = this.extractJsonFromResponse(aiResponse);
            if (!extractedJson) {
                throw new Error("No valid JSON found in AI response");
            }

            const parsed = JSON.parse(extractedJson);

            // Validate and clean the parsed data
            const validatedMetadata = this.validateDietMetadata(parsed);

            // Calculate confidence score based on data completeness and validity
            const confidenceScore = this.calculateDietConfidenceScore(validatedMetadata, aiResponse);

            logger.info("Diet metadata parsed successfully", {
                metadata: validatedMetadata,
                confidenceScore,
                originalResponse: aiResponse.substring(0, 200)
            });

            return {
                ...validatedMetadata,
                confidenceScore,
                extractedAt: new Date(),
            };
        } catch (error) {
            logger.error("Failed to parse diet metadata", {
                aiResponse: aiResponse.substring(0, 500),
                error: error instanceof Error ? error.message : String(error),
                stack: error instanceof Error ? error.stack : undefined,
            });

            // Return fallback metadata with error indication
            return this.createFallbackDietMetadata(aiResponse);
        }
    }

    /**
       * Extract JSON from AI response with multiple fallback strategies
       * @param {string} response - Raw AI response
       * @return {string | null} Extracted JSON string or null if not found
       */
    private extractJsonFromResponse(response: string): string | null {
        try {
            // Strategy 1: Look for JSON object with curly braces
            const jsonMatch = response.match(/\{[\s\S]*?\}/);
            if (jsonMatch) {
                // Validate that it's proper JSON
                JSON.parse(jsonMatch[0]);
                return jsonMatch[0];
            }

            // Strategy 2: Look for JSON array (fallback)
            const arrayMatch = response.match(/\[[\s\S]*?\]/);
            if (arrayMatch) {
                JSON.parse(arrayMatch[0]);
                return arrayMatch[0];
            }

            // Strategy 3: Try to extract key-value pairs and construct JSON
            const keyValuePattern = /"(\w+)"\s*:\s*(".*?"|null|\d+|true|false)/g;
            const matches = [...response.matchAll(keyValuePattern)];

            if (matches.length > 0) {
                const jsonObject: Record<string, any> = {};
                matches.forEach(match => {
                    const key = match[1];
                    let value = match[2];

                    // Parse the value appropriately
                    if (value === "null") {
                        jsonObject[key] = null;
                    } else if (value === "true" || value === "false") {
                        jsonObject[key] = value === "true";
                    } else if (/^\d+$/.test(value)) {
                        jsonObject[key] = parseInt(value, 10);
                    } else if (/^\d+\.\d+$/.test(value)) {
                        jsonObject[key] = parseFloat(value);
                    } else if (value.startsWith('"') && value.endsWith('"')) {
                        jsonObject[key] = value.slice(1, -1);
                    } else {
                        jsonObject[key] = value;
                    }
                });

                return JSON.stringify(jsonObject);
            }

            logger.warn("No JSON found in AI response", {
                response: response.substring(0, 200)
            });
            return null;
        } catch (error) {
            logger.error("Failed to extract JSON from response", {
                response: response.substring(0, 200),
                error: error instanceof Error ? error.message : String(error),
            });
            return null;
        }
    }

    /**
       * Validate and clean exercise metadata
       * @param {any} parsed - Parsed JSON object
       * @return {Omit<ExerciseMetadata, 'extractedAt'>} Validated exercise metadata
       */
    private validateExerciseMetadata(parsed: any): Omit<ExerciseMetadata, 'extractedAt'> {
        const validExerciseTypes = [
            "러닝", "조깅", "달리기", "마라톤",
            "웨이트 트레이닝", "헬스", "근력운동", "보디빌딩",
            "요가", "필라테스", "스트레칭",
            "수영", "아쿠아로빅",
            "사이클링", "자전거", "실내자전거",
            "배드민턴", "테니스", "탁구",
            "축구", "농구", "배구",
            "등산", "하이킹", "트레킹",
            "복싱", "태권도", "무술",
            "댄스", "에어로빅", "줌바",
            "기타"
        ];

        const validTimePeriods = ["오전", "오후", "저녁", "새벽", "밤"];
        const validIntensities = ["낮음", "보통", "높음"];

        // Validate exercise type
        let exerciseType: string | null = null;
        if (typeof parsed.exerciseType === "string" && parsed.exerciseType.trim()) {
            const normalizedType = parsed.exerciseType.trim();
            // Check if it matches any valid type or contains keywords
            if (validExerciseTypes.some(type =>
                normalizedType.includes(type) || type.includes(normalizedType)
            )) {
                exerciseType = normalizedType;
            } else {
                // If not in predefined list, still accept if it looks like an exercise
                if (normalizedType.length > 1 && normalizedType.length < 20) {
                    exerciseType = normalizedType;
                }
            }
        }

        // Validate duration (should be reasonable for exercise)
        let duration: number | null = null;
        if (typeof parsed.duration === "number" && parsed.duration > 0 && parsed.duration <= 480) {
            duration = Math.round(parsed.duration);
        } else if (typeof parsed.duration === "string") {
            const parsedDuration = parseInt(parsed.duration, 10);
            if (!isNaN(parsedDuration) && parsedDuration > 0 && parsedDuration <= 480) {
                duration = parsedDuration;
            }
        }

        // Validate time period
        let timePeriod: string | null = null;
        if (typeof parsed.timePeriod === "string" && parsed.timePeriod.trim()) {
            const normalizedPeriod = parsed.timePeriod.trim();
            if (validTimePeriods.includes(normalizedPeriod)) {
                timePeriod = normalizedPeriod;
            }
        }

        // Validate intensity
        let intensity: string | null = null;
        if (typeof parsed.intensity === "string" && parsed.intensity.trim()) {
            const normalizedIntensity = parsed.intensity.trim();
            if (validIntensities.includes(normalizedIntensity)) {
                intensity = normalizedIntensity;
            }
        }

        return {
            exerciseType,
            duration,
            timePeriod,
            intensity,
        };
    }

    /**
       * Validate and clean diet metadata
       * @param {any} parsed - Parsed JSON object
       * @return {Omit<DietMetadata, 'extractedAt'>} Validated diet metadata
       */
    private validateDietMetadata(parsed: any): Omit<DietMetadata, 'extractedAt'> {
        // Validate food name
        let foodName: string | null = null;
        if (typeof parsed.foodName === "string" && parsed.foodName.trim()) {
            const normalizedName = parsed.foodName.trim();
            // Basic validation: should be reasonable length and contain valid characters
            if (normalizedName.length > 0 && normalizedName.length <= 50) {
                foodName = normalizedName;
            }
        }

        // Validate main ingredients
        let mainIngredients: string[] = [];
        if (Array.isArray(parsed.mainIngredients)) {
            mainIngredients = parsed.mainIngredients
                .filter((ingredient: any) =>
                    typeof ingredient === "string" &&
                    ingredient.trim().length > 0 &&
                    ingredient.trim().length <= 20
                )
                .map((ingredient: string) => ingredient.trim())
                .slice(0, 2); // Limit to 2 ingredients as per design
        }

        // Validate estimated calories (should be reasonable for a meal)
        let estimatedCalories: number | null = null;
        if (typeof parsed.estimatedCalories === "number" &&
            parsed.estimatedCalories > 0 &&
            parsed.estimatedCalories <= 5000) {
            estimatedCalories = Math.round(parsed.estimatedCalories);
        } else if (typeof parsed.estimatedCalories === "string") {
            const parsedCalories = parseInt(parsed.estimatedCalories, 10);
            if (!isNaN(parsedCalories) && parsedCalories > 0 && parsedCalories <= 5000) {
                estimatedCalories = parsedCalories;
            }
        }

        return {
            foodName,
            mainIngredients,
            estimatedCalories,
        };
    }

    /**
     * Categorize error type for monitoring
     * @param {Error | unknown} error - The error to categorize
     * @return {"image_processing" | "ai_service" | "parsing" | "unknown"} Error category
     */
    private categorizeError(error: Error | unknown): "image_processing" | "ai_service" | "parsing" | "unknown" {
        if (error instanceof Error) {
            const message = error.message.toLowerCase();

            if (message.includes("image") || message.includes("sharp") || message.includes("storage")) {
                return "image_processing";
            }

            if (message.includes("vertex") || message.includes("api") || message.includes("quota") || message.includes("rate limit")) {
                return "ai_service";
            }

            if (message.includes("json") || message.includes("parse") || message.includes("invalid")) {
                return "parsing";
            }
        }

        return "unknown";
    }

    /**
     * Estimate API cost based on token usage
     * @param {number} tokenCount - Approximate token count
     * @return {number} Estimated cost in USD
     */
    private estimateApiCost(tokenCount: number): number {
        // Gemini Pro pricing (approximate): $0.00025 per 1K tokens for input, $0.0005 per 1K tokens for output
        // This is a rough estimate - actual pricing may vary
        const inputCostPer1K = 0.00025;
        const outputCostPer1K = 0.0005;

        // Assume roughly equal input/output tokens for simplicity
        const inputTokens = tokenCount * 0.7; // Prompt is usually larger
        const outputTokens = tokenCount * 0.3;

        const inputCost = (inputTokens / 1000) * inputCostPer1K;
        const outputCost = (outputTokens / 1000) * outputCostPer1K;

        return inputCost + outputCost;
    }

    /**
       * Calculate confidence score for exercise metadata
       * @param {Omit<ExerciseMetadata, 'extractedAt'>} metadata - Validated metadata
       * @param {string} originalResponse - Original AI response
       * @return {number} Confidence score between 0 and 1
       */
    private calculateExerciseConfidenceScore(
        metadata: Omit<ExerciseMetadata, 'extractedAt'>,
        originalResponse: string
    ): number {
        let score = 0;
        let maxScore = 0;

        // Exercise type confidence (40% weight)
        maxScore += 0.4;
        if (metadata.exerciseType) {
            score += 0.4;
            // Bonus for specific exercise types
            const specificTypes = ["러닝", "웨이트 트레이닝", "요가", "수영", "사이클링"];
            if (specificTypes.some(type => metadata.exerciseType?.includes(type))) {
                score += 0.1;
                maxScore += 0.1;
            }
        }

        // Duration confidence (25% weight)
        maxScore += 0.25;
        if (metadata.duration) {
            score += 0.25;
            // Bonus for reasonable duration (15-120 minutes)
            if (metadata.duration >= 15 && metadata.duration <= 120) {
                score += 0.05;
                maxScore += 0.05;
            }
        }

        // Time period confidence (20% weight)
        maxScore += 0.2;
        if (metadata.timePeriod) {
            score += 0.2;
        }

        // Intensity confidence (15% weight)
        maxScore += 0.15;
        if (metadata.intensity) {
            score += 0.15;
        }

        // Response quality bonus (check for Korean text and proper formatting)
        if (originalResponse.includes("운동") || originalResponse.includes("분")) {
            score += 0.05;
            maxScore += 0.05;
        }

        return maxScore > 0 ? Math.min(score / maxScore, 1) : 0;
    }

    /**
       * Calculate confidence score for diet metadata
       * @param {Omit<DietMetadata, 'extractedAt'>} metadata - Validated metadata
       * @param {string} originalResponse - Original AI response
       * @return {number} Confidence score between 0 and 1
       */
    private calculateDietConfidenceScore(
        metadata: Omit<DietMetadata, 'extractedAt'>,
        originalResponse: string
    ): number {
        let score = 0;
        let maxScore = 0;

        // Food name confidence (50% weight)
        maxScore += 0.5;
        if (metadata.foodName) {
            score += 0.5;
            // Bonus for Korean food names
            if (/[가-힣]/.test(metadata.foodName)) {
                score += 0.1;
                maxScore += 0.1;
            }
        }

        // Main ingredients confidence (25% weight)
        maxScore += 0.25;
        if (metadata.mainIngredients.length > 0) {
            score += 0.25 * (metadata.mainIngredients.length / 2); // Max 2 ingredients
        }

        // Calories confidence (25% weight)
        maxScore += 0.25;
        if (metadata.estimatedCalories) {
            score += 0.25;
            // Bonus for reasonable calorie range (50-1500)
            if (metadata.estimatedCalories >= 50 && metadata.estimatedCalories <= 1500) {
                score += 0.05;
                maxScore += 0.05;
            }
        }

        // Response quality bonus
        if (originalResponse.includes("음식") || originalResponse.includes("칼로리")) {
            score += 0.05;
            maxScore += 0.05;
        }

        return maxScore > 0 ? Math.min(score / maxScore, 1) : 0;
    }

    /**
       * Create fallback exercise metadata when parsing fails
       * @param {string} originalResponse - Original AI response for context
       * @return {ExerciseMetadata} Fallback metadata
       */
    private createFallbackExerciseMetadata(originalResponse: string): ExerciseMetadata {
        // Try to extract some basic information from the response text
        let exerciseType: string | null = null;
        let duration: number | null = null;

        // Simple keyword extraction as fallback
        const exerciseKeywords = ["러닝", "헬스", "요가", "수영", "운동"];
        for (const keyword of exerciseKeywords) {
            if (originalResponse.includes(keyword)) {
                exerciseType = keyword;
                break;
            }
        }

        // Try to extract duration numbers
        const durationMatch = originalResponse.match(/(\d+)\s*분/);
        if (durationMatch) {
            const extractedDuration = parseInt(durationMatch[1], 10);
            if (extractedDuration > 0 && extractedDuration <= 480) {
                duration = extractedDuration;
            }
        }

        logger.info("Created fallback exercise metadata", {
            exerciseType,
            duration,
            originalResponse: originalResponse.substring(0, 100)
        });

        return {
            exerciseType,
            duration,
            timePeriod: null,
            intensity: null,
            confidenceScore: 0.1, // Low confidence for fallback data
            extractedAt: new Date(),
        };
    }

    /**
       * Create fallback diet metadata when parsing fails
       * @param {string} originalResponse - Original AI response for context
       * @return {DietMetadata} Fallback metadata
       */
    private createFallbackDietMetadata(originalResponse: string): DietMetadata {
        // Try to extract some basic information from the response text
        let foodName: string | null = null;
        let estimatedCalories: number | null = null;

        // Simple keyword extraction as fallback
        const foodKeywords = ["밥", "국", "찌개", "면", "빵", "샐러드", "음식"];
        for (const keyword of foodKeywords) {
            if (originalResponse.includes(keyword)) {
                foodName = keyword;
                break;
            }
        }

        // Try to extract calorie numbers
        const calorieMatch = originalResponse.match(/(\d+)\s*칼로리/);
        if (calorieMatch) {
            const extractedCalories = parseInt(calorieMatch[1], 10);
            if (extractedCalories > 0 && extractedCalories <= 5000) {
                estimatedCalories = extractedCalories;
            }
        }

        logger.info("Created fallback diet metadata", {
            foodName,
            estimatedCalories,
            originalResponse: originalResponse.substring(0, 100)
        });

        return {
            foodName,
            mainIngredients: [],
            estimatedCalories,
            confidenceScore: 0.1, // Low confidence for fallback data
            extractedAt: new Date(),
        };
    }

    /**
       * Validate overall quality of extracted metadata
       * @param {ExerciseMetadata | DietMetadata} metadata - Extracted metadata
       * @param {string} type - Type of metadata ("exercise" or "diet")
       * @return {boolean} Whether the metadata meets quality standards
       */
    private validateMetadataQuality(
        metadata: ExerciseMetadata | DietMetadata,
        type: "exercise" | "diet"
    ): boolean {
        // Check confidence score threshold
        const minConfidenceScore = 0.3;
        if (metadata.confidenceScore && metadata.confidenceScore < minConfidenceScore) {
            logger.warn("Metadata quality check failed: low confidence score", {
                type,
                confidenceScore: metadata.confidenceScore,
                minRequired: minConfidenceScore
            });
            return false;
        }

        if (type === "exercise") {
            const exerciseMetadata = metadata as ExerciseMetadata;
            // At least exercise type should be present for quality
            if (!exerciseMetadata.exerciseType) {
                logger.warn("Exercise metadata quality check failed: missing exercise type");
                return false;
            }
        } else if (type === "diet") {
            const dietMetadata = metadata as DietMetadata;
            // At least food name should be present for quality
            if (!dietMetadata.foodName) {
                logger.warn("Diet metadata quality check failed: missing food name");
                return false;
            }
        }

        return true;
    }

    /**
       * Implement retry logic with exponential backoff
       * @param {() => Promise<T>} operation - Operation to retry
       * @param {number} maxRetries - Maximum number of retries
       * @param {number} baseDelayMs - Base delay in milliseconds
       * @return {Promise<T>} Result of the operation
       */
    private async retryWithBackoff<T>(
        operation: () => Promise<T>,
        maxRetries: number = this.extractionConfig.maxRetries,
        baseDelayMs: number = this.extractionConfig.retryDelayMs
    ): Promise<T> {
        let lastError: Error;

        for (let attempt = 0; attempt <= maxRetries; attempt++) {
            try {
                return await operation();
            } catch (error) {
                lastError = error instanceof Error ? error : new Error(String(error));

                if (attempt === maxRetries) {
                    logger.error("All retry attempts exhausted", {
                        attempts: attempt + 1,
                        lastError: lastError.message
                    });
                    throw lastError;
                }

                // Calculate delay with exponential backoff and jitter
                const delay = baseDelayMs * Math.pow(2, attempt) + Math.random() * 1000;

                logger.warn("Operation failed, retrying with backoff", {
                    attempt: attempt + 1,
                    maxRetries,
                    delayMs: Math.round(delay),
                    error: lastError.message
                });

                await new Promise(resolve => setTimeout(resolve, delay));
            }
        }

        throw lastError!;
    }

    /**
       * Enhanced metadata extraction with quality checks and retry logic
       * @param {string} imageUrl - Firebase Storage URL of the image
       * @param {"exercise" | "diet"} type - Type of metadata to extract
       * @return {Promise<ExerciseMetadata | DietMetadata>} Extracted metadata
       */
    async extractMetadataWithQualityCheck(
        imageUrl: string,
        type: "exercise" | "diet"
    ): Promise<ExerciseMetadata | DietMetadata> {
        return this.retryWithBackoff(async () => {
            let metadata: ExerciseMetadata | DietMetadata;

            if (type === "exercise") {
                metadata = await this.extractExerciseMetadata(imageUrl);
            } else {
                metadata = await this.extractDietMetadata(imageUrl);
            }

            // Validate quality
            if (!this.validateMetadataQuality(metadata, type)) {
                throw new Error(`Metadata quality check failed for ${type} extraction`);
            }

            return metadata;
        });
    }

    /**
       * Create metadata error object
       * @param {string} errorType - Type of error
       * @param {string} errorMessage - Error message
       * @param {number} retryCount - Number of retries attempted
       * @return {MetadataError} Metadata error object
       */
    createMetadataError(
        errorType: MetadataError["errorType"],
        errorMessage: string,
        retryCount = 0
    ): MetadataError {
        return {
            errorType,
            errorMessage,
            retryCount,
            lastRetryAt: new Date(),
            canRetry: errorType !== "parsing" && retryCount < this.extractionConfig.maxRetries,
        };
    }

    /**
       * Test the metadata extraction service
       * @param {string} testImageUrl - URL of test image
       * @return {Promise<boolean>} Whether the test passed
       */
    async testService(testImageUrl: string): Promise<boolean> {
        try {
            logger.info("Testing metadata extraction service", { testImageUrl });

            // Test image processing
            const processedImage = await this.processImage(testImageUrl);

            if (!processedImage.base64Data || processedImage.sizeBytes === 0) {
                throw new Error("Image processing failed");
            }

            logger.info("Metadata extraction service test passed", {
                testImageUrl,
                processedSize: processedImage.sizeBytes,
            });

            return true;
        } catch (error) {
            logger.error("Metadata extraction service test failed", {
                testImageUrl,
                error: error instanceof Error ? error.message : String(error),
            });

            return false;
        }
    }

    /**
       * Get service configuration
       * @return {object} Current service configuration
       */
    getConfiguration(): { imageConfig: ImageProcessingConfig; extractionConfig: ExtractionConfig } {
        return {
            imageConfig: this.imageConfig,
            extractionConfig: this.extractionConfig,
        };
    }
}

// Export singleton instance
export const metadataExtractionService = new MetadataExtractionService();
