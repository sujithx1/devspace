import 'package:flutter/widgets.dart';

import '../../app/theme/app_theme.dart';
import '../services/haptics.dart';

/// Gives any child a soft press-down scale, like native iOS controls.
class DSPressable extends StatefulWidget {
  const DSPressable({
    super.key,
    required this.child,
    this.onPressed,
    this.onLongPress,
    this.pressedScale = 0.97,
    this.haptic = false,
    this.semanticLabel,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final VoidCallback? onLongPress;
  final double pressedScale;

  /// Fires a light impact when pressed.
  final bool haptic;
  final String? semanticLabel;

  @override
  State<DSPressable> createState() => _DSPressableState();
}

class _DSPressableState extends State<DSPressable> {
  bool _pressed = false;

  bool get _enabled => widget.onPressed != null || widget.onLongPress != null;

  void _set(bool value) {
    if (_pressed != value && mounted) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: _enabled,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: _enabled ? (_) => _set(true) : null,
        onTapUp: _enabled ? (_) => _set(false) : null,
        onTapCancel: _enabled ? () => _set(false) : null,
        onTap: widget.onPressed == null
            ? null
            : () {
                if (widget.haptic) Haptics.tap();
                widget.onPressed!();
              },
        onLongPress: widget.onLongPress,
        child: AnimatedScale(
          scale: _pressed ? widget.pressedScale : 1,
          duration: _pressed ? DSMotion.fast : DSMotion.medium,
          curve: _pressed ? Curves.easeOut : DSMotion.spring,
          child: AnimatedOpacity(
            opacity: _pressed ? 0.85 : 1,
            duration: DSMotion.fast,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
