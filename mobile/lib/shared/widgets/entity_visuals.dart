import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../../core/models/enums.dart';

/// Colour for a priority. Only High and Urgent draw attention.
Color priorityColor(BuildContext context, Priority priority) => switch (priority) {
  Priority.urgent => context.colors.danger,
  Priority.high => context.colors.warning,
  Priority.medium => context.colors.info,
  Priority.low => context.colors.textTertiary,
};

Color projectColor(BuildContext context, ProjectColor color) =>
    DSPaletteColor.values.byName(color.name).resolve(Theme.of(context).brightness);

class PriorityIcon extends StatelessWidget {
  const PriorityIcon({super.key, required this.priority, this.size = 16});

  final Priority priority;
  final double size;

  @override
  Widget build(BuildContext context) => Icon(
    priority.rank >= Priority.high.rank ? CupertinoIcons.flag_fill : CupertinoIcons.flag,
    size: size,
    color: priorityColor(context, priority),
  );
}

class ProjectDot extends StatelessWidget {
  const ProjectDot({super.key, required this.color, this.size = 8});

  final ProjectColor color;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: projectColor(context, color), shape: BoxShape.circle),
  );
}

/// Circular progress ring, used for projects and today's progress.
class ProgressRing extends StatelessWidget {
  const ProgressRing({super.key, required this.progress, required this.color, this.size = 22, this.stroke = 3, this.child});

  final double progress;
  final Color color;
  final double size;
  final double stroke;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: progress.clamp(0, 1)),
        duration: DSMotion.slow,
        curve: DSMotion.standard,
        builder: (context, value, child) => CustomPaint(
          painter: _RingPainter(value, color, context.colors.fillStrong, stroke),
          child: Center(child: child),
        ),
        child: child,
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.progress, this.color, this.track, this.stroke);

  final double progress;
  final Color color;
  final Color track;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect.deflate(stroke / 2), 0, 6.2832, false, paint..color = track);
    if (progress > 0) {
      canvas.drawArc(rect.deflate(stroke / 2), -1.5708, 6.2832 * progress, false, paint..color = color);
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress || old.color != color || old.track != track;
}
