import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../entities/note_entity.dart';

//এটা শুধু বলে "কী করতে হবে"
abstract class NoteRepository {
  Future<Either<Failure, List<NoteEntity>>> getNotes();

  Future<Either<Failure, NoteEntity>> addNote(NoteEntity note);

  Future<Either<Failure, NoteEntity>> updateNote(NoteEntity note);

  Future<Either<Failure, bool>> deleteNote(String id);
}
