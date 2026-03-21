import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/budget_provider.dart';
import '../models/goal.dart';
import '../core/utils.dart';
import '../core/formatters.dart';

class AddGoalModal extends ConsumerStatefulWidget {
  const AddGoalModal({super.key});

  @override
  ConsumerState<AddGoalModal> createState() => _AddGoalModalState();
}

class _AddGoalModalState extends ConsumerState<AddGoalModal> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  
  String _selectedIcon = '🎯';
  DateTime _targetDate = DateTime.now().add(const Duration(days: 90));

  final List<String> _icons = ['🎯', '🏠', '🚗', '✈️', '📱', '💻', '🎓', '💍', '🏖️', '💪'];

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final amount = ThousandsSeparatorInputFormatter.parse(_amountController.text);

      final goal = Goal(
        id: AppUtils.generateId(),
        userId: 'temp_user_id',
        title: _titleController.text,
        icon: _selectedIcon,
        targetAmount: amount,
        currentAmount: 0.0,
        targetDate: _targetDate,
        isCompleted: false,
        level: 'beginner',
        levelColor: '#64B5F6',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      ref.read(goalProvider.notifier).addGoal(goal);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  Text('Yeni Birikim Hedefi', style: Theme.of(context).textTheme.titleLarge),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const SizedBox(height: 16),

              // Title Input
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Hedef Adı (örn: Tatil Fonu)'),
                validator: (val) => val == null || val.isEmpty ? 'Hedef adı giriniz' : null,
              ),
              const SizedBox(height: 16),

              // Icon Selection
              Text('İkon Seçin', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _icons.map((icon) {
                  final isSelected = _selectedIcon == icon;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedIcon = icon),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)
                            : Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey.withValues(alpha: 0.3),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Center(child: Text(icon, style: const TextStyle(fontSize: 20))),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Target Amount
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  ThousandsSeparatorInputFormatter(),
                ],
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                decoration: const InputDecoration(
                  labelText: 'Hedef Tutar',
                  prefixText: '₺ ',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Tutar giriniz';
                  final val = ThousandsSeparatorInputFormatter.parse(value);
                  if (val <= 0) return 'Tutar 0\'dan büyük olmalıdır';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Target Date
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Hedef Tarih'),
                subtitle: Text(AppUtils.formatDate(_targetDate)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _targetDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2100),
                  );
                  if (date != null) {
                    setState(() => _targetDate = date);
                  }
                },
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
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
