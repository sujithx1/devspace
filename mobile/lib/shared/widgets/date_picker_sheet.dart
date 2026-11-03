import 'package:flutter/cupertino.dart';

import '../../app/theme/app_theme.dart';
import '../../core/services/haptics.dart';
import '../../core/utils/dates.dart';
import '../../core/widgets/widgets.dart';

/// The result of the date picker. `date == null` means "no date".
typedef DateSelection = ({String? date, String? time});

/// Date (and optional time) picker with quick choices, as a bottom sheet.
/// Resolves to null when dismissed without choosing.
Future<DateSelection?> showDatePickerSheet(
  BuildContext context, {
  required String title,
  String? date,
  String? time,
  bool allowTime = true,
  bool allowClear = true,
}) {
  return showDSBottomSheet<DateSelection>(
    context,
    builder: (_) =>
        _DatePickerSheet(title: title, date: date, time: time, allowTime: allowTime, allowClear: allowClear),
  );
}

class _DatePickerSheet extends StatefulWidget {
  const _DatePickerSheet({
    required this.title,
    required this.date,
    required this.time,
    required this.allowTime,
    required this.allowClear,
  });

  final String title;
  final String? date;
  final String? time;
  final bool allowTime;
  final bool allowClear;

  @override
  State<_DatePickerSheet> createState() => _DatePickerSheetState();
}

class _DatePickerSheetState extends State<_DatePickerSheet> {
  late DateTime _day = widget.date == null ? Dates.dateOnly(DateTime.now()) : Dates.parseIso(widget.date!);
  late bool _hasTime = widget.time != null;
  late DateTime _time = () {
    if (widget.time == null) return DateTime(2000, 1, 1, 9);
    final p = widget.time!.split(':');
    return DateTime(2000, 1, 1, int.parse(p[0]), int.parse(p[1]));
  }();
  int _pickerKey = 0;

  String _fmtTime(DateTime t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  void _done() => Navigator.pop<DateSelection>(context, (
    date: Dates.toIso(_day),
    time: widget.allowTime && _hasTime ? _fmtTime(_time) : null,
  ));

  void _quick(DateTime day) {
    Haptics.selection();
    setState(() {
      _day = day;
      _pickerKey++; // rebuild the wheel at the new date
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final today = Dates.dateOnly(DateTime.now());
    final nextMonday = Dates.addDays(today, 8 - today.weekday);
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: DSSpacing.page),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(child: Text(widget.title, style: context.type.title3)),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: _done,
                  child: Text('Done', style: context.type.headline.copyWith(color: colors.accent)),
                ),
              ],
            ),
            const SizedBox(height: DSSpacing.sm),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _QuickChip(icon: CupertinoIcons.star_fill, label: 'Today', onTap: () => _quick(today)),
                  _QuickChip(icon: CupertinoIcons.sunrise_fill, label: 'Tomorrow', onTap: () => _quick(Dates.addDays(today, 1))),
                  _QuickChip(icon: CupertinoIcons.calendar, label: 'Next Week', onTap: () => _quick(nextMonday)),
                  if (widget.allowClear)
                    _QuickChip(
                      icon: CupertinoIcons.clear_circled,
                      label: 'No Date',
                      onTap: () => Navigator.pop<DateSelection>(context, (date: null, time: null)),
                    ),
                ],
              ),
            ),
            SizedBox(
              height: 190,
              child: CupertinoDatePicker(
                key: ValueKey(_pickerKey),
                mode: CupertinoDatePickerMode.date,
                initialDateTime: _day,
                minimumYear: 2000,
                maximumYear: 2100,
                onDateTimeChanged: (d) => _day = Dates.dateOnly(d),
              ),
            ),
            if (widget.allowTime) ...[
              DSSection(
                margin: const EdgeInsets.only(top: DSSpacing.xs, bottom: DSSpacing.sm),
                children: [
                  DSRow(
                    title: 'Time',
                    trailing: CupertinoSwitch(
                      value: _hasTime,
                      activeTrackColor: colors.accent,
                      onChanged: (v) => setState(() => _hasTime = v),
                    ),
                  ),
                ],
              ),
              AnimatedSize(
                duration: DSMotion.medium,
                curve: DSMotion.standard,
                child: _hasTime
                    ? SizedBox(
                        height: 150,
                        child: CupertinoDatePicker(
                          mode: CupertinoDatePickerMode.time,
                          initialDateTime: _time,
                          minuteInterval: 5,
                          onDateTimeChanged: (t) => _time = t,
                        ),
                      )
                    : const SizedBox(width: double.infinity),
              ),
            ],
            const SizedBox(height: DSSpacing.md),
          ],
        ),
      ),
    );
  }
}

class _QuickChip extends StatelessWidget {
  const _QuickChip({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(right: DSSpacing.xs),
      child: DSPressable(
        onPressed: onTap,
        semanticLabel: label,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: DSSpacing.sm, vertical: DSSpacing.xs),
          decoration: BoxDecoration(color: colors.fill, borderRadius: BorderRadius.circular(999)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: colors.accent),
              const SizedBox(width: 6),
              Text(label, style: context.type.subheadline.copyWith(fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }
}
