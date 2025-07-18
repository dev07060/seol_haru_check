import 'package:firebase_auth/firebase_auth.dart' hide User;
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
import 'package:seol_haru_check/widgets/feed_page_indicator.dart';
import 'package:seol_haru_check/widgets/firebase_storage_image.dart';
import 'package:seol_haru_check/widgets/full_screen_image_viewer.dart';

class OtherUserFeedPage extends ConsumerStatefulWidget {
  final String uuid;
  const OtherUserFeedPage({required this.uuid, super.key});

  @override
  ConsumerState<OtherUserFeedPage> createState() => _OtherUserFeedPageState();
}

class _OtherUserFeedPageState extends ConsumerState<OtherUserFeedPage> {
  DateTime _focusedDate = DateTime.now();
  final PageController _pageController = PageController(viewportFraction: 0.85);
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    final currentUser = FirebaseAuth.instance.currentUser;

    _pageController.addListener(() {
      if (_pageController.page?.round() != _currentPage) {
        setState(() {
          _currentPage = _pageController.page!.round();
        });
      }
    });

    if (currentUser != null && currentUser.uid == widget.uuid) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final userNameAsyncValue = ref.watch(userNicknameProvider(widget.uuid));
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser != null && currentUser.uid == widget.uuid) {
      return const Scaffold(body: Center(child: CircularProgressIndicator.adaptive()));
    }

    return FScaffold(
      appBar: FAppBar.back(
        context,
        title: '${userNameAsyncValue.asData?.value ?? ''}${AppStrings.certificationRecord}',
        onBack: () => context.pop(),
      ),
      body: Column(
        children: [
          FDatePicker(
            focusedDay: _focusedDate,
            targetUuid: widget.uuid, // 이 부분이 이미 올바르게 설정되어 있다면 FDatePicker 내부 로직 문제일 수 있습니다.
            calendarFormat: FCalendarFormat.week,
            onChangedDay: (selectedDay) {
              setState(() {
                _focusedDate = selectedDay;
              });
            },
          ),
          Expanded(child: _buildFeed()),
        ],
      ),
    );
  }

  Widget _buildFeed() {
    final feedAsyncValue = ref.watch(feedProvider((date: _focusedDate, targetUuid: widget.uuid)));
    final userNameAsyncValue = ref.watch(userNicknameProvider(widget.uuid));

    return feedAsyncValue.when(
      data: (certifications) {
        if (certifications.isEmpty) {
          final now = DateTime.now();
          final isToday =
              _focusedDate.year == now.year && _focusedDate.month == now.month && _focusedDate.day == now.day;
          String message;

          if (isToday) {
            message = '${userNameAsyncValue.asData?.value ?? ''}${AppStrings.noCertificationOnToDayOther}';
          } else {
            message = '${userNameAsyncValue.asData?.value ?? ''}${AppStrings.noCertificationOnThisDayOther}';
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
                                    Text(
                                      DateFormat('HH:mm').format(cert.createdAt.toLocal()),
                                      style: FTextStyles.body1_16.copyWith(color: fColors.labelAssistive),
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
            certifications.length > 1
                ? FeedPageIndicator(count: certifications.length, currentPage: _currentPage)
                : const Gap(36),
          ],
        );
      },
      loading: () => Center(child: CircularProgressIndicator.adaptive()),
      error: (err, stack) {
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
