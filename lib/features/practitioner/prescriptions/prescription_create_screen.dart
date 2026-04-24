import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:barcode_widget/barcode_widget.dart';
import '../../../core/constants/colors.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/models/prescription_model.dart';
import '../../../core/services/prescription_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:signature/signature.dart';
import 'dart:typed_data';
import '../../../core/services/pdf_service.dart';

class PrescriptionCreateScreen extends StatefulWidget {
  final String? patientId;
  final String? patientName;

  const PrescriptionCreateScreen({
    super.key,
    this.patientId,
    this.patientName,
  });

  @override
  State<PrescriptionCreateScreen> createState() => _PrescriptionCreateScreenState();
}

class _PrescriptionCreateScreenState extends State<PrescriptionCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final List<MedicationModel> _medications = [];
  final _noteController = TextEditingController();
  
  final SignatureController _signatureController = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );
  final _medNameController = TextEditingController();
  final _medDosageController = TextEditingController();
  final _medDurationController = TextEditingController();
  final _medInstructionsController = TextEditingController();

  String? _selectedPatientId;
  String? _selectedPatientName;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedPatientId = widget.patientId;
    _selectedPatientName = widget.patientName;
  }

  void _addMedication() {
    if (_medNameController.text.isEmpty) return;
    
    setState(() {
      _medications.add(MedicationModel(
        name: _medNameController.text.trim(),
        dosage: _medDosageController.text.trim(),
        duration: _medDurationController.text.trim(),
        instructions: _medInstructionsController.text.trim(),
      ));
      
      // Clear inputs
      _medNameController.clear();
      _medDosageController.clear();
      _medDurationController.clear();
      _medInstructionsController.clear();
    });
    context.pop(); // Close dialog
  }

  Future<void> _savePrescription() async {
    if (_medications.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez ajouter au moins un médicament.')),
      );
      return;
    }

    if (_selectedPatientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner un patient.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final user = context.read<AuthProvider>().currentUser;
      if (user == null) return;

      final service = PrescriptionService();
      final pdfService = PrescriptionPDFService();
      
      // Capturer la signature
      final Uint8List? signatureBytes = await _signatureController.toPngBytes();
      if (signatureBytes == null) {
        setState(() => _isSaving = false);
        return;
      }

      final secureCode = service.generateSecureCode();

      // Upload Signature et Generer PDF
      final signatureUrl = await pdfService.uploadSignature(signatureBytes, user.uid);

      final tempPrescription = PrescriptionModel(
        patientId: _selectedPatientId!,
        patientName: _selectedPatientName!,
        practitionerId: user.uid,
        practitionerName: user.name ?? 'Docteur',
        practitionerSpecialty: user.specialty ?? 'Généraliste',
        date: DateTime.now(),
        medications: _medications,
        secureCode: secureCode,
        signatureUrl: signatureUrl,
        note: _noteController.text.trim(),
      );

      final pdfUrl = await pdfService.generateAndUploadPDF(tempPrescription, signatureBytes);

      final finalPrescription = PrescriptionModel(
        patientId: tempPrescription.patientId,
        patientName: tempPrescription.patientName,
        practitionerId: tempPrescription.practitionerId,
        practitionerName: tempPrescription.practitionerName,
        practitionerSpecialty: tempPrescription.practitionerSpecialty,
        date: tempPrescription.date,
        medications: tempPrescription.medications,
        secureCode: tempPrescription.secureCode,
        signatureUrl: signatureUrl,
        pdfUrl: pdfUrl,
        note: tempPrescription.note,
      );

      final success = await service.createPrescription(finalPrescription);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ordonnance créée avec succès !'), backgroundColor: AppColors.success),
        );
        context.pop();
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Nouvelle Ordonnance'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textMain,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Patient Info
              Text(
                'Patient : ${_selectedPatientName ?? 'Non sélectionné'}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),

              // Medications List
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Médicaments',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  TextButton.icon(
                    onPressed: () => _showAddMedicationDialog(),
                    icon: const Icon(Icons.add),
                    label: const Text('Ajouter'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_medications.isEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(child: Text('Aucun médicament ajouté')),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _medications.length,
                  itemBuilder: (context, index) {
                    final med = _medications[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        title: Text(med.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${med.dosage} - ${med.duration}\n${med.instructions}'),
                        isThreeLine: true,
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: AppColors.error),
                          onPressed: () => setState(() => _medications.removeAt(index)),
                        ),
                      ),
                    );
                  },
                ),
              const SizedBox(height: 32),

              // Notes
              const Text(
                'Note / Observations',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _noteController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Conseils supplémentaires...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 32),

              // Signature Pad
              const Text(
                'Signature du Praticien',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                      child: Signature(
                        controller: _signatureController,
                        height: 150,
                        backgroundColor: Colors.white,
                      ),
                    ),
                    Container(
                      color: Colors.grey.shade50,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => _signatureController.clear(),
                            child: const Text('Effacer', style: TextStyle(color: AppColors.error)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),

              // Save Button
              ElevatedButton(
                onPressed: _isSaving ? null : _savePrescription,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSaving 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Signer et Enregistrer', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddMedicationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ajouter un médicament'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _medNameController,
                decoration: const InputDecoration(labelText: 'Nom du médicament'),
              ),
              TextField(
                controller: _medDosageController,
                decoration: const InputDecoration(labelText: 'Posologie (ex: 1 matin et soir)'),
              ),
              TextField(
                controller: _medDurationController,
                decoration: const InputDecoration(labelText: 'Durée (ex: 7 jours)'),
              ),
              TextField(
                controller: _medInstructionsController,
                decoration: const InputDecoration(labelText: 'Instructions (ex: pendant le repas)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => context.pop(), child: const Text('Annuler')),
          ElevatedButton(onPressed: _addMedication, child: const Text('Ajouter')),
        ],
      ),
    );
  }
}
