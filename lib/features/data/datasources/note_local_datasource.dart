import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/note_model.dart';
import '../../domain/entities/note_entity.dart';

// =================================================================
// 💾 note_local_datasource.dart — Hive DataSource
// =================================================================
//
// DataSource = Data যেখান থেকে আসে তার সাথে সরাসরি কথা বলে।
//
// এই layer এর কাজ:
//   → Hive Box খোলা/পড়া/লেখা
//   → Raw Exception throw করা (Failure না)
//
// Repository এই Exception কে Failure এ convert করবে।
//
// কেন আলাদা Abstract + Implementation?
//   Testing এ MockLocalDataSource inject করা যায়।
//   Datasource বদলালে (Hive → SQLite) শুধু implementation বদলায়।

// ──────────────────────────────────────────────
// Abstract Interface
// ──────────────────────────────────────────────
abstract class NoteLocalDataSource {
  Future<List<NoteModel>> getNotes();
  Future<NoteModel> addNote(NoteEntity note);
  Future<NoteModel> updateNote(NoteEntity note);
  Future<bool> deleteNote(String id);
}

// ──────────────────────────────────────────────
// Hive Implementation
// ──────────────────────────────────────────────
class NoteLocalDataSourceImpl implements NoteLocalDataSource {
  static const String _boxName = 'notes_box';
  final _uuid = const Uuid();

  // Hive Box reference (lazy load)
  Box<NoteModel> get _box => Hive.box<NoteModel>(_boxName);

  // Box name — injection container এ Hive.openBox() করতে লাগবে
  static String get boxName => _boxName;

  // ──────────────────────────────────────────────
  @override
  Future<List<NoteModel>> getNotes() async {
    try {
      // Hive values list → NoteModel list
      // reversed() → সর্বশেষ added টা আগে দেখাবে
      return _box.values.toList().reversed.toList();
    } catch (e) {
      throw Exception('Failed to get notes: $e');
    }
  }

  // ──────────────────────────────────────────────
  @override
  Future<NoteModel> addNote(NoteEntity note) async {
    try {
      // নতুন unique ID দাও
      final newNote = NoteModel.fromEntity(note.copyWith(id: _uuid.v4()));
      // Hive এ key হিসেবে id ব্যবহার করো
      await _box.put(newNote.id, newNote);
      return newNote;
    } catch (e) {
      throw Exception('Failed to add note: $e');
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
}
