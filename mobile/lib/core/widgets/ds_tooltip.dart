import 'package:flutter/material.dart';

/// Names an icon-only control. Shows when the control is pressed and held
/// (with a light haptic), or hovered with a pointer on iPad.
///
/// The child is expected to carry its own semantics label, so the tooltip
/// isn't announced twice by VoiceOver.
class DSTooltip extends StatelessWidget {
  const DSTooltip({super.key, required this.message, required this.child});

  final String message;
  final Widget child;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: message,
    triggerMode: TooltipTriggerMode.longPress,
    excludeFromSemantics: true,
    child: child,
  );
}
