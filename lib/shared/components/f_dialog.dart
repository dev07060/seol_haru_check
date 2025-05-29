import 'dart:async';

import 'package:flutter/material.dart';
import 'package:seol_haru_check/shared/themes/f_colors.dart';
import 'package:seol_haru_check/shared/themes/f_font_styles.dart';

class FDialog extends StatelessWidget {
  const FDialog({super.key, this.title, this.description, required this.buttons, this.barrierDismissible = true});

  // 내부 플래그
  static bool _isActionInProgress = false;

  final String? title;
  final String? description;
  final List<Widget> buttons;
  final bool barrierDismissible;

  // 1button 팩토리 메서드
  factory FDialog.oneButton({
    String? title,
    String? description,
    required String confirmText,
    required FutureOr<void> Function() onConfirm,
    bool barrierDismissible = true,
  }) {
    return FDialog(
      title: title,
      description: description,
      barrierDismissible: barrierDismissible,
      buttons: [_button(text: confirmText, onTap: onConfirm, isAlternative: false)],
    );
  }

  // 2button 팩토리 메서드
  factory FDialog.twoButton(
    BuildContext context, {
    String? title,
    String? description,
    String? confirmText,
    required FutureOr<void> Function() onConfirm,
    String? cancelText,
    FutureOr<void> Function()? onCancel,
    bool barrierDismissible = true,
  }) {
    return FDialog(
      title: title,
      description: description,
      barrierDismissible: barrierDismissible,
      buttons: [
        _button(text: cancelText ?? '취소', onTap: onCancel ?? () {}, isAlternative: true),
        _button(text: confirmText ?? '확인', onTap: onConfirm, isAlternative: false),
      ],
    );
  }

  // 3button 팩토리 메서드
  factory FDialog.threeButton(
    BuildContext context, {
    String? title,
    required String description,
    required String firstText,
    required FutureOr<void> Function() onFirstPressed,
    required String secondText,
    required FutureOr<void> Function() onSecondPressed,
    String? cancelText,
    required FutureOr<void> Function() onCancel,
    bool barrierDismissible = true,
  }) {
    return FDialog(
      title: title,
      description: description,
      barrierDismissible: barrierDismissible,
      buttons: [
        _button(text: firstText, onTap: onFirstPressed, isAlternative: false),
        _button(text: secondText, onTap: onSecondPressed, isAlternative: false),
        _button(text: cancelText ?? '취소', onTap: onCancel, isAlternative: true),
      ],
    );
  }

  Future<T?> show<T extends Object?>(final BuildContext context) async => await showGeneralDialog(
    context: context,
    barrierDismissible: barrierDismissible,
    useRootNavigator: false,
    routeSettings: const RouteSettings(name: 'f_dialog'),
    barrierLabel: '',
    pageBuilder: (
      final BuildContext context,
      final Animation<double> animation,
      final Animation<double> secondaryAnimation,
    ) {
      return this;
    },
  );

  static Future<void> _handleAction(FutureOr<void> Function() action) async {
    if (_isActionInProgress) return;
    _isActionInProgress = true;
    try {
      await action();
    } finally {
      _isActionInProgress = false;
    }
  }

  @override
  Widget build(final BuildContext context) => Material(
    type: MaterialType.transparency,
    child: Center(
      child: Container(
        width: 280,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6.0),
          color: FColors.of(context).backgroundElevatedNormal,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
              child: Column(
                children: [
                  if (title != null) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        title!,
                        maxLines: 1,
                        textAlign: TextAlign.center,
                        style: FTextStyles.bodyL.m.copyWith(color: FColors.of(context).labelNormal),
                      ),
                    ),
                  ],
                  if (description != null)
                    Text(
                      description!,
                      textAlign: TextAlign.center,
                      style: FTextStyles.bodyL.r.copyWith(color: FColors.of(context).labelAlternative),
                    ),
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: FColors.of(context).lineAssistive, width: 1)),
              ),
              child: _buildButtonLayout(context),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _buildButtonLayout(BuildContext context) {
    if (buttons.length == 2) {
      return Row(
        children: [
          Expanded(child: buttons[0]),
          Container(width: 1, height: 44, color: FColors.of(context).lineAssistive),
          Expanded(child: buttons[1]),
        ],
      );
    } else {
      return Column(
        children: List.generate(buttons.length, (index) {
          if (index > 0) {
            return Column(
              children: [Divider(height: 1, thickness: 1, color: FColors.of(context).lineAssistive), buttons[index]],
            );
          }
          return buttons[index];
        }),
      );
    }
  }

  static Widget _button({required String text, required FutureOr<void> Function() onTap, required bool isAlternative}) {
    return Builder(
      builder: (BuildContext context) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            Navigator.of(context).pop();
            _handleAction(onTap);
          },
          child: SizedBox(
            height: 44,
            width: double.infinity,
            child: Center(
              child: Text(
                text,
                style: FTextStyles.bodyL.b.copyWith(
                  color: isAlternative ? FColors.of(context).labelAlternative : FColors.of(context).labelNormal,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
