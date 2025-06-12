import 'package:cloud_firestore/cloud_firestore.dart'; // To fetch user nickname
import 'package:firebase_auth/firebase_auth.dart' hide User; // Import FirebaseAuth
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:seol_haru_check/constants/app_strings.dart';
import 'package:seol_haru_check/providers/feed_provider.dart';
import 'package:seol_haru_check/shared/components/date_picker/f_date_picker.dart';
import 'package:seol_haru_check/shared/components/f_app_bar.dart';
import 'package:seol_haru_check/shared/components/f_chip.dart';
import 'package:seol_haru_check/shared/components/f_scaffold.dart';
import 'package:seol_haru_check/shared/themes/f_colors.dart';
import 'package:seol_haru_check/shared/themes/f_font_styles.dart';
import 'package:seol_haru_check/widgets/firebase_storage_image.dart';

class OtherUserFeedPage extends ConsumerStatefulWidget {
  final String uuid; // User ID to display feed for
  const OtherUserFeedPage({required this.uuid, super.key});

  @override
  ConsumerState<OtherUserFeedPage> createState() => _OtherUserFeedPageState();
}

class _OtherUserFeedPageState extends ConsumerState<OtherUserFeedPage> {
  DateTime _focusedDate = DateTime.now();
  String _userName = AppStrings.defaultUserName; // Default name

  @override
  void initState() {
    super.initState();
    // 현재 로그인한 사용자의 UUID와 이 페이지의 UUID가 같은지 확인
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null && currentUser.uid == widget.uuid) {
      // WidgetsBinding.instance.addPostFrameCallback을 사용하여 initState 내에서 안전하게 라우팅
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/'); // MyFeedPage로 리디렉션
      });
    } else {
      _fetchUserName(); // 다른 사용자의 경우에만 닉네임 가져오기
    }
  }

  Future<void> _fetchUserName() async {
    try {
      final userDoc =
          await FirebaseFirestore.instance.collection('users').where('uuid', isEqualTo: widget.uuid).limit(1).get();
      if (userDoc.docs.isNotEmpty) {
        setState(() {
          _userName = userDoc.docs.first.data()['nickname'] ?? AppStrings.defaultUserName;
        });
      }
    } catch (e) {
      debugPrint('Error fetching user name for ${widget.uuid}: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // 만약 initState에서 리디렉션이 발생하면, 이 build 메서드는 실행되지 않거나
    // 리디렉션이 완료되기 전에 잠깐 실행될 수 있습니다.
    // 따라서 여기서도 한 번 더 체크하거나, 로딩 상태를 표시할 수 있습니다.
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null && currentUser.uid == widget.uuid) {
      return const Scaffold(body: Center(child: CircularProgressIndicator.adaptive())); // 리디렉션 중 로딩 표시
    }
    return FScaffold(
      appBar: FAppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/admin/tracker')),
        context,
        title: '$_userName${AppStrings.certificationRecord}', // Use fetched name and string constant
      ),
      body: Column(
        children: [
          // 1. 날짜 선택기
          FDatePicker(
            focusedDay: _focusedDate,
            lastDay: DateTime.now(), // 오늘 이후 날짜 선택 불가
            targetUuid: widget.uuid, // Pass the target user's UUID
            calendarFormat: FCalendarFormat.week, // 주 단위로 시작
            onChangedDay: (selectedDay) {
              setState(() {
                _focusedDate = selectedDay;
              });
            },
          ),
          const Divider(),
          // 2. 선택된 날짜의 인증 피드
          Expanded(
            child: _buildFeed(), // UI 로직을 별도 메서드로 분리
          ),
        ],
      ),
      floatingActionButton: null, // No FAB for other users' feeds
    );
  }

  // Build the feed UI
  Widget _buildFeed() {
    // feedProvider를 구독하고, _focusedDate와 targetUuid를 파라미터로 전달
    final feedAsyncValue = ref.watch(feedProvider((date: _focusedDate, targetUuid: widget.uuid))); // Corrected call

    // AsyncValue의 상태(data, loading, error)에 따라 다른 위젯을 표시
    return feedAsyncValue.when(
      data: (certifications) {
        if (certifications.isEmpty) {
          final now = DateTime.now();
          final isToday =
              _focusedDate.year == now.year && _focusedDate.month == now.month && _focusedDate.day == now.day;

          String message;
          // No action button for other users' feeds
          // Widget actionButton;

          if (isToday) {
            message = '$_userName${AppStrings.noCertificationOnToDayOther}'; // Use new string constant
          } else {
            message = '$_userName${AppStrings.noCertificationOnThisDayOther}'; // Use new string constant
          }

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  message,
                  style: FTextStyles.bodyXL.copyWith(color: FColors.of(context).labelAlternative),
                  textAlign: TextAlign.center,
                ),
                // const Gap(16), // No button
                // Padding(padding: const EdgeInsets.symmetric(horizontal: 40.0), child: actionButton),
              ],
            ),
          );
        }
        // Reuse the card/container design from MyFeedPage
        return ListView.builder(
          itemCount: certifications.length,
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          itemBuilder: (_, index) {
            final cert = certifications[index];
            final fColors = FColors.of(context);

            return Container(
              margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4), // 좌우 마진 약간 추가
              padding: const EdgeInsets.all(16), // 내부 패딩
              decoration: BoxDecoration(
                color: FColors.of(context).backgroundNormalN, // 배경색
                borderRadius: BorderRadius.circular(16), // 모서리 둥글게
                border: Border.all(color: fColors.lineNormal, width: 1), // 얇은 테두리
                boxShadow: [
                  BoxShadow(
                    color: FColors.of(context).labelDisable.withValues(alpha: .08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (cert.photoUrl.isNotEmpty) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12), // 이미지 자체에도 둥근 모서리 적용
                      child: FirebaseStorageImage(imagePath: cert.photoUrl),
                    ),
                    const Gap(16), // 이미지와 텍스트 사이 간격
                  ],
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      FChip.outline(label: cert.type, onTap: () {}),
                      // No delete button for other users' feeds
                      // TextButton(
                      //   onPressed: () { /* Delete logic */ },
                      //   child: Text(AppStrings.delete, style: FTextStyles.buttonS.copyWith(color: fColors.systemError, fontWeight: FontWeight.bold)),
                      // ),
                    ],
                  ),
                  const Gap(16),
                  if (cert.content.isNotEmpty)
                    Container(
                      width: double.infinity, // 너비를 최대로 확장하여 컨테이너 배경이 보이도록 함
                      padding: const EdgeInsets.all(12), // 내부 패딩
                      decoration: BoxDecoration(
                        color: fColors.backgroundNormalA, // 콘텐츠 박스 배경색
                        borderRadius: BorderRadius.circular(8), // 콘텐츠 박스 모서리 둥글게
                        // border: Border.all(color: fColors.lineAssistive, width: 0.5), // 필요시 테두리 추가
                      ),
                      child: Text(
                        cert.content,
                        style: FTextStyles.bodyM.copyWith(color: fColors.labelNormal, height: 1.5), // 줄 간격(height) 추가
                        maxLines: 5, // 내용이 길 경우 최대 5줄로 제한
                        overflow: TextOverflow.ellipsis, // 내용이 넘칠 경우 ...으로 표시
                      ),
                    ),
                  const Gap(8), // Date/Time gap
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      // DateFormat을 사용하여 날짜 형식 지정 (예: 'yyyy년 MM월 dd일 HH:mm')
                      DateFormat('yyyy.MM.dd HH:mm').format(cert.createdAt.toLocal()),
                      style: FTextStyles.body1_16.copyWith(color: fColors.labelAssistive),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
      loading:
          () => Center(child: CircularProgressIndicator.adaptive(backgroundColor: FColors.of(context).solidStrong)),
      error: (err, stack) {
        // 에러 로그 추가 (개발 중 확인용)
        debugPrint('Error loading feed for user ${widget.uuid}: $err');
        debugPrintStack(stackTrace: stack);
        return Center(
          child: Text(
            AppStrings.errorLoadingData,
            style: FTextStyles.bodyM.copyWith(color: FColors.of(context).labelAlternative),
          ),
        );
      },
    );
  }
}
