import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/note_entity.dart';
import '../repositories/note_repository.dart';

//Repository থেকে সব notes এনে BLoC কে দাও।
class GetNotes implements UseCase<List<NoteEntity>, NoParams> {
  final NoteRepository repository;

  GetNotes(this.repository);

  @override
  Future<Either<Failure, List<NoteEntity>>> call(NoParams params) async {
    // Repository তে delegate করো — UseCase নিজে কিছু করে না
    // Business Logic দরকার হলে এখানে যোগ করা হবে
    // যেমন: sort by date, filter archived, etc.
    return await repository.getNotes();
  }
}
