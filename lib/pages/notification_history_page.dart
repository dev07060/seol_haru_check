// lib/pages/notification_history_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:seol_haru_check/constants/app_strings.dart';
import 'package:seol_haru_check/models/notification_payload.dart';
import 'package:seol_haru_check/providers/fcm_provider.dart';
import 'package:seol_haru_check/router.dart';
import 'package:seol_haru_check/shared/components/f_app_bar.dart';
import 'package:seol_haru_check/shared/components/f_scaffold.dart';
import 'package:seol_haru_check/shared/sp_colors.dart';
import 'package:seol_haru_check/shared/themes/f_font_styles.dart';

/// 알림 기록을 표시하는 페이지
class NotificationHistoryPage extends ConsumerStatefulWidget {
  const NotificationHistoryPage({super.key});

  @override
  ConsumerState<NotificationHistoryPage> createState() => _NotificationHistoryPageState();
}

class _NotificationHistoryPageState extends ConsumerState<NotificationHistoryPage> {
  String _selectedFilter = 'all'; // 'all', 'unread', 'weekly_report'

  @override
  Widget build(BuildContext context) {
    final notifications = ref.watch(notificationHistoryProvider);
    final filteredNotifications = _filterNotifications(notifications);

    return FScaffold(
      backgroundColor: SPColors.backgroundColor(context),
      appBar: FAppBar.back(
        context,
        onBack: () => context.pop(),
        title: AppStrings.notificationHistory,
        actions: [
          if (notifications.isNotEmpty) ...[
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                if (value == 'clear') {
                  _showClearConfirmDialog();
                } else if (value == 'mark_read') {
                  _markAllAsRead();
                }
              },
              itemBuilder:
                  (context) => [
                    const PopupMenuItem(
                      value: 'mark_read',
                      child: Row(
                        children: [
                          Icon(Icons.mark_email_read, size: 20),
                          SizedBox(width: 8),
                          Text(AppStrings.markAllAsRead),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'clear',
                      child: Row(
                        children: [
                          Icon(Icons.clear_all, size: 20),
                          SizedBox(width: 8),
                          Text(AppStrings.clearNotificationHistory),
                        ],
                      ),
                    ),
                  ],
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          // 필터 탭
          _buildFilterTabs(),

          // 알림 목록
          Expanded(
            child: filteredNotifications.isEmpty ? _buildEmptyState() : _buildNotificationList(filteredNotifications),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    final notifications = ref.watch(notificationHistoryProvider);
    final unreadCount = notifications.where((n) => n.data['tapped'] != true).length;
    final weeklyReportCount = notifications.where((n) => n.type == 'weekly_report').length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildFilterTab('all', '${AppStrings.allNotifications} (${notifications.length})'),
          const SizedBox(width: 8),
          _buildFilterTab('unread', '${AppStrings.unreadNotifications} ($unreadCount)'),
          const SizedBox(width: 8),
          _buildFilterTab('weekly_report', '${AppStrings.weeklyReport} ($weeklyReportCount)'),
        ],
      ),
    );
  }

  Widget _buildFilterTab(String value, String label) {
    final isSelected = _selectedFilter == value;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? SPColors.podGreen : SPColors.gray100,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? SPColors.podGreen : SPColors.gray300),
        ),
        child: Text(
          label,
          style: FTextStyles.caption_12.copyWith(
            color: isSelected ? SPColors.white : SPColors.gray700,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none, size: 64, color: SPColors.gray400),
          const SizedBox(height: 16),
          Text(
            AppStrings.noNotifications,
            style: FTextStyles.title3_18.copyWith(color: SPColors.textColor(context), fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            '알림이 도착하면 여기에 표시됩니다',
            style: FTextStyles.body2_14.copyWith(color: SPColors.gray600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationList(List<NotificationPayload> notifications) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.read(notificationHistoryProvider.notifier).refresh();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final notification = notifications[index];
          return _buildNotificationItem(notification);
        },
      ),
    );
  }

  Widget _buildNotificationItem(NotificationPayload notification) {
    final isUnread = notification.data['tapped'] != true;
    final isWeeklyReport = notification.type == 'weekly_report';
    final dateFormat = DateFormat('M월 d일 HH:mm', 'ko_KR');

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isUnread ? SPColors.podGreen.withValues(alpha: 0.05) : SPColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isUnread ? SPColors.podGreen.withValues(alpha: 0.2) : SPColors.gray200),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isWeeklyReport ? SPColors.podGreen.withValues(alpha: 0.1) : SPColors.gray100,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            _getNotificationIcon(notification.type),
            color: isWeeklyReport ? SPColors.podGreen : SPColors.gray600,
            size: 20,
          ),
        ),
        title: Text(
          notification.title.isNotEmpty ? notification.title : '알림',
          style: FTextStyles.body1_16.copyWith(
            fontWeight: isUnread ? FontWeight.w600 : FontWeight.w400,
            color: SPColors.textColor(context),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (notification.body.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                notification.body,
                style: FTextStyles.body2_14.copyWith(color: SPColors.gray700),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  dateFormat.format(notification.receivedAt),
                  style: FTextStyles.caption_12.copyWith(color: SPColors.gray500),
                ),
                const SizedBox(width: 8),
                if (notification.tapped) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: SPColors.gray100, borderRadius: BorderRadius.circular(4)),
                    child: Text(
                      AppStrings.notificationTapped,
                      style: FTextStyles.caption_10.copyWith(color: SPColors.gray600),
                    ),
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: SPColors.podGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      AppStrings.notificationReceived,
                      style: FTextStyles.caption_10.copyWith(color: SPColors.podGreen),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        onTap: () {
          _handleNotificationTap(notification);
        },
      ),
    );
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'weekly_report':
        return Icons.analytics;
      case 'certification':
        return Icons.check_circle;
      case 'system':
        return Icons.info;
      default:
        return Icons.notifications;
    }
  }

  List<NotificationPayload> _filterNotifications(List<NotificationPayload> notifications) {
    switch (_selectedFilter) {
      case 'unread':
        return notifications.where((n) => n.data['tapped'] != true).toList();
      case 'weekly_report':
        return notifications.where((n) => n.type == 'weekly_report').toList();
      default:
        return notifications;
    }
  }

  void _handleNotificationTap(NotificationPayload notification) {
    // 주간 리포트 알림인 경우 주간 리포트 페이지로 이동
    if (notification.type == 'weekly_report') {
      context.go(AppRoutePath.weeklyReport.relativePath);
    }
  }

  void _showClearConfirmDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text(AppStrings.clearNotificationHistory),
            content: const Text(AppStrings.confirmClearHistory),
            actions: [
              TextButton(onPressed: () => context.pop(), child: const Text(AppStrings.cancel)),
              TextButton(
                onPressed: () {
                  context.pop();
                  ref.read(notificationHistoryProvider.notifier).clearHistory();
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text(AppStrings.notificationHistoryCleared)));
                },
                child: const Text(AppStrings.delete),
              ),
            ],
          ),
    );
  }

  void _markAllAsRead() {
    // 실제 구현에서는 FCM 서비스에서 모든 알림을 읽음으로 표시하는 메서드를 호출
    debugPrint('모든 알림을 읽음으로 표시');
    ref.read(notificationHistoryProvider.notifier).refresh();
  }
}
