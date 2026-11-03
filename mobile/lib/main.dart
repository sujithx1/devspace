import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'app/providers/preferences_providers.dart';
import 'app/providers/workspace_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load what the first frame depends on while the launch screen is still up,
  // so the app opens straight into the right theme and screen.
  final container = ProviderContainer();
  final startup = <StreamProvider<Object?>>[
    workspacesProvider,
    activeWorkspaceIdProvider,
    themeModeProvider,
    displayNameProvider,
  ];
  // Riverpod pauses providers nobody listens to, so hold a listener on each.
  for (final provider in startup) {
    container.listen(provider, (_, _) {});
  }
  await Future.wait([for (final provider in startup) container.read(provider.future)]);

  runApp(UncontrolledProviderScope(container: container, child: const DevSpaceApp()));
}
