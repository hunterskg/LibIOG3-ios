import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fe/core/theme/app_colors.dart';
import 'package:fe/core/theme/app_spacing.dart';
import 'package:fe/core/theme/app_text_styles.dart';
import 'package:fe/features/gate/domain/models/gate.dart';
import 'package:fe/features/gate/presentation/gate_provider.dart';
import 'package:fe/shared/widgets/app_card.dart';

class GateListScreen extends StatefulWidget {
  const GateListScreen({super.key});
  @override
  State<GateListScreen> createState() => _GateListScreenState();
}

class _GateListScreenState extends State<GateListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<GateProvider>().load(),
    );
  }

  Future<void> _edit([Gate? gate]) async {
    final code = TextEditingController(text: gate?.code);
    final name = TextEditingController(text: gate?.name);
    final location = TextEditingController(text: gate?.location);
    GateStatus status = gate?.status ?? GateStatus.active;
    final save = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => AlertDialog(
          title: Text(gate == null ? 'Tạo cổng mới' : 'Cập nhật cổng'),
          content: SizedBox(
            width: 380,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: code,
                  enabled: gate == null,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'Mã cổng',
                    hintText: 'VD: GATE-01',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: name,
                  decoration: const InputDecoration(
                    labelText: 'Tên cổng',
                    hintText: 'VD: Cổng chính',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: location,
                  decoration: const InputDecoration(
                    labelText: 'Vị trí',
                    hintText: 'VD: Tầng 1, khu A',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<GateStatus>(
                  value: status,
                  decoration: const InputDecoration(labelText: 'Trạng thái'),
                  items: GateStatus.values
                      .map(
                        (x) => DropdownMenuItem(
                          value: x,
                          child: Text(
                            x == GateStatus.active ? 'Hoạt động' : 'Tạm ngưng',
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (x) => set(() => status = x!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: code.text.trim().isEmpty || name.text.trim().isEmpty
                  ? null
                  : () => Navigator.pop(ctx, true),
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );
    if (save != true || !mounted) return;
    final ok = await context.read<GateProvider>().save(
      id: gate?.id,
      code: code.text.trim(),
      name: name.text.trim(),
      location: location.text.trim().isEmpty ? null : location.text.trim(),
      status: status,
    );
    if (mounted && !ok)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.read<GateProvider>().error ?? 'Không thể lưu cổng',
          ),
          backgroundColor: AppColors.danger,
        ),
      );
  }

  Future<void> _delete(Gate gate) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa cổng?'),
        content: Text(
          'Cổng ${gate.code} sẽ bị xóa và nhân viên đang gán cổng này sẽ không còn cổng phụ trách.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (confirm == true && mounted)
      await context.read<GateProvider>().remove(gate.id);
  }

  Future<void> _assignStaff(Gate gate) async {
    final provider = context.read<GateProvider>();
    await provider.loadStaffs();
    if (!mounted) return;
    if (provider.staffs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.error ?? 'Chưa có nhân viên.')),
      );
      return;
    }
    String? selectedId = provider.staffs.first.id;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Gán nhân viên · ${gate.name}'),
          content: DropdownButtonFormField<String>(
            initialValue: selectedId,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Nhân viên'),
            items: provider.staffs
                .map(
                  (staff) => DropdownMenuItem(
                    value: staff.id,
                    child: Text(staff.name, overflow: TextOverflow.ellipsis),
                  ),
                )
                .toList(),
            onChanged: (value) => setDialogState(() => selectedId = value),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Gán cổng'),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true || selectedId == null || !mounted) return;
    final ok = await provider.assign(selectedId!, gate.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Đã gán nhân viên vào cổng.'
              : (provider.error ?? 'Gán cổng thất bại.'),
        ),
        backgroundColor: ok ? AppColors.success : AppColors.danger,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<GateProvider>();
    final active = p.gates.where((g) => g.status == GateStatus.active).length;
    return Scaffold(
      backgroundColor: AppColors.neutral50,
      appBar: AppBar(
        title: const Text('Quản lý cổng'),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.charcoal900,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: p.loading ? null : () => _edit(),
        icon: const Icon(Icons.add),
        label: const Text('Tạo cổng'),
      ),
      body: RefreshIndicator(
        onRefresh: p.load,
        child: p.loading && p.gates.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: AppSpacing.p5,
                children: [
                  AppCard(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.infoLight,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.door_front_door_outlined,
                            color: AppColors.info,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Cổng thư viện', style: AppTextStyles.h3),
                              const SizedBox(height: 2),
                              Text(
                                '${p.gates.length} cổng · $active đang hoạt động',
                                style: AppTextStyles.bodySm.copyWith(
                                  color: AppColors.charcoal500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: p.loading ? null : p.load,
                          tooltip: 'Tải lại',
                          icon: const Icon(Icons.refresh),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (p.error != null) _ErrorCard(message: p.error!),
                  if (p.gates.isEmpty && !p.loading) const _EmptyState(),
                  ...p.gates.map(
                    (gate) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _GateCard(
                        gate: gate,
                        onEdit: () => _edit(gate),
                        onDelete: () => _delete(gate),
                        onAssignStaff: () => _assignStaff(gate),
                      ),
                    ),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
      ),
    );
  }
}

class _GateCard extends StatelessWidget {
  final Gate gate;
  final VoidCallback onEdit, onDelete, onAssignStaff;
  const _GateCard({
    required this.gate,
    required this.onEdit,
    required this.onDelete,
    required this.onAssignStaff,
  });
  @override
  Widget build(BuildContext context) {
    final active = gate.status == GateStatus.active;
    final color = active ? AppColors.success : AppColors.warning;
    final bg = active ? AppColors.successLight : AppColors.warningLight;
    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              active
                  ? Icons.meeting_room_outlined
                  : Icons.door_front_door_outlined,
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(gate.name, style: AppTextStyles.h3)),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        active ? 'HOẠT ĐỘNG' : 'TẠM NGƯNG',
                        style: AppTextStyles.bodySm.copyWith(
                          color: color,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  gate.code,
                  style: AppTextStyles.mono.copyWith(
                    color: AppColors.charcoal500,
                  ),
                ),
                if (gate.location != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 16,
                          color: AppColors.charcoal400,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            gate.location!,
                            style: AppTextStyles.bodySm.copyWith(
                              color: AppColors.charcoal600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'assign') {
                onAssignStaff();
              } else if (v == 'edit') {
                onEdit();
              } else {
                onDelete();
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'assign',
                child: ListTile(
                  leading: Icon(Icons.person_add_alt_1_outlined),
                  title: Text('Gán nhân viên'),
                ),
              ),
              PopupMenuItem(
                value: 'edit',
                child: ListTile(
                  leading: Icon(Icons.edit_outlined),
                  title: Text('Chỉnh sửa'),
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  leading: Icon(Icons.delete_outline, color: AppColors.danger),
                  title: Text('Xóa', style: TextStyle(color: AppColors.danger)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) => AppCard(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Icon(
            Icons.door_front_door_outlined,
            size: 48,
            color: AppColors.charcoal400,
          ),
          const SizedBox(height: 12),
          Text('Chưa có cổng nào', style: AppTextStyles.h3),
          const SizedBox(height: 4),
          Text(
            'Tạo cổng để gán nhân viên và ghi nhận lượt ra vào.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySm.copyWith(color: AppColors.charcoal500),
          ),
        ],
      ),
    ),
  );
}

class _ErrorCard extends StatelessWidget {
  final String message;
  const _ErrorCard({required this.message});
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.dangerLight,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        const Icon(Icons.error_outline, color: AppColors.danger),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            message,
            style: AppTextStyles.bodySm.copyWith(color: AppColors.danger),
          ),
        ),
      ],
    ),
  );
}
