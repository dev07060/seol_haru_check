import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:seol_haru_check/certification_tracker_page.dart';
import 'package:seol_haru_check/constants/app_strings.dart';

mixin TableDataFromFirestore {
  Future<List<User>> fetchUsersFromFirestore() async {
    final snapshot = await FirebaseFirestore.instance.collection(AppStrings.usersCollection).get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      return User(name: data[AppStrings.nicknameField], uuid: data[AppStrings.uuidField] ?? doc.id);
    }).toList();
  }

  Future<Map<String, bool>> fetchAllCertifications() async {
    final snapshot = await FirebaseFirestore.instance.collection(AppStrings.certificationsCollection).get();
    final Map<String, bool> map = {};
    for (final doc in snapshot.docs) {
      // log('Fetched ${doc.data()} certifications');
      final data = doc.data();
      final uuid = data[AppStrings.uuidField];
      final createdAt = (data[AppStrings.createdAtField] as Timestamp?)?.toDate();
      if (createdAt == null) continue;
      final formattedDate = DateFormat('yyyyMMdd').format(createdAt);
      final key = '${uuid}_$formattedDate';
      log('Loaded certification: $key');
      map[key] = true;
    }

    return map;
  }
}
