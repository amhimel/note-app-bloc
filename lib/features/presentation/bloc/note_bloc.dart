import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/note_entity.dart';
import '../../domain/usecases/get_notes.dart';
import '../../domain/usecases/add_note.dart';
import '../../domain/usecases/update_note.dart';
import '../../domain/usecases/delete_note.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/constants/app_colors.dart';
import 'note_event.dart';
import 'note_state.dart';

// BLoC এর একমাত্র কাজ:
//   Event receive → UseCase call → State emit
//
// BLoC নিজে কোনো Business Logic রাখে না।
// সব Logic UseCase এ আছে।
//
// ──────────────────────────────────────────────
// Clean Architecture তে BLoC:
//
//   UI  →(Event)→  BLoC  →(UseCase)→  Repository  →  DataSource
//   UI  ←(State)←  BLoC  ←(Either)←  Repository  ←  DataSource
// ──────────────────────────────────────────────
//
// Dependency Injection (get_it) দিয়ে BLoC তৈরি:
//   sl<NoteBloc>() → injection_container.dart থেকে

class NoteBloc extends Bloc<NoteEvent, NoteState> {
  // UseCases — Constructor Injection দিয়ে inject করা হয়
  final GetNotes _getNotes;
  final AddNote _addNote;
  final UpdateNote _updateNote;
  final DeleteNote _deleteNote;

  int _colorIndex = 0; // Note card color cycling

  NoteBloc({
    required GetNotes getNotes,
    required AddNote addNote,
    required UpdateNote updateNote,
    required DeleteNote deleteNote,
  }) : _getNotes = getNotes,
       _addNote = addNote,
       _updateNote = updateNote,
       _deleteNote = deleteNote,
       super(const NoteInitial()) {
    // প্রতিটি Event এর জন্য handler register করো
    on<NotesFetched>(_onNotesFetched);
    on<NoteAdded>(_onNoteAdded);
    on<NoteUpdated>(_onNoteUpdated);
    on<NoteDeleted>(_onNoteDeleted);
    on<NotesSearched>(_onNotesSearched);
    on<NoteSearchCleared>(_onNoteSearchCleared);
  }

  // ──────────────────────────────────────────────
  // Helper: current notes list সহজে পাওয়া
  // ──────────────────────────────────────────────
  List<NoteEntity> get _currentNotes {
    if (state is NoteLoaded) return (state as NoteLoaded).notes;
    if (state is NoteActionSuccess) return (state as NoteActionSuccess).notes;
    return const <NoteEntity>[];
  }

  // ══════════════════════════════════════════════
  // Handler: NotesFetched
  // ══════════════════════════════════════════════
  Future<void> _onNotesFetched(
    NotesFetched event,
    Emitter<NoteState> emit,
  ) async {
    emit(const NoteLoading());

    // UseCase call — Either<Failure, List<NoteEntity>> return করে
    final result = await _getNotes(NoParams());

    // fold = Either এর দুটো case handle করা
    //   Left  (failure) → error state
    //   Right (success) → loaded state
    result.fold(
      (failure) => emit(NoteError(failure.message)),
      (notes) => emit(NoteLoaded(notes: notes)),
    );
  }

  // ══════════════════════════════════════════════
  // Handler: NoteAdded
  // ══════════════════════════════════════════════
  Future<void> _onNoteAdded(NoteAdded event, Emitter<NoteState> emit) async {
    final result = await _addNote(
      AddNoteParams(
        title: event.title,
        content: event.content,
        color: event.color,
      ),
    );

    result.fold((failure) => emit(NoteError(failure.message)), (newNote) {
      // নতুন note list এর শুরুতে রাখো (latest first)
      final updated = <NoteEntity>[newNote, ..._currentNotes];

      // প্রথমে ActionSuccess emit করো (snackbar এর জন্য)
      emit(NoteActionSuccess(message: 'Note saved!', notes: updated));
      // তারপর Loaded emit করো (UI এর জন্য)
      emit(NoteLoaded(notes: updated));
    });
  }

  // ══════════════════════════════════════════════
  // Handler: NoteUpdated
  // ══════════════════════════════════════════════
  Future<void> _onNoteUpdated(
    NoteUpdated event,
    Emitter<NoteState> emit,
  ) async {
    final result = await _updateNote(UpdateParams(event.note));

    result.fold((failure) => emit(NoteError(failure.message)), (updatedNote) {
      // ✅ _currentNotes এখন List<NoteEntity>, তাই n এর type NoteEntity
      // map এ পুরানো note replace করো — id match করলে updatedNote দাও
      final updatedList = _currentNotes.map((n) {
        return n.id == updatedNote.id ? updatedNote : n;
      }).toList();

      emit(NoteActionSuccess(message: 'Note updated!', notes: updatedList));
      emit(NoteLoaded(notes: updatedList));
    });
  }

  // ══════════════════════════════════════════════
  // Handler: NoteDeleted
  // ══════════════════════════════════════════════
  Future<void> _onNoteDeleted(
    NoteDeleted event,
    Emitter<NoteState> emit,
  ) async {
    final result = await _deleteNote(DeleteNoteParam(event.id));

    result.fold((failure) => emit(NoteError(failure.message)), (_) {
      // ✅ _currentNotes এখন List<NoteEntity>
      // where() দিয়ে deleted note বাদ দাও
      final updatedList = _currentNotes.where((n) => n.id != event.id).toList();

      emit(NoteActionSuccess(message: 'Note deleted!', notes: updatedList));
      emit(NoteLoaded(notes: updatedList));
    });
  }

  // ══════════════════════════════════════════════
  // Handler: NotesSearched
  // ══════════════════════════════════════════════
  Future<void> _onNotesSearched(
    NotesSearched event,
    Emitter<NoteState> emit,
  ) async {
    if (state is! NoteLoaded) return;
    final currentState = state as NoteLoaded;
    final query = event.query.toLowerCase().trim();

    if (query.isEmpty) {
      emit(currentState.copyWith(filteredNotes: const [], searchQuery: ''));
      return;
    }

    final filtered = currentState.notes.where((note) {
      return note.title.toLowerCase().contains(query) ||
          note.content.toLowerCase().contains(query);
    }).toList();

    emit(
      currentState.copyWith(filteredNotes: filtered, searchQuery: event.query),
    );
  }

  // ══════════════════════════════════════════════
  // Handler: NoteSearchCleared
  // ══════════════════════════════════════════════
  Future<void> _onNoteSearchCleared(
    NoteSearchCleared event,
    Emitter<NoteState> emit,
  ) async {
    if (state is NoteLoaded) {
      final currentState = state as NoteLoaded;
      emit(currentState.copyWith(filteredNotes: const [], searchQuery: ''));
    }
  }

  // ──────────────────────────────────────────────
  // Note color cycling helper
  // ──────────────────────────────────────────────
  Color getNextColor() {
    final color =
        AppColors.noteColors[_colorIndex % AppColors.noteColors.length];
    _colorIndex++;
    return color;
  }
}
