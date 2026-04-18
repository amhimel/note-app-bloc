import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/note_model.dart';

// এই layer সরাসরি Firestore এর সাথে কথা বলে।
// Repository এই datasource কে online থাকলে call করে।
//
// Firestore Structure:
//   Collection: "notes"
//     Document ID: note.id (Hive এর id ব্যবহার করবো)
//       fields: title, content, color, createdAt, updatedAt

abstract class NoteRemoteDataSource {
  /// Firestore থেকে সব notes আনো
  Future<List<NoteModel>> getNotes();

  /// Firestore এ note save করো (create বা overwrite)
  Future<void> saveNote(NoteModel note);

  /// Firestore এ note update করো
  Future<void> updateNote(NoteModel note);

  /// Firestore থেকে note মুছো
  Future<void> deleteNote(String id);

  /// একাধিক note একসাথে sync করো (batch write)
  Future<void> syncNotes(List<NoteModel> notes);
}

class NoteRemoteDataSourceImpl implements NoteRemoteDataSource {
  final FirebaseFirestore firestore;
  static const String _collection = 'notes';

  const NoteRemoteDataSourceImpl({required this.firestore});

  // Firestore collection reference — helper
  CollectionReference<Map<String, dynamic>> get _notesRef =>
      firestore.collection(_collection);

  // ──────────────────────────────────────────────
  @override
  Future<List<NoteModel>> getNotes() async {
    try {
      final snapshot = await _notesRef
          .orderBy('updatedAt', descending: true)
          .get();

      return snapshot.docs.map((doc) => NoteModel.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Firestore getNotes failed: $e');
    }
  }

  // ──────────────────────────────────────────────
  @override
  Future<void> saveNote(NoteModel note) async {
    try {
      // Document ID হিসেবে note.id ব্যবহার করো
      // এতে Hive ও Firestore এ same ID থাকে
      await _notesRef.doc(note.id).set(note.toFirestore());
    } catch (e) {
      throw Exception('Firestore saveNote failed: $e');
    }
  }

  // ──────────────────────────────────────────────
  @override
  Future<void> updateNote(NoteModel note) async {
    try {
      await _notesRef.doc(note.id).update(note.toFirestore());
    } catch (e) {
      throw Exception('Firestore updateNote failed: $e');
    }
  }

  // ──────────────────────────────────────────────
  @override
  Future<void> deleteNote(String id) async {
    try {
      await _notesRef.doc(id).delete();
    } catch (e) {
      throw Exception('Firestore deleteNote failed: $e');
    }
  }

  // ──────────────────────────────────────────────
  // syncNotes — Batch Write (offline এ জমা notes একসাথে push)
  // ──────────────────────────────────────────────
  // Firestore Batch: সব write একটি atomic operation এ।
  // একটা fail করলে সব fail — data inconsistency হয় না।
  @override
  Future<void> syncNotes(List<NoteModel> notes) async {
    if (notes.isEmpty) return;

    try {
      final batch = firestore.batch();

      for (final note in notes) {
        final docRef = _notesRef.doc(note.id);
        batch.set(docRef, note.toFirestore());
      }

      // সব write একসাথে execute করো
      await batch.commit();
    } catch (e) {
      throw Exception('Firestore syncNotes failed: $e');
    }
  }
}
