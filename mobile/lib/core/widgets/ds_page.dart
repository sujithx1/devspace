import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import 'ds_tooltip.dart';

/// Standard screen: native large-title navigation bar that collapses on scroll,
/// with content supplied as slivers.
class DSPage extends StatelessWidget {
  const DSPage({
    super.key,
    required this.title,
    this.slivers = const [],
    this.leading,
    this.trailing,
    this.previousPageTitle,
    this.controller,
    this.largeTitle = true,
  });

  final String title;
  final List<Widget> slivers;
  final Widget? leading;
  final Widget? trailing;
  final String? previousPageTitle;
  final ScrollController? controller;

  /// Detail screens can opt for a compact, standard-height title.
  final bool largeTitle;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final border = Border(bottom: BorderSide(color: colors.separator, width: 0));
    final background = colors.background.withValues(alpha: 0.82);
    return Scaffold(
      backgroundColor: colors.background,
      body: CustomScrollView(
        controller: controller,
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        slivers: [
          if (largeTitle)
            CupertinoSliverNavigationBar(
              largeTitle: Text(title),
              alwaysShowMiddle: false,
              leading: leading,
              trailing: trailing,
              previousPageTitle: previousPageTitle,
              backgroundColor: background,
              border: border,
            )
          else
            SliverPersistentHeader(
              pinned: true,
              delegate: _CompactBarDelegate(
                topPadding: MediaQuery.paddingOf(context).top,
                bar: CupertinoNavigationBar(
                  middle: Text(title),
                  leading: leading,
                  trailing: trailing,
                  previousPageTitle: previousPageTitle,
                  backgroundColor: background,
                  border: border,
                  automaticBackgroundVisibility: false,
                ),
              ),
            ),
          ...slivers,
          SliverToBoxAdapter(child: SizedBox(height: MediaQuery.paddingOf(context).bottom + DSSpacing.xxl)),
        ],
      ),
    );
  }
}

class _CompactBarDelegate extends SliverPersistentHeaderDelegate {
  _CompactBarDelegate({required this.bar, required this.topPadding});

  final Widget bar;
  final double topPadding;

  @override
  double get minExtent => topPadding + kMinInteractiveDimensionCupertino;

  @override
  double get maxExtent => minExtent;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) => bar;

  @override
  bool shouldRebuild(covariant _CompactBarDelegate oldDelegate) =>
      bar != oldDelegate.bar || topPadding != oldDelegate.topPadding;
}

/// Circular icon button for navigation bars (e.g. "+").
class DSNavIconButton extends StatelessWidget {
  const DSNavIconButton({super.key, required this.icon, required this.onPressed, required this.semanticLabel});

  final IconData icon;
  final VoidCallback onPressed;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return DSTooltip(
      message: semanticLabel,
      child: Semantics(
        label: semanticLabel,
        button: true,
        child: CupertinoButton(
          padding: EdgeInsets.zero,
          minimumSize: const Size.square(kMinInteractiveDimensionCupertino),
          onPressed: onPressed,
          child: Icon(icon, size: 24, color: context.colors.accent),
        ),
      ),
    );
  }
}
