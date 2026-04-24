import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/prescription_model.dart';
import 'dart:math';

class PrescriptionService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Créer une ordonnance
  Future<bool> createPrescription(PrescriptionModel prescription) async {
    try {
      await _db.collection('prescriptions').add(prescription.toMap());
      return true;
    } catch (e) {
      print('Erreur creation ordonnance: $e');
      return false;
    }
  }

  // Récupérer les ordonnances d'un patient
  Stream<List<PrescriptionModel>> getPatientPrescriptions(String patientId) {
    return _db
        .collection('prescriptions')
        .where('patientId', isEqualTo: patientId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PrescriptionModel.fromFirestore(doc))
            .toList());
  }

  // Récupérer les ordonnances d'un praticien (historique)
  Stream<List<PrescriptionModel>> getPractitionerPrescriptions(String practitionerId) {
    return _db
        .collection('prescriptions')
        .where('practitionerId', isEqualTo: practitionerId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PrescriptionModel.fromFirestore(doc))
            .toList());
  }

  // Générer un code de sécurité unique (pour le code-barres)
  String generateSecureCode() {
    final random = Random();
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return List.generate(12, (index) => chars[random.nextInt(chars.length)]).join();
  }
}
