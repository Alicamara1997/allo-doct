import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/providers/auth_provider.dart';

class PractitionerClinicInfoScreen extends StatefulWidget {
  const PractitionerClinicInfoScreen({super.key});

  @override
  State<PractitionerClinicInfoScreen> createState() => _PractitionerClinicInfoScreenState();
}

class _PractitionerClinicInfoScreenState extends State<PractitionerClinicInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _clinicNameController = TextEditingController();
  final _clinicAddressController = TextEditingController();
  final _clinicBioController = TextEditingController();
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadClinicInfo();
  }

  Future<void> _loadClinicInfo() async {
    final user = context.read<AuthProvider>().currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists && doc.data()!.containsKey('clinic')) {
        final clinic = doc.data()!['clinic'] as Map<String, dynamic>;
        setState(() {
          _clinicNameController.text = clinic['name'] ?? '';
          _clinicAddressController.text = clinic['address'] ?? '';
          _clinicBioController.text = clinic['bio'] ?? '';
        });
      }
    }
  }

  Future<void> _saveClinicInfo() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    try {
      final user = context.read<AuthProvider>().currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'clinic': {
            'name': _clinicNameController.text.trim(),
            'address': _clinicAddressController.text.trim(),
            'bio': _clinicBioController.text.trim(),
          }
        });
        
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text('Cabinet mis à jour'), backgroundColor: AppColors.success),
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
        title: const Text('Informations du Cabinet'),
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
              const Icon(Icons.maps_home_work, size: 60, color: AppColors.primaryDark),
              const SizedBox(height: 16),
              const Text(
                'Où recevez-vous vos patients ?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textMain),
              ),
              const SizedBox(height: 32),
              
              TextFormField(
                controller: _clinicNameController,
                decoration: InputDecoration(
                  labelText: 'Nom du Cabinet / Clinique',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Requis' : null,
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _clinicAddressController,
                decoration: InputDecoration(
                  labelText: 'Adresse complète',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Requis' : null,
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _clinicBioController,
                decoration: InputDecoration(
                  labelText: 'Présentation du lieu (Accès, parking...)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 32),
              
              ElevatedButton(
                onPressed: _isLoading ? null : _saveClinicInfo,
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
