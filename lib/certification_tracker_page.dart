import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:seol_haru_check/table_data_from_firestore.dart';
import 'package:seol_haru_check/widgets/firebase_storage_image.dart';
import 'package:seol_haru_check/widgets/show_add_certification_dialog.dart';
import 'package:uuid/uuid.dart';

class CertificationTrackerPage extends StatefulWidget {
  const CertificationTrackerPage({super.key});

  @override
  State<CertificationTrackerPage> createState() => _CertificationTrackerPageState();
}

class _CertificationTrackerPageState extends State<CertificationTrackerPage> with TableDataFromFirestore {
  final List<String> days = ['일', '월', '화', '수', '목', '금', '토'];

  List<User> users = [];
  Map<String, bool> certifications = {};
  bool isLoading = true;

  DateTime today = DateTime.now();

  List<DateTime> get weekDates {
    final start = today.subtract(Duration(days: today.weekday % 7));
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

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (users.isEmpty) {
      return const Scaffold(body: Center(child: Text('참여자가 아직 없습니다')));
    }
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '운동 인증 트래커',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.blue),
                ),
                const SizedBox(height: 8),
                Text(
                  DateFormat('yyyy년 M월 d일 (E)', 'ko').format(today),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(.08), blurRadius: 12, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Table(
                    defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                    columnWidths: const {0: FixedColumnWidth(110)},
                    children: [
                      TableRow(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF6F7F9),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            topRight: Radius.circular(12),
                          ),
                        ),
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            alignment: Alignment.center,
                            child: const Text(
                              '참여자',
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF4A4A4A)),
                            ),
                          ),
                          ...weekDates.map(
                            (d) => Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              alignment: Alignment.center,
                              child: Text(
                                days[d.weekday % 7],
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: Color(0xFF4A4A4A),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      ...users.asMap().entries.map((entry) {
                        final index = entry.key;
                        final user = entry.value;
                        return TableRow(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border:
                                index < users.length - 1
                                    ? Border(bottom: BorderSide(color: Colors.grey.shade300, width: 1))
                                    : null,
                          ),
                          children: [
                            Container(
                              width: 40,
                              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                              alignment: Alignment.centerLeft,
                              child: Row(
                                children: [
                                  const CircleAvatar(radius: 10, backgroundColor: Color(0xFFE0E0E0)),
                                  const SizedBox(width: 10),
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
                            ...weekDates.map((date) {
                              final status = getStatus(user.uuid, date);
                              final isToday =
                                  DateFormat('yyyyMMdd').format(date) == DateFormat('yyyyMMdd').format(today);
                              final isPast = date.isBefore(today);

                              Color bgColor;
                              Widget child;
                              VoidCallback? onTap;

                              if (status == true) {
                                log(
                                  'Rendering check icon for user ${user.uuid} on date ${DateFormat('yyyyMMdd').format(date)}',
                                );
                                bgColor = const Color(0xFFDFF6E4);
                                child = const Icon(Icons.check, color: Color(0xFF2E7D32), size: 16);
                                onTap = () async {
                                  final query =
                                      await FirebaseFirestore.instance
                                          .collection('certifications')
                                          .where('uuid', isEqualTo: user.uuid)
                                          .get();

                                  final certDoc = query.docs.firstWhere((doc) {
                                    final createdAt = (doc['createdAt'] as Timestamp).toDate();
                                    return createdAt.year == date.year &&
                                        createdAt.month == date.month &&
                                        createdAt.day == date.day;
                                  });

                                  final data = certDoc.data();
                                  showCertificationDialog(user, data, context);
                                };
                              } else if (status == false) {
                                bgColor = const Color(0xFFFDECEA);
                                child = const Icon(Icons.close, color: Color(0xFFC62828), size: 16);
                              } else if (isToday) {
                                bgColor = const Color(0xFFE3F2FD);
                                child = const Icon(Icons.add, color: Color(0xFF1976D2), size: 16);
                                onTap = () async {
                                  final result = await showAddCertificationDialog(user, context);
                                  if (result == true && mounted) {
                                    await loadData();
                                    ScaffoldMessenger.of(
                                      context,
                                    ).showSnackBar(const SnackBar(content: Text('인증이 등록되었습니다')));
                                  }
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
                                  margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                                  decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
                                  child: Center(child: child),
                                ),
                              );
                            }),
                          ],
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                const Text(
                  '참여자의 칸을 클릭하여 운동 완료 상태를 변경할 수 있습니다',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),

                const SizedBox(height: 12),
                ElevatedButton.icon(
                  icon: const Icon(Icons.person_add),
                  label: const Text('참가하기'),
                  onPressed: () async {
                    final nicknameController = TextEditingController();
                    final passwordController = TextEditingController();

                    final result = await showDialog<bool>(
                      context: context,
                      builder:
                          (ctx) => AlertDialog(
                            title: const Text('참가하기'),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TextField(
                                  controller: nicknameController,
                                  decoration: const InputDecoration(labelText: '닉네임'),
                                ),
                                TextField(
                                  controller: passwordController,
                                  decoration: const InputDecoration(labelText: '비밀번호 (4자리)'),
                                  obscureText: true,
                                  keyboardType: TextInputType.number,
                                  maxLength: 4,
                                ),
                              ],
                            ),
                            actions: [
                              TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('취소')),
                              TextButton(
                                onPressed: () async {
                                  final nickname = nicknameController.text.trim();
                                  final password = passwordController.text.trim();
                                  if (nickname.isNotEmpty && password.length == 4) {
                                    final uuid = const Uuid().v4();
                                    await FirebaseFirestore.instance.collection('users').add({
                                      'nickname': nickname,
                                      'password': password,
                                      'uuid': uuid,
                                      'createdAt': DateTime.now(),
                                      'lastActiveAt': DateTime.now(),
                                    });
                                    if (context.mounted) {
                                      Navigator.of(ctx).pop(true);
                                    }
                                  }
                                },
                                child: const Text('완료'),
                              ),
                            ],
                          ),
                    );

                    if (result == true) {
                      await loadData();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('참가가 완료되었습니다')));
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class User {
  final String name;
  final String uuid;

  User({required this.name, required this.uuid});
}

void showCertificationDialog(User user, Map<String, dynamic> certification, BuildContext context) {
  final String photoUrl = certification['photoUrl'] ?? '';
  final String type = certification['type'] ?? '';
  final String content = certification['content'] ?? '';

  // 디버깅용 로그 추가
  debugPrint('ShowCertificationDialog - PhotoUrl: $photoUrl');

  showDialog(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black54,
    builder: (_) {
      return Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 300,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${user.name}님의 인증 내용', style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (photoUrl.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: FirebaseStorageImage(imagePath: photoUrl),
                      ),
                    const SizedBox(height: 12),
                    if (type.isNotEmpty)
                      Text('유형: $type', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    if (content.isNotEmpty) Text('내용: $content', style: const TextStyle(fontSize: 14)),
                  ],
                ),
                const SizedBox(height: 20),
                ElevatedButton(onPressed: () => Navigator.of(context).pop(), child: const Text('닫기')),
              ],
            ),
          ),
        ),
      );
    },
  );
}
