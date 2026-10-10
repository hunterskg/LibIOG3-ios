import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fe/core/theme/app_colors.dart';
import 'package:fe/core/theme/app_spacing.dart';
import 'package:fe/features/device/presentation/providers/device_provider.dart';
import 'package:fe/shared/widgets/app_button.dart';
import 'package:fe/shared/widgets/app_card.dart';
import 'package:fe/shared/widgets/app_text_field.dart';

class DeviceActivationScreen extends StatefulWidget {
  const DeviceActivationScreen({super.key});

  @override
  State<DeviceActivationScreen> createState() => _DeviceActivationScreenState();
}

class _DeviceActivationScreenState extends State<DeviceActivationScreen> {
  final _code = TextEditingController();

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _activate() async {
    if (_code.text.trim().length != 6) return;
    final result = await context.read<DeviceProvider>().activate(_code.text);
    if (!mounted) return;
    final error = context.read<DeviceProvider>().errorMessage;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result == null
              ? (error ?? 'Kích hoạt thất bại')
              : 'Thiết bị đã được cấp quyền',
        ),
        backgroundColor: result == null ? AppColors.danger : AppColors.success,
      ),
    );
    if (result != null) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DeviceProvider>();
    return Scaffold(
      backgroundColor: AppColors.neutral50,
      appBar: AppBar(
        title: const Text('Cấp quyền thiết bị'),
        backgroundColor: AppColors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.p5,
          child: AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.phonelink_lock_rounded,
                  size: 56,
                  color: AppColors.accent600,
                ),
                const SizedBox(height: AppSpacing.s3),
                const Text('Nhập mã cấp quyền do quản trị viên cung cấp.'),
                const SizedBox(height: AppSpacing.s4),
                AppTextField(
                  controller: _code,
                  labelText: 'Mã kích hoạt 6 số',
                  hintText: '000000',
                  prefixIcon: Icons.password_rounded,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                ),
                const SizedBox(height: AppSpacing.s3),
                AppButton(
                  text: 'Kích hoạt thiết bị',
                  icon: Icons.verified_user_outlined,
                  isLoading: provider.isLoading,
                  onPressed: _activate,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
