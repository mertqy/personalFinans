import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/account.dart';
import '../services/storage_service.dart';
import '../core/utils.dart';
import '../core/formatters.dart';
import 'main_screen.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _accountNameController = TextEditingController(text: 'Nakit');
  final _balanceController = TextEditingController(text: '0');
  String _selectedCurrency = 'TRY';
  String _selectedType = 'cash';

  final List<Map<String, String>> _types = [
    {'value': 'cash', 'label': 'Nakit'},
    {'value': 'bank', 'label': 'Banka'},
    {'value': 'savings', 'label': 'Birikim'},
    {'value': 'investment', 'label': 'Yatırım'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profilini Oluştur'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Hoş geldin! Seni tanıyalım.',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Uygulamayı kişiselleştirmek için birkaç bilgiye ihtiyacımız var.',
                style: TextStyle(color: Colors.grey[400]),
              ),
              const SizedBox(height: 32),
              
              // Kullanıcı Adı
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Adınız',
                  hintText: 'Size nasıl hitap edelim?',
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Lütfen adınızı girin' : null,
              ),
              const SizedBox(height: 24),
              
              const Divider(),
              const SizedBox(height: 24),
              
              const Text(
                'İlk Hesabını Tanımla',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              
              // Hesap Adı
              TextFormField(
                controller: _accountNameController,
                decoration: InputDecoration(
                  labelText: 'Hesap Adı',
                  hintText: 'Örn: Nakit, Banka Hesabım',
                  prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Lütfen hesap adı girin' : null,
              ),
              const SizedBox(height: 16),
              
              Row(
                children: [
                   // Hesap Türü
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedType,
                      decoration: InputDecoration(
                        labelText: 'Hesap Türü',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: _types.map((t) {
                        return DropdownMenuItem(value: t['value']!, child: Text(t['label']!));
                      }).toList(),
                      onChanged: (v) => setState(() => _selectedType = v!),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Bakiye
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _balanceController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        ThousandsSeparatorInputFormatter(),
                      ],
                      decoration: InputDecoration(
                        labelText: 'Bakiye',
                        prefixIcon: const Icon(Icons.money),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (v) => v == null || v.isEmpty ? 'Bakiye girin' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              DropdownButtonFormField<String>(
                initialValue: _selectedCurrency,
                decoration: InputDecoration(
                  labelText: 'Para Birimi',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: ['TRY', 'USD', 'EUR', 'GBP', 'GOLD'].map((c) {
                  return DropdownMenuItem(value: c, child: Text(c));
                }).toList(),
                onChanged: (v) => setState(() => _selectedCurrency = v!),
              ),
              
              const SizedBox(height: 48),
              
              ElevatedButton(
                onPressed: _saveAndContinue,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Kaydet ve Başla', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveAndContinue() async {
    if (_formKey.currentState!.validate()) {
      // 1. Ayarları Kaydet
      await StorageService.settingsBox.put('user_name', _nameController.text);
      
      // 2. İlk Hesabı Oluştur
      final initialAccount = Account(
        id: AppUtils.generateId(),
        userId: 'temp_user',
        name: _accountNameController.text,
        type: _selectedType,
        balance: ThousandsSeparatorInputFormatter.parse(_balanceController.text),
        currency: _selectedCurrency,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      StorageService.addAccount(initialAccount);
      
      // 3. Onboarding Tamamlandı İşaretle
      await StorageService.setOnboardingCompleted(true);
      
      if (!mounted) return;
      
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainScreen()),
      );
    }
  }
}
