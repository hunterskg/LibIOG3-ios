import 'package:flutter/material.dart';

import 'package:fe/core/theme/app_colors.dart';
import 'package:fe/core/theme/app_radius.dart';
import 'package:fe/core/theme/app_shadows.dart';
import 'package:fe/core/theme/app_spacing.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color backgroundColor;
  final Color borderColor;
  final VoidCallback? onTap;

  const AppCard({
    super.key,
    required this.child,
    this.padding = AppSpacing.p5,
    this.backgroundColor = AppColors.white,
    this.borderColor = AppColors.neutral200,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final decoration = BoxDecoration(
      color: backgroundColor,
      borderRadius: AppRadius.brLg,
      border: Border.all(color: borderColor),
      boxShadow: AppShadows.sm,
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        borderRadius: AppRadius.brLg,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.brLg,
          hoverColor: AppColors.neutral50,
          child: Container(
            padding: padding,
            decoration: decoration,
            child: child,
          ),
        ),
      );
    }

    return Container(
      padding: padding,
      decoration: decoration,
      child: child,
    );
  }
}
