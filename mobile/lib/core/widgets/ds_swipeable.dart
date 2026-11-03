import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

import '../../app/theme/app_theme.dart';
import '../services/haptics.dart';

class DSSwipeAction {
  const DSSwipeAction({required this.icon, required this.label, required this.color, required this.onPressed});

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;
}

/// iOS-style swipe actions. Swipe partway to reveal buttons, or swipe all the
/// way to run the first action on that side. Only one row stays open at a time.
class DSSwipeable extends StatefulWidget {
  const DSSwipeable({super.key, required this.child, this.leading = const [], this.trailing = const []});

  final Widget child;

  /// Revealed by swiping right; `leading.first` runs on a full swipe.
  final List<DSSwipeAction> leading;

  /// Revealed by swiping left; `trailing.first` runs on a full swipe.
  final List<DSSwipeAction> trailing;

  @override
  State<DSSwipeable> createState() => _DSSwipeableState();
}

class _DSSwipeableState extends State<DSSwipeable> with SingleTickerProviderStateMixin {
  static const _actionWidth = 76.0;
  static _DSSwipeableState? _openRow;

  late final _controller = AnimationController.unbounded(vsync: this)..addListener(() => setState(() {}));
  double _width = 0;
  bool _armed = false;

  double get _offset => _controller.value;
  double get _leadingExtent => widget.leading.length * _actionWidth;
  double get _trailingExtent => widget.trailing.length * _actionWidth;
  double get _armThreshold => _width * 0.55;

  @override
  void dispose() {
    if (_openRow == this) _openRow = null;
    _controller.dispose();
    super.dispose();
  }

  void _animateTo(double target, {double velocity = 0}) {
    final spring = SpringDescription.withDampingRatio(mass: 1, stiffness: 500, ratio: 0.9);
    _controller.animateWith(SpringSimulation(spring, _offset, target, velocity));
    if (target == 0) {
      if (_openRow == this) _openRow = null;
    } else {
      if (_openRow != null && _openRow != this) _openRow!.close();
      _openRow = this;
    }
  }

  void close() => _animateTo(0);

  void _onDragUpdate(DragUpdateDetails d) {
    var next = _offset + d.primaryDelta!;
    if (widget.leading.isEmpty) next = next.clamp(-double.infinity, 0);
    if (widget.trailing.isEmpty) next = next.clamp(0, double.infinity);
    _controller.value = next.clamp(-_width, _width);
    final armed = _offset.abs() > _armThreshold;
    if (armed != _armed) {
      _armed = armed;
      Haptics.tap();
    }
  }

  void _onDragEnd(DragEndDetails d) {
    final v = d.primaryVelocity ?? 0;
    if (_armed) {
      _armed = false;
      final leading = _offset > 0;
      final action = leading ? widget.leading.first : widget.trailing.first;
      _animateTo(0, velocity: v);
      action.onPressed();
      return;
    }
    if (_offset > 0) {
      _animateTo(_offset > _leadingExtent / 2 || v > 600 ? _leadingExtent : 0, velocity: v);
    } else if (_offset < 0) {
      _animateTo(-_offset > _trailingExtent / 2 || v < -600 ? -_trailingExtent : 0, velocity: v);
    }
  }

  Widget _actions(List<DSSwipeAction> actions, double revealed, {required bool leading}) {
    if (actions.isEmpty || revealed <= 0) return const SizedBox.shrink();
    final expanded = revealed > _armThreshold;
    final slot = expanded ? revealed : revealed / actions.length;
    final visible = expanded ? [actions.first] : actions;
    return Align(
      alignment: leading ? Alignment.centerLeft : Alignment.centerRight,
      child: SizedBox(
        width: revealed,
        child: Row(
          children: [
            for (final a in (leading ? visible : visible.reversed))
              GestureDetector(
                onTap: () {
                  close();
                  a.onPressed();
                },
                child: Container(
                  width: slot,
                  color: a.color,
                  alignment: expanded ? (leading ? Alignment.centerLeft : Alignment.centerRight) : Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: DSSpacing.lg),
                  child: Opacity(
                    opacity: (revealed / (_actionWidth * 0.8)).clamp(0, 1),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(a.icon, color: Colors.white, size: 22),
                        const SizedBox(height: 3),
                        Text(
                          a.label,
                          maxLines: 1,
                          overflow: TextOverflow.clip,
                          textScaler: TextScaler.noScaling,
                          style: context.type.caption2.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final open = _offset != 0;
    return LayoutBuilder(
      builder: (context, constraints) {
        _width = constraints.maxWidth;
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onHorizontalDragStart: (_) => _controller.stop(),
          onHorizontalDragUpdate: _onDragUpdate,
          onHorizontalDragEnd: _onDragEnd,
          child: ClipRect(
            child: Stack(
              children: [
                Positioned.fill(
                  child: _offset > 0
                      ? _actions(widget.leading, _offset, leading: true)
                      : _actions(widget.trailing, -_offset, leading: false),
                ),
                Transform.translate(
                  offset: Offset(_offset, 0),
                  child: open
                      // While open, a tap on the row closes it instead of opening the task.
                      ? GestureDetector(onTap: close, behavior: HitTestBehavior.opaque, child: AbsorbPointer(child: widget.child))
                      : widget.child,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
