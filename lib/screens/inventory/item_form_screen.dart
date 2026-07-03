import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:collection/collection.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_providers.dart';
import '../../models/inventory_item.dart';
import '../../theme/app_theme.dart';

/// Handles both "add new item" (itemId == null) and "edit existing item".
class ItemFormScreen extends ConsumerStatefulWidget {
  final String storeId;
  final String? itemId;
  const ItemFormScreen({super.key, required this.storeId, this.itemId});

  @override
  ConsumerState<ItemFormScreen> createState() => _ItemFormScreenState();
}

class _ItemFormScreenState extends ConsumerState<ItemFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _skuCtrl = TextEditingController();
  final _brandCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController(text: '0');
  final _thresholdCtrl = TextEditingController(text: '3');
  final _priceCtrl = TextEditingController(text: '0');
  final _descCtrl = TextEditingController();
  ItemCategory _category = ItemCategory.cctv;
  bool _saving = false;
  bool _initialized = false;

  @override
  void dispose() {
    for (final c in [_nameCtrl, _skuCtrl, _brandCtrl, _qtyCtrl, _thresholdCtrl, _priceCtrl, _descCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  void _prefillIfNeeded(List<InventoryItem> items) {
    if (_initialized || widget.itemId == null) return;
    final existing = items.firstWhereOrNull((i) => i.id == widget.itemId);
    if (existing == null) return;
    _nameCtrl.text = existing.name;
    _skuCtrl.text = existing.sku;
    _brandCtrl.text = existing.brand ?? '';
    _qtyCtrl.text = '${existing.quantity}';
    _thresholdCtrl.text = '${existing.minThreshold}';
    _priceCtrl.text = '${existing.unitPrice}';
    _descCtrl.text = existing.description ?? '';
    _category = existing.category;
    _initialized = true;
  }

  Future<void> _save(List<InventoryItem> items) async {
    if (!_formKey.currentState!.validate()) return;
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null) return;
    setState(() => _saving = true);
    try {
      final existing = widget.itemId == null ? null : items.firstWhereOrNull((i) => i.id == widget.itemId);
      final item = InventoryItem(
        id: existing?.id ?? '',
        storeId: widget.storeId,
        name: _nameCtrl.text.trim(),
        sku: _skuCtrl.text.trim(),
        category: _category,
        brand: _brandCtrl.text.trim().isEmpty ? null : _brandCtrl.text.trim(),
        quantity: int.tryParse(_qtyCtrl.text) ?? 0,
        minThreshold: int.tryParse(_thresholdCtrl.text) ?? 3,
        unitPrice: double.tryParse(_priceCtrl.text) ?? 0,
        description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        updatedByName: user.name,
      );
      final service = ref.read(firestoreServiceProvider);
      if (existing == null) {
        await service.addItem(widget.storeId, item, actor: user);
      } else {
        await service.updateItem(widget.storeId, item, actor: user, previousQty: existing.quantity);
      }
      if (mounted) context.pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(storeItemsProvider(widget.storeId));
    final items = itemsAsync.valueOrNull ?? [];
    _prefillIfNeeded(items);
    final isEdit = widget.itemId != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Edit item' : 'Add item')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Item name'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _skuCtrl,
              decoration: const InputDecoration(labelText: 'SKU / model number'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(controller: _brandCtrl, decoration: const InputDecoration(labelText: 'Brand (optional)')),
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<ItemCategory>(
              initialValue: _category,
              decoration: const InputDecoration(labelText: 'Category'),
              items: [
                for (final c in ItemCategory.values) DropdownMenuItem(value: c, child: Text(c.label)),
              ],
              onChanged: (v) => setState(() => _category = v ?? _category),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _qtyCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Quantity on hand'),
                    validator: (v) => int.tryParse(v ?? '') == null ? 'Number' : null,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: TextFormField(
                    controller: _thresholdCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Low-stock alert at'),
                    validator: (v) => int.tryParse(v ?? '') == null ? 'Number' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _priceCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Unit price'),
              validator: (v) => double.tryParse(v ?? '') == null ? 'Number' : null,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _descCtrl,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Description (optional)'),
            ),
            const SizedBox(height: AppSpacing.xl),
            ElevatedButton(
              onPressed: _saving ? null : () => _save(items),
              child: _saving
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(isEdit ? 'Save changes' : 'Add item'),
            ),
          ],
        ),
      ),
    );
  }
}
