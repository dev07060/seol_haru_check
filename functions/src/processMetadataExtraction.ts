/**
 * Process Metadata Extraction Cloud Function
 *
 * Triggered when a new certification document is created in Firestore.
 * Automatically extracts metadata from certification images using AI analysis.
 * Implements proper error handling with graceful degradation.
 */

import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";
import type { FirestoreEvent } from "firebase-functions/v2/firestore";
import { onDocumentCreated } from "firebase-functions/v2/firestore";

// Import monitoring logger
import { MetadataExtractionLogger } from "./monitoring/metadataExtractionMonitoring";

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
 * Process Metadata Extraction Cloud Function
 */
export const processMetadataExtraction = onDocumentCreated({
    document: "certifications/{certificationId}",
    region: "asia-northeast3",
    memory: "512MiB",
    timeoutSeconds: 60,
}, async (event: FirestoreEvent<any>): Promise<void> => {
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

    // Log extraction start for monitoring
    MetadataExtractionLogger.logExtractionStart(
        certificationId,
        certificationData.type,
        certificationData.photoUrl
    );

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

        // Import services dynamically to avoid initialization issues
        const { metadataExtractionService } = await import("./services/metadataExtractionService");

        // Determine certification type and route to appropriate analysis
        let extractedMetadata: any = null;
        let metadataField: string;

        if (certificationData.type === "운동") {
            logger.info("Extracting exercise metadata", { certificationId });
            metadataField = "exerciseMetadata";

            try {
                extractedMetadata = await metadataExtractionService.extractExerciseMetadata(
                    certificationData.photoUrl,
                    certificationId
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

                // Create fallback metadata
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
                extractedMetadata = await metadataExtractionService.extractDietMetadata(
                    certificationData.photoUrl,
                    certificationId
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

                // Create fallback metadata
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

            // Mark as processed but without metadata
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
        if (extractedMetadata && (
            (certificationData.type === "운동" && extractedMetadata.exerciseType) ||
            (certificationData.type === "식단" && extractedMetadata.mainIngredients.length > 0)
        )) {
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

        // Update document with error information but still mark as processed
        // to prevent infinite retry loops
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

        // Don't throw the error to prevent Cloud Function retries
        // The certification upload flow should continue normally
        logger.info("Metadata extraction failed but certification flow continues", {
            certificationId,
            originalError: errorMessage,
        });
    }
});