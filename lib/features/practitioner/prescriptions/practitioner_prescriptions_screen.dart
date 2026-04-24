import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/colors.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/prescription_service.dart';
import '../../../core/models/prescription_model.dart';
import '../../../shared/widgets/prescription_detail_screen.dart';
import 'prescription_create_screen.dart';

class PractitionerPrescriptionsScreen extends StatelessWidget {
  const PractitionerPrescriptionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Historique des Ordonnances'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textMain,
        elevation: 0,
      ),
      body: StreamBuilder<List<PrescriptionModel>>(
        stream: PrescriptionService().getPractitionerPrescriptions(user?.uid ?? ''),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final prescriptions = snapshot.data ?? [];

          if (prescriptions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.description_outlined, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  const Text('Aucune ordonnance rédigée'),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: prescriptions.length,
            itemBuilder: (context, index) {
              final pres = prescriptions[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.primaryLight,
                    child: Icon(Icons.description, color: AppColors.primary),
                  ),
                  title: Text(pres.patientName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    '${pres.medications.length} médicament(s) • ${DateFormat('dd/MM/yyyy').format(pres.date)}'
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PrescriptionCreateScreen(
                                existingPrescription: pres,
                              ),
                            ),
                          );
                        },
                      ),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PrescriptionDetailScreen(prescription: pres),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
