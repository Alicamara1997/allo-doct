import 'package:cloud_firestore/cloud_firestore.dart';

class MedicationModel {
  final String name;
  final String dosage;
  final String duration;
  final String instructions;

  MedicationModel({
    required this.name,
    required this.dosage,
    required this.duration,
    required this.instructions,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'dosage': dosage,
      'duration': duration,
      'instructions': instructions,
    };
  }

  factory MedicationModel.fromMap(Map<String, dynamic> map) {
    return MedicationModel(
      name: map['name'] ?? '',
      dosage: map['dosage'] ?? '',
      duration: map['duration'] ?? '',
      instructions: map['instructions'] ?? '',
    );
  }
}

class PrescriptionModel {
  final String? id;
  final String patientId;
  final String patientName;
  final String practitionerId;
  final String practitionerName;
  final String practitionerSpecialty;
  final DateTime date;
  final List<MedicationModel> medications;
  final String secureCode; // Unique code for barcode/QR
  final String? signatureUrl;
  final String? pdfUrl;
  final String? note;

  PrescriptionModel({
    this.id,
    required this.patientId,
    required this.patientName,
    required this.practitionerId,
    required this.practitionerName,
    required this.practitionerSpecialty,
    required this.date,
    required this.medications,
    required this.secureCode,
    this.signatureUrl,
    this.pdfUrl,
    this.note,
  });

  Map<String, dynamic> toMap() {
    return {
      'patientId': patientId,
      'patientName': patientName,
      'practitionerId': practitionerId,
      'practitionerName': practitionerName,
      'practitionerSpecialty': practitionerSpecialty,
      'date': Timestamp.fromDate(date),
      'medications': medications.map((m) => m.toMap()).toList(),
      'secureCode': secureCode,
      'signatureUrl': signatureUrl,
      'pdfUrl': pdfUrl,
      'note': note,
    };
  }

  factory PrescriptionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PrescriptionModel(
      id: doc.id,
      patientId: data['patientId'] ?? '',
      patientName: data['patientName'] ?? '',
      practitionerId: data['practitionerId'] ?? '',
      practitionerName: data['practitionerName'] ?? '',
      practitionerSpecialty: data['practitionerSpecialty'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      medications: (data['medications'] as List)
          .map((m) => MedicationModel.fromMap(m as Map<String, dynamic>))
          .toList(),
      secureCode: data['secureCode'] ?? '',
      signatureUrl: data['signatureUrl'],
      pdfUrl: data['pdfUrl'],
      note: data['note'],
    );
  }
}
