import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_providers.dart';
import '../../models/inventory_item.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

/// Every manager/staff/admin can search stock across ALL stores here —
/// they just can't edit anything outside their own store (enforced in the
/// item detail screen + Firestore rules).
class GlobalSearchScreen extends ConsumerStatefulWidget {
  const GlobalSearchScreen({super.key});

  @override
  ConsumerState<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends ConsumerState<GlobalSearchScreen> {
  String _query = '';
  ItemCategory? _categoryFilter;
  bool _lowStockOnly = false;

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(allItemsProvider);
    final storesAsync = ref.watch(storesProvider);
    final storeNames = {for (final s in storesAsync.valueOrNull ?? []) s.id: s.name};

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(
                hintText: 'Search by name or SKU…',
                prefixIcon: Icon(Icons.search_rounded),
              ),
              onChanged: (v) => setState(() => _query = v.toLowerCase()),
            ),
            const SizedBox(height: AppSpacing.md),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  FilterChip(
                    label: const Text('Low stock only'),
                    selected: _lowStockOnly,
                    onSelected: (v) => setState(() => _lowStockOnly = v),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  for (final c in ItemCategory.values) ...[
                    FilterChip(
                      label: Text(c.label),
                      selected: _categoryFilter == c,
                      onSelected: (v) => setState(() => _categoryFilter = v ? c : null),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: itemsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('$e')),
                data: (items) {
                  var filtered = items.where((i) {
                    final matchesQuery = _query.isEmpty ||
                        i.name.toLowerCase().contains(_query) ||
                        i.sku.toLowerCase().contains(_query);
                    final matchesCategory = _categoryFilter == null || i.category == _categoryFilter;
                    final matchesLowStock = !_lowStockOnly || i.isLowStock;
                    return matchesQuery && matchesCategory && matchesLowStock;
                  }).toList();

                  if (filtered.isEmpty) {
                    return const EmptyState(
                      icon: Icons.search_off_rounded,
                      title: 'No matching items',
                      subtitle: 'Try a different search term or filter.',
                    );
                  }

                  return ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, i) {
                      final item = filtered[i];
                      return Card(
                        child: ListTile(
                          title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Wrap(spacing: 8, runSpacing: 6, children: [
                              CategoryTag(category: item.category),
                              Chip(
                                visualDensity: VisualDensity.compact,
                                label: Text(storeNames[item.storeId] ?? 'Unknown store'),
                                avatar: const Icon(Icons.storefront_rounded, size: 14),
                              ),
                            ]),
                          ),
                          trailing: StockPill(item: item),
                          onTap: () => context.push('/item/${item.storeId}/${item.id}'),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
