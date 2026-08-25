import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/prompt_model.dart';

class PromptRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _userPromptsRef(String userId) {
    return _firestore.collection('users').doc(userId).collection('prompts');
  }

  Future<void> savePrompt(String userId, PromptModel prompt) async {
    try {
      final data = prompt.toMap();
      await _userPromptsRef(userId).doc(prompt.id).set(data);
    } catch (e) {
      debugPrint('Error saving prompt: $e');
      rethrow;
    }
  }

  Future<void> deletePrompt(String userId, String promptId) async {
    try {
      await _userPromptsRef(userId).doc(promptId).delete();
    } catch (e) {
      debugPrint('Error deleting prompt: $e');
      rethrow;
    }
  }

  Future<void> toggleFavourite(String userId, String promptId, bool newStatus) async {
    try {
      await _userPromptsRef(userId).doc(promptId).update({
        'isFavourite': newStatus,
      });
    } catch (e) {
      debugPrint('Error updating favourite: $e');
      rethrow;
    }
  }

  Stream<List<PromptModel>> watchPrompts(String userId) {
    return _userPromptsRef(userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => PromptModel.fromMap(doc.data(), doc.id))
              .toList();
        });
  }

  Future<void> clearAllHistory(String userId) async {
    final snapshot = await _userPromptsRef(userId).get();
    final batch = _firestore.batch();
    for (var doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}
