// lib/services/fcm_service.dart

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:seol_haru_check/models/notification_payload.dart';
import 'package:seol_haru_check/router.dart';

/// Firebase Cloud Messaging 서비스 클래스
/// 푸시 알림 권한 요청, FCM 토큰 관리, 알림 처리를 담당합니다.
class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  // Navigation context for handling notification taps
  BuildContext? _navigationContext;

  // Callback for handling in-app notifications
  Function(RemoteMessage)? _onForegroundMessage;

  // Notification history storage
  final List<NotificationPayload> _notificationHistory = [];

  /// FCM 초기화 및 권한 요청
  Future<void> initialize({BuildContext? context, Function(RemoteMessage)? onForegroundMessage}) async {
    _navigationContext = context;
    _onForegroundMessage = onForegroundMessage;
    try {
      // 알림 권한 요청
      await _requestPermission();

      // FCM 토큰 가져오기
      await _getFCMToken();

      // 포그라운드 메시지 처리 설정
      _setupForegroundMessageHandler();

      // 백그라운드 메시지 처리 설정
      _setupBackgroundMessageHandler();

      // 앱이 종료된 상태에서 알림을 탭해서 열린 경우 처리
      _handleInitialMessage();

      // 토큰 새로고침 리스너 설정
      _setupTokenRefreshListener();
    } catch (e) {
      debugPrint('FCM 초기화 실패: $e');
    }
  }

  /// 알림 권한 요청
  Future<void> _requestPermission() async {
    if (kIsWeb) {
      // 웹에서는 별도 권한 요청 불필요
      return;
    }

    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    debugPrint('알림 권한 상태: ${settings.authorizationStatus}');

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      debugPrint('사용자가 알림 권한을 거부했습니다.');
    }
  }

  /// FCM 토큰 가져오기 및 Firestore에 저장
  Future<void> _getFCMToken() async {
    try {
      _fcmToken = await _messaging.getToken();
      debugPrint('FCM 토큰: $_fcmToken');

      if (_fcmToken != null) {
        await _saveFCMTokenToFirestore(_fcmToken!);
      }
    } catch (e) {
      debugPrint('FCM 토큰 가져오기 실패: $e');
    }
  }

  /// FCM 토큰을 Firestore에 저장
  Future<void> _saveFCMTokenToFirestore(String token) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'fcmToken': token,
          'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
          'platform':
              Platform.isIOS
                  ? 'ios'
                  : Platform.isAndroid
                  ? 'android'
                  : 'web',
        });
        debugPrint('FCM 토큰이 Firestore에 저장되었습니다.');
      }
    } catch (e) {
      debugPrint('FCM 토큰 Firestore 저장 실패: $e');
    }
  }

  /// 포그라운드 메시지 처리 설정
  void _setupForegroundMessageHandler() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('포그라운드에서 메시지 수신: ${message.messageId}');
      debugPrint('제목: ${message.notification?.title}');
      debugPrint('내용: ${message.notification?.body}');
      debugPrint('데이터: ${message.data}');

      // 포그라운드에서 알림을 받았을 때 처리
      _handleForegroundMessage(message);
    });
  }

  /// 백그라운드 메시지 처리 설정
  void _setupBackgroundMessageHandler() {
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('백그라운드에서 알림을 탭하여 앱 열림: ${message.messageId}');
      _handleNotificationTap(message);
    });
  }

  /// 앱이 종료된 상태에서 알림을 탭해서 열린 경우 처리
  Future<void> _handleInitialMessage() async {
    RemoteMessage? initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('앱이 종료된 상태에서 알림을 탭하여 열림: ${initialMessage.messageId}');
      _handleNotificationTap(initialMessage);
    }
  }

  /// 토큰 새로고침 리스너 설정
  void _setupTokenRefreshListener() {
    _messaging.onTokenRefresh.listen((String token) {
      debugPrint('FCM 토큰이 새로고침되었습니다: $token');
      _fcmToken = token;
      _saveFCMTokenToFirestore(token);
    });
  }

  /// 포그라운드에서 메시지를 받았을 때 처리
  void _handleForegroundMessage(RemoteMessage message) {
    // 알림 히스토리에 추가
    _addToNotificationHistory(message);

    // 주간 리포트 알림인 경우 인앱 알림 표시
    if (message.data['type'] == 'weekly_report') {
      _showInAppNotification(message);
    }

    // 외부 콜백 호출
    _onForegroundMessage?.call(message);
  }

  /// 알림을 탭했을 때 처리
  void _handleNotificationTap(RemoteMessage message) {
    final data = message.data;

    // 알림 히스토리에 추가 (탭된 것으로 표시)
    _addToNotificationHistory(message, tapped: true);

    // 주간 리포트 알림인 경우 주간 리포트 페이지로 이동
    if (data['type'] == 'weekly_report') {
      _navigateToWeeklyReport(data);
    }
  }

  /// 인앱 알림 표시 (포그라운드에서 알림을 받았을 때)
  void _showInAppNotification(RemoteMessage message) {
    // 포그라운드에서 알림을 받았을 때 처리
    // 실제 구현에서는 상태 관리를 통해 알림 표시 상태를 업데이트할 수 있습니다.
    debugPrint('인앱 알림 표시: ${message.notification?.title}');

    // 주간 리포트 알림인 경우 새 리포트 플래그 설정
    if (message.data['type'] == 'weekly_report') {
      // 이 부분은 실제로는 Riverpod provider를 통해 상태를 업데이트해야 합니다.
      // 여기서는 로그만 남깁니다.
      debugPrint('새로운 주간 리포트 알림 수신');
    }
  }

  /// 주간 리포트 페이지로 이동
  void _navigateToWeeklyReport(Map<String, dynamic> data) {
    debugPrint('주간 리포트 페이지로 이동: $data');

    if (_navigationContext != null && _navigationContext!.mounted) {
      try {
        // 주간 리포트 페이지로 직접 이동
        GoRouter.of(_navigationContext!).go(AppRoutePath.weeklyReport.relativePath);
        debugPrint('주간 리포트 페이지로 이동 완료');
      } catch (e) {
        debugPrint('네비게이션 실패: $e');
        // 글로벌 네비게이터 키를 사용한 대체 방법
        _navigateUsingGlobalKey(data);
      }
    } else {
      debugPrint('네비게이션 컨텍스트가 없습니다');
      // 글로벌 네비게이터 키를 사용한 대체 방법
      _navigateUsingGlobalKey(data);
    }
  }

  /// 글로벌 네비게이터 키를 사용한 네비게이션 (대체 방법)
  void _navigateUsingGlobalKey(Map<String, dynamic> data) {
    // 이 방법은 main.dart에서 글로벌 네비게이터 키를 설정한 경우에만 작동합니다
    // 현재는 로그만 남기고 추후 필요시 구현할 수 있습니다
    debugPrint('글로벌 네비게이터를 통한 이동 시도: $data');
  }

  /// 현재 사용자의 FCM 토큰을 Firestore에서 제거
  Future<void> removeFCMToken() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'fcmToken': FieldValue.delete(),
          'fcmTokenUpdatedAt': FieldValue.delete(),
          'platform': FieldValue.delete(),
        });
        debugPrint('FCM 토큰이 Firestore에서 제거되었습니다.');
      }
      _fcmToken = null;
    } catch (e) {
      debugPrint('FCM 토큰 제거 실패: $e');
    }
  }

  /// 알림 권한 상태 확인
  Future<AuthorizationStatus> getNotificationPermissionStatus() async {
    NotificationSettings settings = await _messaging.getNotificationSettings();
    return settings.authorizationStatus;
  }

  /// 알림 권한이 허용되었는지 확인
  Future<bool> isNotificationPermissionGranted() async {
    AuthorizationStatus status = await getNotificationPermissionStatus();
    return status == AuthorizationStatus.authorized || status == AuthorizationStatus.provisional;
  }

  /// 네비게이션 컨텍스트 설정
  void setNavigationContext(BuildContext context) {
    _navigationContext = context;
  }

  /// 포그라운드 메시지 콜백 설정
  void setForegroundMessageCallback(Function(RemoteMessage) callback) {
    _onForegroundMessage = callback;
  }

  /// 알림 히스토리에 추가
  void _addToNotificationHistory(RemoteMessage message, {bool tapped = false}) {
    try {
      final payload = NotificationPayload(
        type: message.data['type'] ?? 'unknown',
        title: message.notification?.title ?? '',
        body: message.notification?.body ?? '',
        receivedAt: DateTime.now(),
        tapped: tapped,
        data: {...message.data, 'messageId': message.messageId ?? '', 'tapped': tapped},
      );

      _notificationHistory.insert(0, payload);

      // 히스토리 크기 제한 (최대 50개)
      if (_notificationHistory.length > 50) {
        _notificationHistory.removeRange(50, _notificationHistory.length);
      }

      debugPrint('알림 히스토리에 추가: ${payload.type} - ${payload.title}');
    } catch (e) {
      debugPrint('알림 히스토리 추가 실패: $e');
    }
  }

  /// 알림 히스토리 가져오기
  List<NotificationPayload> getNotificationHistory() {
    return List.unmodifiable(_notificationHistory);
  }

  /// 알림 히스토리 지우기
  void clearNotificationHistory() {
    _notificationHistory.clear();
    debugPrint('알림 히스토리가 지워졌습니다');
  }

  /// 특정 타입의 알림 개수 가져오기
  int getNotificationCountByType(String type) {
    return _notificationHistory.where((notification) => notification.type == type).length;
  }

  /// 읽지 않은 알림 개수 가져오기 (탭하지 않은 알림)
  int getUnreadNotificationCount() {
    return _notificationHistory.where((notification) => notification.data['tapped'] != true).length;
  }
}

/// 백그라운드 메시지 핸들러 (톱레벨 함수여야 함)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('백그라운드에서 메시지 수신: ${message.messageId}');
  debugPrint('제목: ${message.notification?.title}');
  debugPrint('내용: ${message.notification?.body}');
  debugPrint('데이터: ${message.data}');
}
