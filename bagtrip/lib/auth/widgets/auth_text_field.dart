import 'package:bagtrip/design/app_colors.dart';
import 'package:bagtrip/design/tokens.dart';
import 'package:bagtrip/gen/colors.gen.dart';
import 'package:bagtrip/gen/fonts.gen.dart';
import 'package:flutter/material.dart';

class AuthTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final String? hintText;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final Color? backgroundColor;
  final Color? textColor;
  final Color? hintColor;
  final Color? borderColor;
  final double borderWidth;
  final bool hasError;
  final Color? errorBorderColor;
  final Key? formFieldKey;
  final double fieldHeight;
  final BorderRadius borderRadius;

  const AuthTextField({
    super.key,
    required this.label,
    required this.controller,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.hintText,
    this.suffixIcon,
    this.prefixIcon,
    this.backgroundColor,
    this.textColor,
    this.hintColor,
    this.borderColor,
    this.borderWidth = 1.0,
    this.hasError = false,
    this.errorBorderColor,
    this.formFieldKey,
    this.fieldHeight = 48,
    this.borderRadius = AppRadius.large16,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty) ...[
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: textColor ?? ColorName.primaryTrueDark,
            ),
          ),
          const SizedBox(height: AppSpacing.space8),
        ],
        Container(
          decoration: BoxDecoration(
            color: backgroundColor ?? ColorName.primaryLight,
            borderRadius: borderRadius,
            border: hasError
                ? Border.all(
                    color: errorBorderColor ?? ColorName.error,
                    width: 1.5,
                  )
                : (borderColor != null
                      ? Border.all(color: borderColor!, width: borderWidth)
                      : null),
          ),
          child: SizedBox(
            height: fieldHeight,
            child: TextFormField(
              key: formFieldKey,
              controller: controller,
              obscureText: obscureText,
              keyboardType: keyboardType,
              validator: validator,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                fontFamily: FontFamily.dMSans,
                color: textColor ?? ColorName.primaryTrueDark,
              ),
              textAlignVertical: TextAlignVertical.center,
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  fontFamily: FontFamily.dMSans,
                  color: hintColor ?? AppColors.hint,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.space16,
                ),
                prefixIcon: prefixIcon != null
                    ? IconTheme.merge(
                        data: IconThemeData(color: hintColor ?? AppColors.hint),
                        child: prefixIcon!,
                      )
                    : null,
                suffixIcon: suffixIcon,
                prefixIconConstraints: BoxConstraints(
                  minWidth: 48,
                  minHeight: fieldHeight,
                ),
                suffixIconConstraints: BoxConstraints(
                  minWidth: 48,
                  minHeight: fieldHeight,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
