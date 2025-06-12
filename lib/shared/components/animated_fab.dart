import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

class AnimatedFAB extends StatelessWidget {
  const AnimatedFAB({super.key, required this.fem, required this.animationController, required this.radius});

  final double fem;
  final AnimationController animationController;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 30 * fem,
      bottom: 30 * fem,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: animationController,
            builder: (context, child) {
              return Transform.scale(scale: lerpDouble(1.0, 4.0, animationController.value), child: child);
            },
            child: Container(
              width: 60 * fem,
              height: 60 * fem,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: [Colors.blue, Colors.teal]),
              ),
            ),
          ),
          AnimatedBuilder(
            animation: animationController,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(
                  animationController.value * radius * cos(pi + pi / 4),
                  animationController.value * radius * sin(pi + pi / 4),
                ),
                child: child,
              );
            },
            child: const Icon(Icons.edit_notifications_rounded, color: Colors.white, size: 26),
          ),
          AnimatedBuilder(
            animation: animationController,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(
                  animationController.value * radius * cos(pi + pi / 2),
                  animationController.value * radius * sin(pi + pi / 2),
                ),
                child: child,
              );
            },
            child: const Icon(Icons.folder, color: Colors.white, size: 24),
          ),
          Positioned(
            child: AnimatedBuilder(
              animation: animationController,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(
                    animationController.value * radius * cos(pi),
                    animationController.value * radius * sin(pi),
                  ),
                  child: child,
                );
              },
              child: const Icon(Icons.account_circle, color: Colors.white, size: 26),
            ),
          ),
        ],
      ),
    );
  }
}

Positioned actionFAB(double fem, AnimationController animationController, ValueNotifier<bool> isexpanded) {
  return Positioned(
    right: 30 * fem,
    bottom: 30 * fem,
    child: GestureDetector(
      onTap: () {
        animationController.animateWith(
          SpringSimulation(
            const SpringDescription(mass: 1, damping: 10, stiffness: 100),
            isexpanded.value ? 1.0 : 0.0,
            isexpanded.value ? 0.0 : 1.0,
            0.001,
          ),
        );
        isexpanded.value = !isexpanded.value;
      },
      child: ValueListenableBuilder(
        valueListenable: isexpanded,
        builder: (context, isexpand, child) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 60,
            height: 60,
            transformAlignment: Alignment.center,
            transform: Matrix4.identity()..rotateZ(isexpand ? pi / 4 : 0.0),
            decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.blue.shade700),
            child: const Icon(Icons.add, color: Colors.white),
          );
        },
      ),
    ),
  );
}
