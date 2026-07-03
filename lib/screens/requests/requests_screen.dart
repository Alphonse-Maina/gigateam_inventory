import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_providers.dart';
import '../../models/stock_request.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class RequestsScreen extends ConsumerStatefulWidget {
  const RequestsScreen({super.key});

  @override
  ConsumerState<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends ConsumerState<RequestsScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Color _statusColor(RequestStatus s) {
    switch (s) {
      case RequestStatus.pending:
        return AppColors.warning;
      case RequestStatus.approved:
      case RequestStatus.fulfilled:
        return AppColors.success;
      case RequestStatus.rejected:
        return AppColors.danger;
    }
  }

  Widget _buildList(List<StockRequest> requests, {required bool incoming}) {
    if (requests.isEmpty) {
      return const EmptyState(
        icon: Icons.swap_horiz_rounded,
        title: 'Nothing here yet',
        subtitle: 'Stock requests will show up in this list.',
      );
    }
    final user = ref.read(currentUserProvider).valueOrNull;
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: requests.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, i) {
        final r = requests[i];
        final canRespond = incoming && r.status == RequestStatus.pending && user != null;
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text('${r.quantityRequested} × ${r.itemName}',
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _statusColor(r.status).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        r.status.name.toUpperCase(),
                        style: TextStyle(color: _statusColor(r.status), fontSize: 11, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text('${r.toStoreName} is requesting from ${r.fromStoreName}',
                    style: const TextStyle(color: Colors.grey, fontSize: 13)),
                Text('Requested by ${r.requestedByName}${r.createdAt != null ? " · ${DateFormat.MMMd().add_jm().format(r.createdAt!)}" : ""}',
                    style: const TextStyle(color: Colors.grey, fontSize: 12)),
                if (canRespond) ...[
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger),
                          onPressed: () => ref
                              .read(firestoreServiceProvider)
                              .respondToRequest(request: r, approve: false, actor: user),
                          child: const Text('Reject'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => ref
                              .read(firestoreServiceProvider)
                              .respondToRequest(request: r, approve: true, actor: user),
                          child: const Text('Approve'),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final incoming = user?.isAdmin == true
        ? ref.watch(allRequestsProvider).valueOrNull ?? []
        : ref.watch(incomingRequestsProvider).valueOrNull ?? [];
    final mine = ref.watch(myRequestsProvider).valueOrNull ?? [];

    return Scaffold(
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            tabs: [
              Tab(text: user?.isAdmin == true ? 'All requests' : 'Incoming'),
              const Tab(text: 'My requests'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildList(incoming, incoming: true),
                _buildList(mine, incoming: false),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
