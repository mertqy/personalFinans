import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/debt_provider.dart';
import '../models/debt.dart';
import '../core/utils.dart';
import '../core/formatters.dart';

class AddDebtModal extends ConsumerStatefulWidget {
  final Debt? debt;
  const AddDebtModal({super.key, this.debt});

  @override
  ConsumerState<AddDebtModal> createState() => _AddDebtModalState();
}

class _AddDebtModalState extends ConsumerState<AddDebtModal> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _creditorController;
  late final TextEditingController _amountController;
  late final TextEditingController _descriptionController;
  String _selectedCurrency = 'TRY';
  DateTime? _selectedDueDate;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.debt?.name);
    _creditorController = TextEditingController(text: widget.debt?.creditorName);
    _amountController = TextEditingController(
      text: widget.debt != null 
        ? ThousandsSeparatorInputFormatter.format(widget.debt!.totalAmount)
        : '',
    );
    _descriptionController = TextEditingController(text: widget.debt?.description);
    _selectedCurrency = widget.debt?.currency ?? 'TRY';
    _selectedDueDate = widget.debt?.dueDate;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _creditorController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked != null) {
      setState(() => _selectedDueDate = picked);
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final amount = ThousandsSeparatorInputFormatter.parse(_amountController.text);
    const userId = 'temp_user'; // Simplified as per plan logic

    if (widget.debt == null) {
      final debt = Debt(
        id: AppUtils.generateId(),
        userId: userId,
        name: _nameController.text,
        creditorName: _creditorController.text.isEmpty ? null : _creditorController.text,
        totalAmount: amount,
        remainingAmount: amount,
        currency: _selectedCurrency,
        description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
        dueDate: _selectedDueDate,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      ref.read(debtProvider.notifier).addDebt(debt);
    } else {
      final debt = widget.debt!;
      final oldAmount = debt.totalAmount;
      final diff = amount - oldAmount;
      
      debt.name = _nameController.text;
      debt.creditorName = _creditorController.text.isEmpty ? null : _creditorController.text;
      debt.totalAmount = amount;
      debt.remainingAmount = (debt.remainingAmount + diff).clamp(0, amount);
      debt.currency = _selectedCurrency;
      debt.description = _descriptionController.text.isEmpty ? null : _descriptionController.text;
      debt.dueDate = _selectedDueDate;
      debt.updatedAt = DateTime.now();
      
      if (debt.remainingAmount <= 0) {
        debt.remainingAmount = 0;
        debt.isCompleted = true;
      } else {
        debt.isCompleted = false;
      }
      
      ref.read(debtProvider.notifier).updateDebt(debt);
    }

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(widget.debt == null ? 'Borç eklendi' : 'Borç güncellendi')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 20,
        left: 20,
        right: 20,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                    widget.debt == null ? 'Yeni Borç Ekle' : 'Borcu Düzenle',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Borç Adı',
                  hintText: 'Örn: Mehmet\'e borç, Kira borcu',
                  prefixIcon: const Icon(Icons.label_outline),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Gerekli' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _creditorController,
                decoration: InputDecoration(
                  labelText: 'Alacaklı Kişi/Kurum (Opsiyonel)',
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _amountController,
                      decoration: InputDecoration(
                        labelText: 'Toplam Tutar',
                        prefixIcon: const Icon(Icons.attach_money),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [ThousandsSeparatorInputFormatter()],
                      validator: (v) => v == null || v.isEmpty ? 'Gerekli' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedCurrency,
                      decoration: InputDecoration(
                        labelText: 'Birim',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: ['TRY', 'USD', 'EUR']
                          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                          .toList(),
                      onChanged: (v) => setState(() => _selectedCurrency = v!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: _selectDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        _selectedDueDate == null
                            ? 'Son Ödeme Tarihi (Opsiyonel)'
                            : 'Son Tarih: ${AppUtils.formatDate(_selectedDueDate!)}',
                        style: TextStyle(
                          color: _selectedDueDate == null ? Colors.grey : null,
                        ),
                      ),
                      const Spacer(),
                      if (_selectedDueDate != null)
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () => setState(() => _selectedDueDate = null),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Açıklama (Opsiyonel)',
                  prefixIcon: const Icon(Icons.notes),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    widget.debt == null ? 'Ekle' : 'Güncelle',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
