import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers/core_providers.dart';
import '../../app/theme/app_theme.dart';
import '../../core/errors/app_exception.dart';
import '../../core/repositories/preferences_repository.dart';
import '../../core/services/haptics.dart';
import '../../core/widgets/widgets.dart';
import '../../shared/widgets/devspace_mark.dart';
import '../../shared/widgets/emoji_grid.dart';

/// First-run welcome: asks for a name to greet the user by and creates the
/// first workspace. The router moves on to Home as soon as it exists.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _name = TextEditingController();
  final _workspace = TextEditingController(text: 'Personal');
  String _icon = '🚀';
  String? _workspaceError;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _workspace.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _workspaceError = null;
    });
    try {
      final displayName = _name.text.trim();
      if (displayName.isNotEmpty) {
        await ref.read(preferencesRepositoryProvider).set(PreferenceKey.displayName, displayName);
      }
      await ref.read(workspaceServiceProvider).create(name: _workspace.text, icon: _icon);
      Haptics.success();
    } on ValidationException catch (e) {
      Haptics.warning();
      setState(() => _workspaceError = e.fieldErrors['name'] ?? e.message);
    } catch (e) {
      if (mounted) DSToast.error(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final type = context.type;
    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(DSSpacing.xl, DSSpacing.xxxl, DSSpacing.xl, DSSpacing.xl),
                children: [
                  _Reveal(delay: 0, child: const Align(alignment: Alignment.centerLeft, child: DevSpaceMark(size: 64))),
                  const SizedBox(height: DSSpacing.xl),
                  _Reveal(delay: 80, child: Text('Welcome to\nDevSpace', style: type.largeTitle)),
                  const SizedBox(height: DSSpacing.sm),
                  _Reveal(
                    delay: 140,
                    child: Text(
                      'Tasks, notes, docs and sketches for your projects. Everything stays on this iPhone and works offline.',
                      style: type.body.copyWith(color: colors.textSecondary),
                    ),
                  ),
                  const SizedBox(height: DSSpacing.xxl),
                  _Reveal(
                    delay: 220,
                    child: DSTextField(
                      controller: _name,
                      label: 'What should we call you?',
                      placeholder: 'Your name (optional)',
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      maxLength: 40,
                    ),
                  ),
                  const SizedBox(height: DSSpacing.lg),
                  _Reveal(
                    delay: 280,
                    child: DSTextField(
                      controller: _workspace,
                      label: 'Name your first workspace',
                      placeholder: 'e.g. Personal, Side Projects',
                      error: _workspaceError,
                      maxLength: 60,
                      textInputAction: TextInputAction.done,
                      onChanged: (_) {
                        if (_workspaceError != null) setState(() => _workspaceError = null);
                      },
                      onSubmitted: (_) => _start(),
                      prefix: Padding(
                        padding: const EdgeInsets.only(left: 12),
                        child: Text(_icon, style: const TextStyle(fontSize: 20)),
                      ),
                    ),
                  ),
                  const SizedBox(height: DSSpacing.lg),
                  _Reveal(
                    delay: 340,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: DSSpacing.xxs, bottom: DSSpacing.xs),
                          child: Text(
                            'Pick an icon',
                            style: type.footnote.copyWith(color: colors.textSecondary, fontWeight: FontWeight.w500),
                          ),
                        ),
                        EmojiGrid(selected: _icon, onSelected: (v) => setState(() => _icon = v)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(DSSpacing.xl, DSSpacing.xs, DSSpacing.xl, DSSpacing.md),
              child: ValueListenableBuilder(
                valueListenable: _workspace,
                builder: (context, value, _) => DSButton(
                  label: 'Get Started',
                  icon: CupertinoIcons.arrow_right,
                  expand: true,
                  loading: _busy,
                  onPressed: value.text.trim().isEmpty ? null : _start,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Fades and lifts its child into place after [delay] milliseconds.
class _Reveal extends StatefulWidget {
  const _Reveal({required this.delay, required this.child});

  final int delay;
  final Widget child;

  @override
  State<_Reveal> createState() => _RevealState();
}

class _RevealState extends State<_Reveal> with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 520));
  late final _curve = CurvedAnimation(parent: _controller, curve: DSMotion.emphasized);

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _curve.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _curve,
      child: SlideTransition(
        position: Tween(begin: const Offset(0, 0.15), end: Offset.zero).animate(_curve),
        child: widget.child,
      ),
    );
  }
}
