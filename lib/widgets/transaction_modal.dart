import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/transaction_provider.dart';
import '../providers/account_provider.dart';
import '../providers/credit_card_provider.dart';
import '../models/transaction.dart';
import '../core/constants.dart';
import '../core/utils.dart';

class TransactionModal extends ConsumerStatefulWidget {
  const TransactionModal({super.key});

  @override
  ConsumerState<TransactionModal> createState() => _TransactionModalState();
}

class _TransactionModalState extends ConsumerState<TransactionModal> {
  final _formKey = GlobalKey<FormState>();
  String _type = 'expense'; // expense, income, transfer
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  
  String? _selectedCategory;
  DateTime _selectedDate = DateTime.now();
  String? _selectedMethodId; // Combined ID for dropdown: 'card_id' or 'acc_id'
  String? _selectedAccountId;
  String? _selectedCreditCardId;
  
  bool _isRecurring = false;
  String _recurringFrequency = 'monthly';

  final List<String> _recurringOptions = ['daily', 'weekly', 'monthly', 'yearly'];

  @override
  void initState() {
    super.initState();
    // Set initial category based on type
    _updateDefaultCategory();
  }

  void _updateDefaultCategory() {
    final categories = AppConstants.defaultCategories.where((c) => c['type'] == _type).toList();
    if (categories.isNotEmpty) {
      _selectedCategory = categories.first['name'];
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _saveTransaction() {
    if (_formKey.currentState!.validate()) {
      if (_type != 'transfer' && _selectedCategory == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kategori seçiniz')));
        return;
      }

      if (_selectedAccountId == null && _selectedCreditCardId == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Hesap veya Kart seçiniz')));
        return;
      }

      final amountStr = _amountController.text.replaceAll(',', '.');
      final amount = double.tryParse(amountStr) ?? 0.0;

      final transaction = Transaction(
        id: AppUtils.generateId(),
        userId: 'temp_user_id', // auth sonrası değişecek
        type: _type,
        amount: amount,
        category: _selectedCategory ?? 'Transfer',
        description: _descriptionController.text.isEmpty ? (_selectedCategory ?? 'Transfer') : _descriptionController.text,
        date: _selectedDate,
        isPlanned: false, // Gelecekte planlı işlemler eklenebilir
        isRecurring: _isRecurring,
        recurringFrequency: _isRecurring ? _recurringFrequency : null,
        accountId: _selectedAccountId ?? '',
        creditCardId: _selectedCreditCardId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Provider üzerinden ekle (otomatik bakiye düşülecek)
      ref.read(transactionProvider.notifier).addTransaction(transaction);

      // Hesaptan veya karttan bakiyeyi düş / ekle
      if (_type == 'expense') {
        if (_selectedCreditCardId != null) {
          ref.read(creditCardProvider.notifier).adjustDebt(_selectedCreditCardId!, amount);
        } else if (_selectedAccountId != null) {
          ref.read(accountProvider.notifier).adjustBalance(_selectedAccountId!, -amount);
        }
      } else if (_type == 'income') {
        if (_selectedAccountId != null) {
          ref.read(accountProvider.notifier).adjustBalance(_selectedAccountId!, amount);
        }
      }

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accounts = ref.watch(accountProvider);
    final cards = ref.watch(creditCardProvider);

    // Filter categories based on selected type
    final filteredCategories = AppConstants.defaultCategories.where((cat) => cat['type'] == _type).toList();

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
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Yeni İşlem Ekle', style: Theme.of(context).textTheme.titleLarge),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const SizedBox(height: 16),

              // Segmented Control for Type
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'expense', label: Text('Gider'), icon: Icon(Icons.arrow_upward)),
                  ButtonSegment(value: 'income', label: Text('Gelir'), icon: Icon(Icons.arrow_downward)),
                ],
                selected: {_type},
                onSelectionChanged: (Set<String> newSelection) {
                  setState(() {
                    _type = newSelection.first;
                    _updateDefaultCategory();
                    // Reset selected method if it's a card and switching to income
                    if (_type == 'income' && _selectedMethodId != null && _selectedMethodId!.startsWith('card_')) {
                      _selectedMethodId = null;
                      _selectedAccountId = null;
                      _selectedCreditCardId = null;
                    }
                  });
                },
                style: SegmentedButton.styleFrom(
                  selectedForegroundColor: Colors.white,
                  selectedBackgroundColor: _type == 'expense' ? Colors.red : Colors.green,
                ),
              ),
              const SizedBox(height: 16),

              // Tutar Input
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                decoration: const InputDecoration(
                  labelText: 'Tutar',
                  prefixText: '₺ ',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Tutar giriniz';
                  if (double.tryParse(value.replaceAll(',', '.')) == null) return 'Geçerli bir sayı giriniz';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Kategori Dropdown
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                items: filteredCategories.map((cat) {
                  return DropdownMenuItem<String>(
                    value: cat['name'] as String,
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

              // Açıklama Input
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Açıklama (İsteğe Bağlı)'),
              ),
              const SizedBox(height: 16),

              // Tarih Seçici
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Tarih'),
                subtitle: Text(AppUtils.formatDate(_selectedDate)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (date != null) {
                    setState(() => _selectedDate = date);
                  }
                },
              ),
              const SizedBox(height: 16),

              // Hesap / Kart Seçimi (Gider için kart da seçilebilir)
              Text('Ödeme Yöntemi', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedMethodId,
                items: <DropdownMenuItem<String>>[
                  if (_type == 'expense' && cards.isNotEmpty) ...[
                    const DropdownMenuItem<String>(
                      value: 'header_cards',
                      enabled: false,
                      child: Text('--- Kredi Kartları ---', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                    ),
                    ...cards.map((card) => DropdownMenuItem<String>(value: 'card_${card.id}', child: Text('${card.name} (Kart)'))),
                  ],
                  if (accounts.isNotEmpty) ...[
                    const DropdownMenuItem<String>(
                      value: 'header_accounts',
                      enabled: false,
                      child: Text('--- Hesaplar ---', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                    ),
                    ...accounts.map((acc) => DropdownMenuItem<String>(value: 'acc_${acc.id}', child: Text('${acc.name} (${acc.currency})'))),
                  ],
                ],
                onChanged: (val) {
                  if (val == null || val.startsWith('header_')) return;
                  setState(() {
                    _selectedMethodId = val;
                    if (val.startsWith('card_')) {
                      _selectedCreditCardId = val.substring(5);
                      _selectedAccountId = null;
                    } else if (val.startsWith('acc_')) {
                      _selectedAccountId = val.substring(4);
                      _selectedCreditCardId = null;
                    }
                  });
                },
                decoration: const InputDecoration(labelText: 'Hangi Hesaptan/Karttan?'),
                hint: const Text('Seçiniz'),
                validator: (val) => (val == null || val.startsWith('header_')) ? 'Ödeme yöntemi seçiniz' : null,
              ),
              const SizedBox(height: 16),

              // Tekrarlayan İşlem
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Tekrarlayan İşlem'),
                value: _isRecurring,
                onChanged: (val) => setState(() => _isRecurring = val),
              ),
              if (_isRecurring)
                DropdownButtonFormField<String>(
                  initialValue: _recurringFrequency,
                  items: _recurringOptions.map((opt) {
                     String text = '';
                     switch(opt){
                        case 'daily': text = 'Her Gün'; break;
                        case 'weekly': text = 'Her Hafta'; break;
                        case 'monthly': text = 'Her Ay'; break;
                        case 'yearly': text = 'Her Yıl'; break;
                     }
                     return DropdownMenuItem<String>(value: opt, child: Text(text));
                  }).toList(),
                  onChanged: (val) => setState(() => _recurringFrequency = val!),
                  decoration: const InputDecoration(labelText: 'Tekrar Sıklığı'),
                ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _saveTransaction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    shadowColor: Colors.black.withValues(alpha: 0.3),
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
