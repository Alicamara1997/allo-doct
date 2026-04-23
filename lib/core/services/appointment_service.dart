import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/appointment_model.dart';
import '../models/user_model.dart';

class AppointmentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Créer un RDV
  Future<bool> createAppointment({
    required UserModel patient,
    required String practitionerId,
    required String practitionerName,
    required DateTime dateTime,
  }) async {
    try {
      final appointment = AppointmentModel(
        patientId: patient.uid,
        patientName: patient.name,
        practitionerId: practitionerId,
        practitionerName: practitionerName,
        dateTime: dateTime,
        createdAt: DateTime.now(),
      );

      await _firestore.collection('appointments').add(appointment.toMap());
      return true;
    } catch (e) {
      return false;
    }
  }

  // Obtenir les RDV d'un patient
  Stream<List<AppointmentModel>> getPatientAppointments(String patientId) {
    return _firestore
        .collection('appointments')
        .where('patientId', isEqualTo: patientId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) => AppointmentModel.fromMap(doc.data(), doc.id)).toList();
      list.sort((a, b) => a.dateTime.compareTo(b.dateTime));
      return list;
    });
  }

  // Obtenir les RDV d'un praticien (seulement pour la journée d'aujourd'hui en option, ou tout)
  Stream<List<AppointmentModel>> getPractitionerAppointments(String practitionerId) {
    return _firestore
        .collection('appointments')
        .where('practitionerId', isEqualTo: practitionerId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) => AppointmentModel.fromMap(doc.data(), doc.id)).toList();
      list.sort((a, b) => a.dateTime.compareTo(b.dateTime));
      return list;
    });
  }

  // Mettre à jour le statut d'un RDV
  Future<bool> updateAppointmentStatus(String appointmentId, String newStatus) async {
    try {
      await _firestore.collection('appointments').doc(appointmentId).update({
        'status': newStatus,
      });
      return true;
    } catch (e) {
      return false;
    }
  }
}
