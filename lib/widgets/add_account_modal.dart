import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/account_provider.dart';
import '../providers/transaction_provider.dart';
import '../models/account.dart';
import '../models/transaction.dart';
import '../core/utils.dart';
import '../core/formatters.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AddAccountModal extends ConsumerStatefulWidget {
  final Account? account;
  const AddAccountModal({super.key, this.account});

  @override
  ConsumerState<AddAccountModal> createState() => _AddAccountModalState();
}

class _AddAccountModalState extends ConsumerState<AddAccountModal> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _balanceController;
  
  late String _selectedType;
  late String _selectedCurrency;

  final List<Map<String, String>> _types = [
    {'value': 'cash', 'label': 'Nakit'},
    {'value': 'bank', 'label': 'Banka'},
    {'value': 'savings', 'label': 'Birikim'},
    {'value': 'investment', 'label': 'Yatırım'},
  ];
  final List<String> _currencies = ['TRY', 'USD', 'EUR', 'GBP', 'GOLD'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.account?.name);
    _balanceController = TextEditingController(
      text: widget.account != null ? ThousandsSeparatorInputFormatter.format(widget.account!.balance) : '',
    );
    _selectedType = widget.account?.type ?? 'cash';
    _selectedCurrency = widget.account?.currency ?? 'TRY';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final amount = ThousandsSeparatorInputFormatter.parse(_balanceController.text);

      if (widget.account != null) {
        // Düzenleme
        final updatedAccount = widget.account!;
        updatedAccount.name = _nameController.text;
        updatedAccount.type = _selectedType;
        updatedAccount.balance = amount;
        updatedAccount.currency = _selectedCurrency;
        updatedAccount.updatedAt = DateTime.now();
        
        ref.read(accountProvider.notifier).updateAccount(updatedAccount);
      } else {
        // Yeni Ekleme
        final account = Account(
          id: AppUtils.generateId(),
          userId: 'temp_user_id',
          name: _nameController.text,
          type: _selectedType,
          balance: 0,
          currency: _selectedCurrency,
          color: '#64B5F6',
          icon: 'wallet',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        ref.read(accountProvider.notifier).addAccount(account);

        // Açılış bakiyesini işlem olarak ekle (Son işlemlerde gözükmesi için)
        if (amount > 0) {
          final tx = Transaction(
            id: AppUtils.generateId(),
            userId: 'temp_user_id',
            type: 'income',
            amount: amount,
            category: 'Açılış Bakiyesi',
            description: '${account.name} Hesabı Açıldı',
            date: DateTime.now(),
            isPlanned: false,
            accountId: account.id,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          ref.read(transactionProvider.notifier).addTransaction(tx);
        }
      }
      
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.account != null;

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
                Text(isEditing ? 'Hesabı Düzenle' : 'Yeni Hesap Ekle', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Hesap Adı'),
              validator: (val) => val == null || val.isEmpty ? 'Gerekli' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedType,
              items: _types.map((t) => DropdownMenuItem(value: t['value']!, child: Text(t['label']!))).toList(),
              onChanged: (val) => setState(() => _selectedType = val!),
              decoration: const InputDecoration(labelText: 'Hesap Türü'),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _balanceController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      ThousandsSeparatorInputFormatter(),
                    ],
                    decoration: const InputDecoration(labelText: 'Bakiye'),
                    validator: (val) {
                      if (val == null || val.isEmpty) return 'Gerekli';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 1,
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedCurrency,
                    items: _currencies.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (val) {
                      if (val != null && val != _selectedCurrency) {
                        setState(() {
                          final currentAmount = ThousandsSeparatorInputFormatter.parse(_balanceController.text);
                          final convertedAmount = AppUtils.convertToBaseCurrency(currentAmount, _selectedCurrency, val);
                          _balanceController.text = ThousandsSeparatorInputFormatter.format(convertedAmount);
                          _selectedCurrency = val;
                        });
                      }
                    },
                    decoration: const InputDecoration(labelText: 'Para Birimi'),
                  ),
                ),
              ],
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
          ].animate(interval: 50.ms).fade(duration: 400.ms).slideY(begin: 0.1),
        ),
      ),
    );
  }
}
