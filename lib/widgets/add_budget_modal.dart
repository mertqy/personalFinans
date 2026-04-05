import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collection/collection.dart';
import '../providers/budget_provider.dart';
import '../models/budget.dart';
import '../core/constants.dart';
import '../core/utils.dart';
import '../core/formatters.dart';

class AddBudgetModal extends ConsumerStatefulWidget {
  final Budget? budget;
  const AddBudgetModal({super.key, this.budget});

  @override
  ConsumerState<AddBudgetModal> createState() => _AddBudgetModalState();
}

class _AddBudgetModalState extends ConsumerState<AddBudgetModal> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;

  String? _selectedCategory;
  String _period = 'monthly';

  List<Map<String, dynamic>> get _expenseCategories => AppConstants
      .defaultCategories
      .where((c) => c['type'] == 'expense' || c['type'] == 'transfer')
      .toList();

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.budget != null
          ? ThousandsSeparatorInputFormatter.format(widget.budget!.amount)
          : '',
    );
    _selectedCategory = widget.budget?.categoryId;
    _period = widget.budget?.period ?? 'monthly';

    if (_selectedCategory == null && _expenseCategories.isNotEmpty) {
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Kategori seçiniz')));
        return;
      }

      final amount = ThousandsSeparatorInputFormatter.parse(
        _amountController.text,
      );

      if (widget.budget != null) {
        final updated = widget.budget!;
        updated.amount = amount;
        updated.categoryId = _selectedCategory!;
        updated.period = _period;
        updated.updatedAt = DateTime.now();
        ref.read(budgetProvider.notifier).updateBudget(updated);
      } else {
        // Check if budget for this category already exists
        final existing = ref
            .read(budgetProvider)
            .where(
              (b) => b.categoryId == _selectedCategory && b.period == _period,
            )
            .firstOrNull;
        if (existing != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Bu kategori için zaten bir bütçe var. Düzenlemeyi deneyin.',
              ),
            ),
          );
          return;
        }

        const String currentUserId = 'local_user';
        final budget = Budget(
          id: AppUtils.generateId(),
          userId: currentUserId,
          categoryId: _selectedCategory!,
          amount: amount,
          period: _period,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        ref.read(budgetProvider.notifier).addBudget(budget);
      }
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 24,
        left: 24,
        right: 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.budget == null
                        ? 'Yeni Bütçe Ekle'
                        : 'Bütçeyi Düzenle',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Category Selection
              DropdownButtonFormField<String>(
                initialValue:
                    _expenseCategories.any(
                      (cat) => cat['id'] == _selectedCategory,
                    )
                    ? _selectedCategory
                    : null,
                items: _expenseCategories.map((cat) {
                  return DropdownMenuItem<String>(
                    value: cat['id'] as String,
                    child: Row(
                      children: [
                        Text(
                          cat['icon'] as String,
                          style: const TextStyle(fontSize: 20),
                        ),
                        const SizedBox(width: 12),
                        Text(cat['name'] as String),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedCategory = val),
                decoration: const InputDecoration(
                  labelText: 'Kategori',
                  border: OutlineInputBorder(),
                ),
                validator: (val) => val == null ? 'Kategori seçiniz' : null,
              ),
              const SizedBox(height: 20),

              // Period Selection
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: 'monthly',
                    label: Text('Aylık'),
                    icon: Icon(Icons.calendar_month),
                  ),
                  ButtonSegment(
                    value: 'yearly',
                    label: Text('Yıllık'),
                    icon: Icon(Icons.calendar_today),
                  ),
                ],
                selected: {_period},
                onSelectionChanged: (val) =>
                    setState(() => _period = val.first),
                style: SegmentedButton.styleFrom(
                  selectedForegroundColor: Colors.white,
                  selectedBackgroundColor: Theme.of(
                    context,
                  ).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 20),

              // Amount Input
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [ThousandsSeparatorInputFormatter()],
                decoration: const InputDecoration(
                  labelText: 'Limit Tutar',
                  prefixText: '₺ ',
                  prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Tutar giriniz';
                  if (ThousandsSeparatorInputFormatter.parse(val) <= 0) {
                    return 'Tutar geçersiz';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    widget.budget == null ? 'Bütçe Oluştur' : 'Güncelle',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
