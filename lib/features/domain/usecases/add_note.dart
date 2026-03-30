import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/note_entity.dart';
import '../repositories/note_repository.dart';
// UseCase এ Business Validation থাকে।
// যেমন: title empty হলে error দাও — এটা Business Rule।

class AddNote implements UseCase<NoteEntity, AddNoteParams> {
  final NoteRepository repository;

  AddNote(this.repository);

  @override
  Future<Either<Failure, NoteEntity>> call(AddNoteParams params) async {
    // Business Rule: title ও content দুটোই empty হতে পারবে না
    if (params.title.trim().isEmpty && params.content.trim().isEmpty) {
      return Future.value(const Left(CacheFailure('Note cannot be empty')));
    }
    return await repository.addNote(params.toEntity());
  }
}

class AddNoteParams {
  final String title;
  final String content;
  final Color color;

  AddNoteParams({
    required this.title,
    required this.content,
    required this.color,
  });

  // Params থেকে Entity তৈরি করার একটা helper method
  NoteEntity toEntity() {
    final now = DateTime.now();
    return NoteEntity(
      id: '', // ID Repository তে generate হবে
      title: title,
      content: content,
      color: color,
      createdAt: now,
      updatedAt: now,
    );
  }
}
