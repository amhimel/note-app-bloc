import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import '../../domain/entities/note_entity.dart';


//
// Event = UI থেকে BLoC এ পাঠানো "কী করতে চাই" এর নাম।
//
// Clean Architecture তে BLoC জানে না UI কেমন দেখতে।
// BLoC জানে শুধু: কোন Event আসলে কোন UseCase call করতে হবে।
//
// ──────────────────────────────────────────────
// Event naming convention:
//   NotesFetched  → app load / refresh
//   NoteAdded     → নতুন note সংরক্ষণ
//   NoteUpdated   → edit করা note সংরক্ষণ
//   NoteDeleted   → note মুছে ফেলা
//   NotesSearched → search query দেওয়া
//   NoteSearchCleared → search বাতিল

abstract class NoteEvent extends Equatable {
  const NoteEvent();

  @override
  List<Object?> get props => [];
}

// ──────────────────────────────────────────────
class NotesFetched extends NoteEvent {
  const NotesFetched();
}

// ──────────────────────────────────────────────
class NoteAdded extends NoteEvent {
  final String title;
  final String content;
  final Color color;

  const NoteAdded({
    required this.title,
    required this.content,
    required this.color,
  });

  @override
  List<Object?> get props => [title, content, color];
}

// ──────────────────────────────────────────────
class NoteUpdated extends NoteEvent {
  final NoteEntity note; // আপডেট হওয়া পুরো entity

  const NoteUpdated(this.note);

  @override
  List<Object?> get props => [note];
}

// ──────────────────────────────────────────────
class NoteDeleted extends NoteEvent {
  final String id;

  const NoteDeleted(this.id);

  @override
  List<Object?> get props => [id];
}

// ──────────────────────────────────────────────
class NotesSearched extends NoteEvent {
  final String query;

  const NotesSearched(this.query);

  @override
  List<Object?> get props => [query];
}

// ──────────────────────────────────────────────
class NoteSearchCleared extends NoteEvent {
  const NoteSearchCleared();
}
