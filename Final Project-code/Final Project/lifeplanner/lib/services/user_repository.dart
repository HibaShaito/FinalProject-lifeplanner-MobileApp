import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserRepository {
  final CollectionReference _users = FirebaseFirestore.instance.collection(
    'Users',
  );

  // Creates a new Firestore document if one doesn't exist.
  Future<void> createOrUpdateUser(User user) async {
    DocumentSnapshot userDoc = await _users.doc(user.uid).get();
    if (!userDoc.exists) {
      await _users.doc(user.uid).set({
        'email': user.email,
        'displayName': "User",
        'createdAt': FieldValue.serverTimestamp(),
        'customCategories': [],
      });
    }
  }
}
