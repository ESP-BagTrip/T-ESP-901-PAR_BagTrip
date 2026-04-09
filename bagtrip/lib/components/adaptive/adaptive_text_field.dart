import 'package:bagtrip/core/platform/adaptive_platform.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// A text field that renders [TextFormField] on Android and
/// [CupertinoTextField] on iOS.
class AdaptiveTextField extends StatelessWidget {
  const AdaptiveTextField({
    super.key,
    this.controller,
    this.placeholder,
    this.labelText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.maxLines = 1,
    this.onChanged,
    this.decoration,
    this.enabled = true,
    this.semanticLabel,
  });

  final TextEditingController? controller;
  final String? placeholder;
  final String? labelText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final int maxLines;
  final ValueChanged<String>? onChanged;
  final InputDecoration? decoration;
  final bool enabled;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final effectiveLabel = semanticLabel ?? labelText ?? placeholder;

    if (AdaptivePlatform.isIOS) {
      return Semantics(
        textField: true,
        label: effectiveLabel,
        enabled: enabled,
        child: CupertinoTextField(
          controller: controller,
          placeholder: placeholder ?? labelText,
          prefix: prefixIcon != null
              ? Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: prefixIcon,
                )
              : null,
          suffix: suffixIcon != null
              ? Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: suffixIcon,
                )
              : null,
          obscureText: obscureText,
          keyboardType: keyboardType,
          maxLines: maxLines,
          onChanged: onChanged,
          enabled: enabled,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            color: CupertinoColors.systemGrey6.resolveFrom(context),
            borderRadius: BorderRadius.circular(10),
          ),
          style: TextStyle(color: CupertinoColors.label.resolveFrom(context)),
        ),
      );
    }

    return Semantics(
      textField: true,
      label: effectiveLabel,
      enabled: enabled,
      child: TextFormField(
        controller: controller,
        decoration:
            decoration ??
            InputDecoration(
              labelText: labelText,
              hintText: placeholder,
              prefixIcon: prefixIcon,
              suffixIcon: suffixIcon,
              border: const OutlineInputBorder(),
            ),
        obscureText: obscureText,
        keyboardType: keyboardType,
        validator: validator,
        maxLines: maxLines,
        onChanged: onChanged,
        enabled: enabled,
      ),
    );
  }
}
