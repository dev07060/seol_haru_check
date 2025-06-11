import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as f_auth; // 이름 충돌 방지
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // riverpod import
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:seol_haru_check/constants/app_strings.dart';
import 'package:seol_haru_check/providers/certification_provider.dart'; // provider import
import 'package:seol_haru_check/shared/components/date_picker/f_date_picker.dart';
import 'package:seol_haru_check/widgets/show_add_certification_dialog.dart';
import 'package:seol_haru_check/widgets/show_certification_dialog.dart';
import 'package:uuid/uuid.dart';

// StatelessWidget을 ConsumerWidget으로 변경
class CertificationTrackerPage extends ConsumerStatefulWidget {
  const CertificationTrackerPage({super.key});

  @override
  ConsumerState<CertificationTrackerPage> createState() => _CertificationTrackerPageState();
}

class _CertificationTrackerPageState extends ConsumerState<CertificationTrackerPage> {
  final List<String> days = ['월', '화', '수', '목', '금', '토', '일'];
  DateTime today = DateTime.now();
  late DateTime _focusedDate;

  List<DateTime> get weekDates {
    final start = _focusedDate.subtract(Duration(days: _focusedDate.weekday - 1));
    return List.generate(7, (i) => start.add(Duration(days: i)));
  }

  @override
  void initState() {
    super.initState();
    _focusedDate = DateTime.now(); // 초기값은 오늘
    Future.microtask(() => ref.read(certificationProvider.notifier).initialLoad());
  }

  @override
  Widget build(BuildContext context) {
    // ref.watch를 통해 상태를 구독. 상태가 변경되면 자동으로 리빌드됨.
    final state = ref.watch(certificationProvider);
    final users = state.users;

    if (state.isLoading && users.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator.adaptive()));
    }
    if (users.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.grey[300],
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [const Text(AppStrings.noParticipants), const Gap(12), _buildJoinButton()],
            ),
          ),
        ),
      );
    }
    return Scaffold(backgroundColor: Colors.grey[300], body: SafeArea(child: _buildBody(users)));
  }

  Widget _buildSignUpButton() {
    return ElevatedButton.icon(
      icon: const Icon(Icons.person_add),
      label: const Text(AppStrings.join),
      onPressed: () async {
        final nicknameController = TextEditingController();
        final passwordController = TextEditingController();

        await showDialog(
          context: context,
          builder:
              (ctx) => AlertDialog(
                title: const Text(AppStrings.join),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nicknameController,
                      decoration: const InputDecoration(labelText: AppStrings.nickname),
                    ),
                    TextField(
                      controller: passwordController,
                      decoration: const InputDecoration(labelText: AppStrings.password4digits),
                      obscureText: true,
                      maxLength: 6,
                    ),
                  ],
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text(AppStrings.cancel)),
                  TextButton(
                    child: const Text(AppStrings.complete),
                    onPressed: () async {
                      final nickname = nicknameController.text.trim();
                      final password = passwordController.text.trim();
                      if (nickname.isEmpty || password.length < 6) return;

                      try {
                        // [수정] Firebase Auth로 회원가입
                        // 이메일은 '닉네임@seolharu.check' 형식으로 생성
                        final userCredential = await f_auth.FirebaseAuth.instance.createUserWithEmailAndPassword(
                          email: '$nickname@seolharu.check',
                          password: password,
                        );

                        // Firestore에 사용자 정보 저장
                        await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
                          'nickname': nickname,
                          'uuid': userCredential.user!.uid, // Auth의 uid를 uuid로 사용
                          'createdAt': DateTime.now(),
                        });

                        Navigator.of(ctx).pop();
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(const SnackBar(content: Text(AppStrings.joinCompleteMessage)));
                        await ref.read(certificationProvider.notifier).loadData();
                      } on f_auth.FirebaseAuthException catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('회원가입 실패: ${e.message}')));
                      }
                    },
                  ),
                ],
              ),
        );
      },
    );
  }

  Widget _buildTableContent(List<User> users) {
    final allCertifications = ref.watch(certificationProvider).certifications;

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
          // Table Header (기존과 동일)
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
                    days[(d.weekday - 1) % 7],
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF4A4A4A)),
                  ),
                ),
              ),
            ],
          ),
          // Table Body (데이터 로딩 로직 변경)
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
                // 사용자 이름 표시 (기존과 동일)
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
                            context.go('/user/${user.uuid}');
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
                // 날짜별 인증 상태 표시 (콜백 함수 변경)
                ...weekDates.map((date) {
                  final selectedDateStr = DateFormat('yyyyMMdd').format(date);
                  final certsForCell =
                      allCertifications.where((c) {
                        return c.uuid == user.uuid && DateFormat('yyyyMMdd').format(c.createdAt) == selectedDateStr;
                      }).toList();
                  log('2 ${allCertifications}');

                  // 상태 결정을 위한 로직만 남깁니다.
                  final hasCertification = certsForCell.isNotEmpty;
                  final isToday = selectedDateStr == DateFormat('yyyyMMdd').format(today);

                  VoidCallback? onTapCallback;
                  Widget childWidget;
                  Color backgroundColor;

                  if (hasCertification) {
                    backgroundColor = const Color(0xFFDFF6E4);
                    childWidget = Text(
                      certsForCell.length == 1
                          ? '😀'
                          : certsForCell.length == 2
                          ? '😎'
                          : '🔥',
                      style: const TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold, fontSize: 14),
                    );
                    onTapCallback = () {
                      final certsAsMaps = certsForCell.map((c) => c.toMap()..['docId'] = c.docId).toList();
                      showCertificationDialog(
                        user,
                        certsAsMaps,
                        context,
                        onDeleted: () => ref.read(certificationProvider.notifier).loadData(),
                        onUpdated: () => ref.read(certificationProvider.notifier).loadData(),
                      );
                    };
                  } else if (isToday) {
                    backgroundColor = const Color(0xFFE3F2FD);
                    childWidget = const Icon(Icons.add, color: Color(0xFF1976D2), size: 16);
                    onTapCallback =
                        () => showAddCertificationBottomSheet(
                          user: user,
                          context: context,
                          onSuccess: () => ref.read(certificationProvider.notifier).loadData(),
                        );
                  } else {
                    backgroundColor = const Color(0xFFF7F7F7);
                    childWidget = const Text(
                      '-',
                      style: TextStyle(color: Color(0xFF9E9E9E), fontWeight: FontWeight.w600, fontSize: 16),
                    );
                    onTapCallback = null;
                  }

                  return _CertificationCell(
                    viewModel: _CertificationCellViewModel(
                      backgroundColor: backgroundColor,
                      child: childWidget,
                      onTap: onTapCallback,
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

  Widget _buildJoinButton() {
    // `loadData` 호출을 provider의 메서드 호출로 변경합니다.
    return ElevatedButton.icon(
      icon: const Icon(Icons.person_add),
      label: const Text(AppStrings.join),
      onPressed: () async {
        final nicknameController = TextEditingController();
        final passwordController = TextEditingController();

        final result = await showDialog<bool>(
          context: context,
          builder:
              (ctx) => AlertDialog(
                title: const Text(AppStrings.join),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nicknameController,
                      decoration: const InputDecoration(labelText: AppStrings.nickname),
                    ),
                    TextField(
                      controller: passwordController,
                      decoration: const InputDecoration(labelText: AppStrings.password4digits),
                      obscureText: true,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                    ),
                  ],
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text(AppStrings.cancel)),
                  TextButton(
                    onPressed: () async {
                      final nickname = nicknameController.text.trim();
                      final password = passwordController.text.trim();
                      if (nickname.isNotEmpty && password.length == 6) {
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
                    child: const Text(AppStrings.complete),
                  ),
                ],
              ),
        );

        if (result == true) {
          await ref.read(certificationProvider.notifier).loadData();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text(AppStrings.joinCompleteMessage)));
          }
        }
      },
    );
  }

  Widget _buildBody(List<User> users) {
    final content = SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Column(
          children: [
            const Text(AppStrings.appTitle),
            const Gap(16),
            FDatePicker(
              focusedDay: _focusedDate,
              onChangedDay: (selectedDay) {
                setState(() {
                  _focusedDate = selectedDay;
                });
              },
            ),
            const Gap(8),
            _buildTableContent(users),
            const Gap(12),
            const Text(AppStrings.guideText),
            const Gap(12),
            _buildSignUpButton(), // [수정] 이름 변경
            ElevatedButton(onPressed: () => f_auth.FirebaseAuth.instance.signOut(), child: Text("로그아웃")),
          ],
        ),
      ),
    );

    return RefreshIndicator(onRefresh: () => ref.read(certificationProvider.notifier).loadData(), child: content);
  }
}

class User {
  final String name;
  final String uuid;

  User({required this.name, required this.uuid});
}

// _CertificationTrackerPageState 클래스 외부에 추가
class _CertificationCellViewModel {
  final Color backgroundColor;
  final Widget child;
  final VoidCallback? onTap;

  _CertificationCellViewModel({required this.backgroundColor, required this.child, this.onTap});
}

class _CertificationCell extends StatelessWidget {
  final _CertificationCellViewModel viewModel;

  const _CertificationCell({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: viewModel.onTap,
      child: Container(
        height: 32,
        width: 32,
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
        decoration: BoxDecoration(color: viewModel.backgroundColor, shape: BoxShape.circle),
        child: Center(child: viewModel.child),
      ),
    );
  }
}
