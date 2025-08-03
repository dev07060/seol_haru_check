import 'package:flutter/material.dart';
import 'package:seol_haru_check/models/chart_config_models.dart';
import 'package:seol_haru_check/services/chart_foundation_service.dart';
import 'package:seol_haru_check/widgets/report/charts/chart_error_handler.dart';

/// Base chart widget that provides common functionality for all charts
abstract class BaseChartWidget extends StatefulWidget {
  final ChartTheme? theme;
  final AnimationConfig? animationConfig;
  final double? height;
  final EdgeInsets? padding;
  final String? title;
  final bool showTitle;

  const BaseChartWidget({
    super.key,
    this.theme,
    this.animationConfig,
    this.height,
    this.padding,
    this.title,
    this.showTitle = false,
  });
}

/// Base state for chart widgets with error handling and animation support
abstract class BaseChartState<T extends BaseChartWidget> extends State<T>
    with TickerProviderStateMixin, ChartErrorHandlingMixin {
  late ChartTheme _theme;
  late AnimationConfig _animationConfig;
  late AnimationController _animationController;
  late ChartFoundationService _chartService;

  @override
  void initState() {
    super.initState();
    _chartService = ChartFoundationService.instance;
    _initializeThemeAndAnimation();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateTheme();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _initializeThemeAndAnimation() {
    _theme = widget.theme ?? ChartTheme.light(); // Use light theme as default
    _animationConfig = widget.animationConfig ?? const AnimationConfig();
    _animationController = _chartService.createAnimationController(this, _animationConfig);

    // Start animation
    if (_animationConfig.duration > Duration.zero) {
      _animationController.forward();
    }
  }

  void _updateTheme() {
    if (widget.theme == null) {
      setState(() {
        _theme = ChartTheme.fromContext(context);
      });
    }
  }

  /// Get current theme
  ChartTheme get theme => _theme;

  /// Get current animation config
  AnimationConfig get animationConfig => _animationConfig;

  /// Get animation controller
  AnimationController get animationController => _animationController;

  /// Get chart service
  ChartFoundationService get chartService => _chartService;

  /// Build the actual chart content - to be implemented by subclasses
  Widget buildChart(BuildContext context);

  /// Build fallback widget when chart fails - to be implemented by subclasses
  Widget buildFallback(BuildContext context);

  /// Validate chart data - to be implemented by subclasses
  bool validateData();

  /// Get chart data for validation - to be implemented by subclasses
  Map<String, dynamic> getChartData();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      padding: widget.padding ?? const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.showTitle && widget.title != null) ...[
            Text(widget.title!, style: _theme.titleStyle),
            const SizedBox(height: 12),
          ],
          Expanded(
            child: buildWithErrorHandling(
              () {
                if (!validateData()) {
                  return ChartErrorHandler.createEmptyPlaceholder(message: '표시할 데이터가 없습니다');
                }
                return buildChart(context);
              },
              buildFallback(context),
              onRetry: () {
                setState(() {
                  _animationController.reset();
                  _animationController.forward();
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Simple example chart widget to demonstrate the base functionality
class ExampleChartWidget extends BaseChartWidget {
  final Map<String, double> data;

  const ExampleChartWidget({
    super.key,
    required this.data,
    super.theme,
    super.animationConfig,
    super.height,
    super.padding,
    super.title,
    super.showTitle,
  });

  @override
  State<ExampleChartWidget> createState() => _ExampleChartWidgetState();
}

class _ExampleChartWidgetState extends BaseChartState<ExampleChartWidget> {
  @override
  Widget buildChart(BuildContext context) {
    return AnimatedBuilder(
      animation: animationController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            color: theme.backgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.borderColor),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.bar_chart, size: 48 * animationController.value, color: theme.primaryColor),
                const SizedBox(height: 16),
                Text('Chart Foundation Ready!', style: theme.titleStyle),
                const SizedBox(height: 8),
                Text('Data points: ${widget.data.length}', style: theme.labelStyle),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget buildFallback(BuildContext context) {
    return ChartErrorHandler.createTextFallback(
      widget.data.map((key, value) => MapEntry(key, value.toString())),
      title: 'Chart Data',
    );
  }

  @override
  bool validateData() {
    return widget.data.isNotEmpty;
  }

  @override
  Map<String, dynamic> getChartData() {
    return widget.data.map((key, value) => MapEntry(key, value));
  }
}
