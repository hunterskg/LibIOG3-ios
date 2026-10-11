import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:fe/core/constants/route_constants.dart';
import 'package:fe/core/theme/app_colors.dart';
import 'package:fe/core/theme/app_spacing.dart';
import 'package:fe/core/theme/app_text_styles.dart';
import 'package:fe/features/user/presentation/providers/user_provider.dart';
import 'package:fe/shared/widgets/app_card.dart';
import 'package:fe/shared/widgets/app_text_field.dart';

class ReaderListScreen extends StatefulWidget {
  const ReaderListScreen({super.key});

  @override
  State<ReaderListScreen> createState() => _ReaderListScreenState();
}

class _ReaderListScreenState extends State<ReaderListScreen> {
  final _searchCtrl = TextEditingController();
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      context.read<UserProvider>().loadReaders(page: 1);
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
    final page = provider.readersPage;
    final items = page?.data ?? [];

    return Scaffold(
      backgroundColor: AppColors.neutral50,
      appBar: AppBar(
        title: const Text('Danh sách độc giả'),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.charcoal900,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: AppTextField(
                controller: _searchCtrl,
                hintText: 'Tìm theo họ tên, SĐT...',
                prefixIcon: Icons.search_rounded,
                textInputAction: TextInputAction.search,
                onFieldSubmitted: (v) {
                  context.read<UserProvider>().loadReaders(page: 1, search: v);
                },
                suffix: IconButton(
                  icon: const Icon(
                    Icons.search_rounded,
                    color: AppColors.charcoal500,
                  ),
                  tooltip: 'Tìm kiếm',
                  onPressed: () {
                    context.read<UserProvider>().loadReaders(
                      page: 1,
                      search: _searchCtrl.text,
                    );
                  },
                ),
              ),
            ),
            Expanded(
              child: provider.isLoading && page == null
                  ? const Center(child: CircularProgressIndicator())
                  : items.isEmpty
                  ? Center(
                      child: Text(
                        provider.errorMessage ?? 'Chưa có độc giả nào.',
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
                        final r = items[i];
                        return AppCard(
                          padding: AppSpacing.p4,
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              AppRoutes.readerDetail,
                              arguments: {'id': r.id},
                            );
                          },
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: AppColors.accent100,
                                child: const Icon(
                                  Icons.person_outline_rounded,
                                  color: AppColors.accent600,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.s3),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      r.fullName,
                                      style: AppTextStyles.body.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      r.phone ?? r.user?.email ?? '---',
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
                          provider.readerCurrentPage > 1 && !provider.isLoading
                          ? () => context.read<UserProvider>().loadReaders(
                              page: provider.readerCurrentPage - 1,
                            )
                          : null,
                      child: const Text('Trước'),
                    ),
                    Text(
                      'Trang ${provider.readerCurrentPage} • Tổng ${page.total}',
                      style: AppTextStyles.bodySm,
                    ),
                    TextButton(
                      onPressed: !provider.isLoading
                          ? () => context.read<UserProvider>().loadReaders(
                              page: provider.readerCurrentPage + 1,
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
}
