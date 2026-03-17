import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/credit_card_provider.dart';
import '../providers/account_provider.dart';
import '../models/credit_card.dart';
import '../core/utils.dart';

class AddCardModal extends ConsumerStatefulWidget {
  const AddCardModal({super.key});

  @override
  ConsumerState<AddCardModal> createState() => _AddCardModalState();
}

class _AddCardModalState extends ConsumerState<AddCardModal> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _limitController = TextEditingController();
  String? _selectedAccountId;

  void _save() {
    if (_formKey.currentState!.validate()) {
      if (_selectedAccountId == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bağlı hesap seçiniz')));
        return;
      }
      final limitStr = _limitController.text.replaceAll(',', '.');
      final limit = double.tryParse(limitStr) ?? 0.0;

      final selectedAccount = ref.read(accountProvider).firstWhere((acc) => acc.id == _selectedAccountId);

      final card = CreditCard(
        id: AppUtils.generateId(),
        userId: 'temp_user_id',
        name: _nameController.text,
        bank: selectedAccount.name,
        accountId: _selectedAccountId!,
        limit: limit,
        currentDebt: 0.0,
        statementDay: 1,
        dueDay: 10,
        color: '#E57373',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      ref.read(creditCardProvider.notifier).addCard(card);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accounts = ref.watch(accountProvider).where((acc) => acc.type == 'bank').toList();
    
    return Container(
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
            Text('Yeni Kart Ekle', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Kart Adı (örn: Bonus)'),
              validator: (val) => val == null || val.isEmpty ? 'Gerekli' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedAccountId,
              items: accounts.map((acc) => DropdownMenuItem(value: acc.id, child: Text('${acc.name} (${acc.currency})'))).toList(),
              onChanged: (val) => setState(() => _selectedAccountId = val),
              decoration: const InputDecoration(labelText: 'Bağlı Olacağı Hesap'),
              validator: (val) => val == null ? 'Gerekli' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _limitController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Kart Limiti'),
              validator: (val) {
                if (val == null || val.isEmpty) return 'Gerekli';
                if (double.tryParse(val.replaceAll(',', '.')) == null) return 'Geçersiz';
                return null;
              },
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
    );
  }
}
