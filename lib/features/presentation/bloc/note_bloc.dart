import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:note_app_bloc/core/constants/app_colors.dart';
import '../../domain/entities/note_entity.dart';
import '../../domain/usecases/get_notes.dart';
import '../../domain/usecases/add_note.dart';
import '../../domain/usecases/update_note.dart';
import '../../domain/usecases/delete_note.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/usecases/usecase.dart';
import '../../data/repositories/note_repository_impl.dart';
import 'note_event.dart';
import 'note_state.dart';

// =================================================================
// 🧠 note_bloc.dart — Updated with Connectivity + Sync
// =================================================================
//
// নতুন দায়িত্ব:
//   1. NetworkInfo stream listen করো
//   2. Internet এলে → pending notes sync করো
//   3. State এ isOnline রাখো যাতে UI জানতে পারে

class NoteBloc extends Bloc<NoteEvent, NoteState> {
  final GetNotes _getNotes;
  final AddNote _addNote;
  final UpdateNote _updateNote;
  final DeleteNote _deleteNote;
  final NetworkInfo _networkInfo;
  final NoteRepositoryImpl _repository; // syncPendingNotes এর জন্য

  int _colorIndex = 0;
  StreamSubscription<bool>? _connectivitySub; // stream subscription

  NoteBloc({
    required GetNotes getNotes,
    required AddNote addNote,
    required UpdateNote updateNote,
    required DeleteNote deleteNote,
    required NetworkInfo networkInfo,
    required NoteRepositoryImpl repository,
  }) : _getNotes = getNotes,
       _addNote = addNote,
       _updateNote = updateNote,
       _deleteNote = deleteNote,
       _networkInfo = networkInfo,
       _repository = repository,
       super(const NoteInitial()) {
    on<NotesFetched>(_onNotesFetched);
    on<NoteAdded>(_onNoteAdded);
    on<NoteUpdated>(_onNoteUpdated);
    on<NoteDeleted>(_onNoteDeleted);
    on<NotesSearched>(_onNotesSearched);
    on<NoteSearchCleared>(_onNoteSearchCleared);
    on<ConnectivityChanged>(_onConnectivityChanged); // ← নতুন
    on<SyncPendingNotes>(_onSyncPendingNotes); // ← নতুন

    // Connectivity stream শুনতে শুরু করো
    _listenToConnectivity();
  }

  // ──────────────────────────────────────────────
  // Connectivity Stream Listener
  // ──────────────────────────────────────────────
  // BLoC তৈরি হওয়ার সাথে সাথে network change শোনা শুরু।
  // Status বদলালে ConnectivityChanged event পাঠাও।
  void _listenToConnectivity() {
    _connectivitySub = _networkInfo.onConnectivityChanged.listen(
      (isOnline) => add(ConnectivityChanged(isOnline)),
    );
  }

  // ──────────────────────────────────────────────
  // Helper: typed current notes
  // ──────────────────────────────────────────────
  List<NoteEntity> get _currentNotes {
    if (state is NoteLoaded) return (state as NoteLoaded).notes;
    if (state is NoteActionSuccess) return (state as NoteActionSuccess).notes;
    return const <NoteEntity>[];
  }

  bool get _currentIsOnline {
    if (state is NoteLoaded) return (state as NoteLoaded).isOnline;
    return true;
  }

  // ══════════════════════════════════════════════
  // Handler: NotesFetched
  // ══════════════════════════════════════════════
  Future<void> _onNotesFetched(
    NotesFetched event,
    Emitter<NoteState> emit,
  ) async {
    emit(const NoteLoading());
    final online = await _networkInfo.isConnected;
    final result = await _getNotes(NoParams());

    result.fold(
      (failure) => emit(NoteError(failure.message)),
      (notes) => emit(NoteLoaded(notes: notes, isOnline: online)),
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
      final updated = <NoteEntity>[newNote, ..._currentNotes];
      emit(NoteActionSuccess(message: 'Note saved!', notes: updated));
      emit(NoteLoaded(notes: updated, isOnline: _currentIsOnline));
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
      final updatedList = _currentNotes.map((n) {
        return n.id == updatedNote.id ? updatedNote : n;
      }).toList();
      emit(NoteActionSuccess(message: 'Note updated!', notes: updatedList));
      emit(NoteLoaded(notes: updatedList, isOnline: _currentIsOnline));
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
      final updatedList = _currentNotes.where((n) => n.id != event.id).toList();
      emit(NoteActionSuccess(message: 'Note deleted!', notes: updatedList));
      emit(NoteLoaded(notes: updatedList, isOnline: _currentIsOnline));
    });
  }

  // ══════════════════════════════════════════════
  // Handler: ConnectivityChanged ← সবচেয়ে গুরুত্বপূর্ণ নতুন handler
  // ══════════════════════════════════════════════
  Future<void> _onConnectivityChanged(
    ConnectivityChanged event,
    Emitter<NoteState> emit,
  ) async {
    if (state is! NoteLoaded) return;
    final currentState = state as NoteLoaded;

    if (event.isOnline) {
      // ✅ Internet এলো — isSyncing দেখাও
      emit(currentState.copyWith(isOnline: true, isSyncing: true));

      // Pending notes sync করো
      await _repository.syncPendingNotes();

      // Sync শেষে Firestore থেকে fresh data আনো
      final result = await _getNotes(NoParams());
      result.fold(
        (failure) =>
            emit(currentState.copyWith(isOnline: true, isSyncing: false)),
        (notes) =>
            emit(NoteLoaded(notes: notes, isOnline: true, isSyncing: false)),
      );
    } else {
      // ❌ Internet গেলো — শুধু isOnline=false করো
      emit(currentState.copyWith(isOnline: false, isSyncing: false));
    }
  }

  // ══════════════════════════════════════════════
  // Handler: SyncPendingNotes — manual trigger
  // ══════════════════════════════════════════════
  Future<void> _onSyncPendingNotes(
    SyncPendingNotes event,
    Emitter<NoteState> emit,
  ) async {
    if (state is! NoteLoaded) return;
    final currentState = state as NoteLoaded;

    emit(currentState.copyWith(isSyncing: true));
    await _repository.syncPendingNotes();
    emit(currentState.copyWith(isSyncing: false));
  }

  // ══════════════════════════════════════════════
  // Search handlers (unchanged)
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

  Future<void> _onNoteSearchCleared(
    NoteSearchCleared event,
    Emitter<NoteState> emit,
  ) async {
    if (state is NoteLoaded) {
      emit(
        (state as NoteLoaded).copyWith(
          filteredNotes: const [],
          searchQuery: '',
        ),
      );
    }
  }

  // ──────────────────────────────────────────────
  Color getNextColor() {
    final color =
        AppColors.noteColors[_colorIndex % AppColors.noteColors.length];
    _colorIndex++;
    return color;
  }

  // ──────────────────────────────────────────────
  // BLoC close হলে stream subscription cancel করো
  // Memory leak এড়াতে এটা জরুরি
  @override
  Future<void> close() {
    _connectivitySub?.cancel();
    return super.close();
  }
}
