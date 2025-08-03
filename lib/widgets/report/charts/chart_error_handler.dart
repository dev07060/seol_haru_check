import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:seol_haru_check/models/chart_config_models.dart';
import 'package:seol_haru_check/shared/sp_colors.dart';
import 'package:seol_haru_check/shared/themes/f_font_styles.dart';

/// Chart error handler with fallback UI components
class ChartErrorHandler {
  /// Handle chart rendering errors with fallback widget
  static Widget handleChartError(
    BuildContext context,
    Object error,
    Widget fallbackWidget, {
    String? customMessage,
    VoidCallback? onRetry,
  }) {
    log('[ChartError] Chart rendering failed: $error');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SPColors.gray100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SPColors.gray200),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bar_chart_outlined, size: 48, color: SPColors.gray400),
          const SizedBox(height: 8),
          Text(
            customMessage ?? '차트를 불러올 수 없습니다',
            style: FTextStyles.body1_16.copyWith(color: SPColors.gray600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          if (onRetry != null) ...[
            TextButton(
              onPressed: onRetry,
              child: Text('다시 시도', style: FTextStyles.body2_14.copyWith(color: SPColors.reportBlue)),
            ),
            const SizedBox(height: 8),
          ],
          fallbackWidget,
        ],
      ),
    );
  }

  /// Handle specific chart error types
  static Widget handleSpecificError(BuildContext context, ChartError chartError, {VoidCallback? onRetry}) {
    String message;
    IconData icon;

    switch (chartError.type) {
      case ChartErrorType.dataProcessing:
        message = '데이터를 처리하는 중 오류가 발생했습니다';
        icon = Icons.data_usage_outlined;
        break;
      case ChartErrorType.rendering:
        message = '차트를 그리는 중 오류가 발생했습니다';
        icon = Icons.bar_chart_outlined;
        break;
      case ChartErrorType.animation:
        message = '애니메이션 처리 중 오류가 발생했습니다';
        icon = Icons.animation_outlined;
        break;
      case ChartErrorType.interaction:
        message = '차트 상호작용 중 오류가 발생했습니다';
        icon = Icons.touch_app_outlined;
        break;
      case ChartErrorType.export:
        message = '차트 내보내기 중 오류가 발생했습니다';
        icon = Icons.file_download_outlined;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SPColors.gray100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SPColors.gray200),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: SPColors.gray400),
          const SizedBox(height: 8),
          Text(message, style: FTextStyles.body1_16.copyWith(color: SPColors.gray600), textAlign: TextAlign.center),
          if (onRetry != null) ...[
            const SizedBox(height: 12),
            TextButton(
              onPressed: onRetry,
              child: Text('다시 시도', style: FTextStyles.body2_14.copyWith(color: SPColors.reportBlue)),
            ),
          ],
        ],
      ),
    );
  }

  /// Create fallback text display for chart data
  static Widget createTextFallback(Map<String, dynamic> data, {String? title}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SPColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: SPColors.gray300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null) ...[
            Text(title, style: FTextStyles.title4_17.copyWith(color: SPColors.gray800)),
            const SizedBox(height: 8),
          ],
          ...data.entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(entry.key, style: FTextStyles.body2_14.copyWith(color: SPColors.gray700)),
                  Text(
                    entry.value.toString(),
                    style: FTextStyles.body2_14.copyWith(color: SPColors.gray900, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Create loading placeholder for charts
  static Widget createLoadingPlaceholder({double? height, String? message}) {
    return Container(
      height: height ?? 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: SPColors.gray100, borderRadius: BorderRadius.circular(12)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(SPColors.reportGreen),
            ),
          ),
          const SizedBox(height: 12),
          Text(message ?? '차트를 불러오는 중...', style: FTextStyles.body2_14.copyWith(color: SPColors.gray600)),
        ],
      ),
    );
  }

  /// Create empty state placeholder for charts
  static Widget createEmptyPlaceholder({String? message, IconData? icon, VoidCallback? onAction, String? actionText}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: SPColors.gray100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SPColors.gray200),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon ?? Icons.bar_chart_outlined, size: 64, color: SPColors.gray300),
          const SizedBox(height: 16),
          Text(
            message ?? '표시할 데이터가 없습니다',
            style: FTextStyles.body1_16.copyWith(color: SPColors.gray500),
            textAlign: TextAlign.center,
          ),
          if (onAction != null && actionText != null) ...[
            const SizedBox(height: 16),
            TextButton(
              onPressed: onAction,
              child: Text(actionText, style: FTextStyles.body2_14.copyWith(color: SPColors.reportBlue)),
            ),
          ],
        ],
      ),
    );
  }
}

/// Mixin for widgets that need chart error handling
mixin ChartErrorHandlingMixin<T extends StatefulWidget> on State<T> {
  /// Handle errors with automatic fallback
  Widget buildWithErrorHandling(
    Widget Function() builder,
    Widget fallbackWidget, {
    String? errorMessage,
    VoidCallback? onRetry,
  }) {
    try {
      return builder();
    } catch (error, _) {
      log('[ChartErrorHandlingMixin] Error in ${widget.runtimeType}: $error');
      return ChartErrorHandler.handleChartError(
        context,
        error,
        fallbackWidget,
        customMessage: errorMessage,
        onRetry: onRetry,
      );
    }
  }

  /// Handle async operations with error handling
  Widget buildAsyncWithErrorHandling<U>(
    Future<U> future,
    Widget Function(U data) builder,
    Widget fallbackWidget, {
    String? loadingMessage,
    String? errorMessage,
  }) {
    return FutureBuilder<U>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return ChartErrorHandler.createLoadingPlaceholder(message: loadingMessage);
        }

        if (snapshot.hasError) {
          return ChartErrorHandler.handleChartError(
            context,
            snapshot.error!,
            fallbackWidget,
            customMessage: errorMessage,
          );
        }

        if (!snapshot.hasData) {
          return ChartErrorHandler.createEmptyPlaceholder();
        }

        try {
          return builder(snapshot.data as U);
        } catch (error) {
          return ChartErrorHandler.handleChartError(context, error, fallbackWidget, customMessage: errorMessage);
        }
      },
    );
  }
}
