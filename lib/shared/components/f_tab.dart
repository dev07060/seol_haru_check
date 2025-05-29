import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:seol_haru_check/shared/sp_svg.dart';
import 'package:seol_haru_check/shared/themes/f_colors.dart';
import 'package:seol_haru_check/shared/themes/f_font_styles.dart';
import 'package:seol_haru_check/shared/themes/f_font_weight.dart';

/// 디자인 시스템 Tab
/// [currentIndex] 현재 선택된 탭 인덱스
/// [tabList] 탭 리스트
/// [onChangedTap] 탭 변경 콜백
/// 텍스트 너비를 구하기 위해 StatefulWidget을 사용했지만 상태관리는 콜백 함수를 이용해 부모 위젯에서 처리
abstract class FTab extends StatefulWidget {
  const FTab({super.key, required this.currentIndex, required this.tabList, required this.onChangedTap});

  final int currentIndex;
  final List tabList;
  final Function(int index) onChangedTap;

  static const Duration _duration = Duration(milliseconds: 150);
  static const Curve _curve = Curves.decelerate;

  @override
  State<FTab> createState() => _FTabState();

  factory FTab.defaultTab({
    required int currentIndex,
    required List<String> tabList,
    required Function(int index) onChangedTap,
  }) => _DefaultTab(currentIndex: currentIndex, tabList: tabList, onChangedTap: onChangedTap);

  factory FTab.fixedTab({
    required int currentIndex,
    required List<String> tabList,
    required Function(int index) onChangedTap,
  }) => _FixedTab(currentIndex: currentIndex, tabList: tabList, onChangedTap: onChangedTap);

  factory FTab.capsuleTab({
    required int currentIndex,
    required List<String> tabList,
    required CapsuleTapSize size,
    required Function(int index) onChangedTap,
  }) => _CapsuleTab(currentIndex: currentIndex, tabList: tabList, capsuleTapSize: size, onChangedTap: onChangedTap);

  factory FTab.switchTab({
    required int currentIndex,
    required List<SwitchTabValue> tabList,
    SwitchTabType switchTabType = SwitchTabType.round,
    required Function(int index) onChangedTap,
  }) {
    assert(tabList.length >= 2 && tabList.length <= 4, 'Tab list must contain 2 to 4 items');
    return _SwitchTab(
      currentIndex: currentIndex,
      tabList: tabList,
      switchTabType: switchTabType,
      onChangedTap: onChangedTap,
    );
  }
}

class _FTabState extends State<FTab> {
  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

/// Default
class _DefaultTab extends StatefulWidget implements FTab {
  const _DefaultTab({required this.currentIndex, required this.tabList, required this.onChangedTap});

  @override
  final int currentIndex;
  @override
  final List<String> tabList;
  @override
  final Function(int index) onChangedTap;

  @override
  _DefaultTabState createState() => _DefaultTabState();
}

class _DefaultTabState extends State<_DefaultTab> {
  /// 텍스트 키 리스트 (텍스트의 너비를 구하기 위함)
  final List<GlobalKey> _textKeys = [];

  /// 텍스트 너비 리스트
  final List<double> _textWidths = [];

  /// 현재 인덱스에 해당하는 텍스트 너비
  double get _currentTextWidth => _textWidths[widget.currentIndex];
  final ScrollController _scrollController = ScrollController();

  /// 기본 왼쪽 패딩
  final double _defaultLeftPadding = 20;

  /// 탭 오른쪽 패딩
  final double _tabRightPadding = 16;

  /// 현재 인덱스 이전까지의 텍스트 너비 합 + 패딩
  double get _barLeftPadding {
    double padding = _defaultLeftPadding;
    for (int i = 0; i < widget.currentIndex; i++) {
      padding += _textWidths[i] + _tabRightPadding;
    }
    return padding;
  }

  @override
  void initState() {
    super.initState();
    _setTabList(); // 키와 너비를 초기화
    _updateTextWidths(); // 너비 업데이트
  }

  @override
  void didUpdateWidget(covariant _DefaultTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateTextWidths(); // 너비 업데이트
  }

  /// 키와 너비 초기화
  void _setTabList() {
    for (int i = 0; i < widget.tabList.length; i++) {
      _textKeys.add(GlobalKey());
      _textWidths.add(0);
    }
  }

  /// 너비 업데이트
  void _updateTextWidths() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (int i = 0; i < _textKeys.length; i++) {
        final key = _textKeys[i];
        final RenderBox renderBox = key.currentContext?.findRenderObject() as RenderBox;
        _textWidths[i] = renderBox.size.width;
      }
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            controller: _scrollController,
            child: Padding(
              padding: EdgeInsets.only(left: _defaultLeftPadding),
              child: Row(
                children: List.generate(widget.tabList.length, (index) {
                  final String text = widget.tabList[index];
                  final GlobalKey key = _textKeys[index];
                  final bool isSelected = widget.currentIndex == index;

                  return Padding(
                    padding: EdgeInsets.only(right: _tabRightPadding),
                    child: GestureDetector(
                      onTap: () => widget.onChangedTap(index),
                      child: Text(
                        text,
                        key: key,
                        style: FTextStyles.bodyXL.copyWith(
                          color: isSelected ? FColors.of(context).labelNormal : FColors.of(context).labelAlternative,
                          fontWeight: isSelected ? FFontWeight.bold : FFontWeight.regular,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
          const Gap(8),
          Row(
            children: [
              AnimatedContainer(duration: FTab._duration, curve: FTab._curve, width: _barLeftPadding),
              Container(width: _currentTextWidth, height: 1, color: FColors.of(context).lineStrong),
            ],
          ),
          Divider(thickness: 1, height: 1, color: FColors.of(context).lineAssistive),
        ],
      ),
    );
  }
}

/// Fixed
class _FixedTab extends StatefulWidget implements FTab {
  const _FixedTab({required this.currentIndex, required this.tabList, required this.onChangedTap});

  @override
  final int currentIndex;
  @override
  final List<String> tabList;
  @override
  final Function(int index) onChangedTap;

  @override
  State<_FixedTab> createState() => _FixedTabState();
}

class _FixedTabState extends State<_FixedTab> {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double tapWidth = constraints.maxWidth / widget.tabList.length; // t
        double barLeftPadding = tapWidth * widget.currentIndex;

        return SizedBox(
          height: 48,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Row(
                children: List.generate(widget.tabList.length, (index) {
                  final String text = widget.tabList[index];
                  final bool isSelected = widget.currentIndex == index;

                  return Expanded(
                    child: GestureDetector(
                      onTap: () => widget.onChangedTap(index),
                      behavior: HitTestBehavior.opaque,
                      child: Center(
                        child: Text(
                          text,
                          style: FTextStyles.bodyXL.copyWith(
                            color: isSelected ? FColors.of(context).labelNormal : FColors.of(context).labelAlternative,
                            fontWeight: isSelected ? FFontWeight.bold : FFontWeight.regular,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const Gap(8),
              Row(
                children: [
                  AnimatedContainer(duration: FTab._duration, curve: FTab._curve, width: barLeftPadding),
                  Container(width: tapWidth, height: 2, color: FColors.of(context).lineStrong),
                ],
              ),
              Divider(thickness: 1, height: 1, color: FColors.of(context).lineAssistive),
            ],
          ),
        );
      },
    );
  }
}

/// Capsule
class _CapsuleTab extends StatefulWidget implements FTab {
  const _CapsuleTab({
    required this.currentIndex,
    required this.tabList,
    required this.capsuleTapSize,
    required this.onChangedTap,
  });

  @override
  final int currentIndex;
  @override
  final List<String> tabList;
  final CapsuleTapSize capsuleTapSize;
  @override
  final Function(int index) onChangedTap;

  @override
  State<_CapsuleTab> createState() => _CapsuleTabState();
}

class _CapsuleTabState extends State<_CapsuleTab> {
  late final TextStyle _textStyle;
  late final double _verticalPadding;
  late final double _unitHeight;

  @override
  void initState() {
    super.initState();
    _setTextStyle(); // 텍스트 스타일 설정
  }

  /// 텍스트 스타일 설정
  void _setTextStyle() {
    switch (widget.capsuleTapSize) {
      case CapsuleTapSize.small:
        _textStyle = FTextStyles.bodyL;
        _verticalPadding = 6;
        _unitHeight = 36;
        break;
      case CapsuleTapSize.normal:
        _textStyle = FTextStyles.bodyXL;
        _verticalPadding = 4;
        _unitHeight = 40;
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _unitHeight + _verticalPadding * 2,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (int i = 0; i < widget.tabList.length; i++) ...[
            GestureDetector(
              onTap: () => widget.onChangedTap(i),
              child: Container(
                height: _unitHeight,
                margin: EdgeInsets.symmetric(vertical: _verticalPadding),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: widget.currentIndex == i ? FColors.of(context).solidStrong : Colors.transparent,
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(
                    color:
                        widget.currentIndex == i
                            ? FColors.of(context).solidStrong
                            : FColors.of(context).lineAlternative,
                  ),
                ),
                child: Text(
                  widget.tabList[i],
                  style: _textStyle.copyWith(
                    color:
                        widget.currentIndex == i ? FColors.of(context).inverseNormal : FColors.of(context).labelNeutral,
                  ),
                ),
              ),
            ),
            if (i != widget.tabList.length - 1) const Gap(8),
          ],
        ],
      ),
    );
  }
}

/// Switch
class _SwitchTab extends StatefulWidget implements FTab {
  const _SwitchTab({
    required this.currentIndex,
    required this.tabList,
    required this.onChangedTap,
    required this.switchTabType,
  });

  @override
  final int currentIndex;
  @override
  final List<SwitchTabValue> tabList;
  @override
  final Function(int index) onChangedTap;
  final SwitchTabType switchTabType;

  @override
  State<_SwitchTab> createState() => _SwitchTabState();
}

class _SwitchTabState extends State<_SwitchTab> {
  late final double _borderRadius;
  late final EdgeInsetsGeometry _padding;
  late final EdgeInsetsGeometry _tabPadding;

  @override
  void initState() {
    _init();
    super.initState();
  }

  double get _iconSize {
    return widget.tabList.length >= 4 ? 16.0 : 20.0;
  }

  void _init() {
    switch (widget.switchTabType) {
      case SwitchTabType.round:
        _borderRadius = 999;
        _padding = const EdgeInsets.all(4);
        _tabPadding = const EdgeInsets.symmetric(horizontal: 20, vertical: 12);
        break;
      case SwitchTabType.square:
        _borderRadius = 4;
        _padding = const EdgeInsets.all(2);
        _tabPadding =
            widget.tabList.any((element) => element.prefix != null)
                ? const EdgeInsets.symmetric(horizontal: 20, vertical: 10)
                : const EdgeInsets.symmetric(horizontal: 20, vertical: 12);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: _padding,
      decoration: BoxDecoration(
        color: FColors.of(context).solidAssistive,
        borderRadius: BorderRadius.circular(_borderRadius),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double tapWidth = constraints.maxWidth / widget.tabList.length;
          final double leftPadding = tapWidth * widget.currentIndex;

          return Stack(
            alignment: Alignment.center,
            children: [
              Row(
                children: [
                  AnimatedContainer(duration: FTab._duration, curve: FTab._curve, width: leftPadding),
                  Container(
                    width: tapWidth,
                    height: 44,
                    decoration: BoxDecoration(
                      color: FColors.of(context).backgroundNormalN,
                      borderRadius: BorderRadius.circular(_borderRadius),
                      border: Border.all(color: FColors.of(context).lineSubtle),
                    ),
                    alignment: Alignment.center,
                  ),
                ],
              ),
              Row(
                children: List.generate(widget.tabList.length, (index) {
                  final SwitchTabValue tabValue = widget.tabList[index];

                  final bool isSelected = widget.currentIndex == index;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => widget.onChangedTap(index),
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: _tabPadding,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (tabValue.prefix != null) ...[
                              SPSvg.asset(
                                tabValue.prefix!,
                                width: _iconSize,
                                height: _iconSize,
                                color:
                                    isSelected ? FColors.of(context).labelNormal : FColors.of(context).labelAlternative,
                              ),
                              const Gap(4),
                            ],
                            Text(
                              tabValue.text,
                              style: FTextStyles.bodyL.copyWith(
                                color:
                                    isSelected ? FColors.of(context).labelNormal : FColors.of(context).labelAlternative,
                                fontWeight: isSelected ? FFontWeight.medium : FFontWeight.regular,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          );
        },
      ),
    );
  }
}

enum CapsuleTapSize { small, normal }

enum SwitchTabType { round, square }

class SwitchTabValue {
  SwitchTabValue({this.prefix, required this.text});

  final String? prefix;
  final String text;
}
