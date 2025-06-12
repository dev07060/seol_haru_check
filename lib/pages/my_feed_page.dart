import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart' hide User; // FirebaseAuth import 추가
import 'package:flutter/foundation.dart'; // kDebugMode를 사용하기 위해 import 추가
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart'; // intl 패키지 import 추가
import 'package:seol_haru_check/certification_tracker_page.dart' show User; // Import User model
import 'package:seol_haru_check/constants/app_strings.dart';
import 'package:seol_haru_check/providers/feed_provider.dart';
import 'package:seol_haru_check/shared/components/date_picker/f_date_picker.dart';
import 'package:seol_haru_check/shared/components/f_app_bar.dart';
import 'package:seol_haru_check/shared/components/f_chip.dart';
import 'package:seol_haru_check/shared/components/f_dialog.dart';
import 'package:seol_haru_check/shared/components/f_scaffold.dart';
import 'package:seol_haru_check/shared/components/f_solid_button.dart'; // FSolidButton import
import 'package:seol_haru_check/shared/components/f_toast.dart'; // FToast import
import 'package:seol_haru_check/shared/themes/f_colors.dart';
import 'package:seol_haru_check/shared/themes/f_font_styles.dart';
import 'package:seol_haru_check/widgets/firebase_storage_image.dart';
import 'package:seol_haru_check/widgets/show_add_certification_dialog.dart';

class MyFeedPage extends ConsumerStatefulWidget {
  const MyFeedPage({super.key});

  @override
  ConsumerState<MyFeedPage> createState() => _MyFeedPageState();
}

class _MyFeedPageState extends ConsumerState<MyFeedPage> {
  // FDatePicker와 연동될 현재 선택된 날짜
  DateTime _focusedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isToday = _focusedDate.year == now.year && _focusedDate.month == now.month && _focusedDate.day == now.day;

    return FScaffold(
      appBar: FAppBar(
        leading: IconButton(icon: const Icon(Icons.list), onPressed: () => GoRouter.of(context).go('/admin/tracker')),
        context,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed:
                () => FDialog.twoButton(
                  context,
                  title: '로그아웃',
                  description: '정말 로그아웃 하시겠습니까?',
                  onConfirm: () async {
                    try {
                      FirebaseAuth.instance.signOut();
                      FToast(message: '로그아웃 되었습니다.').show(context);
                    } catch (e) {
                      // 실패 메시지도 AppStrings에 추가하는 것이 좋습니다.
                      FToast(message: '로그아웃 실패. 잠시후 다시 시도해주세요').show(context);
                      debugPrint('Error deleting certification: $e');
                    }
                  },
                  confirmText: '로그아웃',
                ).show(context),
          ),
        ],
        title: AppStrings.myActivityFeed,
      ),
      body: Column(
        children: [
          // 1. 날짜 선택기
          FDatePicker(
            focusedDay: _focusedDate,
            lastDay: DateTime.now(), // 오늘 이후 날짜 선택 불가
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
      floatingActionButton:
          isToday // 오늘 날짜일 경우에만 FAB 표시
              ? FloatingActionButton(
                backgroundColor: FColors.of(context).white.withValues(alpha: .6), // 배경색 변경
                elevation: 0.3,
                onPressed: () {
                  final currentUser = FirebaseAuth.instance.currentUser;
                  if (currentUser == null) {
                    // 사용자가 로그인하지 않은 경우, 로그인 페이지로 안내하거나 메시지 표시
                    FToast(message: AppStrings.loginRequired).show(context);
                    return;
                  }

                  // certification_tracker_page.dart에 정의된 User 모델 사용
                  final appUser = User(
                    name: currentUser.displayName ?? AppStrings.defaultUserName, // Firebase displayName 사용, 없을 경우 기본값
                    uuid: currentUser.uid,
                  );

                  showAddCertificationBottomSheet(
                    user: appUser,
                    context: context,
                    onSuccess: () {
                      FToast(message: AppStrings.certificationAddedSuccessfully).show(context);
                      // 피드는 StreamProvider에 의해 자동으로 업데이트됩니다.
                    },
                  );
                },
                child: const Icon(Icons.add), // 아이콘 변경
              )
              : null, // 오늘 날짜가 아니면 FAB를 표시하지 않음
    );
  }

  // _MyFeedPageState 클래스 내에 아래 메서드 추가
  Widget _buildFeed() {
    // feedProvider를 구독하고, _focusedDate를 파라미터로 전달
    final feedAsyncValue = ref.watch(
      feedProvider((date: _focusedDate, targetUuid: null)),
    ); // Pass targetUuid: null for current user

    // AsyncValue의 상태(data, loading, error)에 따라 다른 위젯을 표시
    return feedAsyncValue.when(
      data: (certifications) {
        if (certifications.isEmpty) {
          final now = DateTime.now();
          final isToday =
              _focusedDate.year == now.year && _focusedDate.month == now.month && _focusedDate.day == now.day;

          String message;
          Widget actionButton;

          if (isToday) {
            message = AppStrings.noCertificationOnToDay;
            actionButton = FSolidButton.primary(
              text: AppStrings.addCertificationToday,
              onPressed: () {
                final currentUser = FirebaseAuth.instance.currentUser;
                if (currentUser == null) {
                  FToast(message: AppStrings.loginRequired).show(context);
                  return;
                }
                final appUser = User(
                  name: currentUser.displayName ?? AppStrings.defaultUserName,
                  uuid: currentUser.uid,
                );
                showAddCertificationBottomSheet(
                  user: appUser,
                  context: context,
                  onSuccess: () {
                    FToast(message: AppStrings.certificationAddedSuccessfully).show(context);
                  },
                );
              },
            );
          } else {
            message = AppStrings.noCertificationOnThisDay;
            actionButton = FSolidButton.secondary(
              text: AppStrings.moveToToday,
              onPressed: () {
                setState(() {
                  _focusedDate = DateTime.now();
                });
              },
            );
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
                const Gap(16),
                Padding(padding: const EdgeInsets.symmetric(horizontal: 40.0), child: actionButton),
              ],
            ),
          );
        }
        // UserDetailPage의 카드 디자인을 재활용
        return ListView.builder(
          // 마이그레이션 버튼을 위한 공간 추가 (인증 기록이 있거나 없을 때 모두 표시될 수 있도록)
          itemCount: certifications.length + (kDebugMode ? 1 : 0), // kDebugMode일 때만 버튼 공간 추가
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          itemBuilder: (_, index) {
            log('uuid: ${certifications.last.uuid}');

            // 마지막 인덱스인 경우 마이그레이션 버튼 표시
            if (kDebugMode && index == certifications.length) {
              // kDebugMode일 때만 마이그레이션 버튼 표시
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
                child: FSolidButton.primary(
                  text: AppStrings.migrateOldDataButton,
                  onPressed: () {
                    final currentUser = FirebaseAuth.instance.currentUser;
                    if (currentUser == null) {
                      FToast(message: AppStrings.loginRequired).show(context);
                      return;
                    }
                    FDialog.twoButton(
                      context,
                      title: AppStrings.confirmDataMigrationTitle,
                      description: AppStrings.confirmDataMigrationDescription,
                      confirmText: AppStrings.migrateOldDataButton,
                      onConfirm: () async {
                        final userEmail = currentUser.email;
                        if (userEmail == null || !userEmail.contains('@')) {
                          FToast(message: "사용자 이메일을 가져올 수 없습니다.").show(context);
                          return;
                        }
                        final emailLocalPart = userEmail.split('@')[0];

                        try {
                          await ref
                              .read(certificationRepositoryProvider)
                              .migrateCertificationsByNickname(emailLocalPart, currentUser.uid);
                          FToast(message: AppStrings.dataMigrationSuccessful).show(context);
                        } catch (e) {
                          FToast(message: AppStrings.dataMigrationFailed).show(context);
                          debugPrint('Data migration failed: $e');
                        }
                      },
                    ).show(context);
                  },
                ),
              );
            }

            final cert = certifications[index];
            // UserDetailPage에 있던 카드 위젯을 그대로 가져오거나 재사용 가능한 위젯으로 만듭니다.
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
                      TextButton(
                        onPressed: () async {
                          // 확인 다이얼로그 없이 바로 삭제 로직 실행
                          FDialog.twoButton(
                            context,
                            title: AppStrings.confirmDeleteCertificationTitle,
                            description: AppStrings.confirmDeleteCertificationDescription,
                            onConfirm: () async {
                              try {
                                await ref.read(certificationRepositoryProvider).deleteCertification(cert.docId);
                                FToast(message: AppStrings.certificationDeletedSuccessfully).show(context);
                              } catch (e) {
                                // 실패 메시지도 AppStrings에 추가하는 것이 좋습니다.
                                FToast(message: AppStrings.certificationDeletionFailed).show(context);
                                debugPrint('Error deleting certification: $e');
                              }
                            },
                            confirmText: AppStrings.delete,
                          ).show(context);
                        },
                        child: Text(AppStrings.delete, style: FTextStyles.body1_16Rd.copyWith(color: fColors.red)),
                      ),
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
                  const Gap(8), // 유형과 날짜 사이 간격
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      // Date/Time for the certification
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
        debugPrint('Error loading feed: $err');
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
