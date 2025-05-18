import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:seol_haru_check/table_data_from_firestore.dart';
import 'package:seol_haru_check/widgets/show_add_certification_dialog.dart';

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
                    BoxShadow(color: Colors.black.withValues(alpha: .08), blurRadius: 12, offset: Offset(0, 4)),
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
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          alignment: Alignment.center,
                          child: const Text(
                            '참여자',
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF4A4A4A)),
                          ),
                        ),
                        ...weekDates.map(
                          (d) => Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
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
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                            alignment: Alignment.centerLeft,
                            child: Row(
                              children: [
                                const CircleAvatar(radius: 14, backgroundColor: Color(0xFFE0E0E0)),
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
                              child = const Icon(Icons.check, color: Color(0xFF2E7D32), size: 20);
                              onTap = () => showCertificationDialog(user, context);
                            } else if (status == false) {
                              bgColor = const Color(0xFFFDECEA);
                              child = const Icon(Icons.close, color: Color(0xFFC62828), size: 20);
                            } else if (isToday) {
                              bgColor = const Color(0xFFE3F2FD);
                              child = const Icon(Icons.add, color: Color(0xFF1976D2), size: 20);
                              onTap = () => showAddCertificationDialog(user, context);
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
                                height: 28,
                                width: 28,
                                margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
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
            ],
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

void showCertificationDialog(User user, BuildContext context) {
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
                const Text('여기에 인증 텍스트/사진이 들어갑니다.'),
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
