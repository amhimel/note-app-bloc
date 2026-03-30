import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/note_entity.dart';
import '../repositories/note_repository.dart';

class UpdateNote implements UseCase<NoteEntity, UpdateParams> {
  final NoteRepository repository;

  UpdateNote(this.repository);

  @override
  Future<Either<Failure, NoteEntity>> call(UpdateParams params) async {
    // if (params.note.title.trim().isEmpty &&
    //     params.note.content.trim().isEmpty) {
    //   return Future.value(const Left(CacheFailure('Note cannot be empty')));
    // }
    return await repository.updateNote(params.toEntity());
  }
}

class UpdateParams {
  final NoteEntity note;

  UpdateParams(this.note);

  NoteEntity toEntity() {
    return note.copyWith(updatedAt: DateTime.now());
  }
}
