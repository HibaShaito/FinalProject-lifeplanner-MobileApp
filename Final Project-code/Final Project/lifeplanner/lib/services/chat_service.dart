import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _chatCol {
    final uid = _auth.currentUser!.uid;
    return _db.collection('Users').doc(uid).collection('Chats');
  }

  /// Add a new message (auto‐generate ID)
  Future<void> addMessage(String text, bool isUser) {
    return _chatCol.add({
      'text': text,
      'isUser': isUser,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  /// Delete one message
  Future<void> deleteMessage(String messageId) {
    return _chatCol.doc(messageId).delete();
  }

  /// Delete entire history
  Future<void> clearHistory() async {
    final batch = _db.batch();
    final snap = await _chatCol.get();
    for (var doc in snap.docs) {
      batch.delete(doc.reference);
    }
    return batch.commit();
  }

  /// Stream last N messages, ordered by timestamp descending
  Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>> streamRecent(
    int limit,
  ) {
    return _chatCol
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs);
  }
}
