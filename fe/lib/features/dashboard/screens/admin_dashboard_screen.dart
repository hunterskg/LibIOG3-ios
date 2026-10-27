import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fe/core/theme/app_colors.dart';
import 'package:fe/core/theme/app_spacing.dart';
import 'package:fe/core/theme/app_text_styles.dart';
import 'package:fe/features/auth/domain/models/role.dart';
import 'package:fe/shared/widgets/role_guard.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/check_in_out_chart.dart';
import '../widgets/kpi_summary_grid.dart';
import '../widgets/occupancy_card.dart';
import '../widgets/time_filter_selector.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<DashboardProvider>().init();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return const RoleGuard(
      allowedRoles: [UserRole.admin, UserRole.staff],
      child: _AdminDashboardContent(),
    );
  }
}

class _AdminDashboardContent extends StatelessWidget {
  const _AdminDashboardContent();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DashboardProvider>();

    return Scaffold(
      backgroundColor: AppColors.neutral50,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        title: Text(
          'Bảng điều khiển (Dashboard)',
          style: AppTextStyles.h2.copyWith(color: AppColors.charcoal900),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.charcoal700),
            tooltip: 'Làm mới toàn bộ',
            onPressed: provider.isLoading ? null : () => provider.refresh(),
          ),
          const SizedBox(width: AppSpacing.s2),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => provider.refresh(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: AppSpacing.p5,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (provider.errorMessage != null) ...[
                      Container(
                        padding: AppSpacing.p3,
                        decoration: BoxDecoration(
                          color: AppColors.dangerLight,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.danger),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              color: AppColors.danger,
                              size: 20,
                            ),
                            const SizedBox(width: AppSpacing.s2),
                            Expanded(
                              child: Text(
                                provider.errorMessage!,
                                style: AppTextStyles.bodySm.copyWith(
                                  color: AppColors.danger,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, size: 16),
                              color: AppColors.danger,
                              onPressed: () => provider.fetchOccupancy(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.s4),
                    ],
                    OccupancyCard(
                      occupancy: provider.occupancy,
                      isLoading: provider.isLoadingOccupancy,
                      onRefresh: () => provider.fetchOccupancy(),
                    ),
                    const SizedBox(height: AppSpacing.s5),
                    Text(
                      'Thống kê lượt Ra / Vào',
                      style: AppTextStyles.h2.copyWith(color: AppColors.charcoal900),
                    ),
                    const SizedBox(height: AppSpacing.s3),
                    TimeFilterSelector(
                      selectedFilter: provider.selectedFilter,
                      selectedIntervalMin: provider.selectedIntervalMin,
                      onFilterChanged: (filter) => provider.changeFilter(filter),
                      onIntervalChanged: (interval) =>
                          provider.setIntervalMin(interval),
                    ),
                    const SizedBox(height: AppSpacing.s4),
                    KpiSummaryGrid(
                      totalCheckIn: provider.totalCheckIn,
                      totalCheckOut: provider.totalCheckOut,
                      peakPeople: provider.peakPeople,
                      lowestPeople: provider.lowestPeople,
                    ),
                    const SizedBox(height: AppSpacing.s4),
                    CheckInOutChart(
                      stats: provider.stats,
                      isLoading: provider.isLoadingStats,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
