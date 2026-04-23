import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/providers/auth_provider.dart';

class PractitionerBillingScreen extends StatefulWidget {
  const PractitionerBillingScreen({super.key});

  @override
  State<PractitionerBillingScreen> createState() => _PractitionerBillingScreenState();
}

class _PractitionerBillingScreenState extends State<PractitionerBillingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _feeController = TextEditingController();
  
  bool _acceptCard = true;
  bool _acceptCash = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadBillingInfo();
  }

  Future<void> _loadBillingInfo() async {
    final user = context.read<AuthProvider>().currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists && doc.data()!.containsKey('billing')) {
        final billing = doc.data()!['billing'] as Map<String, dynamic>;
        setState(() {
          _feeController.text = billing['fee']?.toString() ?? '';
          _acceptCard = billing['acceptCard'] ?? true;
          _acceptCash = billing['acceptCash'] ?? true;
        });
      }
    }
  }

  Future<void> _saveBillingInfo() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    try {
      final user = context.read<AuthProvider>().currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'billing': {
            'fee': double.tryParse(_feeController.text.trim()) ?? 0.0,
            'acceptCard': _acceptCard,
            'acceptCash': _acceptCash,
          }
        });
        
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text('Tarifs mis à jour'), backgroundColor: AppColors.success),
           );
           context.pop();
        }
      }
    } catch (e) {
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text('Erreur: $e'), backgroundColor: AppColors.error),
         );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Tarifs et facturation'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.payment, size: 60, color: AppColors.primaryDark),
              const SizedBox(height: 16),
              const Text(
                'Configuration des paiements',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textMain),
              ),
              const SizedBox(height: 32),
              
              TextFormField(
                controller: _feeController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Tarif par défaut (en €)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.euro),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Requis' : null,
              ),
              const SizedBox(height: 24),
              
              const Text('Moyens de paiement acceptés', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    CheckboxListTile(
                      title: const Text('Carte Bancaire'),
                      value: _acceptCard,
                      activeColor: AppColors.primary,
                      onChanged: (val) => setState(() => _acceptCard = val!),
                    ),
                    const Divider(height: 1),
                    CheckboxListTile(
                      title: const Text('Espèces'),
                      value: _acceptCash,
                      activeColor: AppColors.primary,
                      onChanged: (val) => setState(() => _acceptCash = val!),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              ElevatedButton(
                onPressed: _isLoading ? null : _saveBillingInfo,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white) 
                  : const Text('Enregistrer', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
