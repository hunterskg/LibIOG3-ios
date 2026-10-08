import 'package:flutter/material.dart';

import 'package:fe/core/theme/app_colors.dart';
import 'package:fe/core/theme/app_radius.dart';
import 'package:fe/core/theme/app_text_styles.dart';

class AppTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final bool isPassword;
  final IconData? prefixIcon;
  final Widget? suffix;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onFieldSubmitted;
  final bool autofocus;
  final bool enabled;
  final bool isMono;
  final FocusNode? focusNode;
  final int? maxLength;
  final TextAlign textAlign;
  final bool? obscureText;

  const AppTextField({
    super.key,
    this.controller,
    this.labelText,
    this.hintText,
    this.isPassword = false,
    this.prefixIcon,
    this.suffix,
    this.validator,
    this.keyboardType,
    this.textInputAction,
    this.onFieldSubmitted,
    this.autofocus = false,
    this.enabled = true,
    this.isMono = false,
    this.focusNode,
    this.maxLength,
    this.textAlign = TextAlign.start,
    this.obscureText,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  bool _obscureText = true;

  @override
  void initState() {
    super.initState();
    if (widget.obscureText != null) {
      _obscureText = widget.obscureText!;
    }
  }

  @override
  void didUpdateWidget(AppTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.obscureText != null && widget.obscureText != oldWidget.obscureText) {
      _obscureText = widget.obscureText!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = widget.isMono ? AppTextStyles.mono : AppTextStyles.body;

    Widget? suffixIcon = widget.suffix;
    if (widget.isPassword) {
      suffixIcon = IconButton(
        icon: Icon(
          _obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          size: 20,
          color: AppColors.charcoal500,
        ),
        onPressed: () => setState(() => _obscureText = !_obscureText),
        tooltip: _obscureText ? 'Hiện mật khẩu' : 'Ẩn mật khẩu',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.labelText != null) ...[
          Text(
            widget.labelText!,
            style: AppTextStyles.bodySm.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.charcoal900,
            ),
          ),
          const SizedBox(height: 6),
        ],
        TextFormField(
          controller: widget.controller,
          focusNode: widget.focusNode,
          autofocus: widget.autofocus,
          enabled: widget.enabled,
          obscureText: widget.isPassword ? _obscureText : false,
          validator: widget.validator,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          onFieldSubmitted: widget.onFieldSubmitted,
          maxLength: widget.maxLength,
          textAlign: widget.textAlign,
          style: style.copyWith(color: AppColors.charcoal900),
          decoration: InputDecoration(
            hintText: widget.hintText,
            counterText: '',
            prefixIcon: widget.prefixIcon != null
                ? Icon(widget.prefixIcon, size: 20, color: AppColors.charcoal500)
                : null,
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: widget.enabled ? AppColors.white : AppColors.neutral100,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            enabledBorder: const OutlineInputBorder(
              borderRadius: AppRadius.brMd,
              borderSide: BorderSide(color: AppColors.neutral300),
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: AppRadius.brMd,
              borderSide: BorderSide(color: AppColors.accent500, width: 2),
            ),
            errorBorder: const OutlineInputBorder(
              borderRadius: AppRadius.brMd,
              borderSide: BorderSide(color: AppColors.danger),
            ),
            focusedErrorBorder: const OutlineInputBorder(
              borderRadius: AppRadius.brMd,
              borderSide: BorderSide(color: AppColors.danger, width: 2),
            ),
            disabledBorder: const OutlineInputBorder(
              borderRadius: AppRadius.brMd,
              borderSide: BorderSide(color: AppColors.neutral200),
            ),
          ),
        ),
      ],
    );
  }
}
