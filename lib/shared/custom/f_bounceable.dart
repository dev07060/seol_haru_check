import 'package:flutter/material.dart';
import 'package:flutter_bounceable/flutter_bounceable.dart';

class FBounceable extends Bounceable {
  FBounceable({
    super.key,
    required super.child,
    VoidCallback? onTap,
    super.scaleFactor = 0.8,
  }) : super(
          onTap: () {},
          onTapUp: (TapUpDetails _) => onTap?.call(),
        );
}
