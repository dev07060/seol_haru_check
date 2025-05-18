import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:seol_haru_check/certification_tracker_page.dart';

mixin TableDataFromFirestore {
  Future<List<User>> fetchUsersFromFirestore() async {
    final snapshot = await FirebaseFirestore.instance.collection('users').get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      return User(name: data['nickname'], uuid: data['uuid'] ?? doc.id);
    }).toList();
  }

  Future<Map<String, bool>> fetchAllCertifications() async {
    final snapshot = await FirebaseFirestore.instance.collection('certifications').get();
    final Map<String, bool> map = {};
    for (final doc in snapshot.docs) {
      // log('Fetched ${doc.data()} certifications');
      final data = doc.data();
      final uuid = data['uuid'];
      final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
      if (createdAt == null) continue;
      final formattedDate = DateFormat('yyyyMMdd').format(createdAt);
      final key = '${uuid}_$formattedDate';
      log('Loaded certification: $key');
      map[key] = true;
    }

    return map;
  }
}
