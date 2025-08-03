import 'dart:async';
import 'dart:html' as html;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// 웹앱용 알림 서비스
class WebNotificationService {
  static final WebNotificationService _instance = WebNotificationService._internal();
  factory WebNotificationService() => _instance;
  WebNotificationService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription<QuerySnapshot>? _notificationSubscription;

  // 알림 상태 관리
  final ValueNotifier<List<WebNotification>> _notifications = ValueNotifier([]);
  final ValueNotifier<int> _unreadCount = ValueNotifier(0);

  // 현재 사용자 UUID
  String? _currentUserUuid;

  // 알림 설정
  bool _inAppNotificationsEnabled = true;
  bool _toastNotificationsEnabled = true;
  bool _soundNotificationsEnabled = false;

  // Getters
  ValueNotifier<List<WebNotification>> get notifications => _notifications;
  ValueNotifier<int> get unreadCount => _unreadCount;
  bool get inAppNotificationsEnabled => _inAppNotificationsEnabled;
  bool get toastNotificationsEnabled => _toastNotificationsEnabled;
  bool get soundNotificationsEnabled => _soundNotificationsEnabled;

  /// 알림 서비스 초기화
  Future<void> initialize(String userUuid) async {
    _currentUserUuid = userUuid;

    // 사용자 알림 설정 로드
    await _loadNotificationSettings();

    // 브라우저 알림 권한 요청 (선택사항)
    await _requestBrowserNotificationPermission();

    // 실시간 알림 리스너 시작
    _startNotificationListener();

    // 기존 알림 로드
    await _loadExistingNotifications();
  }

  /// 알림 서비스 정리
  void dispose() {
    _notificationSubscription?.cancel();
    _notifications.dispose();
    _unreadCount.dispose();
  }

  /// 브라우저 알림 권한 요청
  Future<void> _requestBrowserNotificationPermission() async {
    if (kIsWeb) {
      try {
        final permission = await html.Notification.requestPermission();
        debugPrint('Browser notification permission: $permission');
      } catch (e) {
        debugPrint('Failed to request browser notification permission: $e');
      }
    }
  }

  /// 사용자 알림 설정 로드
  Future<void> _loadNotificationSettings() async {
    if (_currentUserUuid == null) return;

    try {
      final userDoc = await _firestore.collection('users').doc(_currentUserUuid).get();
      final settings = userDoc.data()?['webNotificationSettings'] as Map<String, dynamic>?;

      if (settings != null) {
        _inAppNotificationsEnabled = settings['inAppNotifications'] ?? true;
        _toastNotificationsEnabled = settings['toastNotifications'] ?? true;
        _soundNotificationsEnabled = settings['soundNotifications'] ?? false;
      }
    } catch (e) {
      debugPrint('Failed to load notification settings: $e');
    }
  }

  /// 실시간 알림 리스너 시작
  void _startNotificationListener() {
    if (_currentUserUuid == null) return;

    _notificationSubscription = _firestore
        .collection('webNotifications')
        .where('userUuid', isEqualTo: _currentUserUuid)
        .where('dismissed', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen(
          _handleNotificationSnapshot,
          onError: (error) {
            debugPrint('Notification listener error: $error');
          },
        );
  }

  /// 알림 스냅샷 처리
  void _handleNotificationSnapshot(QuerySnapshot snapshot) {
    final notifications = snapshot.docs.map((doc) => WebNotification.fromFirestore(doc)).toList();

    // 새로운 알림 확인
    final newNotifications =
        notifications
            .where((notification) => !_notifications.value.any((existing) => existing.id == notification.id))
            .toList();

    // 새 알림이 있으면 표시
    for (final notification in newNotifications) {
      _showNotification(notification);
    }

    // 알림 목록 업데이트
    _notifications.value = notifications;
    _unreadCount.value = notifications.where((n) => !n.read).length;
  }

  /// 기존 알림 로드
  Future<void> _loadExistingNotifications() async {
    if (_currentUserUuid == null) return;

    try {
      final snapshot =
          await _firestore
              .collection('webNotifications')
              .where('userUuid', isEqualTo: _currentUserUuid)
              .where('dismissed', isEqualTo: false)
              .orderBy('createdAt', descending: true)
              .limit(50)
              .get();

      final notifications = snapshot.docs.map((doc) => WebNotification.fromFirestore(doc)).toList();

      _notifications.value = notifications;
      _unreadCount.value = notifications.where((n) => !n.read).length;
    } catch (e) {
      debugPrint('Failed to load existing notifications: $e');
    }
  }

  /// 알림 표시
  void _showNotification(WebNotification notification) {
    // 브라우저 알림 표시
    _showBrowserNotification(notification);

    // 사운드 재생
    if (_soundNotificationsEnabled) {
      _playNotificationSound();
    }
  }

  /// 브라우저 알림 표시
  void _showBrowserNotification(WebNotification notification) {
    if (!kIsWeb) return;

    try {
      if (html.Notification.permission == 'granted') {
        final browserNotification = html.Notification(
          notification.title,
          body: notification.message,
          icon: '/icons/Icon-192.png',
          tag: notification.id,
        );

        // 알림 클릭 시 처리
        browserNotification.onClick.listen((_) {
          // 알림을 읽음으로 표시
          markAsRead(notification.id);

          // 브라우저 알림 닫기
          browserNotification.close();
        });

        // 5초 후 자동 닫기
        Timer(const Duration(seconds: 5), () {
          browserNotification.close();
        });
      }
    } catch (e) {
      debugPrint('Failed to show browser notification: $e');
    }
  }

  /// 알림 사운드 재생
  void _playNotificationSound() {
    if (!kIsWeb) return;

    try {
      final audio = html.AudioElement('/sounds/notification.mp3');
      audio.play();
    } catch (e) {
      debugPrint('Failed to play notification sound: $e');
    }
  }

  /// 알림을 읽음으로 표시
  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore.collection('webNotifications').doc(notificationId).update({'read': true});
    } catch (e) {
      debugPrint('Failed to mark notification as read: $e');
    }
  }

  /// 알림 삭제
  Future<void> dismissNotification(String notificationId) async {
    try {
      await _firestore.collection('webNotifications').doc(notificationId).update({'dismissed': true});
    } catch (e) {
      debugPrint('Failed to dismiss notification: $e');
    }
  }

  /// 모든 알림 삭제
  Future<void> dismissAllNotifications() async {
    if (_currentUserUuid == null) return;

    try {
      final batch = _firestore.batch();

      for (final notification in _notifications.value) {
        final docRef = _firestore.collection('webNotifications').doc(notification.id);
        batch.update(docRef, {'dismissed': true});
      }

      await batch.commit();
    } catch (e) {
      debugPrint('Failed to dismiss all notifications: $e');
    }
  }

  /// 알림 설정 업데이트
  Future<void> updateNotificationSettings({
    bool? inAppNotifications,
    bool? toastNotifications,
    bool? soundNotifications,
  }) async {
    if (_currentUserUuid == null) return;

    try {
      final updates = <String, dynamic>{};

      if (inAppNotifications != null) {
        _inAppNotificationsEnabled = inAppNotifications;
        updates['webNotificationSettings.inAppNotifications'] = inAppNotifications;
      }

      if (toastNotifications != null) {
        _toastNotificationsEnabled = toastNotifications;
        updates['webNotificationSettings.toastNotifications'] = toastNotifications;
      }

      if (soundNotifications != null) {
        _soundNotificationsEnabled = soundNotifications;
        updates['webNotificationSettings.soundNotifications'] = soundNotifications;
      }

      if (updates.isNotEmpty) {
        await _firestore.collection('users').doc(_currentUserUuid).update(updates);
      }
    } catch (e) {
      debugPrint('Failed to update notification settings: $e');
    }
  }

  /// 새 알림 생성 (테스트용)
  Future<void> createTestNotification() async {
    if (_currentUserUuid == null) return;

    await _firestore.collection('webNotifications').add({
      'userUuid': _currentUserUuid,
      'type': 'test',
      'title': '테스트 알림',
      'message': '이것은 테스트 알림입니다.',
      'createdAt': FieldValue.serverTimestamp(),
      'read': false,
      'dismissed': false,
    });
  }
}

/// 웹 알림 모델
class WebNotification {
  final String id;
  final String userUuid;
  final String type;
  final String title;
  final String message;
  final DateTime createdAt;
  final bool read;
  final bool dismissed;
  final String? reportId;
  final Map<String, dynamic>? metadata;

  WebNotification({
    required this.id,
    required this.userUuid,
    required this.type,
    required this.title,
    required this.message,
    required this.createdAt,
    required this.read,
    required this.dismissed,
    this.reportId,
    this.metadata,
  });

  factory WebNotification.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return WebNotification(
      id: doc.id,
      userUuid: data['userUuid'] ?? '',
      type: data['type'] ?? '',
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      read: data['read'] ?? false,
      dismissed: data['dismissed'] ?? false,
      reportId: data['reportId'],
      metadata: data['metadata'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userUuid': userUuid,
      'type': type,
      'title': title,
      'message': message,
      'createdAt': Timestamp.fromDate(createdAt),
      'read': read,
      'dismissed': dismissed,
      'reportId': reportId,
      'metadata': metadata,
    };
  }
}
