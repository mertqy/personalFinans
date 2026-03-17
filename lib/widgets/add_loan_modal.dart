import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/loan_provider.dart';
import '../providers/account_provider.dart';
import '../models/loan.dart';
import '../core/utils.dart';

class AddLoanModal extends ConsumerStatefulWidget {
  const AddLoanModal({super.key});

  @override
  ConsumerState<AddLoanModal> createState() => _AddLoanModalState();
}

class _AddLoanModalState extends ConsumerState<AddLoanModal> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _bankController = TextEditingController();
  final _totalController = TextEditingController();
  final _paymentController = TextEditingController();
  String? _selectedAccountId;

  void _save() {
    if (_formKey.currentState!.validate()) {
      if (_selectedAccountId == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bağlı hesap seçiniz')));
        return;
      }
      
      final totalStr = _totalController.text.replaceAll(',', '.');
      final total = double.tryParse(totalStr) ?? 0.0;
      
      final paymentStr = _paymentController.text.replaceAll(',', '.');
      final payment = double.tryParse(paymentStr) ?? 0.0;

      final loan = Loan(
        id: AppUtils.generateId(),
        name: _nameController.text,
        bank: _bankController.text,
        type: 'consumer',
        accountId: _selectedAccountId!,
        totalAmount: total,
        remainingAmount: total,
        monthlyPayment: payment,
        interestRate: 0.0,
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 365)), // Varsayılan 1 yıl
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      ref.read(loanProvider.notifier).addLoan(loan);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accounts = ref.watch(accountProvider);
    
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 24, left: 24, right: 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Yeni Kredi Ekle', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Kredi Adı (örn: İhtiyaç)'),
                validator: (val) => val == null || val.isEmpty ? 'Gerekli' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _bankController,
                decoration: const InputDecoration(labelText: 'Banka'),
                validator: (val) => val == null || val.isEmpty ? 'Gerekli' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _totalController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Toplam Geri Ödeme Tutarı'),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Gerekli';
                  if (double.tryParse(val.replaceAll(',', '.')) == null) return 'Geçersiz';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _paymentController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Aylık Taksit Tutarı'),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Gerekli';
                  if (double.tryParse(val.replaceAll(',', '.')) == null) return 'Geçersiz';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedAccountId,
                items: accounts.map((acc) => DropdownMenuItem(value: acc.id, child: Text('${acc.name} (${acc.currency})'))).toList(),
                onChanged: (val) => setState(() => _selectedAccountId = val),
                decoration: const InputDecoration(labelText: 'Ödemenin Yapılacağı Hesap'),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary),
                  child: const Text('Kaydet', style: TextStyle(color: Colors.white, fontSize: 16)),
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
