import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/transaction_provider.dart';
import '../providers/account_provider.dart';
import '../providers/credit_card_provider.dart';
import '../providers/budget_provider.dart';
import '../models/transaction.dart';
import '../core/constants.dart';
import '../core/utils.dart';
import '../core/formatters.dart';
import 'goal_success_dialog.dart';
import 'package:geolocator/geolocator.dart';
import '../screens/location_picker_screen.dart';
import 'package:latlong2/latlong.dart';
import 'package:collection/collection.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../widgets/premium_content_gate.dart';

class TransactionModal extends ConsumerStatefulWidget {
  final Transaction? transaction;
  final String? initialType;
  const TransactionModal({super.key, this.transaction, this.initialType});

  @override
  ConsumerState<TransactionModal> createState() => _TransactionModalState();
}

class _TransactionModalState extends ConsumerState<TransactionModal> {
  final _formKey = GlobalKey<FormState>();
  String _type = 'expense';
  late final TextEditingController _amountController;
  late final TextEditingController _descriptionController;

  String? _selectedCategory;
  DateTime _selectedDate = DateTime.now();
  String? _selectedMethodId;
  String? _selectedAccountId;
  String? _selectedCreditCardId;
  String? _selectedToId; // Transfer için hedef

  bool _isRecurring = false;
  String _recurringFrequency = 'monthly';

  bool _addLocation = false;
  double? _lat;
  double? _lng;

  final List<String> _recurringOptions = [
    'daily',
    'weekly',
    'monthly',
    'yearly',
  ];

  @override
  void initState() {
    super.initState();
    final tx = widget.transaction;

    _type = tx?.type ?? widget.initialType ?? 'expense';
    final accounts = ref.read(accountProvider);
    final cards = ref.read(creditCardProvider);
    _amountController = TextEditingController(
      text: tx != null
          ? ThousandsSeparatorInputFormatter.format(
              AppUtils.getDisplayTRYAmount(tx, accounts, cards),
            )
          : '',
    );
    _descriptionController = TextEditingController(text: tx?.description);

    final catMap = AppUtils.getCategoryById(tx?.category ?? '');
    _selectedCategory = catMap?['id'];

    _selectedDate = tx?.date ?? DateTime.now();
    _isRecurring = tx?.isRecurring ?? false;
    _recurringFrequency = tx?.recurringFrequency ?? 'monthly';

    if (tx != null) {
      if (tx.creditCardId != null) {
        _selectedMethodId = 'card_${tx.creditCardId}';
        _selectedCreditCardId = tx.creditCardId;
      } else {
        _selectedMethodId = 'acc_${tx.accountId}';
        _selectedAccountId = tx.accountId;
      }

      if (tx.toAccountId != null) {
        _selectedToId = 'acc_${tx.toAccountId}';
      } else if (tx.toGoalId != null) {
        _selectedToId = 'goal_${tx.toGoalId}';
      }

      _lat = tx.locationLat;
      _lng = tx.locationLng;
      _addLocation = _lat != null;
    } else {
      _updateDefaultCategory();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final accounts = ref.read(accountProvider);
        if (accounts.isNotEmpty && _selectedMethodId == null) {
          setState(() {
            _selectedMethodId = 'acc_${accounts.first.id}';
            _selectedAccountId = accounts.first.id;
          });
        }
      });
    }
  }

  void _updateDefaultCategory() {
    final currentCat = AppUtils.getCategoryById(_selectedCategory ?? '');
    final typeMismatch = currentCat != null && currentCat['type'] != _type;

    if (widget.transaction == null ||
        typeMismatch ||
        _selectedCategory == null) {
      final categories = AppConstants.defaultCategories
          .where((c) => c['type'] == _type)
          .toList();
      if (categories.isNotEmpty) {
        _selectedCategory = categories.first['id'];
      } else {
        _selectedCategory = null;
      }
    }
  }

  String _getCurrencyCode() {
    if (_selectedCreditCardId != null) {
      final cardList = ref.read(creditCardProvider);
      final cardMatches = cardList
          .where((c) => c.id == _selectedCreditCardId)
          .toList();
      if (cardMatches.isNotEmpty) {
        final card = cardMatches.first;
        final accList = ref
            .read(accountProvider)
            .where((a) => a.id == card.accountId)
            .toList();
        if (accList.isNotEmpty) return accList.first.currency;
      }
    } else if (_selectedAccountId != null) {
      final accList = ref
          .read(accountProvider)
          .where((a) => a.id == _selectedAccountId)
          .toList();
      if (accList.isNotEmpty) return accList.first.currency;
    }
    return 'TRY';
  }

  String _getCurrencySymbol() {
    if (_type != 'transfer') return '₺';
    final code = _getCurrencyCode();
    final Map<String, String> currencySymbols = {
      'TRY': '₺',
      'USD': r'$',
      'EUR': '€',
      'GBP': '£',
      'GOLD': 'gr',
    };
    return currencySymbols[code] ?? '₺';
  }

  Future<void> _handleLocation(bool value) async {
    if (value) {
      setState(() => _addLocation = true);
      try {
        final pos = await _getCurrentLocation();
        if (pos != null) {
          setState(() {
            _lat = pos.latitude;
            _lng = pos.longitude;
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Konum alınamadı. Lütfen izinleri kontrol edin.'),
            ),
          );
          setState(() => _addLocation = false);
        }
      }
    } else {
      setState(() {
        _addLocation = false;
        _lat = null;
        _lng = null;
      });
    }
  }

  Future<Position?> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }
    if (permission == LocationPermission.deniedForever) return null;

    return await Geolocator.getCurrentPosition();
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Kategori seçiniz')));
        return;
      }

      if (_selectedAccountId == null && _selectedCreditCardId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Hesap veya Kart seçiniz')),
        );
        return;
      }

      if (_type == 'transfer' && _selectedToId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Hedef hesap veya birikim seçiniz')),
        );
        return;
      }

      final amountFromController = ThousandsSeparatorInputFormatter.parse(
        _amountController.text,
      );
      final accountCurrency = _getCurrencyCode();

      // Calculate final amount for the database (in account currency)
      // Income/Expense are entered in TRY, Transfers are entered in account currency
      final amount = _type == 'transfer'
          ? amountFromController
          : AppUtils.convertToBaseCurrency(
              amountFromController,
              'TRY',
              accountCurrency,
            );

      final categoryName = AppUtils.getCategoryName(
        _selectedCategory ?? 'Transfer',
      );

      // Bakiye Kontrolü (Normal hesaplar eksiye düşmemeli)
      if (_selectedAccountId != null &&
          (_type == 'expense' || _type == 'transfer')) {
        final accounts = ref.read(accountProvider);
        final account = accounts.firstWhere((a) => a.id == _selectedAccountId);

        double currentBalance = account.balance;
        if (widget.transaction != null &&
            widget.transaction!.accountId == _selectedAccountId) {
          // Düzenleme modunda eski tutarı bakiyeye "varmış gibi" ekleyip kontrol edelim
          // Notifier zaten revert ederken ekleyecek, burada sadece kontrol için simüle ediyoruz.
          if (widget.transaction!.type == 'expense' ||
              widget.transaction!.type == 'transfer') {
            currentBalance += widget.transaction!.amount;
          } else if (widget.transaction!.type == 'income') {
            currentBalance -= widget.transaction!.amount;
          }
        }

        if (amount > currentBalance) {
          final String balanceSymbol = AppUtils.getCurrencySymbol(
            account.currency,
          );
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.orange),
                  SizedBox(width: 8),
                  Text('Yetersiz Bakiye'),
                ],
              ),
              content: Text(
                'Bu işlem için seçili hesapta yeterli bakiye bulunmuyor.\n\nEn fazla harcayabileceğiniz tutar: ${ThousandsSeparatorInputFormatter.format(currentBalance)} $balanceSymbol',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Anladım'),
                ),
              ],
            ),
          );
          return;
        }
      }

      String? toAccId;
      String? toGoalId;
      if (_type == 'transfer' && _selectedToId != null) {
        if (_selectedToId!.startsWith('acc_')) {
          toAccId = _selectedToId!.substring(4);
        } else if (_selectedToId!.startsWith('goal_')) {
          toGoalId = _selectedToId!.substring(5);
        }
      }

      if (widget.transaction != null) {
        // Clone for safe update (revert/apply handled in notifier)
        final tx = widget.transaction!;
        tx.type = _type;
        tx.amount = amount;
        tx.category =
            _selectedCategory ??
            (_type == 'transfer'
                ? (toGoalId != null ? 'Birikim Aktarma' : 'Transfer')
                : 'Diğer');
        tx.description = _descriptionController.text.isEmpty
            ? (_type == 'transfer' ? 'Transfer' : categoryName)
            : _descriptionController.text;
        tx.date = _selectedDate;
        tx.isRecurring = _isRecurring;
        tx.recurringFrequency = _isRecurring ? _recurringFrequency : null;
        tx.accountId = _selectedAccountId ?? '';
        tx.creditCardId = _selectedCreditCardId;
        tx.toAccountId = toAccId;
        tx.toGoalId = toGoalId;
        tx.locationLat = _addLocation ? _lat : null;
        tx.locationLng = _addLocation ? _lng : null;
        tx.updatedAt = DateTime.now();

        ref.read(transactionProvider.notifier).updateTransaction(tx);
      } else {
        final transaction = Transaction(
          id: AppUtils.generateId(),
          userId: 'local_user',
          type: _type,
          amount: amount,
          category:
              _selectedCategory ??
              (_type == 'transfer'
                  ? (toGoalId != null ? 'Birikim Aktarma' : 'Transfer')
                  : 'Diğer'),
          description: _descriptionController.text.isEmpty
              ? (_type == 'transfer' ? 'Transfer' : categoryName)
              : _descriptionController.text,
          date: _selectedDate,
          isPlanned: false,
          isRecurring: _isRecurring,
          recurringFrequency: _isRecurring ? _recurringFrequency : null,
          accountId: _selectedAccountId ?? '',
          creditCardId: _selectedCreditCardId,
          toAccountId: toAccId,
          toGoalId: toGoalId,
          locationLat: _addLocation ? _lat : null,
          locationLng: _addLocation ? _lng : null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        ref.read(transactionProvider.notifier).addTransaction(transaction);
      }

      final completedGoalId = toGoalId;
      Navigator.pop(context);

      // Check for goal completion after a delay to allow provider to update
      if (completedGoalId != null) {
        Future.delayed(const Duration(milliseconds: 400), () {
          if (!mounted) return;
          final updatedGoals = ref.read(goalProvider);
          final updatedGoal = updatedGoals
              .where((g) => g.id == completedGoalId)
              .firstOrNull;
          if (updatedGoal != null && updatedGoal.isCompleted) {
            if (context.mounted) {
              GoalSuccessDialog.show(context, updatedGoal);
            }
          }
        });
      }
    }
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('İşlemi Sil'),
        content: const Text(
          'Bu işlemi silmek istediğinize emin misiniz? Bakiye/Borç durumu otomatik olarak düzeltilecektir.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (widget.transaction != null) {
                ref
                    .read(transactionProvider.notifier)
                    .deleteTransaction(widget.transaction!);
              }
              Navigator.pop(context); // Dialog
              Navigator.pop(this.context); // Modal
              ScaffoldMessenger.of(
                this.context,
              ).showSnackBar(const SnackBar(content: Text('İşlem silindi')));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accounts = ref.watch(accountProvider);
    final cards = ref.watch(creditCardProvider);
    final goals = ref.watch(goalProvider);

    final List<Map<String, dynamic>> filteredCategories = _type == 'transfer'
        ? []
        : AppConstants.defaultCategories
              .where((cat) => cat['type'] == _type)
              .toList();

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
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.transaction == null
                        ? 'Yeni İşlem'
                        : 'İşlemi Düzenle',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      if (widget.transaction != null)
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                          ),
                          onPressed: _confirmDelete,
                        ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: 'expense',
                    label: Text('Gider'),
                    icon: Icon(Icons.keyboard_arrow_up),
                  ),
                  ButtonSegment(
                    value: 'income',
                    label: Text('Gelir'),
                    icon: Icon(Icons.keyboard_arrow_down),
                  ),
                  ButtonSegment(
                    value: 'transfer',
                    label: Text('Transfer'),
                    icon: Icon(Icons.swap_horiz),
                  ),
                ],
                selected: {_type},
                onSelectionChanged: (Set<String> newSelection) {
                  final oldType = _type;
                  final newType = newSelection.first;
                  if (oldType == newType) return;

                  setState(() {
                    // Convert amount between TRY and Account Currency if switching to/from transfer
                    final currentAmountStr = _amountController.text;
                    if (currentAmountStr.isNotEmpty) {
                      final currentAmount =
                          ThousandsSeparatorInputFormatter.parse(
                            currentAmountStr,
                          );
                      if (currentAmount > 0) {
                        final accountCurrency = _getCurrencyCode();
                        if (oldType == 'transfer') {
                          // From Account Currency (e.g. USD) to TRY
                          final converted = AppUtils.convertToBaseCurrency(
                            currentAmount,
                            accountCurrency,
                            'TRY',
                          );
                          _amountController.text =
                              ThousandsSeparatorInputFormatter.format(
                                converted,
                              );
                        } else if (newType == 'transfer') {
                          // From TRY to Account Currency (e.g. USD)
                          final converted = AppUtils.convertToBaseCurrency(
                            currentAmount,
                            'TRY',
                            accountCurrency,
                          );
                          _amountController.text =
                              ThousandsSeparatorInputFormatter.format(
                                converted,
                              );
                        }
                      }
                    }

                    _type = newType;
                    _updateDefaultCategory();
                    if (_type == 'income') {
                      _selectedCreditCardId = null;
                      if (_selectedMethodId?.startsWith('card_') ?? false) {
                        _selectedMethodId = null;
                      }
                    }
                  });
                },
                style: SegmentedButton.styleFrom(
                  selectedForegroundColor: Colors.white,
                  selectedBackgroundColor: _type == 'expense'
                      ? Colors.red
                      : (_type == 'income' ? Colors.green : Colors.blue),
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  ThousandsSeparatorInputFormatter(),
                ],
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                decoration: InputDecoration(
                  labelText: 'Tutar',
                  prefixText: '${_getCurrencySymbol()} ',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Tutar giriniz';
                  final val = ThousandsSeparatorInputFormatter.parse(value);
                  if (val <= 0) return 'Tutar 0\'dan büyük olmalıdır';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              if (_type != 'transfer') ...[
                DropdownButtonFormField<String>(
                  initialValue:
                      filteredCategories.any(
                        (cat) => cat['id'] == _selectedCategory,
                      )
                      ? _selectedCategory
                      : null,
                  items: filteredCategories.map((cat) {
                    return DropdownMenuItem<String>(
                      value: cat['id'] as String,
                      child: Row(
                        children: [
                          Text(
                            cat['icon'] as String,
                            style: const TextStyle(fontSize: 18),
                          ),
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
              ],

              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Açıklama (İsteğe Bağlı)',
                ),
              ),
              const SizedBox(height: 16),

              ListTile(
                contentPadding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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

              Text(
                _type == 'transfer' ? 'Nereden?' : 'Ödeme Yöntemi',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _selectedMethodId,
                items: <DropdownMenuItem<String>>[
                  if ((_type == 'expense' || _type == 'transfer') &&
                      cards.isNotEmpty) ...[
                    const DropdownMenuItem<String>(
                      value: 'header_cards',
                      enabled: false,
                      child: Text(
                        '--- Kredi Kartları ---',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    ...cards.map(
                      (card) => DropdownMenuItem<String>(
                        value: 'card_${card.id}',
                        child: Text('${card.name} (Kart)'),
                      ),
                    ),
                  ],
                  if (accounts.isNotEmpty) ...[
                    const DropdownMenuItem<String>(
                      value: 'header_accounts',
                      enabled: false,
                      child: Text(
                        '--- Hesaplar ---',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    ...accounts.map(
                      (acc) => DropdownMenuItem<String>(
                        value: 'acc_${acc.id}',
                        child: Text('${acc.name} (${acc.currency})'),
                      ),
                    ),
                  ],
                ],
                onChanged: (val) {
                  if (val == null || val.startsWith('header_')) return;

                  final oldCurrency = _getCurrencyCode();

                  setState(() {
                    _selectedMethodId = val;
                    if (val.startsWith('card_')) {
                      _selectedCreditCardId = val.substring(5);
                      _selectedAccountId = null;
                    } else if (val.startsWith('acc_')) {
                      _selectedAccountId = val.substring(4);
                      _selectedCreditCardId = null;
                    }

                    final newCurrency = _getCurrencyCode();

                    // Only convert amount in field if we are in transfer mode (input is in account currency)
                    // If in expense/income mode, input is always in TL, so no conversion on account change
                    if (_type == 'transfer' && oldCurrency != newCurrency) {
                      final currentAmount =
                          ThousandsSeparatorInputFormatter.parse(
                            _amountController.text,
                          );
                      if (currentAmount > 0) {
                        final convertedAmount = AppUtils.convertToBaseCurrency(
                          currentAmount,
                          oldCurrency,
                          newCurrency,
                        );
                        _amountController.text =
                            ThousandsSeparatorInputFormatter.format(
                              convertedAmount,
                            );
                      }
                    }
                  });
                },
                decoration: InputDecoration(
                  labelText: _type == 'transfer'
                      ? 'Hangi Hesaptan?'
                      : 'Hangi Hesaptan/Karttan?',
                ),
                hint: const Text('Seçiniz'),
                validator: (val) => (val == null || val.startsWith('header_'))
                    ? 'Kaynak seçiniz'
                    : null,
              ),

              if (_type == 'transfer') ...[
                const SizedBox(height: 16),
                Text('Nereye?', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _selectedToId,
                  items: <DropdownMenuItem<String>>[
                    if (accounts.isNotEmpty) ...[
                      const DropdownMenuItem<String>(
                        value: 'header_acc_to',
                        enabled: false,
                        child: Text(
                          '--- Hesaplar ---',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      ...accounts
                          .where((acc) => 'acc_${acc.id}' != _selectedMethodId)
                          .map(
                            (acc) => DropdownMenuItem<String>(
                              value: 'acc_${acc.id}',
                              child: Text('${acc.name} (${acc.currency})'),
                            ),
                          ),
                    ],
                    if (goals.isNotEmpty) ...[
                      const DropdownMenuItem<String>(
                        value: 'header_goals_to',
                        enabled: false,
                        child: Text(
                          '--- Birikim Hedefleri ---',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      ...goals
                          .where((g) => !g.isCompleted)
                          .map(
                            (goal) => DropdownMenuItem<String>(
                              value: 'goal_${goal.id}',
                              child: Text('${goal.title} (Hedef)'),
                            ),
                          ),
                    ],
                  ],
                  onChanged: (val) {
                    if (val == null || val.startsWith('header_')) return;
                    setState(() => _selectedToId = val);
                  },
                  decoration: const InputDecoration(
                    labelText: 'Hedef Hesap veya Birikim',
                  ),
                  hint: const Text('Hedef Seçiniz'),
                  validator: (val) => (val == null || val.startsWith('header_'))
                      ? 'Hedef seçiniz'
                      : null,
                ),
              ],

              const SizedBox(height: 16),

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
                    switch (opt) {
                      case 'daily':
                        text = 'Her Gün';
                        break;
                      case 'weekly':
                        text = 'Her Hafta';
                        break;
                      case 'monthly':
                        text = 'Her Ay';
                        break;
                      case 'yearly':
                        text = 'Her Yıl';
                        break;
                    }
                    return DropdownMenuItem<String>(
                      value: opt,
                      child: Text(text),
                    );
                  }).toList(),
                  onChanged: (val) =>
                      setState(() => _recurringFrequency = val!),
                  decoration: const InputDecoration(
                    labelText: 'Tekrar Sıklığı',
                  ),
                ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _saveTransaction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Kaydet',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Konum Ekleme Bölümü
              PremiumContentGate(
                compact: true,
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: const Text('Konum Ekle'),
                        subtitle: const Text('Harcama yapılan konumu kaydet'),
                        secondary: const Icon(Icons.location_on_outlined),
                        value: _addLocation,
                        onChanged: _handleLocation,
                      ),
                      if (_addLocation)
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.gps_fixed,
                                size: 16,
                                color: Colors.blue,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _lat != null
                                      ? 'Konum: ${_lat!.toStringAsFixed(4)}, ${_lng!.toStringAsFixed(4)}'
                                      : 'Konum alınıyor...',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                              TextButton.icon(
                                onPressed: () async {
                                  final result = await Navigator.push<LatLng>(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => LocationPickerScreen(
                                        initialLocation: _lat != null
                                            ? LatLng(_lat!, _lng!)
                                            : null,
                                      ),
                                    ),
                                  );
                                  if (result != null) {
                                    setState(() {
                                      _lat = result.latitude;
                                      _lng = result.longitude;
                                    });
                                  }
                                },
                                icon: const Icon(
                                  Icons.edit_location_alt,
                                  size: 16,
                                ),
                                label: const Text(
                                  'Haritada Seç',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ].animate(interval: 50.ms).fade(duration: 400.ms).slideY(begin: 0.1),
          ),
        ),
      ),
    );
  }
}
