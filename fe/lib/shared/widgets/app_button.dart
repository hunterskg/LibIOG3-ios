import 'package:flutter/material.dart';

import 'package:fe/core/theme/app_colors.dart';
import 'package:fe/core/theme/app_radius.dart';
import 'package:fe/core/theme/app_text_styles.dart';

enum AppButtonVariant { primary, secondary, ghost, danger }
enum AppButtonSize { sm, md, lg }

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final bool isLoading;
  final IconData? icon;
  final bool isFullWidth;

  const AppButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.md,
    this.isLoading = false,
    this.icon,
    this.isFullWidth = true,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveOnPressed = isLoading ? null : onPressed;

    final double height;
    final EdgeInsets padding;
    switch (size) {
      case AppButtonSize.sm:
        height = 32;
        padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 6);
        break;
      case AppButtonSize.md:
        height = 40;
        padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 10);
        break;
      case AppButtonSize.lg:
        height = 48;
        padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 14);
        break;
    }

    Widget content;
    final spinnerColor = _spinnerColor;
    if (isLoading) {
      content = SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(spinnerColor),
        ),
      );
    } else if (icon != null) {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Text(text),
        ],
      );
    } else {
      content = Text(text);
    }

    Widget btn;
    switch (variant) {
      case AppButtonVariant.primary:
        btn = ElevatedButton(
          onPressed: effectiveOnPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.charcoal800,
            foregroundColor: AppColors.white,
            disabledBackgroundColor: AppColors.charcoal400,
            disabledForegroundColor: AppColors.neutral200,
            shape: const RoundedRectangleBorder(borderRadius: AppRadius.brMd),
            padding: padding,
            textStyle: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
            elevation: 0,
          ),
          child: content,
        );
        break;
      case AppButtonVariant.secondary:
        btn = OutlinedButton(
          onPressed: effectiveOnPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.charcoal900,
            side: const BorderSide(color: AppColors.neutral300),
            shape: const RoundedRectangleBorder(borderRadius: AppRadius.brMd),
            padding: padding,
            textStyle: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
          ),
          child: content,
        );
        break;
      case AppButtonVariant.ghost:
        btn = TextButton(
          onPressed: effectiveOnPressed,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.charcoal500,
            shape: const RoundedRectangleBorder(borderRadius: AppRadius.brMd),
            padding: padding,
            textStyle: AppTextStyles.body.copyWith(fontWeight: FontWeight.w500),
          ),
          child: content,
        );
        break;
      case AppButtonVariant.danger:
        btn = ElevatedButton(
          onPressed: effectiveOnPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.danger,
            foregroundColor: AppColors.white,
            disabledBackgroundColor: AppColors.dangerLight,
            disabledForegroundColor: AppColors.neutral300,
            shape: const RoundedRectangleBorder(borderRadius: AppRadius.brMd),
            padding: padding,
            textStyle: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
            elevation: 0,
          ),
          child: content,
        );
        break;
    }

    return SizedBox(
      height: height,
      width: isFullWidth ? double.infinity : null,
      child: btn,
    );
  }

  Color get _spinnerColor {
    switch (variant) {
      case AppButtonVariant.primary:
      case AppButtonVariant.danger:
        return AppColors.white;
      case AppButtonVariant.secondary:
        return AppColors.charcoal800;
      case AppButtonVariant.ghost:
        return AppColors.charcoal500;
    }
  }
}
