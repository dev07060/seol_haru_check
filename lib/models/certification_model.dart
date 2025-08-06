import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:seol_haru_check/constants/app_strings.dart';
import 'package:seol_haru_check/enums/certification_type.dart';
import 'package:seol_haru_check/models/metadata_models.dart';

class Certification {
  final String docId;
  final String uuid;
  final String nickname;
  final DateTime createdAt;
  final CertificationType type;
  final String content;
  final String photoUrl;

  // New optional metadata fields for AI-powered analysis
  final ExerciseMetadata? exerciseMetadata;
  final DietMetadata? dietMetadata;
  final bool metadataProcessed;
  final MetadataError? metadataError;

  Certification({
    required this.docId,
    required this.uuid,
    required this.nickname,
    required this.createdAt,
    required this.type,
    required this.content,
    required this.photoUrl,
    this.exerciseMetadata,
    this.dietMetadata,
    this.metadataProcessed = false,
    this.metadataError,
  });

  // Firestore의 Map 데이터를 Certification 객체로 변환
  factory Certification.fromMap(String docId, Map<String, dynamic> map) {
    return Certification(
      docId: docId,
      uuid: map[AppStrings.uuidField] ?? '',
      nickname: map[AppStrings.nicknameField] ?? '',
      createdAt: (map[AppStrings.createdAtField] as Timestamp).toDate(),
      type: CertificationType.fromDisplayName(map[AppStrings.typeField] ?? AppStrings.exercise),
      content: map[AppStrings.contentField] ?? '',
      photoUrl: map[AppStrings.photoUrlField] ?? '',
      // Optional metadata fields with backward compatibility
      exerciseMetadata:
          map['exerciseMetadata'] != null
              ? ExerciseMetadata.fromMap(map['exerciseMetadata'] as Map<String, dynamic>)
              : null,
      dietMetadata:
          map['dietMetadata'] != null ? DietMetadata.fromMap(map['dietMetadata'] as Map<String, dynamic>) : null,
      metadataProcessed: map['metadataProcessed'] as bool? ?? false,
      metadataError:
          map['metadataError'] != null ? MetadataError.fromMap(map['metadataError'] as Map<String, dynamic>) : null,
    );
  }

  // Certification 객체를 다시 Map으로 변환 (필요시 사용)
  Map<String, dynamic> toMap() {
    final map = {
      AppStrings.uuidField: uuid,
      AppStrings.nicknameField: nickname,
      AppStrings.createdAtField: createdAt,
      AppStrings.typeField: type.displayName,
      AppStrings.contentField: content,
      AppStrings.photoUrlField: photoUrl,
      'metadataProcessed': metadataProcessed,
    };

    // Add optional metadata fields only if they exist
    if (exerciseMetadata != null) {
      map['exerciseMetadata'] = exerciseMetadata!.toMap();
    }
    if (dietMetadata != null) {
      map['dietMetadata'] = dietMetadata!.toMap();
    }
    if (metadataError != null) {
      map['metadataError'] = metadataError!.toMap();
    }

    return map;
  }
}
