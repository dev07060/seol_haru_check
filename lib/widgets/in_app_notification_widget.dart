// lib/widgets/in_app_notification_widget.dart

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:seol_haru_check/constants/app_strings.dart';
import 'package:seol_haru_check/providers/fcm_provider.dart';
import 'package:seol_haru_check/shared/sp_colors.dart';
import 'package:seol_haru_check/shared/themes/f_font_styles.dart';

/// 인앱 알림을 표시하는 위젯
class InAppNotificationWidget extends ConsumerStatefulWidget {
  const InAppNotificationWidget({super.key});

  @override
  ConsumerState<InAppNotificationWidget> createState() => _InAppNotificationWidgetState();
}

class _InAppNotificationWidgetState extends ConsumerState<InAppNotificationWidget> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(duration: const Duration(milliseconds: 300), vsync: this);

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notification = ref.watch(inAppNotificationProvider);

    // 알림이 있을 때만 표시
    if (notification == null) {
      return const SizedBox.shrink();
    }

    // 애니메이션 시작
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _animationController.forward();

        // 3초 후 자동으로 숨기기
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            _hideNotification();
          }
        });
      }
    });

    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(opacity: _fadeAnimation, child: _buildNotificationCard(notification)),
      ),
    );
  }

  Widget _buildNotificationCard(RemoteMessage notification) {
    final title = notification.notification?.title ?? '';
    final body = notification.notification?.body ?? '';
    final isWeeklyReport = notification.data['type'] == 'weekly_report';

    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: SPColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isWeeklyReport ? SPColors.podGreen : SPColors.gray300, width: 1),
        ),
        child: Row(
          children: [
            // 아이콘
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isWeeklyReport ? SPColors.podGreen.withValues(alpha: 0.1) : SPColors.gray100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                isWeeklyReport ? Icons.analytics : Icons.notifications,
                color: isWeeklyReport ? SPColors.podGreen : SPColors.gray600,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),

            // 내용
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (title.isNotEmpty) ...[
                    Text(
                      title,
                      style: FTextStyles.body1_16.copyWith(fontWeight: FontWeight.w600, color: SPColors.black),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                  ],
                  if (body.isNotEmpty) ...[
                    Text(
                      body,
                      style: FTextStyles.body2_14.copyWith(color: SPColors.gray700),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (isWeeklyReport) ...[
                    const SizedBox(height: 4),
                    Text(
                      AppStrings.tapToView,
                      style: FTextStyles.caption_12.copyWith(color: SPColors.podGreen, fontWeight: FontWeight.w500),
                    ),
                  ],
                ],
              ),
            ),

            // 닫기 버튼
            GestureDetector(
              onTap: _hideNotification,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(color: SPColors.gray100, borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.close, size: 16, color: SPColors.gray600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _hideNotification() {
    _animationController.reverse().then((_) {
      if (mounted) {
        ref.read(inAppNotificationProvider.notifier).hideNotification();
      }
    });
  }
}

/// 인앱 알림 오버레이를 제공하는 위젯
class InAppNotificationOverlay extends ConsumerWidget {
  final Widget child;

  const InAppNotificationOverlay({required this.child, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Stack(children: [child, const InAppNotificationWidget()]);
  }
}

/// 알림 권한이 비활성화된 경우 표시하는 배너
class NotificationPermissionBanner extends ConsumerWidget {
  const NotificationPermissionBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isGrantedAsync = ref.watch(isNotificationPermissionGrantedProvider);

    return isGrantedAsync.when(
      data: (isGranted) {
        if (isGranted) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.notifications_off, color: Colors.orange, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.newReportAvailable,
                      style: FTextStyles.body2_14.copyWith(fontWeight: FontWeight.w600, color: Colors.orange),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      AppStrings.notificationPermissionRequired,
                      style: FTextStyles.caption_12.copyWith(color: Colors.orange),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () {
                  // 설정 앱으로 이동하는 로직
                  // 실제 구현에서는 app_settings 패키지 등을 사용할 수 있습니다
                  debugPrint('설정 앱으로 이동');
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                child: Text(
                  AppStrings.openSettings,
                  style: FTextStyles.caption_12.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
