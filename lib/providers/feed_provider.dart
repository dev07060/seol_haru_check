import 'dart:developer'; // log 사용을 위해 import 추가

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:seol_haru_check/models/certification_model.dart';

// FirebaseAuth의 인증 상태 변경을 감지하는 Provider
final authStateChangesProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

// StreamProvider.family를 사용하여 특정 날짜(DateTime)와 선택적 사용자 UUID를 파라미터로 받습니다.
// targetUuid가 null이면 현재 로그인된 사용자의 피드를 가져옵니다.
final feedProvider = StreamProvider.family<List<Certification>, ({DateTime date, String? targetUuid})>((ref, params) {
  final firestore = FirebaseFirestore.instance;
  final currentUser = ref.watch(authStateChangesProvider).value; // authStateChangesProvider를 통해 현재 사용자 가져오기

  // targetUuid가 제공되지 않았고, 현재 로그인한 사용자도 없는 경우 빈 스트림 반환
  if (params.targetUuid == null && currentUser == null) {
    return Stream.value([]);
  }

  // 선택된 날짜의 시작과 끝 시간 계산
  final startOfDay = DateTime(params.date.year, params.date.month, params.date.day);
  final endOfDay = startOfDay.add(const Duration(days: 1));

  // 쿼리할 사용자의 UUID 결정
  final String uuidToQuery = params.targetUuid ?? currentUser!.uid;
  // 로그는 그대로 두거나, 필요에 따라 수정/제거할 수 있습니다.
  log(
    '[feedProvider] Querying for UUID: $uuidToQuery, targetUuid: ${params.targetUuid}, watched currentUser.uid: ${currentUser?.uid}',
  );

  // 특정 사용자의, 특정 날짜 범위의 인증 데이터를 실시간으로 가져오는 쿼리
  final query = firestore
      .collection('certifications')
      .where('uuid', isEqualTo: uuidToQuery) // 조회할 사용자의 uid와 일치하는 것만
      .where('createdAt', isGreaterThanOrEqualTo: startOfDay) // 날짜 범위 필터링
      .where('createdAt', isLessThan: endOfDay)
      .orderBy('createdAt', descending: true); // 최신순으로 정렬

  // 쿼리 스냅샷을 스트림으로 반환하고, 데이터를 Certification 리스트로 변환
  return query.snapshots().map((snapshot) {
    return snapshot.docs.map((doc) => Certification.fromMap(doc.id, doc.data())).toList();
  });
});

// 특정 연도와 월에 인증 기록이 있는 날짜들의 '일(day)'을 Set<int> 형태로 반환하는 프로바이더
// targetUuid가 null이면 현재 로그인된 사용자의 데이터를 가져옵니다.
final certifiedDatesInMonthProvider = StreamProvider.family<Set<int>, ({int year, int month, String? targetUuid})>((
  ref,
  params,
) {
  final firestore = FirebaseFirestore.instance;
  final currentUser = ref.watch(authStateChangesProvider).value; // authStateChangesProvider 사용

  // targetUuid가 제공되지 않았고, 현재 로그인한 사용자도 없는 경우 빈 스트림 반환
  if (params.targetUuid == null && currentUser == null) {
    return Stream.value({});
  }
  // 쿼리할 사용자의 UUID 결정
  final String uuidToQuery = params.targetUuid ?? currentUser!.uid;
  log(
    '[certifiedDatesInMonthProvider] Querying for UUID: $uuidToQuery, targetUuid: ${params.targetUuid}, watched currentUser.uid: ${currentUser?.uid}',
  );

  final startOfMonth = DateTime(params.year, params.month, 1);
  // 다음 달의 1일 0시 0분 0초로 설정하여, 해당 월의 마지막 날까지 포함하도록 함
  final endOfMonth = DateTime(params.year, params.month + 1, 1);

  final query = firestore
      .collection('certifications')
      .where('uuid', isEqualTo: uuidToQuery)
      .where('createdAt', isGreaterThanOrEqualTo: startOfMonth)
      .where('createdAt', isLessThan: endOfMonth); // endOfMonth는 포함하지 않음

  return query.snapshots().map((snapshot) {
    if (snapshot.docs.isEmpty) {
      return <int>{};
    }
    // 중복 제거 및 날짜(day)만 추출 (UTC 기준으로 변환 후 사용 권장, 여기서는 Local 사용)
    return snapshot.docs.map((doc) {
      final timestamp = doc.data()['createdAt'] as Timestamp;
      return timestamp.toDate().toLocal().day;
    }).toSet();
  });
});

// 특정 연도와 월에 인증 기록이 하나라도 있는지 여부를 bool 값으로 반환하는 프로바이더
// targetUuid가 null이면 현재 로그인된 사용자의 데이터를 가져옵니다.
final hasCertificationForMonthProvider = StreamProvider.family<bool, ({int year, int month, String? targetUuid})>((
  ref,
  params,
) {
  final firestore = FirebaseFirestore.instance;
  final currentUser = ref.watch(authStateChangesProvider).value; // authStateChangesProvider 사용

  // targetUuid가 제공되지 않았고, 현재 로그인한 사용자도 없는 경우 빈 스트림 반환
  if (params.targetUuid == null && currentUser == null) {
    return Stream.value(false);
  }
  // 쿼리할 사용자의 UUID 결정
  final String uuidToQuery = params.targetUuid ?? currentUser!.uid;
  log(
    '[hasCertificationForMonthProvider] Querying for UUID: $uuidToQuery, targetUuid: ${params.targetUuid}, watched currentUser.uid: ${currentUser?.uid}',
  );

  final startOfMonth = DateTime(params.year, params.month, 1);
  final endOfMonth = DateTime(params.year, params.month + 1, 1);

  final query = firestore
      .collection('certifications')
      .where('uuid', isEqualTo: uuidToQuery)
      .where('createdAt', isGreaterThanOrEqualTo: startOfMonth)
      .where('createdAt', isLessThan: endOfMonth)
      .limit(1); // 하나라도 있는지 확인

  return query.snapshots().map((snapshot) => snapshot.docs.isNotEmpty);
});

// Repository for certification actions like deletion
class CertificationRepository {
  final FirebaseFirestore _firestore;

  CertificationRepository(this._firestore);

  Future<void> deleteCertification(String docId) async {
    await _firestore.collection('certifications').doc(docId).delete();
  }

  // 닉네임과 현재 사용자 이메일의 로컬 파트를 비교하여 이전 인증 데이터를 마이그레이션합니다.
  Future<void> migrateCertificationsByNickname(String userEmailLocalPart, String newUuid) async {
    // 제공된 userEmailLocalPart와 일치하는 nickname을 가진 인증 데이터 조회
    final querySnapshot =
        await _firestore
            .collection('certifications')
            .where('nickname', isEqualTo: userEmailLocalPart)
            // 이전 데이터는 현재 newUuid와 다른 uuid를 가지고 있을 것이라는 가정
            .where('uuid', isNotEqualTo: newUuid)
            .get();

    if (querySnapshot.docs.isEmpty) {
      // 마이그레이션할 데이터가 없는 경우
      return;
    }

    // Firestore 일괄 쓰기(batch)를 사용하여 모든 문서를 한 번에 업데이트
    final batch = _firestore.batch();
    for (var doc in querySnapshot.docs) {
      // 현재 사용자의 nickname도 함께 업데이트할 수 있습니다 (선택 사항).
      // 여기서는 uuid만 업데이트합니다.
      // 필요하다면, 현재 사용자의 displayName을 가져와서 nickname도 업데이트할 수 있습니다.
      batch.update(doc.reference, {'uuid': newUuid});
    }

    await batch.commit();
  }
}

final certificationRepositoryProvider = Provider((ref) => CertificationRepository(FirebaseFirestore.instance));
