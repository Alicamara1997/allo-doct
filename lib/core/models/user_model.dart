import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String role; // 'patient' or 'practitioner'
  final String name;
  final String? photoUrl;
  final String? clinicPhotoUrl;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.role,
    required this.name,
    this.photoUrl,
    this.clinicPhotoUrl,
    required this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> data, String documentId) {
    return UserModel(
      uid: documentId,
      email: data['email'] ?? '',
      role: data['role'] ?? 'patient',
      name: data['name'] ?? '',
      photoUrl: data['photoUrl'],
      clinicPhotoUrl: data['clinicPhotoUrl'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'role': role,
      'name': name,
      'photoUrl': photoUrl,
      'clinicPhotoUrl': clinicPhotoUrl,
      'createdAt': createdAt,
    };
  }
}
