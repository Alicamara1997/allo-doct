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
import '../../../core/constants/medical_data.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/models/notification_model.dart';

class PrescriptionCreateScreen extends StatefulWidget {
  final String? patientId;
  final String? patientName;
  final PrescriptionModel? existingPrescription;

  const PrescriptionCreateScreen({
    super.key,
    this.patientId,
    this.patientName,
    this.existingPrescription,
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
    if (widget.existingPrescription != null) {
      _selectedPatientId = widget.existingPrescription!.patientId;
      _selectedPatientName = widget.existingPrescription!.patientName;
      _noteController.text = widget.existingPrescription!.note ?? '';
      _medications.addAll(widget.existingPrescription!.medications);
    } else {
      _selectedPatientId = widget.patientId;
      _selectedPatientName = widget.patientName;
    }
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
      
      // Capturer la signature (seulement si le pad n'est pas vide)
      Uint8List? signatureBytes;
      if (!_signatureController.isEmpty) {
        signatureBytes = await _signatureController.toPngBytes();
      }

      final secureCode = widget.existingPrescription?.secureCode ?? service.generateSecureCode();

      // Upload Signature et Generer PDF (si nouvelle signature)
      String? signatureUrl = widget.existingPrescription?.signatureUrl;
      if (signatureBytes != null) {
        signatureUrl = await pdfService.uploadSignature(signatureBytes, user.uid);
      }

      final tempPrescription = PrescriptionModel(
        patientId: _selectedPatientId!,
        patientName: _selectedPatientName!,
        practitionerId: user.uid,
        practitionerName: user.name ?? 'Docteur',
        practitionerSpecialty: user.specialty ?? 'Généraliste',
        date: widget.existingPrescription?.date ?? DateTime.now(),
        medications: _medications,
        secureCode: secureCode,
        signatureUrl: signatureUrl,
        note: _noteController.text.trim(),
      );

      // Régénérer le PDF si on a les bytes de signature ou si on veut forcer la mise à jour
      // Note: pour simplifier, on régénère le PDF si signatureBytes est là, 
      // sinon on pourrait avoir besoin de re-télécharger la signature existante pour refaire le PDF.
      // Pour l'instant, on dit : "Pour modifier le PDF, vous devez re-signer".
      String? pdfUrl = widget.existingPrescription?.pdfUrl;
      if (signatureBytes != null) {
        pdfUrl = await pdfService.generateAndUploadPDF(tempPrescription, signatureBytes);
      }

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

      bool success;
      if (widget.existingPrescription != null) {
        success = await service.updatePrescription(widget.existingPrescription!.id!, finalPrescription);
      } else {
        success = await service.createPrescription(finalPrescription);
      }

      if (success && mounted) {
        // Envoyer la notification au patient
        NotificationService().sendNotification(NotificationModel(
          userId: _selectedPatientId!,
          title: widget.existingPrescription != null ? 'Ordonnance modifiée' : 'Nouvelle ordonnance reçue',
          message: 'Le Dr. ${user.name} a ${widget.existingPrescription != null ? 'mis à jour' : 'rédigé'} votre ordonnance.',
          type: 'prescription',
          date: DateTime.now(),
          data: {'prescriptionId': finalPrescription.secureCode}, // On utilise secureCode comme identifiant unique
        ));

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.existingPrescription != null ? 'Ordonnance mise à jour !' : 'Ordonnance créée avec succès !'), 
            backgroundColor: AppColors.success
          ),
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
        title: Text(widget.existingPrescription != null ? 'Modifier Ordonnance' : 'Nouvelle Ordonnance'),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Nom du médicament avec Autocomplete
              Autocomplete<String>(
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text == '') return const Iterable<String>.empty();
                  return MedicalData.commonMedications.where((String option) {
                    return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                  });
                },
                onSelected: (String selection) => _medNameController.text = selection,
                fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                  // Connect internal controller to our state controller
                  controller.text = _medNameController.text;
                  controller.addListener(() => _medNameController.text = controller.text);
                  return TextField(
                    controller: controller,
                    focusNode: focusNode,
                    decoration: const InputDecoration(labelText: 'Nom du médicament'),
                  );
                },
              ),
              const SizedBox(height: 12),
              
              // Posologie avec Autocomplete
              Autocomplete<String>(
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text == '') return MedicalData.commonDosages;
                  return MedicalData.commonDosages.where((String option) {
                    return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                  });
                },
                onSelected: (String selection) => _medDosageController.text = selection,
                fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                  controller.text = _medDosageController.text;
                  controller.addListener(() => _medDosageController.text = controller.text);
                  return TextField(
                    controller: controller,
                    focusNode: focusNode,
                    decoration: const InputDecoration(labelText: 'Posologie (ex: 1 matin et soir)'),
                  );
                },
              ),
              const SizedBox(height: 12),

              // Durée avec Autocomplete
              Autocomplete<String>(
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text == '') return MedicalData.commonDurations;
                  return MedicalData.commonDurations.where((String option) {
                    return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                  });
                },
                onSelected: (String selection) => _medDurationController.text = selection,
                fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                  controller.text = _medDurationController.text;
                  controller.addListener(() => _medDurationController.text = controller.text);
                  return TextField(
                    controller: controller,
                    focusNode: focusNode,
                    decoration: const InputDecoration(labelText: 'Durée (ex: 7 jours)'),
                  );
                },
              ),
              const SizedBox(height: 12),

              TextField(
                controller: _medInstructionsController,
                decoration: const InputDecoration(labelText: 'Instructions (ex: pendant le repas)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => _addMedication(), 
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
  }
}
