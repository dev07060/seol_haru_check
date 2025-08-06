/**
 * Standalone Metadata Extraction Cloud Function
 * 
 * This file contains only the processMetadataExtraction function
 * with minimal dependencies to avoid Firebase Admin initialization issues.
 */

import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";
import { onDocumentCreated } from "firebase-functions/v2/firestore";

// Firebase Admin is initialized in index.ts

interface CertificationDocument {
    uuid: string;
    nickname: string;
    createdAt: admin.firestore.Timestamp;
    type: "운동" | "식단";
    content: string;
    photoUrl: string;
    metadataProcessed?: boolean;
    exerciseMetadata?: any;
    dietMetadata?: any;
    metadataError?: any;
}

interface MetadataError {
    errorType: "image_processing" | "ai_service" | "parsing" | "unknown";
    errorMessage: string;
    retryCount: number;
    lastRetryAt: Date;
    canRetry: boolean;
}

/**
 * Extract metadata using AI service
 */
async function extractMetadataWithAI(photoUrl: string, type: "운동" | "식단"): Promise<any> {
    try {
        // Import the metadata extraction service dynamically
        const { metadataExtractionService } = await import("./services/metadataExtractionService");

        if (type === "운동") {
            return await metadataExtractionService.extractExerciseMetadata(photoUrl);
        } else if (type === "식단") {
            return await metadataExtractionService.extractDietMetadata(photoUrl);
        }

        return null;
    } catch (error) {
        logger.warn("AI metadata extraction failed, using fallback", {
            photoUrl,
            type,
            error: error instanceof Error ? error.message : String(error),
        });

        // Fallback to basic structure if AI fails
        if (type === "운동") {
            return {
                exerciseType: null,
                duration: null,
                timePeriod: null,
                intensity: null,
                extractedAt: new Date(),
            };
        } else if (type === "식단") {
            return {
                mainIngredients: [],
                foodCategory: null,
                mealTime: null,
                estimatedCalories: null,
                extractedAt: new Date(),
            };
        }

        return null;
    }
}

/**
 * Process Metadata Extraction Cloud Function
 */
export const processMetadataExtraction = onDocumentCreated({
    document: "certifications/{certificationId}",
    region: "asia-northeast3",
    memory: "512MiB",
    timeoutSeconds: 60,
}, async (event): Promise<void> => {
    const certificationData = event.data?.data() as CertificationDocument;
    const certificationId = event.params.certificationId;

    if (!certificationData) {
        logger.error("No certification data found", { certificationId });
        return;
    }

    logger.info("Processing metadata extraction for certification", {
        certificationId,
        type: certificationData.type,
        userUuid: certificationData.uuid,
        photoUrl: certificationData.photoUrl,
    });

    try {
        // Skip if metadata already processed or no photo URL
        if (certificationData.metadataProcessed || !certificationData.photoUrl) {
            logger.info("Skipping metadata extraction", {
                certificationId,
                reason: certificationData.metadataProcessed ? "already_processed" : "no_photo_url",
            });
            return;
        }

        // Update document to indicate processing has started
        await event.data?.ref.update({
            metadataProcessed: false,
            metadataProcessingStartedAt: new Date(),
        });

        // Extract metadata
        let extractedMetadata: any = null;
        let metadataField: string;

        if (certificationData.type === "운동") {
            logger.info("Extracting exercise metadata", { certificationId });
            metadataField = "exerciseMetadata";

            try {
                extractedMetadata = await extractMetadataWithAI(
                    certificationData.photoUrl,
                    certificationData.type
                );

                logger.info("Exercise metadata extracted successfully", {
                    certificationId,
                    metadata: extractedMetadata,
                });
            } catch (error) {
                logger.warn("Exercise metadata extraction failed, using fallback", {
                    certificationId,
                    error: error instanceof Error ? error.message : String(error),
                });

                extractedMetadata = {
                    exerciseType: null,
                    duration: null,
                    timePeriod: null,
                    intensity: null,
                    extractedAt: new Date(),
                };
            }
        } else if (certificationData.type === "식단") {
            logger.info("Extracting diet metadata", { certificationId });
            metadataField = "dietMetadata";

            try {
                extractedMetadata = await extractMetadataWithAI(
                    certificationData.photoUrl,
                    certificationData.type
                );

                logger.info("Diet metadata extracted successfully", {
                    certificationId,
                    metadata: extractedMetadata,
                });
            } catch (error) {
                logger.warn("Diet metadata extraction failed, using fallback", {
                    certificationId,
                    error: error instanceof Error ? error.message : String(error),
                });

                extractedMetadata = {
                    mainIngredients: [],
                    foodCategory: null,
                    mealTime: null,
                    estimatedCalories: null,
                    extractedAt: new Date(),
                };
            }
        } else {
            logger.warn("Unknown certification type, skipping metadata extraction", {
                certificationId,
                type: certificationData.type,
            });

            await event.data?.ref.update({
                metadataProcessed: true,
                metadataProcessingCompletedAt: new Date(),
                metadataError: {
                    errorType: "unknown",
                    errorMessage: `Unknown certification type: ${certificationData.type}`,
                    retryCount: 0,
                    lastRetryAt: new Date(),
                    canRetry: false,
                } as MetadataError,
            });
            return;
        }

        // Update the certification document with extracted metadata
        const updateData: any = {
            [metadataField]: extractedMetadata,
            metadataProcessed: true,
            metadataProcessingCompletedAt: new Date(),
        };

        // Remove any previous error if extraction was successful
        if (extractedMetadata) {
            updateData.metadataError = admin.firestore.FieldValue.delete();
        }

        await event.data?.ref.update(updateData);

        logger.info("Metadata extraction completed successfully", {
            certificationId,
            type: certificationData.type,
            metadataField,
            hasValidMetadata: extractedMetadata !== null,
        });

    } catch (error) {
        const errorMessage = error instanceof Error ? error.message : String(error);
        logger.error("Metadata extraction failed with error", {
            certificationId,
            type: certificationData.type,
            error: errorMessage,
            stack: error instanceof Error ? error.stack : undefined,
        });

        // Create metadata error object
        const metadataError: MetadataError = {
            errorType: "ai_service",
            errorMessage,
            retryCount: 0,
            lastRetryAt: new Date(),
            canRetry: true,
        };

        // Update document with error information
        try {
            await event.data?.ref.update({
                metadataProcessed: true,
                metadataProcessingCompletedAt: new Date(),
                metadataError,
            });
        } catch (updateError) {
            logger.error("Failed to update document with error information", {
                certificationId,
                updateError: updateError instanceof Error ? updateError.message : String(updateError),
            });
        }

        logger.info("Metadata extraction failed but certification flow continues", {
            certificationId,
            originalError: errorMessage,
        });
    }
});