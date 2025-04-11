import 'package:cloud_firestore/cloud_firestore.dart';

class UserData {
  final String uid;
  final String email;
  final String? displayName;
  final String? photoURL;
  final DateTime createdAt;
  final Map<String, dynamic> preferences;

  UserData({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoURL,
    required this.createdAt,
    required this.preferences,
  });

  factory UserData.fromFirestore(Map<String, dynamic> data) {
    // Handle the timestamp conversion safely
    DateTime parseCreatedAt() {
      try {
        final createdAtData = data['createdAt'];
        if (createdAtData is Timestamp) {
          return createdAtData.toDate();
        } else {
          // Return current date if timestamp is missing or invalid
          return DateTime.now();
        }
      } catch (e) {
        print('Error parsing timestamp: $e');
        return DateTime.now();
      }
    }

    return UserData(
      uid: data['uid'] as String? ?? '',
      email: data['email'] as String? ?? '',
      displayName: data['displayName'] as String?,
      photoURL: data['photoURL'] as String?,
      createdAt: parseCreatedAt(),
      preferences: data['preferences'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'createdAt': Timestamp.fromDate(createdAt),
      'preferences': preferences,
    };
  }

  UserData copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoURL,
    DateTime? createdAt,
    Map<String, dynamic>? preferences,
  }) {
    return UserData(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      createdAt: createdAt ?? this.createdAt,
      preferences: preferences ?? this.preferences,
    );
  }
} 