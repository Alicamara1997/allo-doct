import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/colors.dart';
import '../../../core/models/prescription_model.dart';

class PrescriptionDetailScreen extends StatelessWidget {
  final PrescriptionModel prescription;

  const PrescriptionDetailScreen({
    super.key,
    required this.prescription,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Détails Ordonnance'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textMain,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.print_outlined),
            onPressed: () {
              // Futur: Génération PDF
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Header Paper Look
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10, offset: const Offset(0, 5)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Dr. ${prescription.practitionerName}',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.black, color: AppColors.primaryDark),
                          ),
                          Text(
                            prescription.practitionerSpecialty,
                            style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      Text(
                        DateFormat('dd/MM/yyyy').format(prescription.date),
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  const Divider(height: 40),
                  const Text('Prescription pour :', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  Text(
                    prescription.patientName,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 32),
                  
                  // Medications
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: prescription.medications.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 24),
                    itemBuilder: (context, index) {
                      final med = prescription.medications[index];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '• ${med.name}',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${med.dosage} - ${med.duration}',
                            style: const TextStyle(color: AppColors.textMain),
                          ),
                          if (med.instructions.isNotEmpty)
                            Text(
                              med.instructions,
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontStyle: FontStyle.italic),
                            ),
                        ],
                      );
                    },
                  ),
                  
                  if (prescription.note != null && prescription.note!.isNotEmpty) ...[
                    const SizedBox(height: 32),
                    const Text('Note supplémentaire :', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    Text(prescription.note!),
                  ],
                  
                  const SizedBox(height: 48),
                  
                  // Security Section with Barcode
                  Center(
                    child: Column(
                      children: [
                        const Text(
                          'SIGNATURE ÉLECTRONIQUE SÉCURISÉE',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Colors.grey),
                        ),
                        const SizedBox(height: 12),
                        BarcodeWidget(
                          barcode: Barcode.code128(),
                          data: prescription.secureCode,
                          width: 250,
                          height: 70,
                          drawText: true,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'ID: ${prescription.secureCode}',
                          style: const TextStyle(fontSize: 12, color: Colors.grey, fontFamily: 'monospace'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Cette ordonnance numérique est sécurisée et valable en pharmacie.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
