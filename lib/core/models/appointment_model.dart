import 'package:cloud_firestore/cloud_firestore.dart';

class AppointmentModel {
  final String? id;
  final String patientId;
  final String patientName;
  final String practitionerId;
  final String practitionerName;
  final DateTime dateTime;
  final String status; // 'pending', 'confirmed', 'cancelled', 'completed'
  final DateTime createdAt;

  AppointmentModel({
    this.id,
    required this.patientId,
    required this.patientName,
    required this.practitionerId,
    required this.practitionerName,
    required this.dateTime,
    this.status = 'pending',
    required this.createdAt,
  });

  factory AppointmentModel.fromMap(Map<String, dynamic> data, String documentId) {
    return AppointmentModel(
      id: documentId,
      patientId: data['patientId'] ?? '',
      patientName: data['patientName'] ?? 'Patient',
      practitionerId: data['practitionerId'] ?? '',
      practitionerName: data['practitionerName'] ?? 'Praticien',
      dateTime: (data['dateTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: data['status'] ?? 'pending',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'patientId': patientId,
      'patientName': patientName,
      'practitionerId': practitionerId,
      'practitionerName': practitionerName,
      'dateTime': Timestamp.fromDate(dateTime),
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
