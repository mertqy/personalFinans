import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/debt.dart';
import '../providers/debt_provider.dart';
import '../core/utils.dart';
import '../core/formatters.dart';

class PayDebtModal extends ConsumerStatefulWidget {
  final Debt debt;
  const PayDebtModal({super.key, required this.debt});

  @override
  ConsumerState<PayDebtModal> createState() => _PayDebtModalState();
}

class _PayDebtModalState extends ConsumerState<PayDebtModal> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _pay(double amount) {
    if (amount <= 0) return;

    final debt = widget.debt;
    final newRemaining = (debt.remainingAmount - amount).clamp(0.0, debt.totalAmount);
    
    debt.remainingAmount = newRemaining;
    debt.updatedAt = DateTime.now();
    
    if (newRemaining <= 0) {
      debt.isCompleted = true;
      debt.remainingAmount = 0;
    }

    ref.read(debtProvider.notifier).updateDebt(debt);
    Navigator.pop(context);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          debt.isCompleted 
            ? 'Borç tamamen ödendi ve kapatıldı!' 
            : 'Ödeme yapıldı. Kalan: ${AppUtils.formatCurrency(newRemaining, currency: debt.currency)}'
        ),
        backgroundColor: Colors.green,
      ),
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
            children: [
              const Text(
                'Borç Ödemesi Yap',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                widget.debt.name,
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Kalan: ',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  Text(
                    AppUtils.formatCurrency(widget.debt.remainingAmount, currency: widget.debt.currency),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: 'Ödeme Tutarı',
                  prefixIcon: const Icon(Icons.payment),
                  suffixText: widget.debt.currency,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [ThousandsSeparatorInputFormatter()],
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Gerekli';
                  final amount = ThousandsSeparatorInputFormatter.parse(v);
                  if (amount <= 0) return 'Tutar sıfırdan büyük olmalı';
                  if (amount > widget.debt.remainingAmount) return 'Kalan borçtan fazla ödeme yapamazsınız';
                  return null;
                },
                autofocus: true,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children: [
                  ActionChip(
                    label: const Text('%25'),
                    onPressed: () => _amountController.text = ThousandsSeparatorInputFormatter.format(widget.debt.remainingAmount * 0.25),
                  ),
                  ActionChip(
                    label: const Text('%50'),
                    onPressed: () => _amountController.text = ThousandsSeparatorInputFormatter.format(widget.debt.remainingAmount * 0.50),
                  ),
                  ActionChip(
                    label: const Text('Tamamı'),
                    onPressed: () => _amountController.text = ThousandsSeparatorInputFormatter.format(widget.debt.remainingAmount),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      final amount = ThousandsSeparatorInputFormatter.parse(_amountController.text);
                      if (amount > 0) {
                        _pay(amount);
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    'Öde',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
