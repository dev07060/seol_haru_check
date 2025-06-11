import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:seol_haru_check/generated/assets.dart';
import 'package:seol_haru_check/shared/components/date_picker/f_month_picker.dart';
import 'package:seol_haru_check/shared/components/f_bottom_sheet.dart';
import 'package:seol_haru_check/shared/sp_svg.dart';
import 'package:seol_haru_check/shared/themes/f_colors.dart';
import 'package:seol_haru_check/shared/themes/f_font_styles.dart';
import 'package:seol_haru_check/shared/themes/f_font_weight.dart';
import 'package:table_calendar/table_calendar.dart';

enum FCalendarFormat { month, week, monthPicker }

// Todo: 다국어 적용
/// 달력 위젯
/// 모든 시간 입력은 UTC로 입력
/// [focusedDay]를 이용해 부모 위젯에서 상태관리 합니다.
/// [calendarFormat]으로 월 또는 주를 선택할 수 있습니다.
/// [events]로 날짜에 닷을 표시할 수 있습니다.
class FDatePicker extends StatefulWidget {
  const FDatePicker({
    super.key,
    required this.focusedDay,
    this.firstDay,
    this.lastDay,
    this.isModal = false,
    this.isShowDragHandle = true,
    this.calendarFormat = FCalendarFormat.week,
    this.events = const {},
    required this.onChangedDay,
    this.onFormatChanged,
    this.useMultiLanguage = true,
  });

  final DateTime focusedDay;
  final DateTime? firstDay;
  final DateTime? lastDay;
  final bool isModal;
  final bool isShowDragHandle;
  final Map<DateTime, List> events;
  final FCalendarFormat calendarFormat;
  final Function(DateTime date) onChangedDay;
  final Function(FCalendarFormat fCalendarFormat)? onFormatChanged;
  final bool useMultiLanguage;

  @override
  State<FDatePicker> createState() => _FDatePickerState();
}

class _FDatePickerState extends State<FDatePicker> {
  late DateTime _now;
  late DateTime _firstDay;
  late DateTime _lastDay;
  late DateTime _focusDay;
  late Map<DateTime, List> _events;

  late CalendarFormat _calendarFormat;

  /// 월 선택 팝업 보여주기 여부
  bool _isShowMonthPicker = false;

  @override
  void initState() {
    super.initState();
    _updateDateTimes();
    _setCalendarFormat(); // 캘린더 포멧 설정
  }

  @override
  void didUpdateWidget(covariant FDatePicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateDateTimes();
    _setCalendarFormat();
  }

  void _updateDateTimes() {
    _now = DateTime.now();
    _firstDay = widget.firstDay?.toLocal() ?? _now.subtract(const Duration(days: 30));
    _lastDay = widget.lastDay?.toLocal() ?? _now.add(const Duration(days: 30));
    _focusDay = widget.focusedDay.toLocal();
    _events = Map.fromEntries(
      widget.events.entries.map((entry) {
        final local = entry.key.toLocal();
        return MapEntry(DateTime.utc(local.year, local.month, local.day), entry.value);
      }),
    );
  }

  /// 캘린더 포맷 설정
  void _setCalendarFormat() {
    switch (widget.calendarFormat) {
      case FCalendarFormat.month:
        _calendarFormat = CalendarFormat.month;
        break;
      case FCalendarFormat.week:
        _calendarFormat = CalendarFormat.week;
        break;
      case FCalendarFormat.monthPicker:
        _calendarFormat = CalendarFormat.month;
        _isShowMonthPicker = true;
        break;
    }
  }

  /// 월 선택 이벤트
  void _onTapMonth() {
    if (widget.isModal) {
      _isShowMonthPicker = !_isShowMonthPicker;
      widget.onFormatChanged?.call(_isShowMonthPicker ? FCalendarFormat.monthPicker : FCalendarFormat.month);
      setState(() {});
      return;
    }

    FBottomSheet(
      item: FMonthPicker(
        focusedDay: _focusDay,
        firstDay: _firstDay,
        lastDay: _lastDay,
        onSelectedMonth: _onSelectedMonth,
        onCanceled: Navigator.of(context).pop,
        useMultiLanguage: widget.useMultiLanguage,
      ),
    ).show(context);
  }

  /// 달 선택 이벤트
  void _onSelectedMonth(DateTime day) {
    if (widget.isModal) {
      _isShowMonthPicker = false;
    } else {
      Navigator.of(context).pop(); // 월 선택 바텀 시트 닫기
    }
    if (day.isBefore(_firstDay)) {
      day = _firstDay;
    } else if (day.isAfter(_lastDay)) {
      day = _lastDay;
    }
    widget.onChangedDay(day);
  }

  @override
  Widget build(BuildContext context) {
    final currentLocale = WidgetsBinding.instance.platformDispatcher.locale;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child:
          _isShowMonthPicker
              ? FMonthPicker(
                focusedDay: _focusDay,
                firstDay: _firstDay,
                lastDay: _lastDay,
                onSelectedMonth: _onSelectedMonth,
                onCanceled: _onTapMonth,
                useMultiLanguage: widget.useMultiLanguage,
              )
              : !widget.isModal
              ? Listener(
                onPointerMove: (PointerMoveEvent event) {
                  // Month<->week 스위칭 상하 스와이프 감도 조절
                  if (event.delta.dy.abs() > 10) {
                    if (event.delta.dy < 0 && _calendarFormat == CalendarFormat.month) {
                      setState(() {
                        _calendarFormat = CalendarFormat.week;
                        widget.onFormatChanged?.call(FCalendarFormat.week);
                      });
                    } else if (event.delta.dy > 0 && _calendarFormat == CalendarFormat.week) {
                      setState(() {
                        _calendarFormat = CalendarFormat.month;
                        widget.onFormatChanged?.call(FCalendarFormat.month);
                      });
                    }
                  }
                },
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: widget.isModal ? 0 : 20, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _header(),
                      Gap(_calendarFormat == CalendarFormat.week ? 18 : 20),
                      TableCalendar(
                        availableGestures: AvailableGestures.all,
                        firstDay: _firstDay,
                        lastDay: _lastDay,
                        focusedDay: _focusDay,
                        headerVisible: false,
                        selectedDayPredicate: (day) => isSameDay(_focusDay, day),
                        eventLoader: (day) => _events[day] ?? [],
                        calendarFormat: _calendarFormat,
                        locale: '${currentLocale.languageCode}_${currentLocale.countryCode}',
                        daysOfWeekHeight: 26,
                        rowHeight: _calendarFormat == CalendarFormat.week ? 36 : 60,
                        onDaySelected: (selectedDay, focusedDay) {
                          widget.onChangedDay(selectedDay);
                        },
                        onPageChanged: widget.onChangedDay,
                        calendarBuilders: CalendarBuilders(
                          markerBuilder: _markerBuilder,
                          todayBuilder: _defaultBuilder,
                          defaultBuilder: _defaultBuilder,
                          selectedBuilder: _selectedBuilder,
                          dowBuilder: _dowBuilder,
                          disabledBuilder:
                              (context, day, focusedDay) =>
                                  _defaultBuilder(context, day, focusedDay, FColors.of(context).labelAssistive),
                          outsideBuilder:
                              (context, day, focusedDay) =>
                                  _defaultBuilder(context, day, focusedDay, FColors.of(context).labelAlternative),
                        ),
                      ),
                      if (widget.isShowDragHandle) _handle(),
                    ],
                  ),
                ),
              )
              : Padding(
                padding: EdgeInsets.symmetric(horizontal: widget.isModal ? 0 : 14, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _header(),
                    Gap(_calendarFormat == CalendarFormat.week ? 12 : 20),
                    TableCalendar(
                      availableGestures: widget.isModal ? AvailableGestures.none : AvailableGestures.all,
                      firstDay: _firstDay,
                      lastDay: _lastDay,
                      focusedDay: _focusDay,
                      headerVisible: false,
                      selectedDayPredicate: (day) => isSameDay(_focusDay, day),
                      eventLoader: (day) => _events[day] ?? [],
                      calendarFormat: _calendarFormat,
                      locale: '${currentLocale.languageCode}_${currentLocale.countryCode}',
                      daysOfWeekHeight: 28,
                      rowHeight: _calendarFormat == CalendarFormat.week ? 36 : 60,
                      onDaySelected: (selectedDay, focusedDay) {
                        widget.onChangedDay(selectedDay);
                      },
                      onPageChanged: widget.onChangedDay,
                      calendarBuilders: CalendarBuilders(
                        markerBuilder: _markerBuilder,
                        todayBuilder: _defaultBuilder,
                        defaultBuilder: _defaultBuilder,
                        selectedBuilder: _selectedBuilder,
                        dowBuilder: _dowBuilder,
                        disabledBuilder:
                            (context, day, focusedDay) =>
                                _defaultBuilder(context, day, focusedDay, FColors.of(context).labelAssistive),
                        outsideBuilder:
                            (context, day, focusedDay) =>
                                _defaultBuilder(context, day, focusedDay, FColors.of(context).labelAlternative),
                      ),
                    ),
                    if (widget.isShowDragHandle) _handle(),
                  ],
                ),
              ),
    );
  }

  Widget _handle() {
    return GestureDetector(
      onVerticalDragUpdate: (details) {
        if (_calendarFormat == CalendarFormat.week && details.delta.dy > 0) {
          setState(() {
            _calendarFormat = CalendarFormat.month;
            widget.onFormatChanged?.call(FCalendarFormat.month);
          });
        } else if (_calendarFormat == CalendarFormat.month && details.delta.dy < 0) {
          setState(() {
            _calendarFormat = CalendarFormat.week;
            widget.onFormatChanged?.call(FCalendarFormat.week);
          });
        }
      },
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 32,
              height: 4,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(99),
                color: FColors.of(context).solidAlternative,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    final String text;

    switch (_calendarFormat) {
      case CalendarFormat.month:
        if (!widget.useMultiLanguage) {
          text = '${_focusDay.year}년 ${_focusDay.month}월';
          break;
        }
        text = '${_focusDay.year}년 ${_focusDay.month}월';
        break;
      case CalendarFormat.week:
        if (!widget.useMultiLanguage) {
          text = '${_focusDay.month}월';
          break;
        }
        text = _focusDay.month.toString();
        break;
      default:
        if (!widget.useMultiLanguage) {
          text = '${_focusDay.month}월';
          break;
        }
        text = '${_focusDay.month}월';
        break;
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _onTapMonth,
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Text(text, style: FTextStyles.bodyXL.copyWith(color: FColors.of(context).labelNormal)),
          ),
          const Gap(8),
          SPSvg.asset(Assets.iconsChevronsChevronDownThick, color: FColors.of(context).labelAlternative, width: 16),
        ],
      ),
    );
  }

  Widget _defaultBuilder(BuildContext context, DateTime day, DateTime focusedDay, [Color? fontColor]) {
    final TextStyle textStyle;
    final double bottomPadding;

    switch (_calendarFormat) {
      case CalendarFormat.month:
        textStyle = FTextStyles.bodyXL;
        bottomPadding = 14;
        break;
      case CalendarFormat.week:
        textStyle = FTextStyles.titleXS;
        bottomPadding = 8;
        break;
      default:
        textStyle = FTextStyles.titleXS;
        bottomPadding = 8;
        break;
    }

    return Center(
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomPadding),
        child: Text(
          day.day.toString(),
          style: textStyle.copyWith(
            color: fontColor ?? FColors.of(context).labelNormal,
            fontWeight: isSameDay(_now, day) ? FFontWeight.bold : FFontWeight.medium,
          ),
        ),
      ),
    );
  }

  Widget _dowBuilder(BuildContext context, DateTime day) {
    final bool isFocusedDay = isSameDay(day, _focusDay);
    final TextStyle textStyle;
    final Color? color;
    final Color fontColor;

    switch (_calendarFormat) {
      case CalendarFormat.month:
        textStyle = FTextStyles.bodyM;
        color = null;
        fontColor = FColors.of(context).labelAlternative;
        break;
      case CalendarFormat.week:
        textStyle = FTextStyles.bodyS;
        color = isFocusedDay ? FColors.of(context).solidStrong : null;
        fontColor = isFocusedDay ? FColors.of(context).inverseAlternative : FColors.of(context).labelAlternative;
        break;
      default:
        textStyle = FTextStyles.bodyS;
        color = isFocusedDay ? FColors.of(context).solidStrong : null;
        fontColor = isFocusedDay ? FColors.of(context).inverseAlternative : FColors.of(context).labelAlternative;
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
              ),
            ),
          ),
          Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(color: color, borderRadius: const BorderRadius.vertical(top: Radius.circular(2))),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(DateFormat.E('ko').format(day), style: textStyle.copyWith(color: fontColor)),
                const Gap(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _selectedBuilder(BuildContext context, DateTime day, DateTime focusedDay) {
    Container week() {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.only(bottom: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: FColors.of(context).solidStrong,
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(2)),
        ),
        child: Text(
          day.day.toString(),
          style: FTextStyles.titleXS.copyWith(color: FColors.of(context).inverseStrong, fontWeight: FFontWeight.bold),
        ),
      );
    }

    Widget month() {
      return Center(
        child: Container(
          width: 28,
          height: 28,
          margin: const EdgeInsets.only(bottom: 16),
          alignment: Alignment.center,
          decoration: BoxDecoration(shape: BoxShape.circle, color: FColors.of(context).solidStrong),
          child: Text(
            day.day.toString(),
            style: FTextStyles.bodyXL.copyWith(color: FColors.of(context).inverseStrong, fontWeight: FFontWeight.bold),
          ),
        ),
      );
    }

    switch (_calendarFormat) {
      case CalendarFormat.month:
        return month();
      case CalendarFormat.week:
        return week();
      default:
        return week();
    }
  }

  Widget? _markerBuilder(BuildContext context, DateTime day, List events) {
    if (events.isEmpty) return null;

    final double bottomPadding;
    final Color color;

    switch (_calendarFormat) {
      case CalendarFormat.month:
        bottomPadding = 12;
        color = FColors.of(context).solidStrong;
        break;
      case CalendarFormat.week:
        bottomPadding = 4;
        color = isSameDay(day, _focusDay) ? FColors.of(context).inverseStrong : FColors.of(context).solidStrong;
        break;
      default:
        bottomPadding = 12;
        color = FColors.of(context).solidStrong;
        break;
    }

    return Container(
      width: 4,
      height: 4,
      margin: EdgeInsets.only(bottom: bottomPadding),
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
