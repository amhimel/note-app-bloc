import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/note_entity.dart';
import '../models/note_model.dart';

abstract class NoteLocalDataSource {
  Future<List<NoteModel>> getNotes();
  Future<NoteModel> addNote(NoteEntity note);
  Future<NoteModel> updateNote(NoteEntity note);
  Future<bool> deleteNote(String id);

  // ✅ Fix 1: clearAll abstract এ যোগ করা হয়েছে
  // _cacheRemoteNotes() এই method call করে।
  // Abstract এ না থাকলে NoteLocalDataSource type এ call হয় না।
  Future<void> clearAll();

  // ✅ Fix 2: cacheNote — Firestore থেকে আনা note store করে
  // addNote() নতুন uuid দেয়, কিন্তু Firestore id ধরে রাখতে হয়।
  // cacheNote() id বদলায় না — যা আছে তাই রাখে।
  Future<NoteModel> cacheNote(NoteEntity note);
}

class NoteLocalDataSourceImpl implements NoteLocalDataSource {
  static const String _boxName = 'notes_box';
  final _uuid = const Uuid();

  Box<NoteModel> get _box => Hive.box<NoteModel>(_boxName);

  static String get boxName => _boxName;

  // ──────────────────────────────────────────────
  @override
  Future<List<NoteModel>> getNotes() async {
    try {
      return _box.values.toList().reversed.toList();
    } catch (e) {
      throw Exception('Failed to get notes: $e');
    }
  }

  // ──────────────────────────────────────────────
  // addNote — সবসময় নতুন UUID দেয় (user create এর জন্য)
  @override
  Future<NoteModel> addNote(NoteEntity note) async {
    try {
      final newNote = NoteModel.fromEntity(note.copyWith(id: _uuid.v4()));
      await _box.put(newNote.id, newNote);
      return newNote;
    } catch (e) {
      throw Exception('Failed to add note: $e');
    }
  }

  // ──────────────────────────────────────────────
  // cacheNote — id অপরিবর্তিত রাখে (Firestore sync এর জন্য)
  // Firestore থেকে আনা note এর id ঠিক রেখে Hive তে store করো।
  @override
  Future<NoteModel> cacheNote(NoteEntity note) async {
    try {
      final model = NoteModel.fromEntity(note);
      await _box.put(model.id, model); // note.id ই key
      return model;
    } catch (e) {
      throw Exception('Failed to cache note: $e');
    }
  }

  // ──────────────────────────────────────────────
  @override
  Future<NoteModel> updateNote(NoteEntity note) async {
    try {
      if (!_box.containsKey(note.id)) {
        throw Exception('Note not found: ${note.id}');
      }
      final updatedModel = NoteModel.fromEntity(note);
      await _box.put(note.id, updatedModel);
      return updatedModel;
    } catch (e) {
      throw Exception('Failed to update note: $e');
    }
  }

  // ──────────────────────────────────────────────
  @override
  Future<bool> deleteNote(String id) async {
    try {
      if (!_box.containsKey(id)) {
        throw Exception('Note not found: $id');
      }
      await _box.delete(id);
      return true;
    } catch (e) {
      throw Exception('Failed to delete note: $e');
    }
  }

  // ──────────────────────────────────────────────
  // clearAll — Firestore sync আগে Hive পরিষ্কার করো
  @override
  Future<void> clearAll() async {
    try {
      await _box.clear();
    } catch (e) {
      throw Exception('Failed to clear notes box: $e');
    }
  }
}
