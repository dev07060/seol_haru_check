import 'package:flutter/material.dart';

class FResponsive extends StatelessWidget {
  final Widget mobile;
  final Widget tablet;

  const FResponsive({
    super.key,
    required this.mobile,
    required this.tablet,
  });

  static const double tabletWidth = 600;

  static bool isMobile(BuildContext context) => MediaQuery.of(context).size.width < tabletWidth;

  static bool isTablet(BuildContext context) => MediaQuery.of(context).size.width >= tabletWidth;

  @override
  Widget build(BuildContext context) {
    final double maxWidth = MediaQuery.of(context).size.width;

    if (maxWidth >= tabletWidth) {
      return tablet;
    } else {
      return mobile;
    }
  }
}
