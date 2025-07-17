import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart' hide User;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:seol_haru_check/certification_tracker_page.dart' show User;
import 'package:seol_haru_check/constants/app_strings.dart';
import 'package:seol_haru_check/providers/feed_provider.dart';
import 'package:seol_haru_check/router.dart';
import 'package:seol_haru_check/shared/components/date_picker/f_date_picker.dart';
import 'package:seol_haru_check/shared/components/f_app_bar.dart';
import 'package:seol_haru_check/shared/components/f_chip.dart';
import 'package:seol_haru_check/shared/components/f_dialog.dart';
import 'package:seol_haru_check/shared/components/f_scaffold.dart';
import 'package:seol_haru_check/shared/components/f_solid_button.dart';
import 'package:seol_haru_check/shared/components/f_toast.dart';
import 'package:seol_haru_check/shared/themes/f_colors.dart';
import 'package:seol_haru_check/shared/themes/f_font_styles.dart';
import 'package:seol_haru_check/widgets/feed_page_indicator.dart';
import 'package:seol_haru_check/widgets/firebase_storage_image.dart';
import 'package:seol_haru_check/widgets/full_screen_image_viewer.dart';
import 'package:seol_haru_check/widgets/show_add_certification_dialog.dart';

class MyFeedPage extends ConsumerStatefulWidget {
  const MyFeedPage({super.key});

  @override
  ConsumerState<MyFeedPage> createState() => _MyFeedPageState();
}

class _MyFeedPageState extends ConsumerState<MyFeedPage> {
  DateTime _focusedDate = DateTime.now();
  final PageController _pageController = PageController(viewportFraction: 0.85);

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isToday = _focusedDate.year == now.year && _focusedDate.month == now.month && _focusedDate.day == now.day;

    return FScaffold(
      appBar: FAppBar(
        leading: IconButton(
          icon: const Icon(Icons.list),
          onPressed: () => context.goNamed(AppRoutePath.adminTracker.name),
        ),
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
          FDatePicker(
            focusedDay: _focusedDate,
            lastDay: DateTime.now(),
            calendarFormat: FCalendarFormat.week,
            onChangedDay: (selectedDay) {
              setState(() {
                _focusedDate = selectedDay;
              });
            },
          ),
          const Divider(),
          Expanded(child: _buildFeed()),
        ],
      ),
      floatingActionButton:
          isToday
              ? FloatingActionButton(
                backgroundColor: FColors.of(context).white.withValues(alpha: .6),
                elevation: 0.3,
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
                child: const Icon(Icons.add),
              )
              : null,
    );
  }

  Widget _buildFeed() {
    final feedAsyncValue = ref.watch(feedProvider((date: _focusedDate, targetUuid: null)));
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
        return Column(
          children: [
            // 가로 스크롤 카드
            Expanded(
              child: PageView.builder(
                itemCount: certifications.length,
                controller: _pageController,
                itemBuilder: (context, index) {
                  log('uuid: ${certifications.last.uuid}');
                  if (kDebugMode && index == certifications.length) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: FColors.of(context).backgroundNormalN,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: FColors.of(context).lineNormal, width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: FColors.of(context).labelDisable.withValues(alpha: .12),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Center(
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
                      ),
                    );
                  }

                  final cert = certifications[index];
                  final fColors = FColors.of(context);

                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
                    decoration: BoxDecoration(
                      color: FColors.of(context).backgroundNormalN,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: fColors.lineNormal, width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: FColors.of(context).labelDisable.withValues(alpha: .12),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (cert.photoUrl.isNotEmpty) ...[
                          GestureDetector(
                            onTap: () {
                              Navigator.of(
                                context,
                              ).push(FullScreenImageViewer.createRoute(cert.photoUrl, cert.content));
                            },
                            child: ClipRRect(
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(20),
                                topRight: Radius.circular(20),
                              ),
                              child: FirebaseStorageImage(
                                imagePath: cert.photoUrl,
                                aspectRatio: 1.0,
                                width: double.infinity,
                              ),
                            ),
                          ),
                        ],
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    FChip.outline(label: cert.type.displayName, onTap: () {}),
                                    TextButton(
                                      onPressed: () async {
                                        FDialog.twoButton(
                                          context,
                                          title: AppStrings.confirmDeleteCertificationTitle,
                                          description: AppStrings.confirmDeleteCertificationDescription,
                                          onConfirm: () async {
                                            try {
                                              await ref
                                                  .read(certificationRepositoryProvider)
                                                  .deleteCertification(cert.docId);
                                              FToast(
                                                message: AppStrings.certificationDeletedSuccessfully,
                                              ).show(context);
                                            } catch (e) {
                                              FToast(message: AppStrings.certificationDeletionFailed).show(context);
                                              debugPrint('Error deleting certification: $e');
                                            }
                                          },
                                          confirmText: AppStrings.delete,
                                        ).show(context);
                                      },
                                      child: Text(
                                        AppStrings.delete,
                                        style: FTextStyles.body1_16Rd.copyWith(color: fColors.red),
                                      ),
                                    ),
                                  ],
                                ),
                                const Gap(16),
                                if (cert.content.isNotEmpty)
                                  Expanded(
                                    child: Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: fColors.backgroundNormalA,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: SingleChildScrollView(
                                        child: Text(
                                          cert.content,
                                          style: FTextStyles.bodyM.copyWith(color: fColors.labelNormal, height: 1.6),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            // 페이지 인디케이터 (하단으로 이동)
            if (certifications.length > 1)
              FeedPageIndicator(count: certifications.length, currentPage: _pageController.page?.round() ?? 0),
          ],
        );
      },
      loading:
          () => Center(child: CircularProgressIndicator.adaptive(backgroundColor: FColors.of(context).solidStrong)),
      error: (err, stack) {
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
