import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';

class NotificationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Envoyer une notification
  Future<void> sendNotification(NotificationModel notification) async {
    try {
      await _db.collection('notifications').add(notification.toMap());
    } catch (e) {
      print('Erreur notification: $e');
    }
  }

  // Écouter les notifications d'un utilisateur
  Stream<List<NotificationModel>> getNotifications(String userId) {
    return _db
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
            .map((doc) => NotificationModel.fromFirestore(doc))
            .toList();
          list.sort((a, b) => b.date.compareTo(a.date));
          return list;
        });
  }

  // Marquer comme lu
  Future<void> markAsRead(String notificationId) async {
    await _db.collection('notifications').doc(notificationId).update({'isRead': true});
  }
}
