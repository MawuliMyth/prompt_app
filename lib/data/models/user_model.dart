import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String? photoUrl;
  final DateTime createdAt;
  final int totalPromptsGenerated;

  // Premium fields
  final bool isPremium;
  final String planType; // 'free', 'monthly', 'yearly', 'lifetime'
  final DateTime? premiumExpiryDate;
  final DateTime? trialStartDate;
  final bool trialUsed;

  UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl,
    required this.createdAt,
    this.totalPromptsGenerated = 0,
    this.isPremium = false,
    this.planType = 'free',
    this.premiumExpiryDate,
    this.trialStartDate,
    this.trialUsed = false,
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
      isPremium: map['isPremium'] ?? false,
      planType: map['planType'] ?? 'free',
      premiumExpiryDate: map['premiumExpiryDate'] != null
          ? (map['premiumExpiryDate'] is Timestamp
              ? (map['premiumExpiryDate'] as Timestamp).toDate()
              : map['premiumExpiryDate'].toDate())
          : null,
      trialStartDate: map['trialStartDate'] != null
          ? (map['trialStartDate'] is Timestamp
              ? (map['trialStartDate'] as Timestamp).toDate()
              : map['trialStartDate'].toDate())
          : null,
      trialUsed: map['trialUsed'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'totalPromptsGenerated': totalPromptsGenerated,
      'isPremium': isPremium,
      'planType': planType,
      'premiumExpiryDate': premiumExpiryDate != null
          ? Timestamp.fromDate(premiumExpiryDate!)
          : null,
      'trialStartDate': trialStartDate != null
          ? Timestamp.fromDate(trialStartDate!)
          : null,
      'trialUsed': trialUsed,
    };
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoUrl,
    DateTime? createdAt,
    int? totalPromptsGenerated,
    bool? isPremium,
    String? planType,
    DateTime? premiumExpiryDate,
    DateTime? trialStartDate,
    bool? trialUsed,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      totalPromptsGenerated: totalPromptsGenerated ?? this.totalPromptsGenerated,
      isPremium: isPremium ?? this.isPremium,
      planType: planType ?? this.planType,
      premiumExpiryDate: premiumExpiryDate ?? this.premiumExpiryDate,
      trialStartDate: trialStartDate ?? this.trialStartDate,
      trialUsed: trialUsed ?? this.trialUsed,
    );
  }

  /// Check if trial is currently active (within 3 days of start)
  bool get isTrialActive {
    if (trialStartDate == null) return false;
    final now = DateTime.now();
    final trialEnd = trialStartDate!.add(const Duration(days: 3));
    return now.isBefore(trialEnd);
  }

  /// Get days left in trial (0 if expired or no trial)
  int get daysLeftInTrial {
    if (trialStartDate == null) return 0;
    final now = DateTime.now();
    final trialEnd = trialStartDate!.add(const Duration(days: 3));
    if (now.isAfter(trialEnd)) return 0;
    return trialEnd.difference(now).inDays;
  }

  /// Check if premium is expired (for time-based plans)
  bool get isPremiumExpired {
    if (!isPremium) return true;
    if (planType == 'lifetime') return false;
    if (premiumExpiryDate == null) return true;
    return DateTime.now().isAfter(premiumExpiryDate!);
  }

  /// Check if user has active premium access
  bool get hasPremiumAccess {
    return isPremium && !isPremiumExpired;
  }
}
