import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:collection/collection.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_providers.dart';
import '../../models/stock_request.dart';
import '../../theme/app_theme.dart';

class RequestFormScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? prefill;
  const RequestFormScreen({super.key, this.prefill});

  @override
  ConsumerState<RequestFormScreen> createState() => _RequestFormScreenState();
}

class _RequestFormScreenState extends ConsumerState<RequestFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _qtyCtrl = TextEditingController(text: '1');
  final _noteCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final user = ref.read(currentUserProvider).valueOrNull;
    final stores = ref.read(storesProvider).valueOrNull ?? [];
    if (user == null || widget.prefill == null) return;

    final fromStoreId = widget.prefill!['fromStoreId'] as String;
    final toStoreId = user.storeId ?? fromStoreId; // admin fallback
    final fromStore = stores.firstWhereOrNull((s) => s.id == fromStoreId);
    final toStore = stores.firstWhereOrNull((s) => s.id == toStoreId);

    setState(() => _saving = true);
    try {
      await ref.read(firestoreServiceProvider).createRequest(
            StockRequest(
              id: '',
              itemId: widget.prefill!['itemId'],
              itemName: widget.prefill!['itemName'],
              fromStoreId: fromStoreId,
              fromStoreName: fromStore?.name ?? fromStoreId,
              toStoreId: toStoreId,
              toStoreName: toStore?.name ?? toStoreId,
              quantityRequested: int.tryParse(_qtyCtrl.text) ?? 1,
              requestedById: user.uid,
              requestedByName: user.name,
              status: RequestStatus.pending,
              note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
            ),
          );
      if (mounted) context.pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final itemName = widget.prefill?['itemName'] ?? 'item';
    return Scaffold(
      appBar: AppBar(title: const Text('Request stock')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Text('Requesting: $itemName', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.lg),
            TextFormField(
              controller: _qtyCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Quantity needed'),
              validator: (v) {
                final n = int.tryParse(v ?? '');
                if (n == null || n <= 0) return 'Enter a valid quantity';
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _noteCtrl,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Note (optional)'),
            ),
            const SizedBox(height: AppSpacing.xl),
            ElevatedButton(
              onPressed: _saving ? null : _submit,
              child: _saving
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Send request'),
            ),
          ],
        ),
      ),
    );
  }
}
