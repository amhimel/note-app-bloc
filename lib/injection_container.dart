import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get_it/get_it.dart';
import 'package:hive/hive.dart';
import 'package:note_app_bloc/features/data/datasources/note_local_datasource.dart';
import 'package:note_app_bloc/features/data/datasources/note_remote_datasource.dart';
import 'package:note_app_bloc/features/data/models/note_model.dart';
import 'package:note_app_bloc/features/data/repositories/note_repository_impl.dart';
import 'package:note_app_bloc/features/domain/repositories/note_repository.dart';
import 'package:note_app_bloc/features/domain/usecases/add_note.dart';
import 'package:note_app_bloc/features/domain/usecases/delete_note.dart';
import 'package:note_app_bloc/features/domain/usecases/get_notes.dart';
import 'package:note_app_bloc/features/domain/usecases/update_note.dart';
import 'package:note_app_bloc/features/presentation/bloc/note_bloc.dart';
import 'package:path_provider/path_provider.dart';

import 'core/network/network_info.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  // ════════════════════════════════════════════
  // Step 1: Hive
  // ════════════════════════════════════════════
  final appDocDir = await getApplicationDocumentsDirectory();
  Hive.init(appDocDir.path);

  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(NoteModelAdapter());
  }

  final notesBox = await Hive.openBox<NoteModel>(
    NoteLocalDataSourceImpl.boxName,
  );
  sl.registerSingleton<Box<NoteModel>>(notesBox);

  // ════════════════════════════════════════════
  // Step 2: External (Firebase + Connectivity)
  // ════════════════════════════════════════════
  sl.registerLazySingleton<FirebaseFirestore>(() => FirebaseFirestore.instance);

  sl.registerLazySingleton<Connectivity>(() => Connectivity());

  // ════════════════════════════════════════════
  // Step 3: Core
  // ════════════════════════════════════════════
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(sl()));

  // ════════════════════════════════════════════
  // Step 4: Data Sources
  // ════════════════════════════════════════════
  sl.registerLazySingleton<NoteLocalDataSource>(
    () => NoteLocalDataSourceImpl(),
  );

  sl.registerLazySingleton<NoteRemoteDataSource>(
    () => NoteRemoteDataSourceImpl(firestore: sl()),
  );

  // ════════════════════════════════════════════
  // Step 5: Repository
  // ════════════════════════════════════════════
  // NoteRepositoryImpl concrete type register করো
  // (syncPendingNotes এর জন্য BLoC concrete type দরকার)
  sl.registerLazySingleton<NoteRepositoryImpl>(
    () => NoteRepositoryImpl(
      localDataSource: sl(),
      remoteDataSource: sl(),
      networkInfo: sl(),
    ),
  );

  // Abstract type — UseCases এর জন্য
  sl.registerLazySingleton<NoteRepository>(() => sl<NoteRepositoryImpl>());

  // ════════════════════════════════════════════
  // Step 6: Use Cases
  // ════════════════════════════════════════════
  sl.registerLazySingleton(() => GetNotes(sl()));
  sl.registerLazySingleton(() => AddNote(sl()));
  sl.registerLazySingleton(() => UpdateNote(sl()));
  sl.registerLazySingleton(() => DeleteNote(sl()));

  // ════════════════════════════════════════════
  // Step 7: BLoC
  // ════════════════════════════════════════════
  sl.registerFactory(
    () => NoteBloc(
      getNotes: sl(),
      addNote: sl(),
      updateNote: sl(),
      deleteNote: sl(),
      networkInfo: sl(),
      repository: sl<NoteRepositoryImpl>(),
    ),
  );
}
