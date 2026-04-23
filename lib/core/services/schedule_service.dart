import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/schedule_model.dart';

class ScheduleService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Récupérer les horaires d'un praticien
  Stream<ScheduleModel?> getPractitionerSchedule(String practitionerId) {
    return _firestore
        .collection('practitioner_schedules')
        .where('practitionerId', isEqualTo: practitionerId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      return ScheduleModel.fromMap(snapshot.docs.first.data(), snapshot.docs.first.id);
    });
  }

  // Obtenir pour usage asynchrone hors flux
  Future<ScheduleModel?> fetchPractitionerSchedule(String practitionerId) async {
    final query = await _firestore
        .collection('practitioner_schedules')
        .where('practitionerId', isEqualTo: practitionerId)
        .get();
    
    if (query.docs.isEmpty) return null;
    return ScheduleModel.fromMap(query.docs.first.data(), query.docs.first.id);
  }

  // Sauvegarder les horaires
  Future<bool> saveSchedule(ScheduleModel schedule) async {
    try {
      if (schedule.id != null && schedule.id!.isNotEmpty) {
        await _firestore.collection('practitioner_schedules').doc(schedule.id).update(schedule.toMap());
      } else {
        final query = await _firestore
            .collection('practitioner_schedules')
            .where('practitionerId', isEqualTo: schedule.practitionerId)
            .get();
        
        if (query.docs.isNotEmpty) {
           await _firestore.collection('practitioner_schedules').doc(query.docs.first.id).update(schedule.toMap());
        } else {
           await _firestore.collection('practitioner_schedules').add(schedule.toMap());
        }
      }
      return true;
    } catch (e) {
      return false;
    }
  }
}
