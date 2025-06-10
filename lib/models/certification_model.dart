import 'package:cloud_firestore/cloud_firestore.dart';

class Certification {
  final String docId;
  final String uuid;
  final String nickname;
  final DateTime createdAt;
  final String type;
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
      uuid: map['uuid'] ?? '',
      nickname: map['nickname'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      type: map['type'] ?? '',
      content: map['content'] ?? '',
      photoUrl: map['photoUrl'] ?? '',
    );
  }

  // Certification 객체를 다시 Map으로 변환 (필요시 사용)
  Map<String, dynamic> toMap() {
    return {
      'uuid': uuid,
      'nickname': nickname,
      'createdAt': createdAt,
      'type': type,
      'content': content,
      'photoUrl': photoUrl,
    };
  }
}
