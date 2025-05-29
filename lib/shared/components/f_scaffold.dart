import 'package:flutter/material.dart';
import 'package:seol_haru_check/shared/themes/f_colors.dart';

class FScaffold extends StatelessWidget {
  const FScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.bottomNavigationBar,
    this.bottomSheet,
    this.canPop = true,
    this.onPopInvoked,
    this.backgroundColor,
    this.resizeToAvoidBottomInset,
    this.floatingActionButton,
  });

  final Widget body;
  final AppBar? appBar;
  final Widget? bottomNavigationBar;
  final Widget? bottomSheet;
  final bool canPop;
  final Function(bool, Object?)? onPopInvoked;
  final Color? backgroundColor;
  final bool? resizeToAvoidBottomInset;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: canPop,
      onPopInvokedWithResult: onPopInvoked,
      child: MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling), //사용자 스케일팩터 무시
        child: Scaffold(
          backgroundColor: backgroundColor ?? FColors.of(context).backgroundNormalN,
          appBar: appBar,
          bottomSheet: bottomSheet,
          bottomNavigationBar: bottomNavigationBar,
          resizeToAvoidBottomInset: resizeToAvoidBottomInset,
          body: GestureDetector(
            onTap: FocusScope.of(context).unfocus, // 빈 영역 터치 시 포커스 해제
            behavior: HitTestBehavior.opaque,
            child: SafeArea(child: body),
          ),
          floatingActionButton: floatingActionButton,
        ),
      ),
    );
  }
}
