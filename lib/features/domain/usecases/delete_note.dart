import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/note_repository.dart';


class DeleteNote implements UseCase<bool, DeleteNoteParam> {
  final NoteRepository repository;

  DeleteNote(this.repository);

  @override
  Future<Either<Failure, bool>> call(DeleteNoteParam params) async {
    return await repository.deleteNote(params.id);
  }
}

class DeleteNoteParam {
  final String id;

  DeleteNoteParam(this.id);
}