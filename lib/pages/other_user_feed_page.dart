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
        return ListView.builder(
          itemCount: certifications.length,
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          itemBuilder: (_, index) {
            final cert = certifications[index];
            final fColors = FColors.of(context);

            return Container(
              margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: FColors.of(context).backgroundNormalN,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: fColors.lineNormal, width: 1),
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
                      borderRadius: BorderRadius.circular(12),
                      child: FirebaseStorageImage(imagePath: cert.photoUrl),
                    ),
                    const Gap(16),
                  ],
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [FChip.outline(label: cert.type, onTap: () {})],
                  ),
                  const Gap(16),
                  if (cert.content.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: fColors.backgroundNormalA,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        cert.content,
                        style: FTextStyles.bodyM.copyWith(color: fColors.labelNormal, height: 1.5),
                        maxLines: 5,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  const Gap(8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
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
