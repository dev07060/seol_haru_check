import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:seol_haru_check/generated/assets.dart';
import 'package:seol_haru_check/shared/sp_svg.dart';
import 'package:seol_haru_check/shared/themes/f_colors.dart';
import 'package:seol_haru_check/shared/themes/f_font_styles.dart';

/// AppBar 위젯
/// [FAppBar.back]을 사용하면 뒤로가기 버튼이 추가됩니다.
/// [FAppBar.close]를 사용하면 닫기 버튼이 추가됩니다.
class FAppBar extends AppBar {
  FAppBar(
    BuildContext context, {
    super.key,
    String? title,
    Widget? titleWidget,
    super.leading,
    List<Widget>? actions,
    bool? centerTitle,
    Color? backgroundColor,
    Color? surfaceTintColor,
    SystemUiOverlayStyle? systemUiOverlayStyle,
  }) : super(
         toolbarHeight: 48,
         backgroundColor: backgroundColor ?? Colors.transparent,
         surfaceTintColor: surfaceTintColor ?? Colors.transparent,
         title:
             title == null
                 ? titleWidget
                 : Text(title, style: FTextStyles.bodyXL.copyWith(color: FColors.of(context).labelNormal)),
         centerTitle: centerTitle ?? true,
         actions: actions == null ? null : [...actions, const Gap(20)],
         systemOverlayStyle:
             systemUiOverlayStyle ??
             SystemUiOverlayStyle(
               statusBarBrightness: Brightness.light,
               statusBarIconBrightness: Brightness.dark,
               statusBarColor: Colors.transparent,
               systemNavigationBarIconBrightness: Brightness.dark,
               systemNavigationBarColor: FColors.of(context).backgroundNormalN,
             ),
       );

  /// 뒤로가기 버튼이 추가된 AppBar
  factory FAppBar.back(
    BuildContext context, {
    String? title,
    Widget? titleWidget,
    Function()? onBack,
    List<Widget>? actions,
    Color? backgroundColor,
    Color? surfaceTintColor,
  }) => FAppBar(
    context,
    title: title,
    titleWidget: titleWidget,
    backgroundColor: backgroundColor,
    surfaceTintColor: surfaceTintColor,
    leading: GestureDetector(
      onTap: () => onBack == null ? Navigator.pop(context) : onBack(),
      child: SizedBox(width: 24, height: 24, child: Center(child: Icon(Icons.arrow_back_ios_new))),
    ),
    actions: actions,
  );

  /// 닫기 버튼이 추가된 AppBar
  factory FAppBar.close(
    BuildContext context, {
    String? title,
    Widget? titleWidget,
    List<Widget>? actions,
    GestureTapCallback? pop,
    Color? backgroundColor,
    Color? surfaceTintColor,
  }) => FAppBar(
    context,
    title: title,
    titleWidget: titleWidget,
    backgroundColor: backgroundColor,
    surfaceTintColor: surfaceTintColor,
    leading: GestureDetector(
      onTap: pop ?? () => Navigator.pop(context),
      child: SizedBox(
        width: 24,
        height: 24,
        child: Center(child: SPSvg.asset(Assets.iconsCloseNormalThin, color: FColors.of(context).labelNormal)),
      ),
    ),
    actions: actions,
  );
}
