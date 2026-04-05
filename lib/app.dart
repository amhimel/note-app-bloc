import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:note_app_bloc/core/constants/app_theme.dart';
import 'package:note_app_bloc/injection_container.dart';
import 'package:note_app_bloc/features/presentation/bloc/note_bloc.dart';
import 'package:note_app_bloc/features/presentation/pages/notes_page.dart';


// App এর কাজ দুটো:
//   1. BlocProvider দিয়ে NoteBloc কে Widget tree তে inject করা
//   2. MaterialApp দিয়ে Theme ও initial Route set করা
//
// ──────────────────────────────────────────────
// BlocProvider কীভাবে কাজ করে:
//
//   BlocProvider(
//     create: (_) => sl<NoteBloc>(),  ← get_it থেকে BLoC নাও
//     child: MaterialApp(...),
//   )
//
//   এখন NotesPage, NoteFormPage যেকোনো জায়গা থেকে:
//   context.read<NoteBloc>()    → BLoC এর reference
//   context.watch<NoteBloc>()   → BLoC watch (rebuild trigger করে)
// ──────────────────────────────────────────────

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      // sl<NoteBloc>() → injection_container এ registerFactory করা আছে
      // প্রতিবার নতুন BLoC instance তৈরি হবে
      create: (_) => sl<NoteBloc>(),
      child: MaterialApp(
        title: 'Notes',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home:  NotesPage(),
      ),
    );
  }
}
