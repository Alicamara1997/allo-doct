import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/colors.dart';
import '../../../core/models/notification_model.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/prescription_service.dart';
import '../../../core/models/prescription_model.dart';
import '../../../shared/widgets/prescription_detail_screen.dart';

class NotificationPanel extends StatelessWidget {
  final String userId;

  const NotificationPanel({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Notifications', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: StreamBuilder<List<NotificationModel>>(
              stream: NotificationService().getNotifications(userId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final notifications = snapshot.data!;

                if (notifications.isEmpty) {
                  return const Center(child: Text('Aucune notification'));
                }

                return ListView.builder(
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final notif = notifications[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: notif.isRead ? Colors.grey.shade100 : AppColors.primaryLight,
                        child: Icon(
                          notif.type == 'prescription' ? Icons.description : Icons.notifications,
                          color: notif.isRead ? Colors.grey : AppColors.primary,
                        ),
                      ),
                      title: Text(notif.title, style: TextStyle(fontWeight: notif.isRead ? FontWeight.normal : FontWeight.bold)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(notif.message),
                          Text(DateFormat('dd/MM HH:mm').format(notif.date), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                        ],
                      ),
                      onTap: () async {
                        // Marquer comme lu
                        NotificationService().markAsRead(notif.id!);
                        
                        // Action selon le type
                        if (notif.type == 'prescription' && notif.data?['prescriptionId'] != null) {
                           _handlePrescriptionClick(context, notif.data!['prescriptionId']);
                        }
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _handlePrescriptionClick(BuildContext context, String secureCode) async {
    // On ferme le panel
    Navigator.pop(context);
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
    
    try {
      final pres = await PrescriptionService().getPrescriptionByCode(secureCode);
      
      if (context.mounted) {
        Navigator.pop(context); // Close loading
        if (pres != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PrescriptionDetailScreen(prescription: pres),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Impossible de charger l\'ordonnance.')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
    }
  }
}
