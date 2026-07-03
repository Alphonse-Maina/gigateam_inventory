import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:collection/collection.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class ItemDetailScreen extends ConsumerWidget {
  final String storeId;
  final String itemId;
  const ItemDetailScreen({super.key, required this.storeId, required this.itemId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final itemsAsync = ref.watch(storeItemsProvider(storeId));
    final canEdit = user != null && user.canEditStore(storeId);
    final currency = NumberFormat.simpleCurrency();

    return Scaffold(
      appBar: AppBar(
        actions: [
          if (canEdit)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => context.push('/item/$storeId/$itemId/edit'),
            ),
        ],
      ),
      body: itemsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (items) {
          final item = items.firstWhereOrNull((i) => i.id == itemId);
          if (item == null) {
            return const EmptyState(
              icon: Icons.search_off_rounded,
              title: 'Item not found',
              subtitle: 'It may have been removed.',
            );
          }
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              Row(
                children: [
                  CategoryTag(category: item.category),
                  const SizedBox(width: AppSpacing.sm),
                  StockPill(item: item),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(item.name, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 4),
              Text('SKU ${item.sku}${item.brand != null ? " · ${item.brand}" : ""}',
                  style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: AppSpacing.xl),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    children: [
                      _row('Quantity on hand', '${item.quantity}'),
                      const Divider(height: AppSpacing.xl),
                      _row('Low-stock threshold', '${item.minThreshold}'),
                      const Divider(height: AppSpacing.xl),
                      _row('Unit price', currency.format(item.unitPrice)),
                      if (item.updatedAt != null) ...[
                        const Divider(height: AppSpacing.xl),
                        _row('Last updated', DateFormat.yMMMd().add_jm().format(item.updatedAt!)),
                      ],
                      if (item.updatedByName != null) ...[
                        const Divider(height: AppSpacing.xl),
                        _row('Updated by', item.updatedByName!),
                      ],
                    ],
                  ),
                ),
              ),
              if (item.description != null && item.description!.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                Text('Description', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: AppSpacing.xs),
                Text(item.description!),
              ],
              const SizedBox(height: AppSpacing.xxl),
              if (!canEdit)
                OutlinedButton.icon(
                  onPressed: () => context.push('/request/new', extra: {
                    'itemId': item.id,
                    'itemName': item.name,
                    'fromStoreId': item.storeId,
                  }),
                  icon: const Icon(Icons.swap_horiz_rounded),
                  label: const Text('Request stock from this store'),
                ),
              if (canEdit)
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger),
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Delete item?'),
                        content: Text('This removes "${item.name}" from ${item.storeId}. This can\'t be undone.'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Delete', style: TextStyle(color: AppColors.danger)),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true && user != null) {
                      await ref.read(firestoreServiceProvider).deleteItem(storeId, item, actor: user);
                      if (context.mounted) context.pop();
                    }
                  },
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: const Text('Delete item'),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _row(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }
}
