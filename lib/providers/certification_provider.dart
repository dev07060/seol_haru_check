import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:seol_haru_check/certification_tracker_page.dart';
import 'package:seol_haru_check/models/certification_model.dart'; // 모델 import
import 'package:seol_haru_check/table_data_from_firestore.dart';

@immutable
class CertificationState {
  final List<User> users;
  // [수정] Map -> List<Certification>
  final List<Certification> certifications;
  final bool isLoading;

  const CertificationState({
    this.users = const [],
    this.certifications = const [], // 기본값을 빈 리스트로
    this.isLoading = true,
  });

  CertificationState copyWith({List<User>? users, List<Certification>? certifications, bool? isLoading}) {
    return CertificationState(
      users: users ?? this.users,
      certifications: certifications ?? this.certifications,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class CertificationNotifier extends StateNotifier<CertificationState> with TableDataFromFirestore {
  CertificationNotifier() : super(const CertificationState());

  // [수정] 데이터를 가져와서 List<Certification>으로 변환하는 로직
  Future<void> _fetchAndSetState() async {
    final fetchedUsers = await fetchUsersFromFirestore();

    final certSnapshot = await FirebaseFirestore.instance.collection('certichevron_down_thickfications').get();
    final fetchedCerts = certSnapshot.docs.map((doc) => Certification.fromMap(doc.id, doc.data())).toList();

    state = state.copyWith(users: fetchedUsers, certifications: fetchedCerts, isLoading: false);
  }

  Future<void> loadData() async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true);
    try {
      await _fetchAndSetState();
    } catch (e) {
      debugPrint('Firestore fetch error: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> initialLoad() async {
    state = state.copyWith(isLoading: true);
    try {
      await _fetchAndSetState();
    } catch (e) {
      debugPrint('Firestore fetch error: $e');
      state = state.copyWith(isLoading: false);
    }
  }
}

final certificationProvider = StateNotifierProvider<CertificationNotifier, CertificationState>((ref) {
  return CertificationNotifier();
});
