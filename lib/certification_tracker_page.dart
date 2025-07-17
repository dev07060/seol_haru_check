import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:seol_haru_check/router.dart';
import 'package:seol_haru_check/shared/themes/f_font_styles.dart';
import 'package:seol_haru_check/table_data_from_firestore.dart';

class CertificationTrackerPage extends StatefulWidget {
  const CertificationTrackerPage({super.key});

  @override
  State<CertificationTrackerPage> createState() => _CertificationTrackerPageState();
}

class _CertificationTrackerPageState extends State<CertificationTrackerPage> with TableDataFromFirestore {
  final List<String> days = ['월', '화', '수', '목', '금', '토', '일'];

  List<User> users = [];
  Map<String, bool> certifications = {};
  bool isLoading = true;

  DateTime today = DateTime.now();

  List<DateTime> get weekDates {
    final start = today.subtract(Duration(days: today.weekday - 1));
    return List.generate(days.length, (i) => start.add(Duration(days: i)));
  }

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    try {
      final fetchedUsers = await fetchUsersFromFirestore();
      final fetchedCerts = await fetchAllCertifications();
      setState(() {
        users = fetchedUsers;
        certifications = fetchedCerts;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Firestore fetch error: $e');
      setState(() {
        users = [];
        certifications = {};
        isLoading = false;
      });
    }
  }

  bool? getStatus(String uuid, DateTime date) {
    final key = '${uuid}_${DateFormat('yyyyMMdd').format(date)}';
    final status = certifications[key];
    log('Status for $key = $status');
    return status;
  }

  int getCertificationCount(String uuid) {
    int count = 0;
    for (final date in weekDates) {
      if (getStatus(uuid, date) == true) {
        count++;
      }
    }
    return count;
  }

  List<User> get sortedUsers {
    final userList = List<User>.from(users);
    userList.sort((a, b) {
      final countA = getCertificationCount(a.uuid);
      final countB = getCertificationCount(b.uuid);
      return countB.compareTo(countA); // 내림차순 정렬
    });
    return userList;
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading && users.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator.adaptive()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('참여자 리스트'),
        leading: IconButton(onPressed: () => context.pop(), icon: Icon(Icons.arrow_back)),
        centerTitle: true,
      ),
      body: users.isEmpty ? Center(child: Text('참여자가 아직 없습니다')) : _buildBody(),
    );
  }

  Widget _buildTableContent() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Header with days
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: const Color(0xFF6366F1).withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4)),
              ],
            ),
            child: Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children:
                    weekDates.asMap().entries.map((entry) {
                      final date = entry.value;
                      final dayName = days[(date.weekday - 1) % 7];
                      final isToday = DateFormat('yyyyMMdd').format(date) == DateFormat('yyyyMMdd').format(today);

                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isToday ? Colors.white.withOpacity(0.2) : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: isToday ? Border.all(color: Colors.white.withOpacity(0.3)) : null,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              dayName,
                              style: TextStyle(
                                fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
                                fontSize: 13,
                                color: Colors.white,
                              ),
                            ),
                            const Gap(2),
                            Text('${date.day}', style: FTextStyles.body1_16Rd.copyWith(color: Colors.white)),
                          ],
                        ),
                      );
                    }).toList(),
              ),
            ),
          ),
          const Gap(12),
          // User cards
          ...sortedUsers.map(
            (user) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: .08), blurRadius: 8, offset: const Offset(0, 2)),
                ],
              ),
              child: Row(
                children: [
                  // User info
                  SizedBox(
                    width: 80,
                    child: GestureDetector(
                      onTap: () {
                        context.push(
                          AppRouter.router.namedLocation(
                            AppRoutePath.otherUserFeed.name,
                            pathParameters: {'uuid': user.uuid},
                          ),
                        );
                      },
                      child: Row(
                        children: [
                          const CircleAvatar(radius: 8, backgroundColor: Color(0xFFE0E0E0)),
                          const Gap(6),
                          Expanded(
                            child: Text(
                              user.name,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 15,
                                color: Color(0xFF4A4A4A),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Status indicators
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children:
                          weekDates.map((date) {
                            final status = getStatus(user.uuid, date);
                            final isToday = DateFormat('yyyyMMdd').format(date) == DateFormat('yyyyMMdd').format(today);
                            final isPast = date.isBefore(today);

                            Color bgColor;
                            Widget child;
                            VoidCallback? onTap;

                            if (status == true) {
                              log(
                                'Rendering check icon for user ${user.uuid} on date ${DateFormat('yyyyMMdd').format(date)}',
                              );
                              bgColor = const Color(0xFFDFF6E4);
                              onTap = () async {
                                // On-tap logic for certified days
                              };
                              child = FutureBuilder<QuerySnapshot>(
                                future:
                                    FirebaseFirestore.instance
                                        .collection('certifications')
                                        .where('uuid', isEqualTo: user.uuid)
                                        .get(),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                    return const SizedBox(width: 16, height: 16);
                                  }
                                  if (!snapshot.hasData) {
                                    return const SizedBox(width: 16, height: 16);
                                  }
                                  final selectedDate = DateFormat('yyyyMMdd').format(date);
                                  final certDocs =
                                      snapshot.data!.docs.where((doc) {
                                        final createdAt = (doc['createdAt'] as Timestamp).toDate();
                                        return DateFormat('yyyyMMdd').format(createdAt) == selectedDate;
                                      }).toList();
                                  return Text(
                                    certDocs.length == 1
                                        ? '😀'
                                        : certDocs.length == 2
                                        ? '😎'
                                        : certDocs.length >= 3
                                        ? '🔥'
                                        : '',
                                    style: const TextStyle(
                                      color: Color(0xFF2E7D32),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  );
                                },
                              );
                            } else if (status == false) {
                              bgColor = const Color(0xFFFDECEA);
                              child = const Icon(Icons.close, color: Color(0xFFC62828), size: 16);
                            } else if (isToday) {
                              bgColor = const Color(0xFFE3F2FD);
                              child = const Icon(Icons.add, color: Color(0xFF1976D2), size: 16);
                              onTap = () async {
                                // On-tap logic for today
                              };
                            } else if (isPast) {
                              bgColor = const Color(0xFFF7F7F7);
                              child = const Text(
                                '-',
                                style: TextStyle(color: Color(0xFF9E9E9E), fontWeight: FontWeight.w600, fontSize: 16),
                              );
                            } else {
                              bgColor = const Color(0xFFF7F7F7);
                              child = const Text(
                                '-',
                                style: TextStyle(color: Color(0xFF9E9E9E), fontWeight: FontWeight.w600, fontSize: 16),
                              );
                            }

                            return GestureDetector(
                              onTap: onTap,
                              child: Container(
                                height: 32,
                                width: 32,
                                decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
                                child: Center(child: child),
                              ),
                            );
                          }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Returns the main body widget, with web/mobile differences for refresh.
  Widget _buildBody() {
    final content = SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          _buildTableContent(),
          const Gap(16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              '다른 참여자의 닉네임을 클릭하여 피드를 확인할 수 있어요',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
        ],
      ),
    );

    return RefreshIndicator(onRefresh: loadData, child: content);
  }
}

class User {
  final String name;
  final String uuid;

  User({required this.name, required this.uuid});
}
