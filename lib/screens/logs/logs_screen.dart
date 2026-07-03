import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_providers.dart';
import '../../models/activity_log.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

/// Full cross-store audit trail. Only rendered for Admins (also enforced by
/// Firestore security rules — see firestore.rules, `match /logs/{logId}`).
class LogsScreen extends ConsumerStatefulWidget {
  const LogsScreen({super.key});

  @override
  ConsumerState<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends ConsumerState<LogsScreen> {
  String? _storeFilter;

  Color _colorFor(LogAction a) {
    switch (a) {
      case LogAction.added:
      case LogAction.transferIn:
      case LogAction.requestApproved:
        return AppColors.success;
      case LogAction.removed:
      case LogAction.requestRejected:
        return AppColors.danger;
      case LogAction.edited:
      case LogAction.requestCreated:
        return AppColors.info;
      case LogAction.transferOut:
        return AppColors.warning;
    }
  }

  IconData _iconFor(LogAction a) {
    switch (a) {
      case LogAction.added:
        return Icons.add_circle_outline_rounded;
      case LogAction.removed:
        return Icons.remove_circle_outline_rounded;
      case LogAction.edited:
        return Icons.edit_outlined;
      case LogAction.transferIn:
        return Icons.call_received_rounded;
      case LogAction.transferOut:
        return Icons.call_made_rounded;
      case LogAction.requestCreated:
        return Icons.swap_horiz_rounded;
      case LogAction.requestApproved:
        return Icons.check_circle_outline_rounded;
      case LogAction.requestRejected:
        return Icons.cancel_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    if (user != null && !user.isAdmin) {
      return const Scaffold(
        body: EmptyState(
          icon: Icons.lock_outline_rounded,
          title: 'Admins only',
          subtitle: 'Activity logs are visible to Admin accounts.',
        ),
      );
    }

    final logsAsync = ref.watch(activityLogsProvider);
    final storesAsync = ref.watch(storesProvider);
    final storeNames = ['All stores', ...(storesAsync.valueOrNull ?? []).map((s) => s.name)];

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final name in storeNames) ...[
                    FilterChip(
                      label: Text(name),
                      selected: (_storeFilter ?? 'All stores') == name,
                      onSelected: (_) => setState(() => _storeFilter = name == 'All stores' ? null : name),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                ],
              ),
            ),
          ),
          Expanded(
            child: logsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('$e')),
              data: (logs) {
                final filtered = _storeFilter == null ? logs : logs.where((l) => l.storeName == _storeFilter).toList();
                if (filtered.isEmpty) {
                  return const EmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: 'No activity yet',
                    subtitle: 'Every add, edit, removal, and transfer will be logged here.',
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, i) {
                    final log = filtered[i];
                    final color = _colorFor(log.action);
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: color.withValues(alpha: 0.14),
                          child: Icon(_iconFor(log.action), color: color, size: 20),
                        ),
                        title: Text('${log.action.label}: ${log.itemName}', style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(
                          '${log.storeName} · by ${log.performedByName}'
                          '${log.quantityChange != null ? " · ${log.quantityChange! > 0 ? "+" : ""}${log.quantityChange}" : ""}'
                          '${log.timestamp != null ? "\n${DateFormat.MMMd().add_jm().format(log.timestamp!)}" : ""}',
                        ),
                        isThreeLine: true,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
