import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/budget_provider.dart';
import '../models/goal.dart';
import '../core/utils.dart';
import '../core/formatters.dart';

class AddGoalModal extends ConsumerStatefulWidget {
  final Goal? goal;
  const AddGoalModal({super.key, this.goal});

  @override
  ConsumerState<AddGoalModal> createState() => _AddGoalModalState();
}

class _AddGoalModalState extends ConsumerState<AddGoalModal> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _amountController;

  String _selectedIcon = '🎯';
  DateTime _targetDate = DateTime.now().add(const Duration(days: 90));
  String _selectedLevel = 'beginner';
  String _selectedLevelColor = '#64B5F6';

  final List<String> _icons = [
    '🎯',
    '🏠',
    '🚗',
    '✈️',
    '📱',
    '💻',
    '🎓',
    '💍',
    '🏖️',
    '💪',
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.goal?.title ?? '');
    _amountController = TextEditingController(
      text: widget.goal != null
          ? ThousandsSeparatorInputFormatter.format(widget.goal!.targetAmount)
          : '',
    );
    if (widget.goal != null) {
      _selectedIcon = widget.goal!.icon;
      _targetDate = widget.goal!.targetDate;
      _selectedLevel = widget.goal!.level;
      _selectedLevelColor = widget.goal!.levelColor;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final amount = ThousandsSeparatorInputFormatter.parse(
        _amountController.text,
      );

      if (widget.goal != null) {
        // Edit
        final updatedGoal = widget.goal!;
        updatedGoal.title = _titleController.text;
        updatedGoal.icon = _selectedIcon;
        updatedGoal.targetAmount = amount;
        updatedGoal.targetDate = _targetDate;
        updatedGoal.isCompleted = updatedGoal.currentAmount >= amount;
        updatedGoal.updatedAt = DateTime.now();

        ref.read(goalProvider.notifier).updateGoal(updatedGoal);
      } else {
        // Add
        final goal = Goal(
          id: AppUtils.generateId(),
          userId: FirebaseAuth.instance.currentUser?.uid ?? 'temp_user',
          title: _titleController.text,
          icon: _selectedIcon,
          targetAmount: amount,
          currentAmount: 0.0,
          targetDate: _targetDate,
          isCompleted: false,
          level: _selectedLevel,
          levelColor: _selectedLevelColor,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        ref.read(goalProvider.notifier).addGoal(goal);
      }

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.goal == null
                        ? 'Yeni Birikim Hedefi'
                        : 'Hedefi Düzenle',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Title Input
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Hedef Adı',
                  hintText: 'Örn: Tatil Fonu',
                  prefixIcon: Icon(Icons.edit_outlined),
                ),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Hedef adı giriniz' : null,
              ),
              const SizedBox(height: 16),

              // Target Amount
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [ThousandsSeparatorInputFormatter()],
                decoration: const InputDecoration(
                  labelText: 'Hedeflenen Tutar',
                  prefixText: '₺ ',
                  prefixIcon: Icon(Icons.flag_outlined),
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Tutar giriniz';
                  if (ThousandsSeparatorInputFormatter.parse(val) <= 0) {
                    return 'Tutar geçersiz';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Date Selection
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today_outlined),
                title: const Text('Hedef Tarih'),
                subtitle: Text(
                  DateFormat('dd MMMM yyyy', 'tr_TR').format(_targetDate),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _targetDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 3650)),
                  );
                  if (picked != null) {
                    setState(() => _targetDate = picked);
                  }
                },
              ),
              const SizedBox(height: 16),

              // Icon Selection
              Text('İkon Seçin', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _icons.map((icon) {
                  final isSelected = _selectedIcon == icon;
                  return InkWell(
                    onTap: () => setState(() => _selectedIcon = icon),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Theme.of(
                                context,
                              ).colorScheme.primary.withValues(alpha: 0.1)
                            : Colors.grey.withValues(alpha: 0.05),
                        border: Border.all(
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Colors.transparent,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Text(icon, style: const TextStyle(fontSize: 24)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    widget.goal == null
                        ? 'Hedef Ekle'
                        : 'Değişiklikleri Kaydet',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
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
