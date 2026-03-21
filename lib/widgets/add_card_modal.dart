import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/credit_card_provider.dart';
import '../providers/account_provider.dart';
import '../models/credit_card.dart';
import '../core/utils.dart';
import '../core/formatters.dart';

class AddCardModal extends ConsumerStatefulWidget {
  final CreditCard? card;
  const AddCardModal({super.key, this.card});

  @override
  ConsumerState<AddCardModal> createState() => _AddCardModalState();
}

class _AddCardModalState extends ConsumerState<AddCardModal> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _limitController;
  String? _selectedAccountId;
  late Color _selectedColor;

  static const List<Color> _cardColors = [
    Color(0xFF1E88E5), // Blue
    Color(0xFF43A047), // Green
    Color(0xFFE53935), // Red
    Color(0xFFFB8C00), // Orange
    Color(0xFF00ACC1), // Cyan
    Color(0xFF757575), // Grey
    Color(0xFF5D4037), // Brown
    Color(0xFF3949AB), // Indigo
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.card?.name);
    _limitController = TextEditingController(
      text: widget.card != null ? ThousandsSeparatorInputFormatter.format(widget.card!.limit) : '',
    );
    _selectedAccountId = widget.card?.accountId;
    _selectedColor = widget.card != null 
        ? AppUtils.hexToColor(widget.card!.color) 
        : _cardColors[0];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _limitController.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      if (_selectedAccountId == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bağlı hesap seçiniz')));
        return;
      }
      final limit = ThousandsSeparatorInputFormatter.parse(_limitController.text);

      final selectedAccount = ref.read(accountProvider).firstWhere((acc) => acc.id == _selectedAccountId);

      if (widget.card != null) {
        // Edit
        final updatedCard = widget.card!;
        updatedCard.name = _nameController.text;
        updatedCard.bank = selectedAccount.name;
        updatedCard.accountId = _selectedAccountId!;
        updatedCard.limit = limit;
        updatedCard.color = AppUtils.colorToHex(_selectedColor);
        updatedCard.updatedAt = DateTime.now();
        
        ref.read(creditCardProvider.notifier).updateCard(updatedCard);
      } else {
        // Add
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
          color: AppUtils.colorToHex(_selectedColor),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        ref.read(creditCardProvider.notifier).addCard(card);
      }
      
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accounts = ref.watch(accountProvider);
    final isEditing = widget.card != null;
    
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
                Text(isEditing ? 'Kartı Düzenle' : 'Yeni Kart Ekle', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Kart Adı (örn: Bonus)'),
              validator: (val) => val == null || val.isEmpty ? 'Gerekli' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: accounts.any((acc) => acc.id == _selectedAccountId) ? _selectedAccountId : null,
              items: accounts.map((acc) => DropdownMenuItem(value: acc.id, child: Text('${acc.name} (${acc.currency})'))).toList(),
              onChanged: (val) {
                if (val != null && val != _selectedAccountId) {
                  final newAccount = accounts.firstWhere((acc) => acc.id == val);
                  
                  if (_selectedAccountId != null) {
                    final oldAccount = accounts.firstWhere((acc) => acc.id == _selectedAccountId);
                    if (oldAccount.currency != newAccount.currency) {
                      setState(() {
                        final currentLimit = ThousandsSeparatorInputFormatter.parse(_limitController.text);
                        if (currentLimit > 0) {
                          final convertedLimit = AppUtils.convertToBaseCurrency(currentLimit, oldAccount.currency, newAccount.currency);
                          _limitController.text = ThousandsSeparatorInputFormatter.format(convertedLimit);
                        }
                        _selectedAccountId = val;
                      });
                      return;
                    }
                  }
                  
                  setState(() => _selectedAccountId = val);
                }
              },
              decoration: const InputDecoration(labelText: 'Bağlı Olacağı Hesap'),
              validator: (val) => val == null ? 'Gerekli' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _limitController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                ThousandsSeparatorInputFormatter(),
              ],
              decoration: const InputDecoration(labelText: 'Kart Limiti'),
              validator: (val) {
                if (val == null || val.isEmpty) return 'Gerekli';
                return null;
              },
            ),
            const SizedBox(height: 24),
            Text('Kart Rengi', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            SizedBox(
              height: 50,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _cardColors.length,
                separatorBuilder: (context, index) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final color = _cardColors[index];
                  final isSelected = _selectedColor.toARGB32() == color.toARGB32();
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColor = color),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: isSelected 
                            ? Border.all(color: Theme.of(context).colorScheme.onSurface, width: 3)
                            : null,
                        boxShadow: [
                          if (isSelected)
                            BoxShadow(
                              color: color.withValues(alpha: 0.4),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                        ],
                      ),
                      child: isSelected 
                          ? const Icon(Icons.check, color: Colors.white, size: 24)
                          : null,
                    ),
                  );
                },
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
