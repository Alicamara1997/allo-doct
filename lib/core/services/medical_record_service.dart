import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/medical_record_model.dart';

class MedicalRecordService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Récupérer le dossier médical d'un patient
  Stream<MedicalRecordModel?> getPatientMedicalRecord(String patientId) {
    return _firestore
        .collection('medical_records')
        .where('patientId', isEqualTo: patientId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      return MedicalRecordModel.fromMap(snapshot.docs.first.data(), snapshot.docs.first.id);
    });
  }

  // Sauvegarder ou mettre à jour un dossier médical
  Future<bool> saveMedicalRecord(MedicalRecordModel record) async {
    try {
      if (record.id != null && record.id!.isNotEmpty) {
        // Mise à jour
        await _firestore.collection('medical_records').doc(record.id).update(record.toMap());
      } else {
        // Création (ou écrasement basé sur patientId pour s'assurer de l'unicité)
        // D'abord vérifier s'il existe déjà pour éviter les doublons
        final query = await _firestore
            .collection('medical_records')
            .where('patientId', isEqualTo: record.patientId)
            .get();
        
        if (query.docs.isNotEmpty) {
          await _firestore.collection('medical_records').doc(query.docs.first.id).update(record.toMap());
        } else {
           await _firestore.collection('medical_records').add(record.toMap());
        }
      }
      return true;
    } catch (e) {
      return false;
    }
  }
}
