import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NoteService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _notesCol {
    final uid = _auth.currentUser!.uid;
    return _db.collection('Users').doc(uid).collection('Notes');
  }

  Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>> streamNotes() {
    return _notesCol
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snap) => snap.docs);
  }

  Future<void> addNote(String text, [int? color]) {
    return _notesCol.add({
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
      'color': color ?? 0xFFFFFFFF,
    });
  }

  Future<void> updateNote(String id, String text, int color) {
    return _notesCol.doc(id).update({
      'text': text,
      'color': color,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteNote(String id) {
    return _notesCol.doc(id).delete();
  }
}
