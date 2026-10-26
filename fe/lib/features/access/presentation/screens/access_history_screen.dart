import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:fe/core/network/api_client.dart';
import 'package:fe/core/network/api_exception.dart';
import 'package:fe/core/theme/app_colors.dart';
import 'package:fe/core/theme/app_spacing.dart';
import 'package:fe/core/theme/app_text_styles.dart';
import 'package:fe/features/access/data/services/access_api_service.dart';
import 'package:fe/features/auth/domain/models/role.dart';
import 'package:fe/shared/widgets/app_card.dart';
import 'package:fe/shared/widgets/app_text_field.dart';
import 'package:fe/shared/widgets/role_guard.dart';
import 'package:fe/shared/widgets/status_badge.dart';

class AccessHistoryScreen extends StatefulWidget {
  const AccessHistoryScreen({super.key});

  @override
  State<AccessHistoryScreen> createState() => _AccessHistoryScreenState();
}

class _AccessHistoryScreenState extends State<AccessHistoryScreen> {
  final _searchCtrl = TextEditingController();
  late final AccessApiService _accessService;

  bool _initialized = false;
  bool _loading = true;
  String? _errorMsg;

  String _selectedAction = '';
  String _selectedMethod = '';
  int _page = 1;
  int _total = 0;
  int _totalPages = 1;
  List<Map<String, dynamic>> _logs = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _accessService = AccessApiService(context.read<ApiClient>());
      _loadLogs(page: 1);
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadLogs({int page = 1}) async {
    setState(() {
      _loading = true;
      _errorMsg = null;
    });

    try {
      final res = await _accessService.getAccessLogs(
        page: page,
        size: 20,
        action: _selectedAction.isEmpty ? null : _selectedAction,
        method: _selectedMethod.isEmpty ? null : _selectedMethod,
        search: _searchCtrl.text.trim(),
      );

      if (!mounted) return;
      final list = res['data'] is List
          ? (res['data'] as List).whereType<Map<String, dynamic>>().toList()
          : <Map<String, dynamic>>[];

      setState(() {
        _logs = list;
        _page = (res['page'] as num?)?.toInt() ?? page;
        _total = (res['total'] as num?)?.toInt() ?? list.length;
        _totalPages = (res['totalPages'] as num?)?.toInt() ?? 1;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMsg = e.message;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMsg = 'Lỗi tải lịch sử: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return RoleGuard(
      allowedRoles: const [UserRole.admin, UserRole.staff],
      child: Scaffold(
        backgroundColor: AppColors.neutral50,
        appBar: AppBar(
          title: const Text('Lịch sử Ra / Vào Thư viện'),
          backgroundColor: AppColors.white,
          foregroundColor: AppColors.charcoal900,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Làm mới',
              onPressed: _loading ? null : () => _loadLogs(page: _page),
            ),
          ],
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 850),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AppTextField(
                          controller: _searchCtrl,
                          hintText: 'Tìm theo tên bạn đọc, email, hoặc lý do...',
                          prefixIcon: Icons.search_rounded,
                          textInputAction: TextInputAction.search,
                          onFieldSubmitted: (_) => _loadLogs(page: 1),
                          suffix: IconButton(
                            icon: const Icon(
                              Icons.search_rounded,
                              color: AppColors.charcoal500,
                            ),
                            onPressed: () => _loadLogs(page: 1),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _filterChip(
                                label: 'Tất cả hành động',
                                selected: _selectedAction.isEmpty,
                                onTap: () {
                                  setState(() => _selectedAction = '');
                                  _loadLogs(page: 1);
                                },
                              ),
                              const SizedBox(width: 6),
                              _filterChip(
                                label: 'Check-in',
                                selected: _selectedAction == 'CHECK_IN',
                                onTap: () {
                                  setState(() => _selectedAction = 'CHECK_IN');
                                  _loadLogs(page: 1);
                                },
                              ),
                              const SizedBox(width: 6),
                              _filterChip(
                                label: 'Check-out',
                                selected: _selectedAction == 'CHECK_OUT',
                                onTap: () {
                                  setState(() => _selectedAction = 'CHECK_OUT');
                                  _loadLogs(page: 1);
                                },
                              ),
                              const SizedBox(width: 6),
                              _filterChip(
                                label: 'Auto Check-out',
                                selected: _selectedAction == 'AUTO_CHECK_OUT',
                                onTap: () {
                                  setState(
                                    () => _selectedAction = 'AUTO_CHECK_OUT',
                                  );
                                  _loadLogs(page: 1);
                                },
                              ),
                              const SizedBox(width: 16),
                              _filterChip(
                                label: 'Mọi phương thức',
                                selected: _selectedMethod.isEmpty,
                                onTap: () {
                                  setState(() => _selectedMethod = '');
                                  _loadLogs(page: 1);
                                },
                              ),
                              const SizedBox(width: 6),
                              _filterChip(
                                label: 'QR',
                                selected: _selectedMethod == 'QR',
                                onTap: () {
                                  setState(() => _selectedMethod = 'QR');
                                  _loadLogs(page: 1);
                                },
                              ),
                              const SizedBox(width: 6),
                              _filterChip(
                                label: 'FACE',
                                selected: _selectedMethod == 'FACE',
                                onTap: () {
                                  setState(() => _selectedMethod = 'FACE');
                                  _loadLogs(page: 1);
                                },
                              ),
                              const SizedBox(width: 6),
                              _filterChip(
                                label: 'MANUAL',
                                selected: _selectedMethod == 'MANUAL',
                                onTap: () {
                                  setState(() => _selectedMethod = 'MANUAL');
                                  _loadLogs(page: 1);
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _loading
                        ? const Center(child: CircularProgressIndicator())
                        : _errorMsg != null
                        ? Center(
                            child: Text(
                              _errorMsg!,
                              style: AppTextStyles.body.copyWith(
                                color: AppColors.danger,
                              ),
                            ),
                          )
                        : _logs.isEmpty
                        ? Center(
                            child: Text(
                              'Chưa có bản ghi lịch sử ra/vào nào.',
                              style: AppTextStyles.body.copyWith(
                                color: AppColors.charcoal500,
                              ),
                            ),
                          )
                        : ListView.separated(
                            padding: AppSpacing.p4,
                            itemCount: _logs.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final item = _logs[index];
                              return _buildLogCard(item);
                            },
                          ),
                  ),
                  if (_totalPages > 1)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextButton(
                            onPressed: _page > 1 && !_loading
                                ? () => _loadLogs(page: _page - 1)
                                : null,
                            child: const Text('Trước'),
                          ),
                          Text(
                            'Trang $_page / $_totalPages • Tổng $_total lượt',
                            style: AppTextStyles.bodySm,
                          ),
                          TextButton(
                            onPressed: _page < _totalPages && !_loading
                                ? () => _loadLogs(page: _page + 1)
                                : null,
                            child: const Text('Sau'),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _filterChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      selectedColor: AppColors.accent100,
      onSelected: (_) => onTap(),
    );
  }

  Widget _buildLogCard(Map<String, dynamic> item) {
    final action = item['action']?.toString() ?? '';
    final method = item['method']?.toString() ?? '';
    final reason = item['reason']?.toString();
    final staffName = item['staffName']?.toString();
    final gateName = item['gateName']?.toString();

    final dt = DateTime.tryParse(
      item['occurredAt']?.toString() ?? '',
    )?.toLocal();
    final timeStr = dt != null
        ? DateFormat('HH:mm:ss dd/MM/yyyy').format(dt)
        : '---';

    final isCheckIn = action == 'CHECK_IN';
    final isAutoOut = action == 'AUTO_CHECK_OUT';

    final Color badgeColor = isCheckIn
        ? AppColors.success
        : isAutoOut
        ? AppColors.warning
        : AppColors.info;
    final Color badgeBg = isCheckIn
        ? AppColors.successLight
        : isAutoOut
        ? AppColors.warningLight
        : AppColors.infoLight;

    return AppCard(
      padding: AppSpacing.p4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: badgeBg,
                child: Icon(
                  isCheckIn
                      ? Icons.login_rounded
                      : isAutoOut
                      ? Icons.timer_off_outlined
                      : Icons.logout_rounded,
                  color: badgeColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['readerName']?.toString() ?? '---',
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      item['readerEmail']?.toString() ?? '---',
                      style: AppTextStyles.bodySm.copyWith(
                        color: AppColors.charcoal500,
                      ),
                    ),
                  ],
                ),
              ),
              StatusBadge(
                label: '$action ($method)',
                color: badgeColor,
                backgroundColor: badgeBg,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 16,
            runSpacing: 4,
            children: [
              Text(
                'Thời gian: $timeStr',
                style: AppTextStyles.bodySm.copyWith(
                  color: AppColors.charcoal600,
                ),
              ),
              if (gateName != null && gateName.isNotEmpty)
                Text(
                  'Cổng: $gateName',
                  style: AppTextStyles.bodySm.copyWith(
                    color: AppColors.charcoal600,
                  ),
                ),
              if (staffName != null && staffName.isNotEmpty)
                Text(
                  'Người duyệt: $staffName',
                  style: AppTextStyles.bodySm.copyWith(
                    color: AppColors.charcoal600,
                  ),
                ),
            ],
          ),
          if (reason != null && reason.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Lý do: $reason',
              style: AppTextStyles.bodySm.copyWith(
                color: AppColors.accent600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
