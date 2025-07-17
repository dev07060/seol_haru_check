import 'package:cloud_firestore/cloud_firestore.dart';
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
import 'package:seol_haru_check/widgets/firebase_storage_image.dart';

class OtherUserFeedPage extends ConsumerStatefulWidget {
  final String uuid;
  const OtherUserFeedPage({required this.uuid, super.key});

  @override
  ConsumerState<OtherUserFeedPage> createState() => _OtherUserFeedPageState();
}

class _OtherUserFeedPageState extends ConsumerState<OtherUserFeedPage> {
  DateTime _focusedDate = DateTime.now();
  String _userName = AppStrings.defaultUserName;

  @override
  void initState() {
    super.initState();
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null && currentUser.uid == widget.uuid) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/');
      });
    } else {
      _fetchUserName();
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
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null && currentUser.uid == widget.uuid) {
      return const Scaffold(body: Center(child: CircularProgressIndicator.adaptive()));
    }
    return FScaffold(
      appBar: FAppBar.back(context, title: '$_userName${AppStrings.certificationRecord}', onBack: () => context.pop()),
      body: Column(
        children: [
          FDatePicker(
            focusedDay: _focusedDate,
            targetUuid: widget.uuid,
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
    );
  }

  Widget _buildFeed() {
    final feedAsyncValue = ref.watch(feedProvider((date: _focusedDate, targetUuid: widget.uuid)));

    return feedAsyncValue.when(
      data: (certifications) {
        if (certifications.isEmpty) {
          final now = DateTime.now();
          final isToday =
              _focusedDate.year == now.year && _focusedDate.month == now.month && _focusedDate.day == now.day;
          String message;

          if (isToday) {
            message = '$_userName${AppStrings.noCertificationOnToDayOther}';
          } else {
            message = '$_userName${AppStrings.noCertificationOnThisDayOther}';
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
                controller: PageController(viewportFraction: 0.85),
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
                              Navigator.of(context).push(_createFullScreenImageRoute(cert.photoUrl, cert.content));
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
                        Padding(
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
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: fColors.backgroundNormalA,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    cert.content,
                                    maxLines: 8,
                                    style: FTextStyles.bodyM.copyWith(color: fColors.labelNormal, height: 1.6),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            // 페이지 인디케이터 (하단으로 이동)
            if (certifications.length > 1) ...[
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    certifications.length,
                    (index) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: FColors.of(context).labelAssistive.withValues(alpha: 0.4),
                      ),
                    ),
                  ),
                ),
              ),
            ],
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

  PageRouteBuilder _createFullScreenImageRoute(String imageUrl, String content) {
    return PageRouteBuilder(
      opaque: false,
      pageBuilder:
          (context, animation, secondaryAnimation) => _FullScreenImageViewer(imageUrl: imageUrl, content: content),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    );
  }
}

class _FullScreenImageViewer extends StatelessWidget {
  final String imageUrl;
  final String content;

  const _FullScreenImageViewer({required this.imageUrl, required this.content});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.8),
      body: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Stack(
          children: [
            Center(
              child: SingleChildScrollView(
                child: FirebaseStorageImage(
                  imagePath: imageUrl,
                  width: MediaQuery.of(context).size.width,
                  fit: BoxFit.fitWidth,
                ),
              ),
            ),
            if (content.isNotEmpty)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.4),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
                      stops: const [0.0, 0.4],
                    ),
                  ),
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 60, 20, 40),
                      child: Text(content, style: FTextStyles.bodyM.copyWith(color: Colors.white, height: 1.5)),
                    ),
                  ),
                ),
              ),
            Positioned(top: 40, right: 16, child: CloseButton(color: Colors.white)),
          ],
        ),
      ),
    );
  }
}
