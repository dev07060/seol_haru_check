import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:seol_haru_check/generated/assets.dart';
import 'package:seol_haru_check/shared/components/f_solid_button.dart';
import 'package:seol_haru_check/shared/sp_svg.dart';
import 'package:seol_haru_check/shared/themes/f_colors.dart';
import 'package:seol_haru_check/shared/themes/f_font_styles.dart';

/// 새 프로젝트 적용시 item의 vertical padding을 12로 변경
class FBottomSheet extends StatefulWidget {
  const FBottomSheet({
    super.key,
    required this.item,
    this.title,
    this.actionButton = false,
    this.onActionButtonPressed,
    this.actionButtonDisabled = false,
    this.actionButtonLabel,
    this.showIcon = false,
    this.iconPath,
    this.onIconPressed,
    this.onClose,
  });
  final Widget item;
  final String? title;
  final bool? actionButton;
  final bool actionButtonDisabled;
  final Function? onActionButtonPressed;
  final String? actionButtonLabel;
  final bool showIcon;
  final String? iconPath;
  final Function? onIconPressed;
  final Function? onClose;

  @override
  State<FBottomSheet> createState() => _FBottomSheetState();

  Future show(context) {
    return showModalBottomSheet(
      isDismissible: true,
      backgroundColor: Colors.transparent,
      context: context,
      isScrollControlled: true,
      enableDrag: false,
      useSafeArea: true,
      builder: (BuildContext context) {
        return this;
      },
    );
  }

  factory FBottomSheet.withHandler({
    Key? key,
    required Widget Function(bool isExpanded) contentBuilder,
    Widget? Function(BuildContext)? bottomBuilder,
    double initialHeight = 0.5,
    bool enableDrag = true,
    bool useRootNavigator = false,
  }) {
    return FBottomSheet(
      key: key,
      item: _FExpandableSheetContent(
        contentBuilder: contentBuilder,
        bottomBuilder: bottomBuilder,
        initialHeight: initialHeight,
        enableDrag: enableDrag,
        useRootNavigator: useRootNavigator,
      ),
    );
  }

  static Future<void> showWithHandler(
    BuildContext context, {
    required Widget Function(bool isExpanded) contentBuilder,
    Widget? Function(BuildContext)? bottomBuilder,
    double initialHeight = 0.5,
    bool enableDrag = true,
    bool useRootNavigator = false,
  }) {
    return showModalBottomSheet(
      isDismissible: true,
      context: context,
      isScrollControlled: true,
      enableDrag: enableDrag,
      useRootNavigator: useRootNavigator,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return FBottomSheet.withHandler(
          contentBuilder: contentBuilder,
          bottomBuilder: bottomBuilder,
          initialHeight: initialHeight,
          enableDrag: enableDrag,
          useRootNavigator: useRootNavigator,
        );
      },
    ).then((_) => FocusManager.instance.primaryFocus?.unfocus());
  }
}

class _FBottomSheetState extends State<FBottomSheet> {
  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final bottomPadding = MediaQuery.of(context).padding.bottom; // 홈 인디케이터 높이

    return IntrinsicHeight(
      child: Container(
        decoration: BoxDecoration(
          color: FColors.of(context).backgroundElevatedNormal,
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(8.0), topRight: Radius.circular(8.0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (widget.title != null) ...[
              const Gap(4),
              ListTile(
                minTileHeight: 48.0,
                leading: GestureDetector(
                  onTap: () {
                    if (widget.onClose != null) {
                      widget.onClose!();
                    } else {
                      Navigator.pop(context);
                    }
                  },
                  child: SPSvg.asset(
                    Assets.iconsNormalCloseNormalThin,
                    color: FColors.of(context).labelStrong,
                    width: 24,
                    height: 24,
                  ),
                ),
                titleAlignment: ListTileTitleAlignment.center,
                title: Center(
                  child: Text(
                    widget.title!,
                    style: FTextStyles.bodyXL.m.copyWith(color: FColors.of(context).labelNormal),
                  ),
                ),
                trailing:
                    widget.showIcon
                        ? GestureDetector(
                          onTap: () {
                            if (widget.onIconPressed != null) {
                              widget.onIconPressed!();
                              Navigator.pop(context);
                            }
                          },
                          child: SPSvg.asset(
                            widget.iconPath!,
                            width: 24,
                            height: 24,
                            color: FColors.of(context).labelNormal,
                          ),
                        )
                        : const SizedBox(width: 24),
              ),
            ],
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.only(left: 20.0, right: 20.0, bottom: keyboardHeight),
                  child: Padding(padding: const EdgeInsets.symmetric(vertical: 12.0), child: widget.item),
                ),
              ),
            ),
            if (widget.actionButton != null && widget.actionButton == true) ...[
              const Gap(4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: FSolidButton.primary(
                  disabled: widget.actionButtonDisabled,
                  text: widget.actionButtonLabel ?? '',
                  onPressed: () {
                    if (widget.onActionButtonPressed != null) {
                      widget.onActionButtonPressed!();
                      Navigator.pop(context);
                    }
                  },
                  size: FSolidButtonSize.large,
                ),
              ),
              const Gap(12),
            ],
            Gap(bottomPadding),
          ],
        ),
      ),
    );
  }
}

class _FExpandableSheetContent extends StatefulWidget {
  final Widget Function(bool isExpanded) contentBuilder;
  final Widget? Function(BuildContext)? bottomBuilder;
  final double initialHeight;
  final bool enableDrag;
  final bool useRootNavigator;

  const _FExpandableSheetContent({
    required this.contentBuilder,
    this.bottomBuilder,
    this.initialHeight = 0.5,
    this.enableDrag = true,
    this.useRootNavigator = false,
  });

  @override
  _FExpandableSheetContentState createState() => _FExpandableSheetContentState();
}

class _FExpandableSheetContentState extends State<_FExpandableSheetContent> {
  final double _maxHeight = 0.9;
  late double _currentHeight = widget.initialHeight;
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: FocusScope.of(context).unfocus,
      onVerticalDragUpdate: (details) {
        if (widget.enableDrag) {
          setState(() {
            _currentHeight -= details.primaryDelta! / MediaQuery.of(context).size.height;
            _currentHeight = _currentHeight.clamp(0.1, _maxHeight);
          });
        }
      },
      onVerticalDragEnd: (details) {
        if (widget.enableDrag) {
          if (_currentHeight <= 0.2) {
            Navigator.of(context).pop();
          } else if (_currentHeight < widget.initialHeight) {
            setState(() {
              _currentHeight = widget.initialHeight;
              _isExpanded = false;
            });
          } else if (_currentHeight > widget.initialHeight) {
            setState(() {
              _currentHeight = _maxHeight;
              _isExpanded = true;
            });
          }
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: MediaQuery.of(context).size.height * _currentHeight,
        decoration: BoxDecoration(
          color: FColors.of(context).backgroundElevatedNormal,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16.0)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            if (widget.enableDrag) ...[_buildDragHandler(), const Gap(8)],
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.only(bottom: keyboardHeight),
                  child: widget.contentBuilder(_isExpanded),
                ),
              ),
            ),
            if (widget.bottomBuilder != null) ...[widget.bottomBuilder!(context)!],
            const Gap(12),
          ],
        ),
      ),
    );
  }

  Widget _buildDragHandler() {
    return Container(
      width: 32.0,
      height: 4.0,
      decoration: BoxDecoration(color: FColors.of(context).solidAlternative, borderRadius: BorderRadius.circular(8.0)),
    );
  }
}
