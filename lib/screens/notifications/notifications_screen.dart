import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_providers.dart';
import '../../models/app_notification.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  IconData _iconFor(NotificationType t) {
    switch (t) {
      case NotificationType.stockRequest:
        return Icons.swap_horiz_rounded;
      case NotificationType.requestApproved:
        return Icons.check_circle_outline_rounded;
      case NotificationType.requestRejected:
        return Icons.cancel_outlined;
      case NotificationType.lowStock:
        return Icons.warning_amber_rounded;
      case NotificationType.general:
        return Icons.notifications_none_rounded;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final notifsAsync = ref.watch(notificationsProvider);

    return Scaffold(
      body: notifsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (notifs) {
          if (notifs.isEmpty) {
            return const EmptyState(
              icon: Icons.notifications_none_rounded,
              title: 'No notifications yet',
              subtitle: 'Stock requests and alerts will appear here.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: notifs.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, i) {
              final n = notifs[i];
              return Card(
                color: n.read ? null : AppColors.surfaceDarkAlt,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.accent.withValues(alpha: 0.12),
                    child: Icon(_iconFor(n.type), color: AppColors.accent, size: 20),
                  ),
                  title: Text(n.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(
                    '${n.body}${n.createdAt != null ? "\n${DateFormat.MMMd().add_jm().format(n.createdAt!)}" : ""}',
                  ),
                  isThreeLine: true,
                  onTap: () {
                    if (!n.read && user != null) {
                      ref.read(firestoreServiceProvider).markNotificationRead(user.uid, n.id);
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
