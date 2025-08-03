import 'package:flutter/material.dart';
import 'package:seol_haru_check/models/category_visualization_models.dart';
import 'package:seol_haru_check/shared/sp_colors.dart';
import 'package:seol_haru_check/shared/themes/f_font_styles.dart';

/// Widget for displaying subcategory breakdown within a category
class SubcategoryBreakdownSection extends StatefulWidget {
  final CategoryVisualizationData categoryData;
  final bool showAnimations;

  const SubcategoryBreakdownSection({super.key, required this.categoryData, this.showAnimations = true});

  @override
  State<SubcategoryBreakdownSection> createState() => _SubcategoryBreakdownSectionState();
}

class _SubcategoryBreakdownSectionState extends State<SubcategoryBreakdownSection> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late List<Animation<double>> _itemAnimations;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(duration: const Duration(milliseconds: 800), vsync: this);

    _itemAnimations = List.generate(
      widget.categoryData.subcategories.length,
      (index) => Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Interval(index * 0.1, (index * 0.1) + 0.6, curve: Curves.easeOutCubic),
        ),
      ),
    );

    if (widget.showAnimations) {
      _animationController.forward();
    } else {
      _animationController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.categoryData.hasSubcategories) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [_buildSectionHeader(), const SizedBox(height: 16), _buildSubcategoryList()],
    );
  }

  Widget _buildSectionHeader() {
    return Row(
      children: [
        Icon(Icons.category, color: widget.categoryData.color, size: 20),
        const SizedBox(width: 8),
        Text(
          '세부 분류',
          style: FTextStyles.body1_16.copyWith(fontWeight: FontWeight.w600, color: widget.categoryData.color),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: widget.categoryData.color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '${widget.categoryData.subcategories.length}개',
            style: FTextStyles.body3_13.copyWith(color: widget.categoryData.color, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _buildSubcategoryList() {
    return Column(
      children:
          widget.categoryData.subcategories.asMap().entries.map((entry) {
            final index = entry.key;
            final subcategory = entry.value;

            return AnimatedBuilder(
              animation: _itemAnimations[index],
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, 20 * (1 - _itemAnimations[index].value)),
                  child: Opacity(
                    opacity: _itemAnimations[index].value,
                    child: _buildSubcategoryItem(subcategory, index),
                  ),
                );
              },
            );
          }).toList(),
    );
  }

  Widget _buildSubcategoryItem(SubcategoryData subcategory, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: widget.categoryData.color.withValues(alpha: 0.2), width: 1),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Emoji or icon
              if (subcategory.emoji != null) ...[
                Text(subcategory.emoji!, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 12),
              ] else ...[
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: widget.categoryData.color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(Icons.label, size: 16, color: widget.categoryData.color),
                ),
                const SizedBox(width: 12),
              ],

              // Name and count
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subcategory.name,
                      style: FTextStyles.body1_16.copyWith(fontWeight: FontWeight.w600, color: SPColors.gray800),
                    ),
                    if (subcategory.description != null) ...[
                      const SizedBox(height: 4),
                      Text(subcategory.description!, style: FTextStyles.body3_13.copyWith(color: SPColors.gray600)),
                    ],
                  ],
                ),
              ),

              // Count and percentage
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: widget.categoryData.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${subcategory.count}회',
                      style: FTextStyles.body2_14.copyWith(
                        fontWeight: FontWeight.bold,
                        color: widget.categoryData.color,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${(subcategory.percentage * 100).toStringAsFixed(1)}%',
                    style: FTextStyles.body3_13.copyWith(color: SPColors.gray600),
                  ),
                ],
              ),
            ],
          ),

          // Progress bar
          const SizedBox(height: 12),
          _buildProgressBar(subcategory),
        ],
      ),
    );
  }

  Widget _buildProgressBar(SubcategoryData subcategory) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('전체 대비', style: FTextStyles.body3_13.copyWith(color: SPColors.gray600)),
            Text(
              '${(subcategory.percentage * 100).toStringAsFixed(1)}%',
              style: FTextStyles.body3_13.copyWith(color: widget.categoryData.color, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: subcategory.percentage,
            backgroundColor: SPColors.gray200,
            valueColor: AlwaysStoppedAnimation<Color>(widget.categoryData.color),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}
