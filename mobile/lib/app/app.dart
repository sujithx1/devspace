import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/widgets/widget_sync.dart';
import 'providers/preferences_providers.dart';
import 'router.dart';
import 'theme/app_theme.dart';

class DevSpaceApp extends ConsumerWidget {
  const DevSpaceApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider).value ?? ThemeMode.system;
    ref.watch(widgetSyncProvider);
    return MaterialApp.router(
      title: 'DevSpace',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      themeAnimationDuration: DSMotion.medium,
      routerConfig: ref.watch(routerProvider),
    );
  }
}
