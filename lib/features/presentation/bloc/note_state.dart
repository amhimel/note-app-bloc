import 'package:equatable/equatable.dart';
import '../../domain/entities/note_entity.dart';

// State = App এর current situation।
// BLoC নতুন State emit করলে BlocBuilder UI rebuild করে।
//
// State Rules:
//   ✅ Immutable — সরাসরি পরিবর্তন করা যাবে না
//   ✅ Equatable — same state এ UI rebuild হবে না
//   ✅ Descriptive — State এর নাম দেখেই বোঝা যায় কী হচ্ছে

abstract class NoteState extends Equatable {
  const NoteState();

  @override
  List<Object?> get props => [];
}

// ──────────────────────────────────────────────
// Initial — App এর প্রথম মুহূর্ত
// ──────────────────────────────────────────────
class NoteInitial extends NoteState {
  const NoteInitial();
}

// ──────────────────────────────────────────────
// Loading — Async operation চলছে
// ──────────────────────────────────────────────
class NoteLoading extends NoteState {
  const NoteLoading();
}

// ──────────────────────────────────────────────
// Loaded — Data ready, UI দেখাও
// ──────────────────────────────────────────────
// এই State সবচেয়ে বেশি ব্যবহার হয়।
// notes, filteredNotes, searchQuery — সব এখানে।
class NoteLoaded extends NoteState {
  final List<NoteEntity> notes; // সব notes
  final List<NoteEntity> filteredNotes; // search result
  final String searchQuery;

  const NoteLoaded({
    required this.notes,
    this.filteredNotes = const [],
    this.searchQuery = '',
  });

  // search চলছে কিনা
  bool get isSearching => searchQuery.isNotEmpty;

  // UI কোন list দেখাবে সেটা State নিজেই জানে
  List<NoteEntity> get displayNotes => isSearching ? filteredNotes : notes;

  NoteLoaded copyWith({
    List<NoteEntity>? notes,
    List<NoteEntity>? filteredNotes,
    String? searchQuery,
  }) => NoteLoaded(
    notes: notes ?? this.notes,
    filteredNotes: filteredNotes ?? this.filteredNotes,
    searchQuery: searchQuery ?? this.searchQuery,
  );

  @override
  List<Object?> get props => [notes, filteredNotes, searchQuery];
}

// ──────────────────────────────────────────────
// Action Success — Add/Update/Delete সফল
// ──────────────────────────────────────────────
// Loaded state emit করার আগে এই state emit করলে
// UI snackbar / navigation trigger করতে পারে।
class NoteActionSuccess extends NoteState {
  final String message;
  final List<NoteEntity> notes; // সর্বশেষ notes list

  const NoteActionSuccess({required this.message, required this.notes});

  @override
  List<Object?> get props => [message, notes];
}

// ──────────────────────────────────────────────
// Error — কিছু একটা ভুল হয়েছে
// ──────────────────────────────────────────────
class NoteError extends NoteState {
  final String message;

  const NoteError(this.message);

  @override
  List<Object?> get props => [message];
}
