// lib/providers/fcm_provider.dart

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:seol_haru_check/models/notification_payload.dart';
import 'package:seol_haru_check/services/fcm_service.dart';

/// FCM 서비스 인스턴스를 제공하는 Provider
final fcmServiceProvider = Provider<FCMService>((ref) {
  return FCMService();
});

/// FCM 토큰을 제공하는 Provider
final fcmTokenProvider = FutureProvider<String?>((ref) async {
  final fcmService = ref.read(fcmServiceProvider);
  await fcmService.initialize();
  return fcmService.fcmToken;
});

/// 알림 권한 상태를 제공하는 Provider
final notificationPermissionProvider = FutureProvider<AuthorizationStatus>((ref) async {
  final fcmService = ref.read(fcmServiceProvider);
  return await fcmService.getNotificationPermissionStatus();
});

/// 알림 권한이 허용되었는지 확인하는 Provider
final isNotificationPermissionGrantedProvider = FutureProvider<bool>((ref) async {
  final fcmService = ref.read(fcmServiceProvider);
  return await fcmService.isNotificationPermissionGranted();
});

/// FCM 초기화 상태를 관리하는 StateNotifier
class FCMInitializationNotifier extends StateNotifier<AsyncValue<void>> {
  FCMInitializationNotifier(this._fcmService) : super(const AsyncValue.loading()) {
    _initialize();
  }

  final FCMService _fcmService;

  Future<void> _initialize() async {
    try {
      await _fcmService.initialize();
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// FCM 재초기화
  Future<void> reinitialize() async {
    state = const AsyncValue.loading();
    await _initialize();
  }

  /// FCM 토큰 제거
  Future<void> removeFCMToken() async {
    try {
      await _fcmService.removeFCMToken();
    } catch (error) {
      // 에러 처리는 로그로만 남기고 상태는 변경하지 않음
      debugPrint('FCM 토큰 제거 실패: $error');
    }
  }
}

/// FCM 초기화 상태를 제공하는 Provider
final fcmInitializationProvider = StateNotifierProvider<FCMInitializationNotifier, AsyncValue<void>>((ref) {
  final fcmService = ref.read(fcmServiceProvider);
  return FCMInitializationNotifier(fcmService);
});

/// 새로운 주간 리포트 알림이 있는지 확인하는 StateNotifier
class NewReportNotificationNotifier extends StateNotifier<bool> {
  NewReportNotificationNotifier() : super(false);

  /// 새로운 리포트 알림 설정
  void setNewReportNotification(bool hasNew) {
    state = hasNew;
  }

  /// 새로운 리포트 알림 확인 완료
  void markAsRead() {
    state = false;
  }
}

/// 새로운 주간 리포트 알림 상태를 제공하는 Provider
final newReportNotificationProvider = StateNotifierProvider<NewReportNotificationNotifier, bool>((ref) {
  return NewReportNotificationNotifier();
});

/// 알림 히스토리를 관리하는 StateNotifier
class NotificationHistoryNotifier extends StateNotifier<List<NotificationPayload>> {
  final FCMService _fcmService;

  NotificationHistoryNotifier(this._fcmService) : super([]) {
    _loadHistory();
  }

  /// 히스토리 로드
  void _loadHistory() {
    state = _fcmService.getNotificationHistory();
  }

  /// 히스토리 새로고침
  void refresh() {
    _loadHistory();
  }

  /// 히스토리 지우기
  void clearHistory() {
    _fcmService.clearNotificationHistory();
    state = [];
  }

  /// 특정 타입의 알림 개수 가져오기
  int getCountByType(String type) {
    return _fcmService.getNotificationCountByType(type);
  }

  /// 읽지 않은 알림 개수 가져오기
  int getUnreadCount() {
    return _fcmService.getUnreadNotificationCount();
  }
}

/// 알림 히스토리 상태를 제공하는 Provider
final notificationHistoryProvider = StateNotifierProvider<NotificationHistoryNotifier, List<NotificationPayload>>((
  ref,
) {
  final fcmService = ref.read(fcmServiceProvider);
  return NotificationHistoryNotifier(fcmService);
});

/// 읽지 않은 알림 개수를 제공하는 Provider
final unreadNotificationCountProvider = Provider<int>((ref) {
  final history = ref.watch(notificationHistoryProvider);
  return history.where((notification) => notification.data['tapped'] != true).length;
});

/// 인앱 알림 표시 상태를 관리하는 StateNotifier
class InAppNotificationNotifier extends StateNotifier<RemoteMessage?> {
  InAppNotificationNotifier() : super(null);

  /// 인앱 알림 표시
  void showNotification(RemoteMessage message) {
    state = message;
  }

  /// 인앱 알림 숨기기
  void hideNotification() {
    state = null;
  }
}

/// 인앱 알림 상태를 제공하는 Provider
final inAppNotificationProvider = StateNotifierProvider<InAppNotificationNotifier, RemoteMessage?>((ref) {
  return InAppNotificationNotifier();
});

/// 알림 설정 상태를 관리하는 StateNotifier
class NotificationSettingsNotifier extends StateNotifier<AsyncValue<Map<String, bool>>> {
  NotificationSettingsNotifier() : super(const AsyncValue.loading()) {
    _loadSettings();
  }

  /// 설정 로드
  Future<void> _loadSettings() async {
    try {
      // 실제 구현에서는 SharedPreferences나 다른 저장소에서 설정을 로드
      // 현재는 기본값으로 설정
      final settings = {'weeklyReport': true, 'certification': true, 'system': true};
      state = AsyncValue.data(settings);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// 설정 업데이트
  Future<void> updateSetting(String key, bool value) async {
    final currentState = state;
    if (currentState is AsyncData<Map<String, bool>>) {
      final updatedSettings = Map<String, bool>.from(currentState.value);
      updatedSettings[key] = value;
      state = AsyncValue.data(updatedSettings);

      // 실제 구현에서는 SharedPreferences에 저장
      debugPrint('알림 설정 업데이트: $key = $value');
    }
  }

  /// 설정 새로고침
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    await _loadSettings();
  }
}

/// 알림 설정 상태를 제공하는 Provider
final notificationSettingsProvider = StateNotifierProvider<NotificationSettingsNotifier, AsyncValue<Map<String, bool>>>(
  (ref) {
    return NotificationSettingsNotifier();
  },
);
