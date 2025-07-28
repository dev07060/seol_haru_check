import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:seol_haru_check/constants/app_strings.dart';
import 'package:seol_haru_check/enums/certification_type.dart';

class Certification {
  final String docId;
  final String uuid;
  final String nickname;
  final DateTime createdAt;
  final CertificationType type;
  final String content;
  final String photoUrl;

  Certification({
    required this.docId,
    required this.uuid,
    required this.nickname,
    required this.createdAt,
    required this.type,
    required this.content,
    required this.photoUrl,
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
    );
  }

  // Certification 객체를 다시 Map으로 변환 (필요시 사용)
  Map<String, dynamic> toMap() {
    return {
      AppStrings.uuidField: uuid,
      AppStrings.nicknameField: nickname,
      AppStrings.createdAtField: createdAt,
      AppStrings.typeField: type.displayName,
      AppStrings.contentField: content,
      AppStrings.photoUrlField: photoUrl,
    };
  }
}
