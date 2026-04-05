import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../../domain/entities/note_entity.dart';
import '../../domain/repositories/note_repository.dart';
import '../datasources/note_local_datasource.dart';

// Repository = Data Layer এর main entry point।
//
// এটা Domain এর abstract contract কে Data Layer এ implement করে।
//
// Domain Layer কখনো Exception দেখে না, শুধু Either দেখে।
//
// ──────────────────────────────────────────────
// Data Flow চিত্র:
//
//   UseCase.call()
//     → repository.getNotes()           ← domain contract
//       → dataSource.getNotes()         ← data call
//         → Hive.box.values             ← actual storage
//       ← List<NoteModel>
//     ← Right(List<NoteEntity>)         ← success
//   ← Either<Failure, List<NoteEntity>>
// ──────────────────────────────────────────────

class NoteRepositoryImpl implements NoteRepository {
  final NoteLocalDataSource dataSource;

  const NoteRepositoryImpl({required this.dataSource});

  // ──────────────────────────────────────────────
  @override
  Future<Either<Failure, List<NoteEntity>>> getNotes() async {
    try {
      final models = await dataSource.getNotes();
      // NoteModel IS-A NoteEntity, তাই direct cast করা যায়
      return Right(models.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  // ──────────────────────────────────────────────
  @override
  Future<Either<Failure, NoteEntity>> addNote(NoteEntity note) async {
    try {
      final model = await dataSource.addNote(note);
      return Right(model.toEntity());
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  // ──────────────────────────────────────────────
  @override
  Future<Either<Failure, NoteEntity>> updateNote(NoteEntity note) async {
    try {
      final model = await dataSource.updateNote(note);
      return Right(model.toEntity());
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  // ──────────────────────────────────────────────
  @override
  Future<Either<Failure, bool>> deleteNote(String id) async {
    try {
      final result = await dataSource.deleteNote(id);
      return Right(result);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}
