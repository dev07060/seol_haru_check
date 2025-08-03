// lib/widgets/notification_settings_widget.dart

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:seol_haru_check/constants/app_strings.dart';
import 'package:seol_haru_check/pages/notification_history_page.dart';
import 'package:seol_haru_check/providers/fcm_provider.dart';
import 'package:seol_haru_check/shared/sp_colors.dart';
import 'package:seol_haru_check/shared/themes/f_font_styles.dart';

/// 알림 설정 상태를 표시하는 위젯
class NotificationSettingsWidget extends ConsumerWidget {
  const NotificationSettingsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissionAsync = ref.watch(notificationPermissionProvider);
    final isGrantedAsync = ref.watch(isNotificationPermissionGrantedProvider);
    final settingsAsync = ref.watch(notificationSettingsProvider);
    final unreadCount = ref.watch(unreadNotificationCountProvider);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더
            Row(
              children: [
                Icon(Icons.notifications, color: SPColors.podGreen, size: 24),
                const SizedBox(width: 8),
                Text(
                  AppStrings.notificationSettings,
                  style: FTextStyles.title3_18.copyWith(
                    fontWeight: FontWeight.bold,
                    color: SPColors.textColor(context),
                  ),
                ),
                const Spacer(),
                if (unreadCount > 0) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: SPColors.danger100, borderRadius: BorderRadius.circular(12)),
                    child: Text(
                      '$unreadCount',
                      style: FTextStyles.caption_12.copyWith(color: SPColors.white, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),

            // 권한 상태
            permissionAsync.when(
              data: (status) => _buildPermissionStatus(context, status),
              loading: () => const CircularProgressIndicator(),
              error: (error, stack) => Text('오류: $error'),
            ),
            const SizedBox(height: 12),

            // 권한 안내
            isGrantedAsync.when(
              data: (isGranted) => _buildPermissionIndicator(isGranted),
              loading: () => const SizedBox.shrink(),
              error: (error, stack) => const SizedBox.shrink(),
            ),

            // 알림 설정 (권한이 허용된 경우에만 표시)
            isGrantedAsync.when(
              data:
                  (isGranted) =>
                      isGranted ? _buildNotificationSettings(context, ref, settingsAsync) : const SizedBox.shrink(),
              loading: () => const SizedBox.shrink(),
              error: (error, stack) => const SizedBox.shrink(),
            ),

            const SizedBox(height: 16),

            // 알림 기록 버튼
            _buildNotificationHistoryButton(context, unreadCount),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionStatus(BuildContext context, AuthorizationStatus status) {
    String statusText;
    Color statusColor;
    IconData statusIcon;

    switch (status) {
      case AuthorizationStatus.authorized:
        statusText = '알림이 허용되었습니다';
        statusColor = Colors.green;
        statusIcon = Icons.notifications_active;
        break;
      case AuthorizationStatus.denied:
        statusText = '알림이 거부되었습니다';
        statusColor = Colors.red;
        statusIcon = Icons.notifications_off;
        break;
      case AuthorizationStatus.notDetermined:
        statusText = '알림 권한이 설정되지 않았습니다';
        statusColor = Colors.orange;
        statusIcon = Icons.notifications_none;
        break;
      case AuthorizationStatus.provisional:
        statusText = '임시 알림이 허용되었습니다';
        statusColor = Colors.blue;
        statusIcon = Icons.notifications_paused;
        break;
    }

    return Row(
      children: [
        Icon(statusIcon, color: statusColor, size: 20),
        const SizedBox(width: 8),
        Expanded(child: Text(statusText, style: TextStyle(color: statusColor))),
      ],
    );
  }

  Widget _buildPermissionIndicator(bool isGranted) {
    if (!isGranted) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.orange, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.notificationPermissionRequired,
                    style: FTextStyles.body2_14.copyWith(color: Colors.orange, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text('주간 리포트 알림을 받으려면 알림 권한을 허용해주세요.', style: FTextStyles.caption_12.copyWith(color: Colors.orange)),
                ],
              ),
            ),
            TextButton(
              onPressed: () {
                // 설정 앱으로 이동
                debugPrint('설정 앱으로 이동');
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.orange,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              child: Text(AppStrings.openSettings, style: FTextStyles.caption_12.copyWith(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildNotificationSettings(BuildContext context, WidgetRef ref, AsyncValue<Map<String, bool>> settingsAsync) {
    return settingsAsync.when(
      data:
          (settings) => Column(
            children: [
              const Divider(),
              const SizedBox(height: 8),
              _buildSettingTile(
                context,
                ref,
                '주간 리포트 알림',
                '매주 일요일 저녁에 AI 분석 리포트를 받습니다',
                Icons.analytics,
                'weeklyReport',
                settings['weeklyReport'] ?? true,
              ),
              _buildSettingTile(
                context,
                ref,
                '인증 관련 알림',
                '인증 관련 업데이트를 받습니다',
                Icons.check_circle,
                'certification',
                settings['certification'] ?? true,
              ),
              _buildSettingTile(
                context,
                ref,
                '시스템 알림',
                '앱 업데이트 및 중요 공지사항을 받습니다',
                Icons.info,
                'system',
                settings['system'] ?? true,
              ),
            ],
          ),
      loading: () => const CircularProgressIndicator(),
      error: (error, stack) => Text('설정 로드 실패: $error'),
    );
  }

  Widget _buildSettingTile(
    BuildContext context,
    WidgetRef ref,
    String title,
    String subtitle,
    IconData icon,
    String key,
    bool value,
  ) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: SPColors.podGreen, size: 20),
      title: Text(
        title,
        style: FTextStyles.body1_16.copyWith(color: SPColors.textColor(context), fontWeight: FontWeight.w500),
      ),
      subtitle: Text(subtitle, style: FTextStyles.caption_12.copyWith(color: SPColors.gray600)),
      trailing: Switch(
        value: value,
        onChanged: (newValue) {
          ref.read(notificationSettingsProvider.notifier).updateSetting(key, newValue);
        },
        activeColor: SPColors.podGreen,
      ),
    );
  }

  Widget _buildNotificationHistoryButton(BuildContext context, int unreadCount) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {
          Navigator.of(context).push(MaterialPageRoute(builder: (context) => const NotificationHistoryPage()));
        },
        icon: const Icon(Icons.history),
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(AppStrings.notificationHistory),
            if (unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: SPColors.danger100, borderRadius: BorderRadius.circular(10)),
                child: Text(
                  '$unreadCount',
                  style: FTextStyles.caption_10.copyWith(color: SPColors.white, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ],
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: SPColors.podGreen,
          side: BorderSide(color: SPColors.podGreen),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}

/// FCM 토큰을 표시하는 디버그 위젯 (개발용)
class FCMTokenDebugWidget extends ConsumerWidget {
  const FCMTokenDebugWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokenAsync = ref.watch(fcmTokenProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('FCM 토큰 (디버그)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            tokenAsync.when(
              data:
                  (token) =>
                      token != null
                          ? SelectableText(token, style: const TextStyle(fontSize: 12, fontFamily: 'monospace'))
                          : const Text('토큰을 가져올 수 없습니다'),
              loading: () => const CircularProgressIndicator(),
              error: (error, stack) => Text('오류: $error'),
            ),
          ],
        ),
      ),
    );
  }
}
