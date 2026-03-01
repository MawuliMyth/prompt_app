import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createUserDoc(User user) async {
    final docRef = _firestore.collection('users').doc(user.uid);
    final docSnap = await docRef.get();

    if (!docSnap.exists) {
      final newUser = UserModel(
        uid: user.uid,
        email: user.email ?? '',
        displayName: user.displayName ?? '',
        photoUrl: user.photoURL,
        createdAt: DateTime.now(),
        totalPromptsGenerated: 0,
      );

      await docRef.set(newUser.toMap());
    }
  }

  Future<UserModel?> getUser(String uid) async {
    final docSnap = await _firestore.collection('users').doc(uid).get();
    if (docSnap.exists && docSnap.data() != null) {
      return UserModel.fromMap(docSnap.data()!, docSnap.id);
    }
    return null;
  }

  Future<void> incrementTotalPrompts(String uid) async {
    final docRef = _firestore.collection('users').doc(uid);
    // Use set with merge to create document if it doesn't exist
    await docRef.set({
      'totalPromptsGenerated': FieldValue.increment(1),
    }, SetOptions(merge: true));
  }
}
