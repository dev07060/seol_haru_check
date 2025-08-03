import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:seol_haru_check/generated/assets.dart';
import 'package:seol_haru_check/providers/feed_provider.dart';
import 'package:seol_haru_check/shared/components/f_solid_button.dart';
import 'package:seol_haru_check/shared/sp_svg.dart';
import 'package:seol_haru_check/shared/themes/f_colors.dart';
import 'package:seol_haru_check/shared/themes/f_font_styles.dart';

class FMonthPicker extends ConsumerStatefulWidget {
  const FMonthPicker({
    super.key,
    required this.focusedDay,
    required this.firstDay,
    required this.lastDay,
    required this.onSelectedMonth,
    required this.onCanceled,
    this.useMultiLanguage = true,
    this.targetUuid, // Add targetUuid parameter
  });

  final DateTime focusedDay;
  final DateTime firstDay;
  final DateTime lastDay;
  final Function(DateTime day) onSelectedMonth;
  final GestureTapCallback onCanceled;
  final bool useMultiLanguage;
  final String? targetUuid; // Add targetUuid field

  @override
  ConsumerState<FMonthPicker> createState() => FMonthPickerState();
}

class FMonthPickerState extends ConsumerState<FMonthPicker> {
  late final PageController _pageController = PageController(
    initialPage: widget.focusedDay.year - widget.firstDay.year,
  );
  late DateTime _selectedDay = widget.focusedDay;
  final Duration duration = const Duration(milliseconds: 300);
  final Curve curve = Curves.ease;

  /// 보여지는 년도
  int get _currentYear {
    try {
      return widget.firstDay.year + _pageController.page!.round();
    } catch (e) {
      return _selectedDay.year;
    }
  }

  @override
  void dispose() {
    super.dispose();

    _pageController.dispose();
  }

  /// 달 선택
  void _onTapMonth(DateTime date) {
    _selectedDay = date;
    setState(() {});
  }

  /// 이전 페이지
  void _onPreviousPage() {
    _pageController.previousPage(duration: duration, curve: curve);
  }

  /// 다음 페이지
  void _onNextPage() {
    _pageController.nextPage(duration: duration, curve: curve);
  }

  /// 페이지 변경
  void onPageChanged(int index) {
    DateTime date = DateTime(_currentYear, _selectedDay.month);

    if (date.isBefore(widget.firstDay)) {
      date = DateTime(date.year, widget.firstDay.month);
    } else if (date.isAfter(widget.lastDay)) {
      date = DateTime(date.year, widget.lastDay.month);
    }

    _selectedDay = date;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _appBar(),
        const Gap(12),
        _yearPicker(),
        const Gap(16),
        _month(),
        const Gap(32),
        FSolidButton.primary(
          text: '확인',
          size: FSolidButtonSize.large,
          onPressed: () => widget.onSelectedMonth(_selectedDay),
        ),
        const Gap(4),
      ],
    );
  }

  Widget _month() {
    return AspectRatio(
      aspectRatio: 1.36,
      child: PageView.builder(
        controller: _pageController,
        itemCount: widget.lastDay.year - widget.firstDay.year + 1,
        onPageChanged: onPageChanged,
        itemBuilder: (context, index) {
          return GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              childAspectRatio: 1,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
            ),
            itemCount: 12,
            itemBuilder: (context, index) {
              final month = index + 1;
              final DateTime dateForThisMonth = DateTime(_currentYear, month);

              // 각 월별 인증 데이터 유무를 watch
              final hasCertificationAsyncValue = ref.watch(
                hasCertificationForMonthProvider((
                  year: _currentYear,
                  month: month,
                  targetUuid: widget.targetUuid,
                )), // Pass targetUuid
              );

              // 기존 비활성화 조건 (날짜 범위)
              final bool isOutOfRange =
                  DateTime(_currentYear, month + 1, 0).isBefore(widget.firstDay) || // 해당 월의 마지막 날이 firstDay 이전인지
                  dateForThisMonth.isAfter(widget.lastDay); // 해당 월의 첫 날이 lastDay 이후인지

              return hasCertificationAsyncValue.when(
                data: (hasCert) {
                  final bool isDisabledByCert = !hasCert; // 인증 없으면 비활성화
                  final bool isDisabled = isOutOfRange || isDisabledByCert;
                  final bool isSelectedMonth = _selectedDay.year == _currentYear && _selectedDay.month == month;

                  return GestureDetector(
                    onTap: isDisabled ? null : () => _onTapMonth(DateTime(_currentYear, month, _selectedDay.day)),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelectedMonth ? FColors.of(context).solidStrong : null,
                        borderRadius: BorderRadius.circular(2),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '$month월',
                        style: FTextStyles.titleS.copyWith(
                          color:
                              isDisabled
                                  ? FColors.of(context).labelAlternative
                                  : isSelectedMonth
                                  ? FColors.of(context).inverseStrong
                                  : FColors.of(context).labelNormal,
                        ),
                      ),
                    ),
                  );
                },
                loading: () => _buildMonthCellLoading(context, month), // 로딩 중 UI
                error: (err, stack) {
                  // 에러 발생 시 로그 및 UI 처리
                  debugPrint('Error loading certification status for month $month/$_currentYear: $err');
                  return _buildMonthCellLoading(context, month, isError: true); // 에러 시 로딩과 유사한 UI
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildMonthCellLoading(BuildContext context, int month, {bool isError = false}) {
    final bool isSelectedMonth = _selectedDay.year == _currentYear && _selectedDay.month == month;
    return Container(
      decoration: BoxDecoration(
        color: isSelectedMonth ? FColors.of(context).solidStrong : null,
        borderRadius: BorderRadius.circular(2),
      ),
      alignment: Alignment.center,
      child: Text(
        '$month월',
        style: FTextStyles.titleS.copyWith(
          color: FColors.of(context).labelAlternative, // 로딩/에러 시 비활성화된 것처럼
        ),
      ),
    );
  }

  Widget _yearPicker() {
    return SizedBox(
      height: 44,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          InkWell(
            onTap: _currentYear <= widget.firstDay.year ? null : _onPreviousPage,
            child: SPSvg.asset(
              Assets.iconsChevronsChevronLeftThick,
              color:
                  _currentYear <= widget.firstDay.year
                      ? FColors.of(context).labelDisable
                      : FColors.of(context).labelAlternative,
              width: 20,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 44),
            child: Text('$_currentYear년', style: FTextStyles.bodyXL.copyWith(color: FColors.of(context).labelNormal)),
          ),
          InkWell(
            onTap: _currentYear >= widget.lastDay.year ? null : _onNextPage,
            child: SPSvg.asset(
              Assets.iconsChevronsChevronRightThick,
              color:
                  _currentYear >= widget.lastDay.year
                      ? FColors.of(context).labelDisable
                      : FColors.of(context).labelAlternative,
              width: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _appBar() {
    return SizedBox(
      height: 48,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 0,
            child: InkWell(
              onTap: widget.onCanceled,
              child: SPSvg.asset(Assets.iconsNormalCloseNormalThin, width: 24, color: FColors.of(context).labelNormal),
            ),
          ),
          Text('월 선택', style: FTextStyles.bodyXL.copyWith(color: FColors.of(context).labelNormal)),
        ],
      ),
    );
  }
}
