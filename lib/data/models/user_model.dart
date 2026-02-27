import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String? photoUrl;
  final DateTime createdAt;
  final int totalPromptsGenerated;

  UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl,
    required this.createdAt,
    this.totalPromptsGenerated = 0,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String documentId) {
    return UserModel(
      uid: documentId,
      email: map['email'] ?? '',
      displayName: map['displayName'] ?? '',
      photoUrl: map['photoUrl'],
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] is Timestamp
              ? (map['createdAt'] as Timestamp).toDate()
              : map['createdAt'].toDate())
          : DateTime.now(),
      totalPromptsGenerated: map['totalPromptsGenerated']?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'totalPromptsGenerated': totalPromptsGenerated,
    };
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoUrl,
    DateTime? createdAt,
    int? totalPromptsGenerated,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      totalPromptsGenerated: totalPromptsGenerated ?? this.totalPromptsGenerated,
    );
  }
}
