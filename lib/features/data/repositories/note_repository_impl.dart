import 'package:dartz/dartz.dart';
import 'package:note_app_bloc/core/error/failure.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/note_entity.dart';
import '../../domain/repositories/note_repository.dart';
import '../datasources/note_local_datasource.dart';
import '../datasources/note_remote_datasource.dart';
import '../models/note_model.dart';


class NoteRepositoryImpl implements NoteRepository {
  final NoteLocalDataSource localDataSource;
  final NoteRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  const NoteRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
    required this.networkInfo,
  });

  // ══════════════════════════════════════════════
  // getNotes — Online: Firestore | Offline: Hive
  // ══════════════════════════════════════════════
  @override
  Future<Either<Failure, List<NoteEntity>>> getNotes() async {
    final online = await networkInfo.isConnected;

    if (online) {
      try {
        final remoteModels = await remoteDataSource.getNotes();

        // Firestore notes → Hive cache (id অক্ষত রেখে)
        await _cacheRemoteNotes(remoteModels);

        return Right(remoteModels.map((m) => m.toEntity()).toList());
      } catch (e) {
        // Firestore fail হলে Hive fallback
        return _getLocalNotes();
      }
    } else {
      return _getLocalNotes();
    }
  }

  // ══════════════════════════════════════════════
  // addNote
  // ══════════════════════════════════════════════
  @override
  Future<Either<Failure, NoteEntity>> addNote(NoteEntity note) async {
    final online = await networkInfo.isConnected;

    try {
      // ✅ Fix 3: unused `model` variable সরানো হয়েছে
      // Online হলে isSynced=true, Offline হলে isSynced=false
      final noteToSave = note.copyWith(isSynced: online);

      // Hive তে save (নতুন UUID পাবে)
      final saved = await localDataSource.addNote(noteToSave);

      // Online হলে Firestore এও save করো
      if (online) {
        await remoteDataSource.saveNote(
          NoteModel.fromEntity(saved.copyWith(isSynced: true)),
        );
        // Hive তে isSynced=true করো
        await localDataSource.updateNote(saved.copyWith(isSynced: true));
        return Right(saved.copyWith(isSynced: true));
      }

      return Right(saved.toEntity());
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  // ══════════════════════════════════════════════
  // updateNote
  // ══════════════════════════════════════════════
  @override
  Future<Either<Failure, NoteEntity>> updateNote(NoteEntity note) async {
    final online = await networkInfo.isConnected;

    try {
      final noteToUpdate = note.copyWith(isSynced: online);
      final updated = await localDataSource.updateNote(noteToUpdate);

      if (online) {
        await remoteDataSource.updateNote(
          NoteModel.fromEntity(updated.copyWith(isSynced: true)),
        );
      }

      return Right(updated.toEntity());
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  // ══════════════════════════════════════════════
  // deleteNote
  // ══════════════════════════════════════════════
  @override
  Future<Either<Failure, bool>> deleteNote(String id) async {
    final online = await networkInfo.isConnected;

    try {
      await localDataSource.deleteNote(id);

      if (online) {
        await remoteDataSource.deleteNote(id);
      }

      return const Right(true);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  // ══════════════════════════════════════════════
  // syncPendingNotes — Internet ফিরলে BLoC call করে
  // ══════════════════════════════════════════════
  Future<Either<Failure, int>> syncPendingNotes() async {
    try {
      final allModels = await localDataSource.getNotes();

      // শুধু unsynced notes
      final unsynced = allModels.where((m) => !m.isSynced).toList();

      if (unsynced.isEmpty) return const Right(0);

      // Firestore এ batch write
      await remoteDataSource.syncNotes(unsynced);

      // Hive তে isSynced=true আপডেট করো
      for (final model in unsynced) {
        await localDataSource.updateNote(model.copyWith(isSynced: true));
      }

      return Right(unsynced.length);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  // ──────────────────────────────────────────────
  // Private Helpers
  // ──────────────────────────────────────────────

  Future<Either<Failure, List<NoteEntity>>> _getLocalNotes() async {
    try {
      final models = await localDataSource.getNotes();
      return Right(models.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  // ✅ Fix 2: cacheNote() ব্যবহার করছি — Firestore id অক্ষত থাকে
  // আগে addNote() ব্যবহার করা হতো যা নতুন UUID দিত।
  // এখন cacheNote() id বদলায় না।
  Future<void> _cacheRemoteNotes(List<NoteModel> remoteModels) async {
    try {
      // Hive পরিষ্কার করো
      await localDataSource.clearAll();

      // প্রতিটি Firestore note Hive তে cache করো (original id সহ)
      for (final model in remoteModels) {
        await localDataSource.cacheNote(model.toEntity());
      }
    } catch (_) {
      // Cache fail হলে silent ignore
    }
  }
}
