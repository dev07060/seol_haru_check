import 'package:flutter/material.dart';
import 'package:seol_haru_check/shared/themes/f_colors.dart';

class FeedPageIndicator extends StatelessWidget {
  final int count;
  final int currentPage; // 현재 페이지를 나타내는 인덱스

  const FeedPageIndicator({super.key, required this.count, required this.currentPage});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          count,
          (index) => Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: 8,
            height: 8,
            decoration: BoxDecoration(shape: BoxShape.circle, color: FColors.of(context).labelAssistive),
          ),
        ),
      ),
    );
  }
}
