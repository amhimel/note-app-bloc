import 'package:get_it/get_it.dart';
import 'package:hive/hive.dart';
import 'package:note_app_bloc/features/data/datasources/note_local_datasource.dart';
import 'package:note_app_bloc/features/data/models/note_model.dart';
import 'package:note_app_bloc/features/data/repositories/note_repository_impl.dart';
import 'package:note_app_bloc/features/domain/repositories/note_repository.dart';
import 'package:note_app_bloc/features/domain/usecases/add_note.dart';
import 'package:note_app_bloc/features/domain/usecases/delete_note.dart';
import 'package:note_app_bloc/features/domain/usecases/get_notes.dart';
import 'package:note_app_bloc/features/domain/usecases/update_note.dart';
import 'package:note_app_bloc/features/presentation/bloc/note_bloc.dart';
import 'package:path_provider/path_provider.dart';


// get_it = Service Locator pattern।
// পুরো app এ যেকোনো জায়গা থেকে sl<T>() দিয়ে
// registered dependency পাওয়া যায়।
//
// ──────────────────────────────────────────────
// Registration এর ৩ ধরন:
//
//   sl.registerLazySingleton → একবার তৈরি, সবসময় same instance
//                              (DataSource, Repository, UseCase)
//
//   sl.registerFactory        → প্রতিবার নতুন instance
//                              (BLoC — প্রতিটি screen নিজের BLoC চায়)
//
//   sl.registerSingleton      → app শুরুতেই তৈরি, সবসময় same instance
// ──────────────────────────────────────────────
//
// Dependency Graph (নিচ থেকে উপরে register করো):
//
//   Hive Box
//     ↓
//   DataSource  (Hive Box লাগে)
//     ↓
//   Repository  (DataSource লাগে)
//     ↓
//   UseCases    (Repository লাগে)
//     ↓
//   BLoC        (সব UseCase লাগে)

// Global service locator instance
final sl = GetIt.instance;

Future<void> initDependencies() async {
  // ════════════════════════════════════════════
  // Step 1: Hive Initialize ও Box Open
  // ════════════════════════════════════════════
  //
  // hive_flutter এর Hive.initFlutter() এর পরিবর্তে:
  //   1. path_provider দিয়ে app এর document directory পাও
  //   2. সেই path দিয়ে Hive.init() করো
  //
  // hive_flutter আসলে ভেতরে এটাই করে।
  final appDocDir = await getApplicationDocumentsDirectory();
  Hive.init(appDocDir.path);

  // NoteModel এর TypeAdapter register করো
  // Hive এটা ছাড়া NoteModel read/write করতে পারবে না
  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(NoteModelAdapter());
  }

  // Notes box খোলো — এটা Hive এর "table" এর মতো
  final notesBox = await Hive.openBox<NoteModel>(
    NoteLocalDataSourceImpl.boxName,
  );

  // Box কে sl এ register করো যাতে DataSource inject করতে পারে
  sl.registerSingleton<Box<NoteModel>>(notesBox);

  // ════════════════════════════════════════════
  // Step 2: Data Sources
  // ════════════════════════════════════════════
  // LazySingleton — প্রথমবার call হলে তৈরি হবে, পরে same instance
  sl.registerLazySingleton<NoteLocalDataSource>(
    () => NoteLocalDataSourceImpl(),
  );

  // ════════════════════════════════════════════
  // Step 3: Repositories
  // ════════════════════════════════════════════
  // Abstract type (NoteRepository) register করো —
  // Domain Layer শুধু Abstract জানে, Impl জানে না
  sl.registerLazySingleton<NoteRepository>(
    () => NoteRepositoryImpl(dataSource: sl()),
  );

  // ════════════════════════════════════════════
  // Step 4: Use Cases
  // ════════════════════════════════════════════
  sl.registerLazySingleton(() => GetNotes(sl()));
  sl.registerLazySingleton(() => AddNote(sl()));
  sl.registerLazySingleton(() => UpdateNote(sl()));
  sl.registerLazySingleton(() => DeleteNote(sl()));

  // ════════════════════════════════════════════
  // Step 5: BLoC
  // ════════════════════════════════════════════
  // Factory — প্রতিবার নতুন BLoC instance দেবে।
  // কেন? একই BLoC দুটো screen share করলে state mix হতে পারে।
  sl.registerFactory(
    () => NoteBloc(
      getNotes: sl(),
      addNote: sl(),
      updateNote: sl(),
      deleteNote: sl(),
    ),
  );
}
