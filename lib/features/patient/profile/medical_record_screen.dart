import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/models/medical_record_model.dart';
import '../../../core/services/medical_record_service.dart';
import '../../../core/constants/colors.dart';

class MedicalRecordScreen extends StatefulWidget {
  const MedicalRecordScreen({super.key});

  @override
  State<MedicalRecordScreen> createState() => _MedicalRecordScreenState();
}

class _MedicalRecordScreenState extends State<MedicalRecordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _bloodTypeController = TextEditingController();
  final _allergiesController = TextEditingController(); // Virgule séparée
  final _treatmentsController = TextEditingController();
  final _notesController = TextEditingController();
  
  bool _isLoading = false;
  String? _recordId;

  @override
  void initState() {
    super.initState();
    _loadRecord();
  }

  Future<void> _loadRecord() async {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;
    
    // Pour simplifier l'UX on va écouter le flux, mais on initialise les champs 
    // à partir de la première lecture si elle existe.
    final service = MedicalRecordService();
    final stream = service.getPatientMedicalRecord(user.uid);
    stream.first.then((record) {
      if (record != null && mounted) {
        setState(() {
          _recordId = record.id;
          _bloodTypeController.text = record.bloodType;
          _allergiesController.text = record.allergies.join(', ');
          _treatmentsController.text = record.currentTreatments.join(', ');
          _notesController.text = record.notes;
        });
      }
    });
  }

  Future<void> _saveRecord() async {
    if (!_formKey.currentState!.validate()) return;
    
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    final record = MedicalRecordModel(
      id: _recordId,
      patientId: user.uid,
      bloodType: _bloodTypeController.text.trim(),
      allergies: _allergiesController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
      currentTreatments: _treatmentsController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
      notes: _notesController.text.trim(),
    );

    final success = await MedicalRecordService().saveMedicalRecord(record);
    
    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dossier médical mis à jour.'), backgroundColor: AppColors.success),
        );
        context.pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur de sauvegarde.'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Dossier Médical'),
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
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withAlpha(50),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: AppColors.primaryDark),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Ces informations sont confidentielles et aident les praticiens à mieux vous soigner.',
                        style: TextStyle(color: Colors.grey.shade800),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              
              TextFormField(
                controller: _bloodTypeController,
                decoration: InputDecoration(
                  labelText: 'Groupe Sanguin (ex: O+, A-)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _allergiesController,
                decoration: InputDecoration(
                  labelText: 'Allergies (séparées par des virgules)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _treatmentsController,
                decoration: InputDecoration(
                  labelText: 'Traitements en cours',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _notesController,
                decoration: InputDecoration(
                  labelText: 'Notes supplémentaires (Antécédents)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                maxLines: 4,
              ),

              const SizedBox(height: 32),
              
              ElevatedButton(
                onPressed: _isLoading ? null : _saveRecord,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white) 
                  : const Text('Sauvegarder le dossier', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
