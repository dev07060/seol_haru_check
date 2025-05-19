import 'package:flutter/material.dart';

class FFullScreenLoading extends StatelessWidget {
  const FFullScreenLoading({super.key, this.spinnerColor, this.backgroundColor});

  final Color? spinnerColor;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor ?? Colors.black87.withValues(alpha: 0.2),
      alignment: Alignment.center,
      child: CircularProgressIndicator.adaptive(),
    );
  }
}
