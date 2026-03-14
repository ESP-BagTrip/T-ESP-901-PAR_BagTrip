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
              color: ColorName.primaryTrueDark,
            ),
          ),
          const SizedBox(height: AppSpacing.space8),
        ],
        Container(
          decoration: BoxDecoration(
            color: backgroundColor ?? ColorName.primaryLight,
            borderRadius: AppRadius.large16,
            border: hasError
                ? Border.all(
                    color: errorBorderColor ?? ColorName.error,
                    width: 1.5,
                  )
                : (borderColor != null
                      ? Border.all(color: borderColor!, width: borderWidth)
                      : null),
          ),
          child: TextFormField(
            key: formFieldKey,
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            validator: validator,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              fontFamily: FontFamily.b612,
              color: textColor ?? ColorName.primaryTrueDark,
            ),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                fontFamily: FontFamily.b612,
                color: hintColor ?? AppColors.hint,
              ),
              border: InputBorder.none,
              contentPadding: AppSpacing.allEdgeInsetSpace16,
              prefixIcon: prefixIcon != null
                  ? IconTheme.merge(
                      data: IconThemeData(color: hintColor ?? AppColors.hint),
                      child: prefixIcon!,
                    )
                  : null,
              suffixIcon: suffixIcon,
            ),
          ),
        ),
      ],
    );
  }
}
