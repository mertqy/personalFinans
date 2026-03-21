import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/budget_provider.dart';
import '../models/budget.dart';
import '../core/constants.dart';
import '../core/utils.dart';
import '../core/formatters.dart';

class AddBudgetModal extends ConsumerStatefulWidget {
  const AddBudgetModal({super.key});

  @override
  ConsumerState<AddBudgetModal> createState() => _AddBudgetModalState();
}

class _AddBudgetModalState extends ConsumerState<AddBudgetModal> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  
  String? _selectedCategory;
  String _period = 'monthly';

  // Only expense categories for budgets
  List<Map<String, dynamic>> get _expenseCategories =>
      AppConstants.defaultCategories.where((c) => c['type'] == 'expense').toList();

  @override
  void initState() {
    super.initState();
    if (_expenseCategories.isNotEmpty) {
      _selectedCategory = _expenseCategories.first['id'] as String;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      if (_selectedCategory == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kategori seçiniz')),
        );
        return;
      }

      final amount = ThousandsSeparatorInputFormatter.parse(_amountController.text);

      final budget = Budget(
        id: AppUtils.generateId(),
        userId: 'temp_user_id',
        categoryId: _selectedCategory!,
        amount: amount,
        period: _period,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      ref.read(budgetProvider.notifier).addBudget(budget);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 24, left: 24, right: 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Yeni Bütçe Ekle', style: Theme.of(context).textTheme.titleLarge),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 16),

            // Category Dropdown
            DropdownButtonFormField<String>(
              value: _expenseCategories.any((cat) => cat['id'] == _selectedCategory) ? _selectedCategory : null,
              items: _expenseCategories.map((cat) {
                return DropdownMenuItem<String>(
                  value: cat['id'] as String,
                  child: Row(
                    children: [
                      Text(cat['icon'] as String, style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 8),
                      Text(cat['name'] as String),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (val) => setState(() => _selectedCategory = val),
              decoration: const InputDecoration(labelText: 'Kategori'),
              validator: (val) => val == null ? 'Kategori seçiniz' : null,
            ),
            const SizedBox(height: 16),

            // Amount Input
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                ThousandsSeparatorInputFormatter(),
              ],
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                labelText: 'Bütçe Limiti',
                prefixText: '₺ ',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Tutar giriniz';
                final val = ThousandsSeparatorInputFormatter.parse(value);
                if (val <= 0) return 'Tutar 0\'dan büyük olmalıdır';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Period Selection
            DropdownButtonFormField<String>(
              value: AppConstants.budgetPeriods.any((p) => p['id'] == _period) ? _period : null,
              items: AppConstants.budgetPeriods.map((p) {
                return DropdownMenuItem<String>(
                  value: p['id'] as String,
                  child: Text(p['name'] as String),
                );
              }).toList(),
              onChanged: (val) => setState(() => _period = val!),
              decoration: const InputDecoration(labelText: 'Dönem'),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                ),
                child: const Text('Kaydet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
