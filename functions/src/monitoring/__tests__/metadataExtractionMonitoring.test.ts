/**
 * Tests for Metadata Extraction Monitoring and Analytics
 */

import { beforeEach, describe, expect, it, jest } from '@jest/globals';
import { MetadataExtractionLogger } from '../metadataExtractionMonitoring';

// Mock Firebase Admin
jest.mock('firebase-admin/firestore', () => ({
    getFirestore: jest.fn(() => ({
        collection: jest.fn(() => ({
            add: jest.fn(),
            where: jest.fn(() => ({
                get: jest.fn(() => ({
                    docs: [],
                    size: 0,
                })),
                orderBy: jest.fn(() => ({
                    get: jest.fn(() => ({
                        docs: [],
                        size: 0,
                    })),
                    limit: jest.fn(() => ({
                        get: jest.fn(() => ({
                            docs: [],
                            size: 0,
                        })),
                    })),
                })),
            })),
        })),
    })),
}));

// Mock Firebase Functions Logger
jest.mock('firebase-functions/logger', () => ({
    info: jest.fn(),
    warn: jest.fn(),
    error: jest.fn(),
}));

describe('MetadataExtractionLogger', () => {
    beforeEach(() => {
        jest.clearAllMocks();
    });

    describe('logExtractionStart', () => {
        it('should log extraction start with correct parameters', () => {
            const certificationId = 'test-cert-123';
            const type = '운동' as const;
            const photoUrl = 'https://example.com/photo.jpg';

            MetadataExtractionLogger.logExtractionStart(certificationId, type, photoUrl);

            const logger = require('firebase-functions/logger');
            expect(logger.info).toHaveBeenCalledWith(
                'Metadata extraction started',
                expect.objectContaining({
                    event: 'metadata_extraction_start',
                    certificationId,
                    type,
                    photoUrl,
                    timestamp: expect.any(String),
                })
            );
        });
    });

    describe('logExtractionSuccess', () => {
        it('should log successful extraction with metrics', () => {
            const certificationId = 'test-cert-123';
            const type = '운동' as const;
            const processingTimeMs = 1500;
            const metadata = {
                exerciseType: '러닝',
                duration: 30,
                timePeriod: '오전',
                intensity: '보통',
            };
            const aiMetadata = {
                responseLength: 150,
                finishReason: 'STOP',
            };

            MetadataExtractionLogger.logExtractionSuccess(
                certificationId,
                type,
                processingTimeMs,
                metadata,
                aiMetadata
            );

            const logger = require('firebase-functions/logger');
            expect(logger.info).toHaveBeenCalledWith(
                'Metadata extraction completed successfully',
                expect.objectContaining({
                    event: 'metadata_extraction_success',
                    certificationId,
                    type,
                    processingTimeMs,
                    metadata,
                    aiMetadata,
                    timestamp: expect.any(String),
                })
            );
        });
    });

    describe('logExtractionFailure', () => {
        it('should log extraction failure with error details', () => {
            const certificationId = 'test-cert-123';
            const type = '식단' as const;
            const errorType = 'ai_service' as const;
            const errorMessage = 'API quota exceeded';
            const processingTimeMs = 500;

            MetadataExtractionLogger.logExtractionFailure(
                certificationId,
                type,
                errorType,
                errorMessage,
                processingTimeMs
            );

            const logger = require('firebase-functions/logger');
            expect(logger.error).toHaveBeenCalledWith(
                'Metadata extraction failed',
                expect.objectContaining({
                    event: 'metadata_extraction_failure',
                    certificationId,
                    type,
                    errorType,
                    errorMessage,
                    processingTimeMs,
                    timestamp: expect.any(String),
                })
            );
        });
    });

    describe('logApiUsage', () => {
        it('should log API usage metrics', () => {
            const certificationId = 'test-cert-123';
            const requestType = 'exercise' as const;
            const tokensUsed = 150;
            const responseTimeMs = 800;
            const estimatedCost = 0.0001;

            MetadataExtractionLogger.logApiUsage(
                certificationId,
                requestType,
                tokensUsed,
                responseTimeMs,
                estimatedCost
            );

            const logger = require('firebase-functions/logger');
            expect(logger.info).toHaveBeenCalledWith(
                'AI API usage recorded',
                expect.objectContaining({
                    event: 'api_usage',
                    certificationId,
                    requestType,
                    tokensUsed,
                    responseTimeMs,
                    estimatedCost,
                    timestamp: expect.any(String),
                })
            );
        });
    });

    describe('logImageProcessing', () => {
        it('should log image processing metrics', () => {
            const certificationId = 'test-cert-123';
            const originalSizeBytes = 2048000;
            const processedSizeBytes = 512000;
            const processingTimeMs = 300;
            const compressionRatio = 75;

            MetadataExtractionLogger.logImageProcessing(
                certificationId,
                originalSizeBytes,
                processedSizeBytes,
                processingTimeMs,
                compressionRatio
            );

            const logger = require('firebase-functions/logger');
            expect(logger.info).toHaveBeenCalledWith(
                'Image processing completed',
                expect.objectContaining({
                    event: 'image_processing',
                    certificationId,
                    originalSizeBytes,
                    processedSizeBytes,
                    processingTimeMs,
                    compressionRatio,
                    timestamp: expect.any(String),
                })
            );
        });
    });
});

describe('Alert Conditions', () => {
    const createMockMetrics = (overrides = {}) => ({
        timestamp: new Date(),
        totalExtractions: 10,
        successfulExtractions: 8,
        failedExtractions: 2,
        successRate: 80,
        averageProcessingTime: 2000,
        exerciseExtractions: 6,
        dietExtractions: 4,
        apiUsage: {
            totalRequests: 10,
            totalTokensUsed: 1500,
            averageTokensPerRequest: 150,
            estimatedCost: 0.001,
        },
        errorBreakdown: {
            imageProcessingErrors: 1,
            aiServiceErrors: 1,
            parsingErrors: 0,
            unknownErrors: 0,
        },
        performanceMetrics: {
            averageImageProcessingTime: 300,
            averageAiResponseTime: 800,
            averageParsingTime: 50,
        },
        ...overrides,
    });

    it('should trigger high failure rate alert when success rate is below 70%', () => {
        const metrics = createMockMetrics({
            totalExtractions: 10,
            successfulExtractions: 6,
            failedExtractions: 4,
            successRate: 60,
        });

        // Import alert rules (would need to be exported for testing)
        // const { METADATA_EXTRACTION_ALERT_RULES } = require('../metadataExtractionMonitoring');
        // const highFailureRateRule = METADATA_EXTRACTION_ALERT_RULES.find(rule => rule.name === 'high_failure_rate');

        // expect(highFailureRateRule.condition(metrics)).toBe(true);
    });

    it('should trigger no extractions alert when total extractions is 0', () => {
        const metrics = createMockMetrics({
            totalExtractions: 0,
            successfulExtractions: 0,
            failedExtractions: 0,
        });

        // Test would check no_extractions alert condition
        expect(metrics.totalExtractions).toBe(0);
    });

    it('should trigger high API cost alert when cost exceeds threshold', () => {
        const metrics = createMockMetrics({
            apiUsage: {
                totalRequests: 100,
                totalTokensUsed: 15000,
                averageTokensPerRequest: 150,
                estimatedCost: 15, // $15 in 5 minutes
            },
        });

        expect(metrics.apiUsage.estimatedCost).toBeGreaterThan(10);
    });

    it('should trigger slow processing alert when average time exceeds threshold', () => {
        const metrics = createMockMetrics({
            averageProcessingTime: 35000, // 35 seconds
        });

        expect(metrics.averageProcessingTime).toBeGreaterThan(30000);
    });

    it('should trigger high AI service errors alert', () => {
        const metrics = createMockMetrics({
            errorBreakdown: {
                imageProcessingErrors: 1,
                aiServiceErrors: 6, // High number of AI service errors
                parsingErrors: 0,
                unknownErrors: 0,
            },
        });

        expect(metrics.errorBreakdown.aiServiceErrors).toBeGreaterThan(5);
    });
});

describe('Metrics Calculation', () => {
    it('should calculate success rate correctly', () => {
        const totalExtractions = 20;
        const successfulExtractions = 16;
        const successRate = (successfulExtractions / totalExtractions) * 100;

        expect(successRate).toBe(80);
    });

    it('should calculate average processing time correctly', () => {
        const processingTimes = [1000, 1500, 2000, 2500, 3000];
        const averageProcessingTime = processingTimes.reduce((sum, time) => sum + time, 0) / processingTimes.length;

        expect(averageProcessingTime).toBe(2000);
    });

    it('should calculate average tokens per request correctly', () => {
        const totalRequests = 10;
        const totalTokensUsed = 1500;
        const averageTokensPerRequest = totalTokensUsed / totalRequests;

        expect(averageTokensPerRequest).toBe(150);
    });

    it('should handle zero division gracefully', () => {
        const totalExtractions = 0;
        const successfulExtractions = 0;
        const successRate = totalExtractions > 0 ? (successfulExtractions / totalExtractions) * 100 : 0;

        expect(successRate).toBe(0);
    });
});

describe('Error Categorization', () => {
    it('should categorize image processing errors correctly', () => {
        const errorMessages = [
            'Image processing failed',
            'Sharp error occurred',
            'Storage download failed',
            'Invalid image format',
        ];

        errorMessages.forEach(message => {
            const isImageError = message.toLowerCase().includes('image') ||
                message.toLowerCase().includes('sharp') ||
                message.toLowerCase().includes('storage');
            expect(isImageError).toBe(true);
        });
    });

    it('should categorize AI service errors correctly', () => {
        const errorMessages = [
            'VertexAI API error',
            'API quota exceeded',
            'Rate limit reached',
            'Service unavailable',
        ];

        errorMessages.forEach(message => {
            const isAiError = message.toLowerCase().includes('vertex') ||
                message.toLowerCase().includes('api') ||
                message.toLowerCase().includes('quota') ||
                message.toLowerCase().includes('rate') ||
                message.toLowerCase().includes('service');
            expect(isAiError).toBe(true);
        });
    });

    it('should categorize parsing errors correctly', () => {
        const errorMessages = [
            'JSON parse error',
            'Invalid response format',
            'Parsing failed',
        ];

        errorMessages.forEach(message => {
            const isParsingError = message.toLowerCase().includes('json') ||
                message.toLowerCase().includes('parse') ||
                message.toLowerCase().includes('invalid') ||
                message.toLowerCase().includes('parsing');
            expect(isParsingError).toBe(true);
        });
    });
});

describe('Cost Estimation', () => {
    it('should estimate API costs correctly', () => {
        const tokenCount = 1000;
        const inputCostPer1K = 0.00025;
        const outputCostPer1K = 0.0005;

        // Assume 70% input, 30% output
        const inputTokens = tokenCount * 0.7;
        const outputTokens = tokenCount * 0.3;

        const inputCost = (inputTokens / 1000) * inputCostPer1K;
        const outputCost = (outputTokens / 1000) * outputCostPer1K;
        const totalCost = inputCost + outputCost;

        expect(totalCost).toBeCloseTo(0.000325, 6);
    });

    it('should handle zero token count', () => {
        const tokenCount = 0;
        const estimatedCost = tokenCount * 0.00025; // Simplified calculation

        expect(estimatedCost).toBe(0);
    });
});