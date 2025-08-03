import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:seol_haru_check/shared/themes/f_font_styles.dart';
import 'package:seol_haru_check/widgets/report/charts/base_chart_widget.dart';
import 'package:seol_haru_check/widgets/report/charts/chart_error_handler.dart';

/// Hierarchical category chart widget that displays nested donut chart
/// showing main types and subcategories with interactive drill-down functionality
class HierarchicalCategoryChart extends BaseChartWidget {
  final Map<String, Map<String, int>> hierarchicalData; // main type -> subcategories
  final Map<String, String> categoryEmojis;
  final Map<String, Color> categoryColors;
  final bool showSubcategoryDetails;
  final double maxRadius;
  final double minRadius;
  final bool enableDrillDown;
  final Function(String mainCategory, String? subcategory)? onCategoryTap;
  final bool showCenterInfo;
  final bool enableZoomPan;

  const HierarchicalCategoryChart({
    super.key,
    required this.hierarchicalData,
    required this.categoryEmojis,
    required this.categoryColors,
    this.showSubcategoryDetails = true,
    this.maxRadius = 120.0,
    this.minRadius = 60.0,
    this.enableDrillDown = true,
    this.onCategoryTap,
    this.showCenterInfo = true,
    this.enableZoomPan = false,
    super.theme,
    super.animationConfig,
    super.height,
    super.padding,
    super.title,
    super.showTitle,
  });

  @override
  State<HierarchicalCategoryChart> createState() => _HierarchicalCategoryChartState();
}

class _HierarchicalCategoryChartState extends BaseChartState<HierarchicalCategoryChart> {
  int _touchedMainIndex = -1;
  int _touchedSubIndex = -1;
  String? _selectedMainCategory;
  bool _isDrilledDown = false;
  double _zoomLevel = 1.0;
  Offset _panOffset = Offset.zero;

  // Animation controllers for smooth transitions
  late AnimationController _drillDownController;
  late AnimationController _zoomController;
  late Animation<double> _drillDownAnimation;
  late Animation<double> _zoomAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  @override
  void dispose() {
    _drillDownController.dispose();
    _zoomController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _drillDownController = AnimationController(duration: const Duration(milliseconds: 800), vsync: this);

    _zoomController = AnimationController(duration: const Duration(milliseconds: 600), vsync: this);

    _drillDownAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _drillDownController, curve: Curves.easeInOutCubic));

    _zoomAnimation = Tween<double>(
      begin: 1.0,
      end: 1.5,
    ).animate(CurvedAnimation(parent: _zoomController, curve: Curves.easeInOut));
  }

  @override
  Widget buildChart(BuildContext context) {
    if (!validateData()) {
      return ChartErrorHandler.createEmptyPlaceholder(message: '계층 데이터가 없습니다', icon: Icons.donut_large);
    }

    return AnimatedBuilder(
      animation: Listenable.merge([animationController, _drillDownController, _zoomController]),
      builder: (context, child) {
        return GestureDetector(
          onTap: _isDrilledDown ? _handleBackTap : null,
          onScaleUpdate: widget.enableZoomPan ? _handleScaleUpdate : null,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Transform.scale(
                scale: _zoomLevel * (widget.enableZoomPan ? _zoomAnimation.value : 1.0),
                child: Transform.translate(offset: _panOffset, child: _buildHierarchicalChart()),
              ),
              if (widget.showCenterInfo) _buildCenterInfo(),
              if (_isDrilledDown) _buildBackButton(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHierarchicalChart() {
    if (_isDrilledDown && _selectedMainCategory != null) {
      return _buildDrilledDownChart();
    } else {
      return _buildMainChart();
    }
  }

  Widget _buildMainChart() {
    final totalCount = _getTotalCount();

    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer ring - main categories
        PieChart(
          PieChartData(
            pieTouchData: PieTouchData(enabled: widget.enableDrillDown, touchCallback: _handleMainCategoryTouch),
            borderData: FlBorderData(show: false),
            sectionsSpace: 3,
            centerSpaceRadius: widget.maxRadius * 0.5,
            sections: _buildMainCategorySections(totalCount),
          ),
        ),
        // Inner ring - subcategories preview
        if (widget.showSubcategoryDetails)
          PieChart(
            PieChartData(
              pieTouchData: PieTouchData(enabled: false),
              borderData: FlBorderData(show: false),
              sectionsSpace: 1,
              centerSpaceRadius: widget.minRadius * 0.8,
              sections: _buildSubcategoryPreviewSections(totalCount),
            ),
          ),
      ],
    );
  }

  Widget _buildDrilledDownChart() {
    if (_selectedMainCategory == null) return Container();

    final subcategoryData = widget.hierarchicalData[_selectedMainCategory]!;
    final totalCount = subcategoryData.values.fold<int>(0, (sum, count) => sum + count);

    return PieChart(
      PieChartData(
        pieTouchData: PieTouchData(enabled: true, touchCallback: _handleSubcategoryTouch),
        borderData: FlBorderData(show: false),
        sectionsSpace: 2,
        centerSpaceRadius: widget.minRadius,
        sections: _buildDrilledDownSections(subcategoryData, totalCount),
      ),
    );
  }

  List<PieChartSectionData> _buildMainCategorySections(int totalCount) {
    final mainCategories = widget.hierarchicalData.keys.toList();

    return mainCategories.asMap().entries.map((entry) {
      final index = entry.key;
      final mainCategory = entry.value;
      final categoryCount = widget.hierarchicalData[mainCategory]!.values.fold<int>(0, (sum, count) => sum + count);
      final percentage = totalCount > 0 ? categoryCount / totalCount : 0.0;
      final isTouched = index == _touchedMainIndex;

      final animationValue = _getStaggeredAnimationValue(index, mainCategories.length);
      final color = widget.categoryColors[mainCategory] ?? theme.getCategoryColor(index);

      return PieChartSectionData(
        color: color,
        value: categoryCount.toDouble() * animationValue,
        title: '${(percentage * 100).toStringAsFixed(0)}%',
        radius: (widget.maxRadius + (isTouched ? 15 : 0)) * animationValue,
        titleStyle: theme.labelStyle.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: isTouched ? 14 : 12,
        ),
        titlePositionPercentageOffset: 0.7,
        badgeWidget: isTouched ? _buildMainCategoryBadge(mainCategory, categoryCount) : null,
        badgePositionPercentageOffset: 1.4,
      );
    }).toList();
  }

  List<PieChartSectionData> _buildSubcategoryPreviewSections(int totalCount) {
    final List<PieChartSectionData> sections = [];
    int colorIndex = 0;

    for (final mainCategory in widget.hierarchicalData.keys) {
      final subcategories = widget.hierarchicalData[mainCategory]!;
      final mainColor = widget.categoryColors[mainCategory] ?? theme.getCategoryColor(colorIndex);

      for (final subcategoryEntry in subcategories.entries) {
        final subcategoryName = subcategoryEntry.key;
        final subcategoryCount = subcategoryEntry.value;

        final animationValue = animationController.value;
        final subcategoryColor = _getSubcategoryColor(mainColor, subcategories.keys.toList().indexOf(subcategoryName));

        sections.add(
          PieChartSectionData(
            color: subcategoryColor,
            value: subcategoryCount.toDouble() * animationValue,
            title: '',
            radius: widget.minRadius * animationValue,
            titleStyle: const TextStyle(fontSize: 0),
          ),
        );
      }
      colorIndex++;
    }

    return sections;
  }

  List<PieChartSectionData> _buildDrilledDownSections(Map<String, int> subcategoryData, int totalCount) {
    return subcategoryData.entries.toList().asMap().entries.map((entry) {
      final index = entry.key;
      final subcategoryEntry = entry.value;
      final subcategoryName = subcategoryEntry.key;
      final subcategoryCount = subcategoryEntry.value;
      final percentage = totalCount > 0 ? subcategoryCount / totalCount : 0.0;
      final isTouched = index == _touchedSubIndex;

      final animationValue = _drillDownAnimation.value;
      final mainColor = widget.categoryColors[_selectedMainCategory!] ?? theme.primaryColor;
      final subcategoryColor = _getSubcategoryColor(mainColor, index);

      return PieChartSectionData(
        color: subcategoryColor,
        value: subcategoryCount.toDouble() * animationValue,
        title: '${(percentage * 100).toStringAsFixed(0)}%',
        radius: (widget.maxRadius * 0.8 + (isTouched ? 10 : 0)) * animationValue,
        titleStyle: theme.labelStyle.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: isTouched ? 14 : 12,
        ),
        titlePositionPercentageOffset: 0.6,
        badgeWidget: isTouched ? _buildSubcategoryBadge(subcategoryName, subcategoryCount) : null,
        badgePositionPercentageOffset: 1.3,
      );
    }).toList();
  }

  Widget _buildMainCategoryBadge(String mainCategory, int count) {
    final emoji = widget.categoryEmojis[mainCategory] ?? '📊';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 4),
          Text(
            '$count',
            style: FTextStyles.body3_13.copyWith(
              color: widget.categoryColors[mainCategory] ?? theme.primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubcategoryBadge(String subcategoryName, int count) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Text(
        '$subcategoryName: $count',
        style: FTextStyles.body3_13.copyWith(color: theme.textColor, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildCenterInfo() {
    if (_isDrilledDown && _selectedMainCategory != null) {
      final subcategoryData = widget.hierarchicalData[_selectedMainCategory]!;
      final totalCount = subcategoryData.values.fold<int>(0, (sum, count) => sum + count);
      final emoji = widget.categoryEmojis[_selectedMainCategory!] ?? '📊';

      return AnimatedOpacity(
        opacity: _drillDownAnimation.value,
        duration: const Duration(milliseconds: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(height: 4),
            Text(
              '$totalCount',
              style: theme.titleStyle.copyWith(fontSize: 24, fontWeight: FontWeight.bold, color: theme.primaryColor),
            ),
            Text(_selectedMainCategory!, style: theme.labelStyle.copyWith(fontSize: 12), textAlign: TextAlign.center),
          ],
        ),
      );
    } else {
      final totalCount = _getTotalCount();
      final mainCategoryCount = widget.hierarchicalData.length;

      return AnimatedOpacity(
        opacity: animationController.value,
        duration: animationConfig.duration,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$totalCount',
              style: theme.titleStyle.copyWith(fontSize: 28, fontWeight: FontWeight.bold, color: theme.primaryColor),
            ),
            Text('총 활동', style: theme.labelStyle.copyWith(fontSize: 12)),
            const SizedBox(height: 4),
            Text(
              '$mainCategoryCount개 카테고리',
              style: theme.labelStyle.copyWith(fontSize: 10, color: theme.textColor.withValues(alpha: 0.7)),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildBackButton() {
    return Positioned(
      top: 16,
      right: 16,
      child: AnimatedOpacity(
        opacity: _drillDownAnimation.value,
        duration: const Duration(milliseconds: 400),
        child: GestureDetector(
          onTap: _handleBackTap,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.backgroundColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: theme.borderColor),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4, offset: const Offset(0, 2)),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.arrow_back, size: 16, color: theme.textColor),
                const SizedBox(width: 4),
                Text('뒤로', style: theme.labelStyle.copyWith(fontSize: 12)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleMainCategoryTouch(FlTouchEvent event, PieTouchResponse? pieTouchResponse) {
    if (!widget.enableDrillDown) return;

    setState(() {
      if (!event.isInterestedForInteractions || pieTouchResponse == null || pieTouchResponse.touchedSection == null) {
        _touchedMainIndex = -1;
        return;
      }
      _touchedMainIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
    });

    // Handle drill-down on tap
    if (event is FlTapUpEvent && _touchedMainIndex >= 0) {
      final mainCategories = widget.hierarchicalData.keys.toList();
      if (_touchedMainIndex < mainCategories.length) {
        final selectedCategory = mainCategories[_touchedMainIndex];
        _drillDown(selectedCategory);

        if (widget.onCategoryTap != null) {
          widget.onCategoryTap!(selectedCategory, null);
        }
      }
    }
  }

  void _handleSubcategoryTouch(FlTouchEvent event, PieTouchResponse? pieTouchResponse) {
    setState(() {
      if (!event.isInterestedForInteractions || pieTouchResponse == null || pieTouchResponse.touchedSection == null) {
        _touchedSubIndex = -1;
        return;
      }
      _touchedSubIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
    });

    // Handle subcategory tap
    if (event is FlTapUpEvent && _touchedSubIndex >= 0 && _selectedMainCategory != null) {
      final subcategories = widget.hierarchicalData[_selectedMainCategory!]!.keys.toList();
      if (_touchedSubIndex < subcategories.length) {
        final selectedSubcategory = subcategories[_touchedSubIndex];

        if (widget.onCategoryTap != null) {
          widget.onCategoryTap!(_selectedMainCategory!, selectedSubcategory);
        }
      }
    }
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    if (!widget.enableZoomPan) return;

    setState(() {
      // Handle zoom
      _zoomLevel = (details.scale * _zoomLevel).clamp(0.5, 3.0);
      // Handle pan
      _panOffset += details.focalPointDelta;
    });

    _zoomController.animateTo(_zoomLevel / 3.0);
  }

  void _drillDown(String mainCategory) {
    setState(() {
      _selectedMainCategory = mainCategory;
      _isDrilledDown = true;
      _touchedMainIndex = -1;
      _touchedSubIndex = -1;
    });

    _drillDownController.forward();
  }

  void _handleBackTap() {
    _drillDownController.reverse().then((_) {
      setState(() {
        _selectedMainCategory = null;
        _isDrilledDown = false;
        _touchedMainIndex = -1;
        _touchedSubIndex = -1;
      });
    });
  }

  Color _getSubcategoryColor(Color mainColor, int index) {
    // Create variations of the main color for subcategories
    final hsl = HSLColor.fromColor(mainColor);
    final lightness = (hsl.lightness + (index * 0.1) - 0.2).clamp(0.2, 0.8);
    final saturation = (hsl.saturation - (index * 0.05)).clamp(0.3, 1.0);

    return hsl.withLightness(lightness).withSaturation(saturation).toColor();
  }

  double _getStaggeredAnimationValue(int index, int totalItems) {
    if (!animationConfig.enableStagger) return animationController.value;

    final staggerProgress = (animationController.value * totalItems - index).clamp(0.0, 1.0);
    return animationConfig.curve.transform(staggerProgress);
  }

  int _getTotalCount() {
    return widget.hierarchicalData.values
        .expand((subcategories) => subcategories.values)
        .fold<int>(0, (sum, count) => sum + count);
  }

  @override
  Widget buildFallback(BuildContext context) {
    if (!validateData()) {
      return ChartErrorHandler.createEmptyPlaceholder(message: '계층 데이터가 없습니다', icon: Icons.donut_large);
    }

    // Create text-based fallback
    final dataMap = <String, String>{};
    for (final mainEntry in widget.hierarchicalData.entries) {
      final mainCategory = mainEntry.key;
      final subcategories = mainEntry.value;
      final totalCount = subcategories.values.fold<int>(0, (sum, count) => sum + count);
      final emoji = widget.categoryEmojis[mainCategory] ?? '📊';

      dataMap['$emoji $mainCategory'] = '$totalCount개';

      for (final subEntry in subcategories.entries) {
        dataMap['  └ ${subEntry.key}'] = '${subEntry.value}개';
      }
    }

    return ChartErrorHandler.createTextFallback(dataMap, title: '계층 카테고리 분포');
  }

  @override
  bool validateData() {
    return widget.hierarchicalData.isNotEmpty &&
        widget.hierarchicalData.values.any((subcategories) => subcategories.values.any((count) => count > 0));
  }

  @override
  Map<String, dynamic> getChartData() {
    final totalCount = _getTotalCount();
    final mainCategoryCount = widget.hierarchicalData.length;
    final subcategoryCount = widget.hierarchicalData.values
        .map((subcategories) => subcategories.length)
        .fold<int>(0, (sum, count) => sum + count);

    return {
      'totalCount': totalCount,
      'mainCategories': mainCategoryCount,
      'subcategories': subcategoryCount,
      'isDrilledDown': _isDrilledDown,
      'selectedMainCategory': _selectedMainCategory,
      'hasValidData': validateData(),
    };
  }
}
