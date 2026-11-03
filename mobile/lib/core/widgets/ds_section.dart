import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';

/// Inset grouped section: optional header and footer around rounded rows
/// separated by hairlines.
class DSSection extends StatelessWidget {
  const DSSection({
    super.key,
    this.header,
    this.headerTrailing,
    this.footer,
    required this.children,
    this.dividerIndent = DSSpacing.md,
    this.margin = const EdgeInsets.fromLTRB(DSSpacing.page, 0, DSSpacing.page, DSSpacing.xl),
  });

  final String? header;
  final Widget? headerTrailing;
  final String? footer;
  final List<Widget> children;

  /// Leading inset of separators; use [DSRow.iconIndent] for rows with icons.
  final double dividerIndent;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) {
        rows.add(Padding(
          padding: EdgeInsetsDirectional.only(start: dividerIndent),
          child: Container(height: 0.5, color: colors.separator),
        ));
      }
      rows.add(children[i]);
    }

    return Padding(
      padding: margin,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (header != null || headerTrailing != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(DSSpacing.md, 0, DSSpacing.xxs, DSSpacing.xs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(
                        header ?? '',
                        style: context.type.footnote.copyWith(color: colors.textSecondary, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                  ?headerTrailing,
                ],
              ),
            ),
          DecoratedBox(
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(DSRadius.md),
              border: context.isDark ? Border.all(color: colors.border, width: 0.5) : null,
              boxShadow: context.isDark
                  ? null
                  : [BoxShadow(color: colors.shadow, blurRadius: 2, offset: const Offset(0, 0.5))],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(DSRadius.md),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: rows),
            ),
          ),
          if (footer != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(DSSpacing.md, DSSpacing.xs, DSSpacing.md, 0),
              child: Text(footer!, style: context.type.footnote.copyWith(color: colors.textSecondary)),
            ),
        ],
      ),
    );
  }
}

/// A row inside a [DSSection]. Highlights on press like a native table cell.
class DSRow extends StatefulWidget {
  const DSRow({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.value,
    this.trailing,
    this.showChevron = false,
    this.onTap,
    this.onLongPress,
    this.destructive = false,
    this.accent = false,
    this.enabled = true,
  });

  /// Separator indent that lines up with the title of a row with a [DSIconBadge].
  static const double iconIndent = DSSpacing.md + DSIconBadge.size + DSSpacing.sm;

  final String title;
  final String? subtitle;
  final Widget? leading;
  final String? value;
  final Widget? trailing;
  final bool showChevron;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool destructive;

  /// Renders the title in the accent colour, for action rows like "New Folder".
  final bool accent;
  final bool enabled;

  @override
  State<DSRow> createState() => _DSRowState();
}

class _DSRowState extends State<DSRow> {
  bool _pressed = false;

  bool get _interactive => widget.enabled && (widget.onTap != null || widget.onLongPress != null);

  void _set(bool v) {
    if (_pressed != v && mounted) setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final type = context.type;
    final titleColor = widget.destructive
        ? colors.danger
        : widget.accent
        ? colors.accent
        : colors.textPrimary;

    final content = AnimatedContainer(
      duration: _pressed ? Duration.zero : DSMotion.medium,
      color: _pressed ? colors.fillStrong : colors.surface,
      constraints: const BoxConstraints(minHeight: 48),
      padding: const EdgeInsets.symmetric(horizontal: DSSpacing.md, vertical: DSSpacing.sm - 1),
      child: Opacity(
        opacity: widget.enabled ? 1 : 0.45,
        child: Row(
          children: [
            if (widget.leading != null) ...[widget.leading!, const SizedBox(width: DSSpacing.sm)],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(widget.title, style: type.body.copyWith(color: titleColor)),
                  if (widget.subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      widget.subtitle!,
                      style: type.footnote.copyWith(color: colors.textSecondary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            if (widget.value != null)
              Padding(
                padding: const EdgeInsetsDirectional.only(start: DSSpacing.xs),
                child: Text(widget.value!, style: type.body.copyWith(color: colors.textSecondary)),
              ),
            if (widget.trailing != null)
              Padding(padding: const EdgeInsetsDirectional.only(start: DSSpacing.xs), child: widget.trailing!),
            if (widget.showChevron)
              Padding(
                padding: const EdgeInsetsDirectional.only(start: DSSpacing.xs),
                child: Icon(CupertinoIcons.chevron_forward, size: 15, color: colors.textTertiary),
              ),
          ],
        ),
      ),
    );

    return Semantics(
      button: _interactive,
      enabled: widget.enabled,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: _interactive ? (_) => _set(true) : null,
        onTapUp: _interactive ? (_) => _set(false) : null,
        onTapCancel: _interactive ? () => _set(false) : null,
        onTap: _interactive ? widget.onTap : null,
        onLongPress: _interactive ? widget.onLongPress : null,
        child: content,
      ),
    );
  }
}

/// Rounded-square coloured icon, as used in iOS Settings.
class DSIconBadge extends StatelessWidget {
  const DSIconBadge({super.key, required this.icon, required this.color});

  static const double size = 30;

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(7.5)),
      alignment: Alignment.center,
      child: Icon(icon, size: 18, color: Colors.white),
    );
  }
}

/// Emoji in a soft rounded tile; used for workspace icons.
class DSEmojiTile extends StatelessWidget {
  const DSEmojiTile({super.key, required this.emoji, this.size = DSIconBadge.size});

  final String emoji;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: context.colors.fill,
        borderRadius: BorderRadius.circular(size * 0.26),
      ),
      alignment: Alignment.center,
      child: Text(
        emoji,
        textScaler: TextScaler.noScaling,
        style: TextStyle(fontSize: size * 0.56, height: 1.1),
      ),
    );
  }
}
