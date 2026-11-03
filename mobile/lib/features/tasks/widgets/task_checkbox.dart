import 'package:flutter/cupertino.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/models/enums.dart';
import '../../../shared/widgets/entity_visuals.dart';

/// Round checkbox. The ring takes the priority colour for High and Urgent,
/// a half-filled ring means In Progress, and completing pops a filled check.
class TaskCheckbox extends StatelessWidget {
  const TaskCheckbox({super.key, required this.status, required this.priority, required this.onTap, this.size = 24});

  final TaskStatus status;
  final Priority priority;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final done = status == TaskStatus.completed;
    final ring = priority.rank >= Priority.high.rank ? priorityColor(context, priority) : colors.textTertiary;
    return Semantics(
      checked: done,
      button: true,
      label: done ? 'Completed' : 'Mark complete',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        // Generous hit area around a small visual.
        child: Padding(
          padding: const EdgeInsets.all(DSSpacing.xs),
          child: AnimatedSwitcher(
            duration: DSMotion.medium,
            switchInCurve: DSMotion.spring,
            transitionBuilder: (child, a) => ScaleTransition(scale: a, child: child),
            child: done
                ? Container(
                    key: const ValueKey('done'),
                    width: size,
                    height: size,
                    decoration: BoxDecoration(color: colors.accent, shape: BoxShape.circle),
                    child: Icon(CupertinoIcons.checkmark_alt, size: size * 0.7, color: colors.onAccent),
                  )
                : Container(
                    key: ValueKey(status),
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: ring, width: 1.6),
                    ),
                    child: status == TaskStatus.inProgress
                        ? Padding(
                            padding: const EdgeInsets.all(3),
                            child: CustomPaint(painter: _HalfPainter(ring)),
                          )
                        : null,
                  ),
          ),
        ),
      ),
    );
  }
}

class _HalfPainter extends CustomPainter {
  _HalfPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawArc(Offset.zero & size, -1.5708, 3.1416, true, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_HalfPainter old) => old.color != color;
}
