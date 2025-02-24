import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String id;
  final String fullName;
  final String email;
  final String nationalId;
  final String farmLocation;
  final String phoneNumber;
  final String gender;
  final String dateOfBirth;
  final String? profileImage; // Stores Base64 string

  AppUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.nationalId,
    required this.farmLocation,
    required this.phoneNumber,
    required this.gender,
    required this.dateOfBirth,
    this.profileImage,
  });

  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'email': email,
      'nationalId': nationalId,
      'farmLocation': farmLocation,
      'phoneNumber': phoneNumber,
      'gender': gender,
      'dateOfBirth': dateOfBirth,
      'profileImage': profileImage,
    };
  }

  factory AppUser.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot, SnapshotOptions? options) {
    final data = snapshot.data();
    return AppUser(
      id: snapshot.id,
      fullName: data?['fullName'] ?? '',
      email: data?['email'] ?? '',
      nationalId: data?['nationalId'] ?? '',
      farmLocation: data?['farmLocation'] ?? '',
      phoneNumber: data?['phoneNumber'] ?? '',
      gender: data?['gender'] ?? '-',
      dateOfBirth: data?['dateOfBirth'] ?? '-',
      profileImage: data?['profileImage'] as String?, // Explicitly cast to String?
    );
  }
}