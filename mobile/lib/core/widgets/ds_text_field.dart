import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../../app/theme/app_theme.dart';

/// Filled single-line text field with an optional label and inline error.
class DSTextField extends StatelessWidget {
  const DSTextField({
    super.key,
    this.controller,
    this.focusNode,
    this.label,
    this.placeholder,
    this.error,
    this.autofocus = false,
    this.maxLength,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.sentences,
    this.onChanged,
    this.onSubmitted,
    this.prefix,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? label;
  final String? placeholder;
  final String? error;
  final bool autofocus;
  final int? maxLength;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final Widget? prefix;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final type = context.type;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null)
          Padding(
            padding: const EdgeInsets.only(left: DSSpacing.xxs, bottom: DSSpacing.xs),
            child: Text(label!, style: type.footnote.copyWith(color: colors.textSecondary, fontWeight: FontWeight.w500)),
          ),
        CupertinoTextField(
          controller: controller,
          focusNode: focusNode,
          autofocus: autofocus,
          placeholder: placeholder,
          prefix: prefix,
          textInputAction: textInputAction,
          textCapitalization: textCapitalization,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          maxLength: maxLength,
          maxLengthEnforcement: MaxLengthEnforcement.enforced,
          clearButtonMode: OverlayVisibilityMode.editing,
          style: type.body,
          placeholderStyle: type.body.copyWith(color: colors.textTertiary),
          cursorColor: colors.accent,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: colors.fill,
            borderRadius: BorderRadius.circular(DSRadius.md),
            border: error == null ? null : Border.all(color: colors.danger, width: 1),
          ),
        ),
        AnimatedSize(
          duration: DSMotion.medium,
          curve: DSMotion.standard,
          alignment: Alignment.topLeft,
          child: error == null
              ? const SizedBox(width: double.infinity)
              : Padding(
                  padding: const EdgeInsets.only(left: DSSpacing.xxs, top: 6),
                  child: Text(error!, style: type.footnote.copyWith(color: colors.danger)),
                ),
        ),
      ],
    );
  }
}
