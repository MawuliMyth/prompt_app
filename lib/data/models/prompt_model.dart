import 'package:cloud_firestore/cloud_firestore.dart';

class PromptModel {
  final String id;
  final String originalText;
  final String enhancedPrompt;
  final String category;
  final int strengthScore;
  final bool isFavourite;
  final DateTime createdAt;
  final String? userId; // nullable for guest users

  PromptModel({
    required this.id,
    required this.originalText,
    required this.enhancedPrompt,
    required this.category,
    required this.strengthScore,
    this.isFavourite = false,
    required this.createdAt,
    this.userId,
  });

  factory PromptModel.fromMap(Map<String, dynamic> map, String documentId) {
    return PromptModel(
      id: documentId,
      originalText: map['originalText'] ?? '',
      enhancedPrompt: map['enhancedPrompt'] ?? '',
      category: map['category'] ?? 'General',
      strengthScore: map['strengthScore']?.toInt() ?? 0,
      isFavourite: map['isFavourite'] ?? false,
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] is Timestamp
              ? (map['createdAt'] as Timestamp).toDate()
              : map['createdAt'].toDate())
          : DateTime.now(),
      userId: map['userId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'originalText': originalText,
      'enhancedPrompt': enhancedPrompt,
      'category': category,
      'strengthScore': strengthScore,
      'isFavourite': isFavourite,
      'createdAt': Timestamp.fromDate(createdAt),
      'userId': userId,
    };
  }

  PromptModel copyWith({
    String? id,
    String? originalText,
    String? enhancedPrompt,
    String? category,
    int? strengthScore,
    bool? isFavourite,
    DateTime? createdAt,
    String? userId,
  }) {
    return PromptModel(
      id: id ?? this.id,
      originalText: originalText ?? this.originalText,
      enhancedPrompt: enhancedPrompt ?? this.enhancedPrompt,
      category: category ?? this.category,
      strengthScore: strengthScore ?? this.strengthScore,
      isFavourite: isFavourite ?? this.isFavourite,
      createdAt: createdAt ?? this.createdAt,
      userId: userId ?? this.userId,
    );
  }
}
