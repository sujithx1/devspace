import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers/core_providers.dart';
import '../../app/providers/preferences_providers.dart';
import '../../app/theme/app_theme.dart';
import '../../core/repositories/preferences_repository.dart';
import '../../core/services/haptics.dart';
import '../../core/widgets/widgets.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static const _themeLabels = {ThemeMode.system: 'System', ThemeMode.light: 'Light', ThemeMode.dark: 'Dark'};

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final themeMode = ref.watch(themeModeProvider).value ?? ThemeMode.system;
    final name = ref.watch(displayNameProvider).value ?? '';
    final prefs = ref.read(preferencesRepositoryProvider);

    return DSPage(
      title: 'Settings',
      previousPageTitle: 'More',
      slivers: [
        const SliverToBoxAdapter(child: SizedBox(height: DSSpacing.xs)),
        SliverToBoxAdapter(
          child: DSSection(
            header: 'Profile',
            footer: 'Used to greet you on Home.',
            children: [
              DSRow(
                title: 'Your Name',
                value: name.isEmpty ? 'Not set' : name,
                showChevron: true,
                onTap: () => showDSTextPrompt<void>(
                  context,
                  title: 'Your Name',
                  initialValue: name,
                  placeholder: 'Name',
                  confirmLabel: 'Save',
                  onSubmit: (value) =>
                      prefs.set(PreferenceKey.displayName, value.trim().isEmpty ? null : value.trim()),
                ),
              ),
            ],
          ),
        ),
        SliverToBoxAdapter(
          child: DSSection(
            header: 'Appearance',
            children: [
              for (final mode in ThemeMode.values)
                DSRow(
                  title: _themeLabels[mode]!,
                  subtitle: mode == ThemeMode.system ? 'Match iPhone’s appearance' : null,
                  trailing: AnimatedOpacity(
                    opacity: themeMode == mode ? 1 : 0,
                    duration: DSMotion.fast,
                    child: Icon(CupertinoIcons.checkmark_alt, color: colors.accent, size: 22),
                  ),
                  onTap: () {
                    Haptics.selection();
                    prefs.set(PreferenceKey.themeMode, mode.name);
                  },
                ),
            ],
          ),
        ),
        const SliverToBoxAdapter(
          child: DSSection(
            header: 'About',
            footer: 'Everything you create is stored on this iPhone and works offline. No account needed.',
            children: [
              DSRow(title: 'Version', value: '0.1.0'),
              DSRow(title: 'Storage', value: 'On This iPhone'),
            ],
          ),
        ),
      ],
    );
  }
}
