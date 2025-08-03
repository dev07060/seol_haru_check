import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

/// 웹앱용 인앱 알림 배너 위젯
class WebNotificationBanner extends StatefulWidget {
  final String title;
  final String message;
  final String? reportId;
  final VoidCallback? onDismiss;
  final VoidCallback? onTap;

  const WebNotificationBanner({
    super.key,
    required this.title,
    required this.message,
    this.reportId,
    this.onDismiss,
    this.onTap,
  });

  @override
  State<WebNotificationBanner> createState() => _WebNotificationBannerState();
}

class _WebNotificationBannerState extends State<WebNotificationBanner> with SingleTickerProviderStateMixin {
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
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOut));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeIn));

    _animationController.forward();

    // Auto-dismiss after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        _dismiss();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _dismiss() {
    _animationController.reverse().then((_) {
      if (mounted) {
        widget.onDismiss?.call();
      }
    });
  }

  void _handleTap() {
    if (widget.onTap != null) {
      widget.onTap!();
    } else if (widget.reportId != null) {
      // Navigate to weekly report page
      context.go('/weekly-report/${widget.reportId}');
    }
    _dismiss();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Material(
            elevation: 8,
            child: Container(
              key: const Key('in_app_notification_banner'),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Theme.of(context).primaryColor, Theme.of(context).primaryColor.withValues(alpha: .8)],
                ),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: .1), blurRadius: 8, offset: const Offset(0, 2)),
                ],
              ),
              child: SafeArea(
                child: Semantics(
                  label: '${widget.title}: ${widget.message}',
                  hint: '탭하여 확인하거나 ESC 키로 닫기',
                  button: true,
                  child: Focus(
                    autofocus: true,
                    onKeyEvent: (node, event) {
                      if (event is KeyDownEvent) {
                        if (event.logicalKey == LogicalKeyboardKey.escape) {
                          _dismiss();
                          return KeyEventResult.handled;
                        } else if (event.logicalKey == LogicalKeyboardKey.enter ||
                            event.logicalKey == LogicalKeyboardKey.space) {
                          _handleTap();
                          return KeyEventResult.handled;
                        }
                      }
                      return KeyEventResult.ignored;
                    },
                    child: InkWell(
                      onTap: _handleTap,
                      borderRadius: BorderRadius.circular(8),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: .2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.notifications_active, color: Colors.white, size: 24),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  widget.title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  widget.message,
                                  style: TextStyle(color: Colors.white.withValues(alpha: .9), fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: _dismiss,
                            icon: const Icon(Icons.close, color: Colors.white),
                            tooltip: '알림 닫기',
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 웹앱용 토스트 알림 위젯
class WebToastNotification extends StatefulWidget {
  final String message;
  final Duration duration;
  final VoidCallback? onDismiss;

  const WebToastNotification({
    super.key,
    required this.message,
    this.duration = const Duration(seconds: 3),
    this.onDismiss,
  });

  @override
  State<WebToastNotification> createState() => _WebToastNotificationState();
}

class _WebToastNotificationState extends State<WebToastNotification> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(duration: const Duration(milliseconds: 250), vsync: this);

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_animationController);

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOut));

    _animationController.forward();

    // Auto-dismiss after specified duration
    Future.delayed(widget.duration, () {
      if (mounted) {
        _dismiss();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _dismiss() {
    _animationController.reverse().then((_) {
      if (mounted) {
        widget.onDismiss?.call();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 24,
      right: 24,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Material(
            elevation: 6,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              key: const Key('toast_notification'),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              constraints: const BoxConstraints(maxWidth: 400),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.inverseSurface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, color: Theme.of(context).colorScheme.onInverseSurface, size: 20),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      widget.message,
                      style: TextStyle(color: Theme.of(context).colorScheme.onInverseSurface, fontSize: 14),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: _dismiss,
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(Icons.close, color: Theme.of(context).colorScheme.onInverseSurface, size: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 웹앱용 알림 표시기 위젯 (헤더나 네비게이션에 사용)
class WebNotificationIndicator extends StatelessWidget {
  final int notificationCount;
  final VoidCallback? onTap;

  const WebNotificationIndicator({super.key, required this.notificationCount, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: const Key('notification_indicator'),
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(8),
        child: Stack(
          children: [
            const Icon(Icons.notifications_outlined, size: 24),
            if (notificationCount > 0)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  key: const Key('notification_badge'),
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.error,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  child: Text(
                    notificationCount > 99 ? '99+' : notificationCount.toString(),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onError,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
