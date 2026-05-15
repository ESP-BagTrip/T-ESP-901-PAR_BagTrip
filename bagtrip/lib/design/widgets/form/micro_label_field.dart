import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:flutter/material.dart';

/// Rounded field with an uppercase micro-label above the input value.
class MicroLabelField extends StatelessWidget {
  const MicroLabelField({
    super.key,
    required this.label,
    this.controller,
    this.hint,
    this.prefixIcon,
    this.suffixIcon,
    this.readOnly = false,
    this.onTap,
    this.onChanged,
    this.validator,
    this.errorText,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.maxLines = 1,
    this.displayValue,
  });

  final String label;
  final TextEditingController? controller;
  final String? hint;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool readOnly;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;
  final String? errorText;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final int maxLines;

  /// When set (e.g. date picker), shown instead of the text field.
  final String? displayValue;

  BoxDecoration _fieldDecoration({required bool hasError}) {
    return BoxDecoration(
      color: ColorName.surfaceLight,
      borderRadius: AppRadius.medium12,
      border: Border.all(color: hasError ? ColorName.error : ColorName.border),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null && errorText!.isNotEmpty;

    final field = readOnly && displayValue != null
        ? GestureDetector(
            onTap: onTap,
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                if (prefixIcon != null) ...[
                  prefixIcon!,
                  const SizedBox(width: AppSpacing.space8),
                ],
                Expanded(
                  child: Text(
                    displayValue!,
                    maxLines: maxLines,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: FontFamily.b612,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: displayValue!.startsWith('--')
                          ? ColorName.hint
                          : ColorName.primaryTrueDark,
                    ),
                  ),
                ),
                if (suffixIcon != null) suffixIcon!,
              ],
            ),
          )
        : TextFormField(
            controller: controller,
            readOnly: readOnly,
            onTap: onTap,
            onChanged: onChanged,
            validator: validator,
            keyboardType: keyboardType,
            textCapitalization: textCapitalization,
            maxLines: maxLines,
            style: const TextStyle(
              fontFamily: FontFamily.b612,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: ColorName.primaryTrueDark,
            ),
            decoration: InputDecoration(
              isDense: true,
              hintText: hint,
              hintStyle: const TextStyle(
                fontFamily: FontFamily.b612,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: ColorName.hint,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
              contentPadding: EdgeInsets.zero,
              prefixIcon: prefixIcon == null
                  ? null
                  : Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.space8),
                      child: prefixIcon,
                    ),
              prefixIconConstraints: const BoxConstraints(),
              suffixIcon: suffixIcon,
              suffixIconConstraints: const BoxConstraints(minHeight: 24),
              errorStyle: const TextStyle(height: 0, fontSize: 0),
            ),
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: readOnly ? onTap : null,
            borderRadius: AppRadius.medium12,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space12,
                vertical: AppSpacing.space8,
              ),
              decoration: _fieldDecoration(hasError: hasError),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label.toUpperCase(),
                    style: const TextStyle(
                      fontFamily: FontFamily.b612,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.4,
                      color: ColorName.textMutedLight,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space4),
                  field,
                ],
              ),
            ),
          ),
        ),
        if (hasError && errorText!.length > 1)
          Padding(
            padding: const EdgeInsets.only(
              top: AppSpacing.space4,
              left: AppSpacing.space4,
            ),
            child: Text(
              errorText!,
              style: const TextStyle(
                fontFamily: FontFamily.b612,
                fontSize: 11,
                color: ColorName.error,
              ),
            ),
          ),
      ],
    );
  }
}
