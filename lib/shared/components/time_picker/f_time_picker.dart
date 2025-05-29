import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:seol_haru_check/generated/assets.dart';
import 'package:seol_haru_check/shared/components/time_picker/time_picker_spinner.dart';
import 'package:seol_haru_check/shared/sp_colors.dart';
import 'package:seol_haru_check/shared/sp_svg.dart';
import 'package:seol_haru_check/shared/themes/f_font_styles.dart';

class FTimePicker extends StatelessWidget {
  const FTimePicker({super.key, this.onTimeChange, this.onConfirm, this.useMultiLanguage = true});

  final Function(DateTime)? onTimeChange;
  final Function? onConfirm;
  final bool useMultiLanguage;

  @override
  Widget build(BuildContext context) {
    return TimePickerSpinner(
      is24HourMode: false,
      normalTextStyle: FTextStyles.titleS.r.copyWith(color: const Color.fromRGBO(197, 202, 211, 1)),
      highlightedTextStyle: FTextStyles.titleS.m.copyWith(color: SPColors.black),
      spacing: 16,
      itemHeight: 66,
      itemWidth: 80,
      alignment: Alignment.center,
      isForce2Digits: true,
      onTimeChange: onTimeChange,
      useMultiLanguage: useMultiLanguage,
    );
  }
}

class FTimePickerBottomSheet extends StatefulWidget {
  final Function(DateTime)? onConfirm;
  final String confirmText;
  final bool useMultiLanguage;

  const FTimePickerBottomSheet({super.key, this.onConfirm, this.confirmText = '확인', this.useMultiLanguage = true});

  @override
  State<FTimePickerBottomSheet> createState() => _FTimePickerBottomSheetState();

  static Future<DateTime?> show(
    BuildContext context, {
    String confirmText = '확인',
    Function(DateTime)? onConfirm,
    bool useMultiLanguage = true,
  }) {
    return showModalBottomSheet<DateTime?>(
      context: context,
      builder:
          (context) => FTimePickerBottomSheet(
            confirmText: confirmText,
            onConfirm: onConfirm,
            useMultiLanguage: useMultiLanguage,
          ),
    );
  }
}

class _FTimePickerBottomSheetState extends State<FTimePickerBottomSheet> {
  DateTime? _time;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        color: SPColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
      ),
      child: IntrinsicHeight(
        child: Column(
          children: [
            SizedBox(
              height: 48,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: Navigator.of(context).pop,
                    child: SPSvg.asset(Assets.iconsCloseNormalThin, width: 24, color: SPColors.black),
                  ),
                  Text('시간 선택', style: FTextStyles.bodyXL.m.copyWith(color: SPColors.black)),
                  const SizedBox(width: 24),
                ],
              ),
            ),
            const Gap(12),
            FTimePicker(
              onTimeChange: (time) {
                _time = time;
              },
              useMultiLanguage: widget.useMultiLanguage,
            ),
            const Gap(16),

            GestureDetector(
              onTap: () {
                widget.onConfirm?.call(_time!);
                context.pop();
              },
              child: Container(
                width: 340,
                height: 50,
                decoration: BoxDecoration(
                  color: SPColors.podGreen,
                  borderRadius: BorderRadius.circular(10),
                  border: const Border(
                    right: BorderSide(color: Colors.black, width: 4.0),
                    left: BorderSide(color: Colors.black, width: 1),
                    top: BorderSide(color: Colors.black, width: 1),
                    bottom: BorderSide(color: Colors.black, width: 4.0),
                  ),
                ),
                child: Center(child: Text('확인', style: FTextStyles.bodyXL.b)),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
