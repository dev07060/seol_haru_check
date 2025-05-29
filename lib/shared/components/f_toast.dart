import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart' as fluttertoast;
import 'package:seol_haru_check/shared/components/f_responsive.dart';
import 'package:seol_haru_check/shared/sp_colors.dart';
import 'package:seol_haru_check/shared/sp_svg.dart';
import 'package:seol_haru_check/shared/themes/f_font_styles.dart';

class FToast {
  String message;
  String? prefixPath;
  final ftoast = fluttertoast.FToast();

  FToast({required this.message, this.prefixPath});

  void show(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        ftoast.init(context);
        ftoast.showToast(
          child: toast(context),
          gravity: fluttertoast.ToastGravity.BOTTOM,
          toastDuration: const Duration(seconds: 3),
          positionedToastBuilder: (context, child, _) {
            final bool isTablet = FResponsive.isTablet(context);
            return Positioned(
              bottom: MediaQuery.of(context).viewInsets.bottom + (isTablet ? 24 : 20),
              left: 20.0,
              right: 20.0,
              child: child,
            );
          },
        );
      } catch (e) {
        log(e.toString());
      }
    });
  }

  Widget toast(context) {
    final bool isTablet = FResponsive.isTablet(context);

    return IntrinsicWidth(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0),
        margin: const EdgeInsets.symmetric(horizontal: 20.0),
        constraints: BoxConstraints(maxWidth: isTablet ? 458 : 350),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4.0),
          color: SPColors.black.withValues(alpha: .9),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (prefixPath != null)
              Padding(
                padding: const EdgeInsets.only(right: 6.0),
                child: SPSvg.asset(prefixPath!, width: 20, color: SPColors.gray200),
              ),
            Expanded(
              child: Text(
                message,
                style: FTextStyles.bodyL.r.copyWith(color: SPColors.gray200),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
