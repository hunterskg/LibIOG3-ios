import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:fe/core/constants/route_constants.dart';
import 'package:fe/core/theme/app_colors.dart';
import 'package:fe/core/theme/app_spacing.dart';
import 'package:fe/core/theme/app_text_styles.dart';
import 'package:fe/features/user/presentation/providers/user_provider.dart';
import 'package:fe/shared/widgets/app_card.dart';
import 'package:fe/shared/widgets/app_text_field.dart';

class StaffListScreen extends StatefulWidget {
  const StaffListScreen({super.key});

  @override
  State<StaffListScreen> createState() => _StaffListScreenState();
}

class _StaffListScreenState extends State<StaffListScreen> {
  final _searchCtrl = TextEditingController();
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      context.read<UserProvider>().loadStaffs(page: 1);
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<UserProvider>();
    final page = provider.staffsPage;
    final items = page?.data ?? [];

    return Scaffold(
      backgroundColor: AppColors.neutral50,
      appBar: AppBar(
        title: const Text('Quản lý nhân sự'),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.charcoal900,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.pushNamed(context, AppRoutes.createStaff);
          if (context.mounted) {
            await context.read<UserProvider>().loadStaffs(page: 1);
          }
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Thêm nhân viên'),
        backgroundColor: AppColors.charcoal900,
        foregroundColor: AppColors.white,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: AppTextField(
                controller: _searchCtrl,
                hintText: 'Tìm theo tên nhân viên...',
                prefixIcon: Icons.search_rounded,
                textInputAction: TextInputAction.search,
                onFieldSubmitted: (v) {
                  context.read<UserProvider>().loadStaffs(page: 1, search: v);
                },
                suffix: IconButton(
                  icon: const Icon(
                    Icons.search_rounded,
                    color: AppColors.charcoal500,
                  ),
                  tooltip: 'Tìm kiếm',
                  onPressed: () {
                    context.read<UserProvider>().loadStaffs(
                      page: 1,
                      search: _searchCtrl.text,
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  _roleChip(context, label: 'Tất cả', value: ''),
                  const SizedBox(width: 8),
                  _roleChip(context, label: 'STAFF', value: 'staff'),
                  const SizedBox(width: 8),
                  _roleChip(context, label: 'ADMIN', value: 'admin'),
                ],
              ),
            ),
            Expanded(
              child: provider.isLoading && page == null
                  ? const Center(child: CircularProgressIndicator())
                  : items.isEmpty
                  ? Center(
                      child: Text(
                        provider.errorMessage ?? 'Chưa có nhân viên nào.',
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.charcoal500,
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: AppSpacing.p4,
                      itemCount: items.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 8),
                      itemBuilder: (context, i) {
                        final s = items[i];
                        final roleLabel =
                            s.user?.role.value.toUpperCase() ?? 'STAFF';
                        return AppCard(
                          padding: AppSpacing.p4,
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              AppRoutes.staffDetail,
                              arguments: {'id': s.id},
                            );
                          },
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: AppColors.successLight,
                                child: const Icon(
                                  Icons.badge_outlined,
                                  color: AppColors.success,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.s3),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      s.name,
                                      style: AppTextStyles.body.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${s.user?.email ?? '---'} • $roleLabel',
                                      style: AppTextStyles.bodySm.copyWith(
                                        color: AppColors.charcoal500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right_rounded,
                                color: AppColors.charcoal400,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            if (page != null && page.total > page.data.length)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed:
                          provider.staffCurrentPage > 1 && !provider.isLoading
                          ? () => context.read<UserProvider>().loadStaffs(
                              page: provider.staffCurrentPage - 1,
                            )
                          : null,
                      child: const Text('Trước'),
                    ),
                    Text(
                      'Trang ${provider.staffCurrentPage} • Tổng ${page.total}',
                      style: AppTextStyles.bodySm,
                    ),
                    TextButton(
                      onPressed: !provider.isLoading
                          ? () => context.read<UserProvider>().loadStaffs(
                              page: provider.staffCurrentPage + 1,
                            )
                          : null,
                      child: const Text('Sau'),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _roleChip(
    BuildContext context, {
    required String label,
    required String value,
  }) {
    final provider = context.watch<UserProvider>();
    final active =
        (provider.staffRoleFilter ?? '') == value ||
        (value.isEmpty && provider.staffRoleFilter == null);
    return FilterChip(
      label: Text(label),
      selected: active,
      onSelected: (_) {
        context.read<UserProvider>().loadStaffs(
          page: 1,
          role: value,
          search: _searchCtrl.text,
        );
      },
      selectedColor: AppColors.charcoal900,
      labelStyle: TextStyle(
        color: active ? AppColors.white : AppColors.charcoal900,
      ),
    );
  }
}
