import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/haptics.dart';
import 'ds_tab_bar.dart';

const _tabs = [
  DSTabItem(label: 'Home', icon: CupertinoIcons.house, activeIcon: CupertinoIcons.house_fill),
  DSTabItem(label: 'Tasks', icon: CupertinoIcons.checkmark_circle, activeIcon: CupertinoIcons.checkmark_circle_fill),
  DSTabItem(label: 'Projects', icon: CupertinoIcons.square_stack_3d_up, activeIcon: CupertinoIcons.square_stack_3d_up_fill),
  DSTabItem(label: 'Notes', icon: CupertinoIcons.doc_text, activeIcon: CupertinoIcons.doc_text_fill),
  DSTabItem(label: 'More', icon: CupertinoIcons.ellipsis_circle, activeIcon: CupertinoIcons.ellipsis_circle_fill),
];

/// Hosts the five tab stacks. Each tab keeps its own navigation history and
/// scroll position; tapping the current tab again returns to its root.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      resizeToAvoidBottomInset: false,
      body: shell,
      bottomNavigationBar: DSTabBar(
        items: _tabs,
        currentIndex: shell.currentIndex,
        onTap: (index) {
          Haptics.selection();
          shell.goBranch(index, initialLocation: index == shell.currentIndex);
        },
      ),
    );
  }
}
