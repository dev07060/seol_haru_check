import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:seol_haru_check/table_data_from_firestore.dart';
import 'package:uuid/uuid.dart';

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
    final start = today.subtract(Duration(days: today.weekday - 1)); // Start from Monday
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
    if (isLoading && users.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator.adaptive()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('운동 식단 인증'),
        leading: IconButton(onPressed: () => context.go('/'), icon: Icon(Icons.arrow_back)),
      ),
      body: users.isEmpty ? Center(child: Text('참여자가 아직 없습니다')) : _buildBody(),
    );
  }

  /// Returns the table content only, for use in _buildBody.
  Widget _buildTableContent() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .08), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Table(
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        columnWidths: const {0: FixedColumnWidth(80)},
        children: [
          TableRow(
            decoration: BoxDecoration(
              color: const Color(0xFFF6F7F9),
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
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
                    days[(d.weekday - 1) % 7], // Monday=0, ..., Sunday=6
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF4A4A4A)),
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
                    index < users.length - 1 ? Border(bottom: BorderSide(color: Colors.grey.shade300, width: 1)) : null,
              ),
              children: [
                Container(
                  width: 40,
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      const Gap(6),
                      const CircleAvatar(radius: 8, backgroundColor: Color(0xFFE0E0E0)),
                      const Gap(6),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            // Change navigation to the new feed page route
                            context.go('/user/${user.uuid}/feed');
                          },
                          child: Text(
                            user.name,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15, color: Color(0xFF4A4A4A)),
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
                    log('Rendering check icon for user ${user.uuid} on date ${DateFormat('yyyyMMdd').format(date)}');
                    bgColor = const Color(0xFFDFF6E4);
                    onTap = () async {
                      // final query =
                      //     await FirebaseFirestore.instance
                      //         .collection('certifications')
                      //         .where('uuid', isEqualTo: user.uuid)
                      //         .get();

                      // final selectedDate = DateFormat('yyyyMMdd').format(date);

                      // final certDocs =
                      //     query.docs.where((doc) {
                      //       final createdAt = (doc['createdAt'] as Timestamp).toDate();
                      //       return DateFormat('yyyyMMdd').format(createdAt) == selectedDate;
                      //     }).toList();

                      // final certs = certDocs.map((doc) => {'docId': doc.id, ...doc.data()}).toList();

                      // showCertificationDialog(
                      //   user,
                      //   certs,
                      //   context,
                      //   onDeleted: () async {
                      //     await loadData();
                      //   },
                      //   onUpdated: () async {
                      //     await loadData();
                      //   },
                      // );
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
                          style: const TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold, fontSize: 14),
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
                      // final result = await showAddCertificationBottomSheet(
                      //   user: user,
                      //   context: context,
                      //   onSuccess: loadData,
                      // );
                      // if (result == true && mounted) {
                      //   await loadData();
                      //   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('인증이 등록되었습니다'))
                      //   );
                      // }
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
    );
  }

  /// Returns the join button widget, for use in _buildBody.
  Widget _buildJoinButton() {
    return ElevatedButton.icon(
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
                    TextField(controller: nicknameController, decoration: const InputDecoration(labelText: '닉네임')),
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
    );
  }

  /// Returns the main body widget, with web/mobile differences for refresh.
  Widget _buildBody() {
    final content = SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateFormat('yyyy년 M월 d일 (E)', 'ko').format(today),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const Gap(8),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 111, 112, 113),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      textStyle: const TextStyle(fontWeight: FontWeight.w400),
                    ),
                    onPressed: () async {
                      setState(() {
                        isLoading = true;
                      });
                      await loadData();
                    },
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('새로고침'),
                  ),
                ],
              ),
            ),
            const Gap(8),
            _buildTableContent(),
            const Gap(12),
            const Text(
              '다른 참여자의 닉네임을 클릭하여 피드를 확인할 수 있어요',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            // const Gap(12),
            // _buildJoinButton(),
          ],
        ),
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
