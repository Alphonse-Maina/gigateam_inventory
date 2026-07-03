import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_providers.dart';
import '../../models/store.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class StoreListScreen extends ConsumerWidget {
  const StoreListScreen({super.key});

  void _showAddStoreSheet(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          top: AppSpacing.lg,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Add store', style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.lg),
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Store name')),
            const SizedBox(height: AppSpacing.md),
            TextField(controller: addressCtrl, decoration: const InputDecoration(labelText: 'Address')),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Phone (for tap-to-call)'),
            ),
            const SizedBox(height: AppSpacing.xl),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty) return;
                await ref.read(firestoreServiceProvider).createStore(
                      Store(id: '', name: nameCtrl.text.trim(), address: addressCtrl.text.trim(), phone: phoneCtrl.text.trim()),
                    );
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Create store'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final storesAsync = ref.watch(storesProvider);

    return Scaffold(
      floatingActionButton: user?.isAdmin == true
          ? FloatingActionButton.extended(
              onPressed: () => _showAddStoreSheet(context, ref),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add store'),
            )
          : null,
      body: storesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load stores: $e')),
        data: (stores) {
          if (stores.isEmpty) {
            return const EmptyState(
              icon: Icons.storefront_outlined,
              title: 'No stores yet',
              subtitle: 'Tap "Add store" to create your first location.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: stores.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (context, i) {
              final store = stores[i];
              return Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.all(AppSpacing.md),
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: const Icon(Icons.storefront_rounded, color: AppColors.accent),
                  ),
                  title: Text(store.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('${store.address}\nManager: ${store.managerName ?? "Unassigned"}'),
                  ),
                  isThreeLine: true,
                  trailing: store.phone == null || store.phone!.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.call_rounded, color: AppColors.success),
                          onPressed: () => launchUrl(Uri.parse('tel:${store.phone}')),
                        ),
                  onTap: () => context.push('/stores/${store.id}'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
