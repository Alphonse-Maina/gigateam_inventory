import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final storesAsync = ref.watch(storesProvider);
    final itemsAsync = ref.watch(allItemsProvider);
    final requestsAsync = user?.isAdmin == true
        ? ref.watch(allRequestsProvider)
        : ref.watch(incomingRequestsProvider);

    final items = itemsAsync.valueOrNull ?? [];
    final stores = storesAsync.valueOrNull ?? [];
    final lowStock = items.where((i) => i.isLowStock).toList();
    final pendingRequests = (requestsAsync.valueOrNull ?? []).where((r) => r.status.name == 'pending').length;
    final isWide = MediaQuery.of(context).size.width >= 700;

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              Text('Welcome back${user != null ? ', ${user.name.split(' ').first}' : ''}',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 4),
              Text(
                user == null
                    ? ''
                    : (user.isAdmin
                        ? 'Here\'s what\'s happening across every store.'
                        : 'Here\'s what\'s happening at your store.'),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
              ),
              const SizedBox(height: AppSpacing.xl),
              GridView.count(
                crossAxisCount: isWide ? 4 : 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: AppSpacing.md,
                mainAxisSpacing: AppSpacing.md,
                childAspectRatio: 1.35,
                children: [
                  StatCard(
                    label: 'Stores',
                    value: '${stores.length}',
                    icon: Icons.storefront_rounded,
                    color: AppColors.info,
                    onTap: () => context.go('/stores'),
                  ),
                  StatCard(
                    label: 'Total items tracked',
                    value: '${items.length}',
                    icon: Icons.inventory_2_rounded,
                    color: AppColors.accent,
                    onTap: () => context.go('/search'),
                  ),
                  StatCard(
                    label: 'Low / out of stock',
                    value: '${lowStock.length}',
                    icon: Icons.warning_amber_rounded,
                    color: AppColors.warning,
                    onTap: () => context.go('/search'),
                  ),
                  StatCard(
                    label: 'Pending requests',
                    value: '$pendingRequests',
                    icon: Icons.swap_horiz_rounded,
                    color: AppColors.roleManager,
                    onTap: () => context.go('/requests'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              SectionHeader(
                title: 'Needs attention',
                action: TextButton(onPressed: () => context.go('/search'), child: const Text('View all')),
              ),
              if (lowStock.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.lg),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle_rounded, color: AppColors.success),
                        SizedBox(width: AppSpacing.md),
                        Expanded(child: Text('All stock levels look healthy across every store.')),
                      ],
                    ),
                  ),
                )
              else
                Card(
                  child: Column(
                    children: [
                      for (final item in lowStock.take(6))
                        ListTile(
                          leading: CategoryTag(category: item.category),
                          title: Text(item.name),
                          subtitle: Text('SKU ${item.sku}'),
                          trailing: StockPill(item: item),
                          onTap: () => context.push('/item/${item.storeId}/${item.id}'),
                        ),
                    ],
                  ),
                ),
              const SizedBox(height: AppSpacing.xl),
              SectionHeader(
                title: 'Stores',
                action: TextButton(onPressed: () => context.go('/stores'), child: const Text('View all')),
              ),
              if (stores.isEmpty)
                const EmptyState(
                  icon: Icons.storefront_outlined,
                  title: 'No stores yet',
                  subtitle: 'An admin needs to add the first store to get started.',
                )
              else
                Wrap(
                  spacing: AppSpacing.md,
                  runSpacing: AppSpacing.md,
                  children: [
                    for (final store in stores)
                      SizedBox(
                        width: isWide ? 260 : double.infinity,
                        child: Card(
                          child: ListTile(
                            leading: const CircleAvatar(child: Icon(Icons.storefront_rounded)),
                            title: Text(store.name),
                            subtitle: Text(store.managerName ?? 'No manager assigned', maxLines: 1),
                            onTap: () => context.push('/stores/${store.id}'),
                          ),
                        ),
                      ),
                  ],
                ),
              const SizedBox(height: AppSpacing.xxl),
            ]),
          ),
        ),
      ],
    );
  }
}
