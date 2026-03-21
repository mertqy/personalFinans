import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import '../providers/subscription_provider.dart';
import '../providers/account_provider.dart';
import '../models/subscription.dart';
import '../core/utils.dart';
import '../core/formatters.dart';

class AddSubscriptionModal extends ConsumerStatefulWidget {
  final Subscription? subscription;
  const AddSubscriptionModal({super.key, this.subscription});

  @override
  ConsumerState<AddSubscriptionModal> createState() => _AddSubscriptionModalState();
}

class _AddSubscriptionModalState extends ConsumerState<AddSubscriptionModal> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _amountController;
  int _billingDay = 1;
  String _frequency = 'monthly';
  String? _selectedAccountId;
  String _selectedIcon = '📺';
  String _selectedColor = '#FF6B6B';

  static const List<Map<String, String>> popularServices = [
    {'name': 'Netflix', 'icon': '🎬'},
    {'name': 'Spotify', 'icon': '🎵'},
    {'name': 'YouTube Premium', 'icon': '▶️'},
    {'name': 'Apple Music', 'icon': '🍎'},
    {'name': 'Disney+', 'icon': '🏰'},
    {'name': 'Amazon Prime', 'icon': '📦'},
    {'name': 'iCloud', 'icon': '☁️'},
    {'name': 'Google One', 'icon': '🔵'},
    {'name': 'Xbox Game Pass', 'icon': '🎮'},
    {'name': 'PlayStation Plus', 'icon': '🎮'},
    {'name': 'ChatGPT Plus', 'icon': '🤖'},
    {'name': 'Diğer', 'icon': '📌'},
  ];

  static const List<String> colorOptions = [
    '#FF6B6B', '#4ECDC4', '#45B7D1', '#96CEB4',
    '#FFEAA7', '#DDA0DD', '#FF8C42', '#6C5CE7',
  ];

  @override
  void initState() {
    super.initState();
    final sub = widget.subscription;
    _nameController = TextEditingController(text: sub?.name);
    _amountController = TextEditingController(
      text: sub != null ? ThousandsSeparatorInputFormatter.format(sub.amount) : '',
    );
    _billingDay = sub?.billingDay ?? 1;
    _frequency = sub?.frequency ?? 'monthly';
    _selectedAccountId = sub?.accountId;
    _selectedIcon = sub?.icon ?? '📺';
    _selectedColor = sub?.color ?? '#FF6B6B';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accounts = ref.watch(accountProvider);
    final isEditing = widget.subscription != null;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          top: 16, left: 20, right: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag Handle
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(isEditing ? 'Aboneliği Düzenle' : 'Abonelik Ekle',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),

                // Popüler Servisler
                if (!isEditing) ...[
                  const Text('Popüler Servisler', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: popularServices.map((service) {
                      final isSelected = _nameController.text == service['name'];
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _nameController.text = service['name']!;
                            _selectedIcon = service['icon']!;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary.withOpacity(0.15)
                                : Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(12),
                            border: isSelected
                                ? Border.all(color: Theme.of(context).colorScheme.primary)
                                : null,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(service['icon']!, style: const TextStyle(fontSize: 16)),
                              const SizedBox(width: 6),
                              Text(service['name']!, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                ],

                // İsim
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Abonelik Adı', border: OutlineInputBorder()),
                  validator: (v) => v == null || v.isEmpty ? 'Gerekli' : null,
                ),
                const SizedBox(height: 12),

                Builder(
                  builder: (context) {
                    final selectedAccount = accounts.where((a) => a.id == _selectedAccountId).firstOrNull;
                    final currency = selectedAccount?.currency ?? '₺';
                    return TextFormField(
                      controller: _amountController,
                      decoration: InputDecoration(
                        labelText: 'Aylık Tutar (${AppUtils.getCurrencySymbol(currency)})', 
                        border: const OutlineInputBorder()
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        ThousandsSeparatorInputFormatter(),
                      ],
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Gerekli';
                        if (ThousandsSeparatorInputFormatter.parse(v) <= 0) return 'Geçerli bir tutar girin';
                        return null;
                      },
                    );
                  }
                ),
                const SizedBox(height: 12),

                // Fatura Günü ve Periyot
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: List.generate(28, (i) => i + 1).contains(_billingDay) ? _billingDay : null,
                        decoration: const InputDecoration(labelText: 'Ödeme Günü', border: OutlineInputBorder()),
                        items: List.generate(28, (i) => DropdownMenuItem(value: i + 1, child: Text('${i + 1}'))),
                        onChanged: (v) => setState(() => _billingDay = v!),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: ['monthly', 'yearly'].contains(_frequency) ? _frequency : null,
                        decoration: const InputDecoration(labelText: 'Periyot', border: OutlineInputBorder()),
                        items: const [
                          DropdownMenuItem(value: 'monthly', child: Text('Aylık')),
                          DropdownMenuItem(value: 'yearly', child: Text('Yıllık')),
                        ],
                        onChanged: (v) => setState(() => _frequency = v!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Hesap Seçimi
                DropdownButtonFormField<String>(
                  value: accounts.any((a) => a.id == _selectedAccountId) ? _selectedAccountId : null,
                  decoration: const InputDecoration(labelText: 'Bağlı Hesap', border: OutlineInputBorder()),
                  items: accounts.map((a) => DropdownMenuItem(value: a.id, child: Text(a.name))).toList(),
                  onChanged: (v) => setState(() => _selectedAccountId = v),
                  validator: (v) => v == null ? 'Hesap seçin' : null,
                ),
                const SizedBox(height: 12),

                // Renk Seçimi
                const Text('Renk', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 8),
                Row(
                  children: colorOptions.map((c) {
                    final isSelected = _selectedColor == c;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedColor = c),
                      child: Container(
                        width: 32, height: 32,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: Color(int.parse(c.replaceFirst('#', 'ff'), radix: 16)),
                          borderRadius: BorderRadius.circular(8),
                          border: isSelected ? Border.all(color: Colors.white, width: 2) : null,
                          boxShadow: isSelected ? [BoxShadow(color: Color(int.parse(c.replaceFirst('#', 'ff'), radix: 16)).withOpacity(0.5), blurRadius: 8)] : null,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // Kaydet Butonu
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
                    child: Text(isEditing ? 'Güncelle' : 'Kaydet'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final now = DateTime.now();
    final subscription = Subscription(
      id: widget.subscription?.id ?? AppUtils.generateId(),
      userId: 'temp_user',
      name: _nameController.text,
      amount: ThousandsSeparatorInputFormatter.parse(_amountController.text),
      category: 'subscription',
      accountId: _selectedAccountId!,
      billingDay: _billingDay,
      frequency: _frequency,
      isActive: widget.subscription?.isActive ?? true,
      icon: _selectedIcon,
      color: _selectedColor,
      createdAt: widget.subscription?.createdAt ?? now,
      updatedAt: now,
    );

    if (widget.subscription != null) {
      ref.read(subscriptionProvider.notifier).updateSubscription(subscription);
    } else {
      ref.read(subscriptionProvider.notifier).addSubscription(subscription);
    }

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(widget.subscription != null ? 'Abonelik güncellendi' : 'Abonelik eklendi')),
    );
  }
}
