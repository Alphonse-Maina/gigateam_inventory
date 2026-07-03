import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:collection/collection.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class StoreDetailScreen extends ConsumerWidget {
  final String storeId;
  const StoreDetailScreen({super.key, required this.storeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final storesAsync = ref.watch(storesProvider);
    final itemsAsync = ref.watch(storeItemsProvider(storeId));
    final canEdit = user != null && user.canEditStore(storeId);

    final store = storesAsync.valueOrNull?.where((s) => s.id == storeId).firstOrNull;

    return Scaffold(
      appBar: AppBar(
        title: Text(store?.name ?? 'Store'),
        actions: [
          if (store?.phone != null && store!.phone!.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.call_outlined),
              onPressed: () => launchUrl(Uri.parse('tel:${store.phone}')),
              tooltip: 'Call store',
            ),
        ],
      ),
      floatingActionButton: canEdit
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/item/$storeId/new'),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add item'),
            )
          : null,
      body: Column(
        children: [
          if (store != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
              child: Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(child: Text(store.address, style: const TextStyle(color: Colors.grey))),
                  if (!canEdit)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.borderDark,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text('View only', style: TextStyle(fontSize: 11)),
                    ),
                ],
              ),
            ),
          Expanded(
            child: itemsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Failed to load inventory: $e')),
              data: (items) {
                if (items.isEmpty) {
                  return const EmptyState(
                    icon: Icons.inventory_2_outlined,
                    title: 'No items yet',
                    subtitle: 'Items added to this store will show up here.',
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, i) {
                    final item = items[i];
                    return Card(
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
                        title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Wrap(spacing: 8, runSpacing: 6, children: [
                            CategoryTag(category: item.category),
                            Text('SKU ${item.sku}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          ]),
                        ),
                        trailing: StockPill(item: item),
                        onTap: () => context.push('/item/$storeId/${item.id}'),
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
