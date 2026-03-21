import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/loan_provider.dart';
import '../providers/account_provider.dart';
import '../providers/transaction_provider.dart';
import '../models/loan.dart';
import '../models/transaction.dart';
import '../core/utils.dart';
import '../core/formatters.dart';

class AddLoanModal extends ConsumerStatefulWidget {
  final Loan? loan;
  const AddLoanModal({super.key, this.loan});

  @override
  ConsumerState<AddLoanModal> createState() => _AddLoanModalState();
}

class _AddLoanModalState extends ConsumerState<AddLoanModal> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _totalController;
  late final TextEditingController _paymentController;
  late final TextEditingController _interestController;
  late final TextEditingController _durationController;
  String? _selectedName;
  String? _selectedAccountId;
  double _totalRepayment = 0.0;

  final List<String> _loanNames = ['İhtiyaç', 'Araç', 'Konut'];

  @override
  void initState() {
    super.initState();
    _selectedName = widget.loan?.name;
    if (_selectedName == null && widget.loan == null) _selectedName = _loanNames.first;
    
    final accounts = ref.read(accountProvider);
    final loanAccount = accounts.where((a) => a.id == widget.loan?.accountId).firstOrNull;
    final displayTotal = widget.loan != null 
        ? AppUtils.convertToBaseCurrency(widget.loan!.totalAmount, loanAccount?.currency ?? 'TRY', 'TRY')
        : null;
    final displayPayment = widget.loan != null 
        ? AppUtils.convertToBaseCurrency(widget.loan!.monthlyPayment, loanAccount?.currency ?? 'TRY', 'TRY')
        : null;

    _totalController = TextEditingController(
      text: displayTotal != null ? ThousandsSeparatorInputFormatter.format(displayTotal) : '',
    );
    _paymentController = TextEditingController(
      text: displayPayment != null ? ThousandsSeparatorInputFormatter.format(displayPayment) : '',
    );
    _interestController = TextEditingController(text: widget.loan?.interestRate.toString() ?? '');
    _durationController = TextEditingController(text: '12'); // Default 12 months
    _selectedAccountId = widget.loan?.accountId;

    if (widget.loan != null) {
      _totalRepayment = displayTotal ?? 0.0;
      // Estimate duration if possible, or keep default
    }

    _totalController.addListener(_calculate);
    _interestController.addListener(_calculate);
    _durationController.addListener(_calculate);
  }

  @override
  void dispose() {
    _totalController.dispose();
    _paymentController.dispose();
    _interestController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  void _calculate() {
    final amount = ThousandsSeparatorInputFormatter.parse(_totalController.text);
    final interestRate = double.tryParse(_interestController.text.replaceAll(',', '.')) ?? 0;
    final months = int.tryParse(_durationController.text) ?? 0;

    if (months > 0) {
      // Monthly Flat Interest Rate Calculation
      // User requested "monthly interest" instead of "total interest"
      // Total Interest = Principal * (MonthlyRate / 100) * Months
      final totalInterest = amount * (interestRate / 100) * months;
      final total = amount + totalInterest;
      final monthly = total / months;
      
      setState(() {
        _totalRepayment = total;
        _paymentController.text = ThousandsSeparatorInputFormatter.format(monthly);
      });
    }
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      if (_selectedAccountId == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bağlı hesap seçiniz')));
        return;
      }
      
      final paymentInTry = ThousandsSeparatorInputFormatter.parse(_paymentController.text);
      final principalInTry = ThousandsSeparatorInputFormatter.parse(_totalController.text);
      final totalRepaymentInTry = _totalRepayment;
      final interest = double.tryParse(_interestController.text.replaceAll(',', '.')) ?? 0.0;

      final accounts = ref.read(accountProvider);
      final selectedAccount = accounts.firstWhere((acc) => acc.id == _selectedAccountId);
      final currency = selectedAccount.currency;

      final payment = AppUtils.convertToBaseCurrency(paymentInTry, 'TRY', currency);
      final principal = AppUtils.convertToBaseCurrency(principalInTry, 'TRY', currency);
      final totalRepayment = AppUtils.convertToBaseCurrency(totalRepaymentInTry, 'TRY', currency);

      if (widget.loan != null) {
        // Edit
        final updatedLoan = widget.loan!;
        updatedLoan.name = _selectedName!;
        updatedLoan.bank = selectedAccount.name;
        updatedLoan.totalAmount = totalRepayment;
        updatedLoan.monthlyPayment = payment;
        updatedLoan.interestRate = interest;
        updatedLoan.accountId = _selectedAccountId!;
        updatedLoan.updatedAt = DateTime.now();
        
        ref.read(loanProvider.notifier).updateLoan(updatedLoan);
      } else {
        // Add
        final loan = Loan(
          id: AppUtils.generateId(),
          name: _selectedName!,
          bank: selectedAccount.name,
          type: _selectedName == 'Araç' ? 'auto' : (_selectedName == 'Konut' ? 'mortgage' : 'personal'),
          accountId: _selectedAccountId!,
          totalAmount: totalRepayment,
          remainingAmount: totalRepayment,
          monthlyPayment: payment,
          interestRate: interest,
          startDate: DateTime.now(),
          endDate: DateTime.now().add(Duration(days: (int.tryParse(_durationController.text) ?? 12) * 30)), 
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        ref.read(loanProvider.notifier).addLoan(loan);

        // Kredi girişini işlem olarak ekle (Son işlemlerde gözükmesi için)
        final tx = Transaction(
          id: AppUtils.generateId(),
          userId: 'temp_user_id',
          type: 'income',
          amount: principal, // Sadece anapara
          category: 'Kredi Girişi',
          description: '${loan.name} Kredisi Alındı',
          date: DateTime.now(),
          isPlanned: false,
          accountId: loan.accountId,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        ref.read(transactionProvider.notifier).addTransaction(tx);
      }
      
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Only bank accounts
    final accounts = ref.watch(accountProvider).toList();
    final isEditing = widget.loan != null;
    
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
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(isEditing ? 'Krediyi Düzenle' : 'Yeni Kredi Ekle', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _loanNames.contains(_selectedName) ? _selectedName : null,
                items: _loanNames.map((name) => DropdownMenuItem(value: name, child: Text(name))).toList(),
                onChanged: (val) => setState(() => _selectedName = val),
                decoration: const InputDecoration(labelText: 'Kredi Türü'),
                validator: (val) => val == null ? 'Gerekli' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: accounts.any((acc) => acc.id == _selectedAccountId) ? _selectedAccountId : null,
                items: accounts.map((acc) => DropdownMenuItem(value: acc.id, child: Text('${acc.name} (${acc.currency})'))).toList(),
                onChanged: (val) => setState(() => _selectedAccountId = val),
                decoration: const InputDecoration(labelText: 'Bağlı Banka Hesabı'),
                validator: (val) => val == null ? 'Gerekli' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _totalController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        ThousandsSeparatorInputFormatter(),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Kredi Tutarı',
                        prefixText: '₺ ',
                      ),
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Gerekli';
                        if (double.tryParse(val.replaceAll(',', '.')) == null) return 'Geçersiz';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _interestController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Aylık Faiz Oranı', suffixText: '%'),
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Gerekli';
                        if (double.tryParse(val.replaceAll(',', '.')) == null) return 'Geçersiz';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _durationController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Vade (Ay)', suffixText: 'Ay'),
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Gerekli';
                        if (int.tryParse(val) == null) return 'Geçersiz';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _paymentController,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Aylık Taksit',
                        prefixText: '₺ ',
                        filled: true,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Toplam Geri Ödeme:', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(
                      '₺ ${ThousandsSeparatorInputFormatter.format(_totalRepayment)}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Kaydet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
