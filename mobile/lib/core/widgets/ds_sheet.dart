import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';

/// Presents a native iOS page sheet (the stacked card that scales the screen
/// behind it). Build the content with [DSSheetScaffold].
Future<T?> showDSSheet<T>(
  BuildContext context, {
  required Widget Function(BuildContext context, ScrollController controller) builder,
}) {
  return showCupertinoSheet<T>(
    context: context,
    scrollableBuilder: (context, controller) => builder(context, controller),
  );
}

/// Content of a form sheet: Cancel / title / Done bar above a scrolling body.
class DSSheetScaffold extends StatelessWidget {
  const DSSheetScaffold({
    super.key,
    required this.title,
    required this.scrollController,
    required this.children,
    this.doneLabel = 'Done',
    this.onDone,
    this.busy = false,
    this.cancelLabel = 'Cancel',
  });

  final String title;
  final ScrollController scrollController;
  final List<Widget> children;
  final String doneLabel;

  /// Null disables the Done button.
  final VoidCallback? onDone;
  final bool busy;
  final String cancelLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final type = context.type;
    return Material(
      color: colors.background,
      child: Column(
        children: [
          Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: DSSpacing.xs),
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: colors.separator, width: 0.5))),
            child: NavigationToolbar(
              leading: CupertinoButton(
                padding: const EdgeInsets.symmetric(horizontal: DSSpacing.sm),
                onPressed: () => Navigator.of(context).maybePop(),
                child: Text(cancelLabel, style: type.body.copyWith(color: colors.accent)),
              ),
              middle: Text(title, style: type.headline, maxLines: 1, overflow: TextOverflow.ellipsis),
              trailing: busy
                  ? const Padding(padding: EdgeInsets.symmetric(horizontal: DSSpacing.lg), child: CupertinoActivityIndicator())
                  : CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: DSSpacing.sm),
                      onPressed: onDone,
                      child: Text(
                        doneLabel,
                        style: type.headline.copyWith(color: onDone == null ? colors.textTertiary : colors.accent),
                      ),
                    ),
            ),
          ),
          Expanded(
            child: ListView(
              controller: scrollController,
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.only(
                top: DSSpacing.xl,
                bottom: MediaQuery.viewInsetsOf(context).bottom + MediaQuery.paddingOf(context).bottom + DSSpacing.xl,
              ),
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottom sheet that sizes to its content, for pickers and switchers.
Future<T?> showDSBottomSheet<T>(BuildContext context, {required WidgetBuilder builder}) {
  final colors = context.colors;
  return showModalBottomSheet<T>(
    context: context,
    useRootNavigator: true,
    useSafeArea: true,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: colors.background,
    barrierColor: Colors.black.withValues(alpha: 0.3),
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(DSRadius.xl))),
    builder: builder,
  );
}
