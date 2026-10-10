import 'package:flutter/material.dart';

import 'package:fe/core/theme/app_colors.dart';
import 'package:fe/core/theme/app_spacing.dart';
import 'package:fe/core/theme/app_text_styles.dart';
import 'app_card.dart';

class AuthLayout extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  final Widget? headerAction;
  final double maxWidth;

  const AuthLayout({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
    this.headerAction,
    this.maxWidth = 480,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutral50,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: AppSpacing.p4,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo & System branding
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.charcoal800,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.local_library_rounded,
                          color: AppColors.accent500,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'LibIO',
                        style: AppTextStyles.h1.copyWith(
                          color: AppColors.charcoal900,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.s4),

                  // Main Form Card
                  AppCard(
                    padding: AppSpacing.p5,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          title,
                          style: AppTextStyles.h2.copyWith(
                            color: AppColors.charcoal900,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: AppSpacing.s2),
                          Text(
                            subtitle!,
                            style: AppTextStyles.body.copyWith(
                              color: AppColors.charcoal500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                        const SizedBox(height: AppSpacing.s5),
                        child,
                      ],
                    ),
                  ),

                  if (headerAction != null) ...[
                    const SizedBox(height: AppSpacing.s3),
                    headerAction!,
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
