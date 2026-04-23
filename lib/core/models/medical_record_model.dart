import 'package:cloud_firestore/cloud_firestore.dart';

class MedicalRecordModel {
  final String? id;
  final String patientId;
  final String bloodType;
  final List<String> allergies;
  final List<String> currentTreatments;
  final String notes;

  MedicalRecordModel({
    this.id,
    required this.patientId,
    this.bloodType = '',
    this.allergies = const [],
    this.currentTreatments = const [],
    this.notes = '',
  });

  factory MedicalRecordModel.fromMap(Map<String, dynamic> data, String documentId) {
    return MedicalRecordModel(
      id: documentId,
      patientId: data['patientId'] ?? '',
      bloodType: data['bloodType'] ?? '',
      allergies: List<String>.from(data['allergies'] ?? []),
      currentTreatments: List<String>.from(data['currentTreatments'] ?? []),
      notes: data['notes'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'patientId': patientId,
      'bloodType': bloodType,
      'allergies': allergies,
      'currentTreatments': currentTreatments,
      'notes': notes,
    };
  }
}
