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

  // Mettre à jour une ordonnance
  Future<bool> updatePrescription(String id, PrescriptionModel prescription) async {
    try {
      await _db.collection('prescriptions').doc(id).update(prescription.toMap());
      return true;
    } catch (e) {
      print('Erreur mise à jour ordonnance: $e');
      return false;
    }
  }

  // Récupérer les ordonnances d'un patient
  Stream<List<PrescriptionModel>> getPatientPrescriptions(String patientId) {
    return _db
        .collection('prescriptions')
        .where('patientId', isEqualTo: patientId)
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
            .map((doc) => PrescriptionModel.fromFirestore(doc))
            .toList();
          // Tri côté client pour éviter l'erreur d'index Firestore
          list.sort((a, b) => b.date.compareTo(a.date));
          return list;
        });
  }

  // Récupérer les ordonnances d'un praticien (historique)
  Stream<List<PrescriptionModel>> getPractitionerPrescriptions(String practitionerId) {
    return _db
        .collection('prescriptions')
        .where('practitionerId', isEqualTo: practitionerId)
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
            .map((doc) => PrescriptionModel.fromFirestore(doc))
            .toList();
          // Tri côté client
          list.sort((a, b) => b.date.compareTo(a.date));
          return list;
        });
  }

  // Récupérer une ordonnance par son code sécurisé
  Future<PrescriptionModel?> getPrescriptionByCode(String code) async {
    final query = await _db
        .collection('prescriptions')
        .where('secureCode', isEqualTo: code)
        .limit(1)
        .get();
    
    if (query.docs.isNotEmpty) {
      return PrescriptionModel.fromFirestore(query.docs.first);
    }
    return null;
  }

  // Générer un code de sécurité unique (pour le code-barres)
  String generateSecureCode() {
    final random = Random();
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return List.generate(12, (index) => chars[random.nextInt(chars.length)]).join();
  }
}
