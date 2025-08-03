import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:seol_haru_check/constants/app_strings.dart';
import 'package:seol_haru_check/shared/sp_colors.dart';
import 'package:seol_haru_check/shared/themes/f_font_styles.dart';

/// Dialog for selecting a specific week for report viewing
class WeekPickerDialog extends StatefulWidget {
  final DateTime initialDate;
  final DateTime? earliestDate;
  final Function(DateTime) onWeekSelected;

  const WeekPickerDialog({super.key, required this.initialDate, this.earliestDate, required this.onWeekSelected});

  @override
  State<WeekPickerDialog> createState() => _WeekPickerDialogState();
}

class _WeekPickerDialogState extends State<WeekPickerDialog> with TickerProviderStateMixin {
  late DateTime selectedDate;
  late PageController _pageController;
  late DateTime currentMonth;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    selectedDate = widget.initialDate;
    currentMonth = DateTime(selectedDate.year, selectedDate.month);
    _pageController = PageController(
      initialPage: _getMonthDifference(widget.earliestDate ?? DateTime(2024), currentMonth),
    );

    // Initialize fade animation for smooth transitions
    _fadeController = AnimationController(duration: const Duration(milliseconds: 300), vsync: this);
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut));

    // Start animation
    _fadeController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  int _getMonthDifference(DateTime start, DateTime end) {
    return (end.year - start.year) * 12 + end.month - start.month;
  }

  DateTime _getWeekStart(DateTime date) {
    final daysFromSunday = date.weekday % 7;
    return DateTime(date.year, date.month, date.day - daysFromSunday);
  }

  DateTime _getWeekEnd(DateTime weekStart) {
    return weekStart.add(const Duration(days: 6));
  }

  bool _isSameWeek(DateTime date1, DateTime date2) {
    final week1Start = _getWeekStart(date1);
    final week2Start = _getWeekStart(date2);
    return week1Start.isAtSameMomentAs(week2Start);
  }

  bool _isCurrentWeek(DateTime date) {
    return _isSameWeek(date, DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: SPColors.backgroundColor(context),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Text(
                    AppStrings.selectWeek,
                    style: FTextStyles.title2_20.copyWith(
                      color: SPColors.textColor(context),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close, color: SPColors.textColor(context)),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Month navigation
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed:
                      _isNavigating
                          ? null
                          : () async {
                            setState(() {
                              _isNavigating = true;
                              currentMonth = DateTime(currentMonth.year, currentMonth.month - 1);
                            });

                            await _fadeController.reverse();
                            await _pageController.previousPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                            await _fadeController.forward();

                            setState(() {
                              _isNavigating = false;
                            });
                          },
                  icon: Icon(Icons.chevron_left, color: _isNavigating ? SPColors.gray400 : SPColors.textColor(context)),
                ),
                Text(
                  DateFormat('yyyy년 M월', 'ko_KR').format(currentMonth),
                  style: FTextStyles.title3_18.copyWith(
                    color: SPColors.textColor(context),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                IconButton(
                  onPressed:
                      _isNavigating
                          ? null
                          : () async {
                            final nextMonth = DateTime(currentMonth.year, currentMonth.month + 1);
                            if (nextMonth.isBefore(DateTime.now()) || nextMonth.month == DateTime.now().month) {
                              setState(() {
                                _isNavigating = true;
                                currentMonth = nextMonth;
                              });

                              await _fadeController.reverse();
                              await _pageController.nextPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                              await _fadeController.forward();

                              setState(() {
                                _isNavigating = false;
                              });
                            }
                          },
                  icon: Icon(
                    Icons.chevron_right,
                    color:
                        _isNavigating || DateTime(currentMonth.year, currentMonth.month + 1).isAfter(DateTime.now())
                            ? SPColors.gray400
                            : SPColors.textColor(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Calendar with fade animation
            Expanded(
              child: AnimatedBuilder(
                animation: _fadeAnimation,
                builder:
                    (context, child) => FadeTransition(
                      opacity: _fadeAnimation,
                      child: PageView.builder(
                        controller: _pageController,
                        onPageChanged: (index) async {
                          final earliestDate = widget.earliestDate ?? DateTime(2024);
                          final monthsFromEarliest = index;

                          await _fadeController.reverse();
                          setState(() {
                            currentMonth = DateTime(earliestDate.year, earliestDate.month + monthsFromEarliest);
                          });
                          await _fadeController.forward();
                        },
                        itemBuilder: (context, index) {
                          final earliestDate = widget.earliestDate ?? DateTime(2024);
                          final monthsFromEarliest = index;
                          final month = DateTime(earliestDate.year, earliestDate.month + monthsFromEarliest);
                          return _buildCalendar(month);
                        },
                      ),
                    ),
              ),
            ),

            const SizedBox(height: 16),

            // Selected week info
            ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: SPColors.podGreen.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: SPColors.podGreen.withValues(alpha: .3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, color: SPColors.podGreen, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _formatWeekRange(_getWeekStart(selectedDate)),
                        style: FTextStyles.body1_16.copyWith(
                          color: SPColors.textColor(context),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (_isCurrentWeek(selectedDate))
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: SPColors.podGreen, borderRadius: BorderRadius.circular(12)),
                        child: Text(
                          AppStrings.currentWeek,
                          style: FTextStyles.body2_14.copyWith(color: SPColors.white, fontWeight: FontWeight.w500),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Action buttons with loading states
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: _isNavigating ? null : () => Navigator.of(context).pop(),
                    child: Text(
                      AppStrings.cancel,
                      style: FTextStyles.body1_16.copyWith(color: _isNavigating ? SPColors.gray400 : SPColors.gray600),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed:
                        _isNavigating
                            ? null
                            : () async {
                              final weekStart = _getWeekStart(selectedDate);

                              // Add smooth closing animation
                              await _fadeController.reverse();
                              Navigator.of(context).pop();
                              widget.onWeekSelected(weekStart);
                            },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isNavigating ? SPColors.gray300 : SPColors.podGreen,
                      foregroundColor: SPColors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child:
                        _isNavigating
                            ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(SPColors.white),
                              ),
                            )
                            : Text(AppStrings.goToWeek),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendar(DateTime month) {
    final firstDayOfMonth = DateTime(month.year, month.month, 1);
    final lastDayOfMonth = DateTime(month.year, month.month + 1, 0);
    final firstDayOfWeek = firstDayOfMonth.weekday % 7;
    final daysInMonth = lastDayOfMonth.day;

    return Column(
      children: [
        // Week day headers
        Row(
          children:
              ['일', '월', '화', '수', '목', '금', '토']
                  .map(
                    (day) => Expanded(
                      child: Center(
                        child: Text(
                          day,
                          style: FTextStyles.body2_14.copyWith(color: SPColors.gray600, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
                  )
                  .toList(),
        ),
        const SizedBox(height: 8),

        // Calendar grid
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, childAspectRatio: 1),
            itemCount: 42, // 6 weeks * 7 days
            itemBuilder: (context, index) {
              final dayIndex = index - firstDayOfWeek;

              if (dayIndex < 0 || dayIndex >= daysInMonth) {
                return const SizedBox(); // Empty cell
              }

              final day = dayIndex + 1;
              final date = DateTime(month.year, month.month, day);
              final weekStart = _getWeekStart(date);
              final isSelected = _isSameWeek(date, selectedDate);
              final isCurrentWeek = _isCurrentWeek(date);
              final isFutureWeek = weekStart.isAfter(DateTime.now());
              final isBeforeEarliest =
                  widget.earliestDate != null && weekStart.isBefore(_getWeekStart(widget.earliestDate!));

              return GestureDetector(
                onTap:
                    isFutureWeek || isBeforeEarliest
                        ? null
                        : () {
                          setState(() {
                            selectedDate = date;
                          });
                        },
                child: Container(
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color:
                        isSelected
                            ? SPColors.podGreen
                            : isCurrentWeek
                            ? SPColors.podGreen.withValues(alpha: .1)
                            : null,
                    borderRadius: BorderRadius.circular(8),
                    border:
                        isCurrentWeek && !isSelected
                            ? Border.all(color: SPColors.podGreen.withValues(alpha: .5))
                            : null,
                  ),
                  child: Center(
                    child: Text(
                      day.toString(),
                      style: FTextStyles.body1_16.copyWith(
                        color:
                            isFutureWeek || isBeforeEarliest
                                ? SPColors.gray400
                                : isSelected
                                ? SPColors.white
                                : isCurrentWeek
                                ? SPColors.podGreen
                                : SPColors.textColor(context),
                        fontWeight: isSelected || isCurrentWeek ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _formatWeekRange(DateTime weekStart) {
    final weekEnd = _getWeekEnd(weekStart);
    final dateFormat = DateFormat('M월 d일', 'ko_KR');
    return '${dateFormat.format(weekStart)} - ${dateFormat.format(weekEnd)}';
  }
}
