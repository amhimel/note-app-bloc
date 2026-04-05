import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:note_app_bloc/core/constants/app_colors.dart';
import 'package:note_app_bloc/features/presentation/pages/note_card.dart';
import 'package:note_app_bloc/features/presentation/pages/note_form_page.dart';
import '../bloc/note_bloc.dart';
import '../bloc/note_event.dart';
import '../bloc/note_state.dart';

// Design: Home_Screen.png ও Home_Screen_Empty.png অনুযায়ী
//
// এই page এ BLoC এর ৩টি widget দেখবে:
//
//   BlocListener  → State change এ side-effect (snackbar)
//   BlocBuilder   → State দেখে UI build করে
//   BlocConsumer  → দুটো একসাথে (এখানে আলাদা রাখা হয়েছে শেখার জন্য)

class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  @override
  void initState() {
    super.initState();
    // App শুরুতে সব notes load করো
    context.read<NoteBloc>().add(const NotesFetched());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,

      // ══════════════════════════════════════════
      // BlocListener — Side effects এর জন্য
      // ══════════════════════════════════════════
      // UI rebuild করে না, শুধু "reaction" দেখায়।
      // যেমন: Snackbar, Navigation, Dialog।
      //
      // listenWhen → কোন state এ listen করবে সেটা filter করো
      body: BlocListener<NoteBloc, NoteState>(
        listenWhen: (previous, current) =>
            current is NoteActionSuccess || current is NoteError,
        listener: (context, state) {
          if (state is NoteActionSuccess) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.saveGreen,
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 2),
                ),
              );
          }
          if (state is NoteError) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.discardRed,
                  behavior: SnackBarBehavior.floating,
                ),
              );
          }
        },

        // ══════════════════════════════════════════
        // BlocBuilder — State দেখে UI build করো
        // ══════════════════════════════════════════
        // buildWhen → অপ্রয়োজনীয় rebuild এড়াও।
        // NoteActionSuccess এ rebuild দরকার নেই (শুধু snackbar দরকার)।
        child: BlocBuilder<NoteBloc, NoteState>(
          buildWhen: (previous, current) =>
              current is NoteLoading ||
              current is NoteLoaded ||
              current is NoteError,
          builder: (context, state) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    _buildAppBar(context),
                    const SizedBox(height: 20),
                    Expanded(child: _buildBody(context, state)),
                  ],
                ),
              ),
            );
          },
        ),
      ),

      // ── FAB ─────────────────────────────────────
      floatingActionButton: FloatingActionButton(
        onPressed: () => _goToCreateNote(context),
        backgroundColor: Colors.white,
        child: const Icon(Icons.add, color: Colors.black, size: 28),
      ),
    );
  }

  // ══════════════════════════════════════════════
  // AppBar
  // ══════════════════════════════════════════════
  Widget _buildAppBar(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Notes',
          style: TextStyle(
            color: Colors.white,
            fontSize: 36,
            fontWeight: FontWeight.bold,
          ),
        ),
        Row(
          children: [
            // 🔍 Search
            _IconBtn(icon: Icons.search, onTap: () => _showSearch(context)),
            const SizedBox(width: 10),
            // ℹ️ Info
            _IconBtn(
              icon: Icons.info_outline_rounded,
              onTap: () => _showInfo(context),
            ),
          ],
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════
  // Body — State অনুযায়ী ভিন্ন UI
  // ══════════════════════════════════════════════
  Widget _buildBody(BuildContext context, NoteState state) {
    // 🔄 Loading
    if (state is NoteLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white54),
      );
    }

    // ❌ Error
    if (state is NoteError) {
      return Center(
        child: Text(
          state.message,
          style: const TextStyle(color: Colors.redAccent),
        ),
      );
    }

    // ✅ Loaded
    if (state is NoteLoaded) {
      // Empty State — Design: Home_Screen_Empty.png
      if (state.notes.isEmpty) {
        return _buildEmptyState();
      }

      // Notes List
      return ListView.builder(
        itemCount: state.notes.length,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 100),
        itemBuilder: (context, index) {
          final note = state.notes[index];
          return NoteCard(
            note: note,
            onTap: () => _goToEditNote(context, note),
          );
        },
      );
    }

    return const SizedBox.shrink();
  }

  // ══════════════════════════════════════════════
  // Empty State Widget
  // ══════════════════════════════════════════════
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              color: AppColors.surfaceBg,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              Icons.note_alt_outlined,
              size: 72,
              color: Colors.white.withOpacity(0.25),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'Create your first note !',
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════
  // Search — Overlay হিসেবে দেখাও
  // ══════════════════════════════════════════════
  void _showSearch(BuildContext context) {
    showSearch(
      context: context,
      delegate: _NoteSearchDelegate(context.read<NoteBloc>()),
    );
  }

  // ══════════════════════════════════════════════
  // Info Dialog
  // ══════════════════════════════════════════════
  void _showInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surfaceBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Notes App', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Built with Flutter\nClean Architecture + BLoC',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'OK',
              style: TextStyle(color: AppColors.saveGreen),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════
  // Navigation
  // ══════════════════════════════════════════════
  void _goToCreateNote(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NoteFormPage()),
    );
  }

  void _goToEditNote(BuildContext context, note) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => NoteFormPage(noteToEdit: note)),
    );
  }
}

// =================================================================
// 🔍 NoteSearchDelegate — SearchBar UI
// =================================================================
// Design: Searching_Note.png ও Searching_Note_Empty.png অনুযায়ী
//
// showSearch() এর সাথে SearchDelegate ব্যবহার করলে
// Flutter নিজেই একটা সুন্দর search page তৈরি করে।

class _NoteSearchDelegate extends SearchDelegate<String> {
  final NoteBloc bloc;

  _NoteSearchDelegate(this.bloc);

  @override
  String get searchFieldLabel => 'Search by the keyword...';

  @override
  ThemeData appBarTheme(BuildContext context) {
    return Theme.of(context).copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surfaceBg,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
        border: InputBorder.none,
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(color: Colors.white, fontSize: 16),
      ),
    );
  }

  // ── X button ──────────────────────────────────
  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () {
            query = '';
            bloc.add(const NoteSearchCleared());
            showSuggestions(context);
          },
        ),
    ];
  }

  // ── Back button ───────────────────────────────
  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back, color: Colors.white),
      onPressed: () {
        bloc.add(const NoteSearchCleared());
        close(context, '');
      },
    );
  }

  // ── Search Results ────────────────────────────
  @override
  Widget buildResults(BuildContext context) {
    bloc.add(NotesSearched(query));
    return _buildSearchBody();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isNotEmpty) {
      bloc.add(NotesSearched(query));
    }
    return _buildSearchBody();
  }

  Widget _buildSearchBody() {
    return ColoredBox(
      color: AppColors.scaffoldBg,
      child: BlocBuilder<NoteBloc, NoteState>(
        bloc: bloc,
        builder: (context, state) {
          if (state is! NoteLoaded) return const SizedBox.shrink();

          // Query নেই — blank
          if (!state.isSearching) return const SizedBox.shrink();

          // কোনো result নেই — Design: Searching_Note_Empty.png
          if (state.filteredNotes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.search_off_rounded,
                    size: 80,
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'File not found. Try searching again.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            );
          }

          // Results আছে
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: state.filteredNotes.length,
            itemBuilder: (context, index) {
              final note = state.filteredNotes[index];
              return NoteCard(
                note: note,
                onTap: () {
                  close(context, '');
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => NoteFormPage(noteToEdit: note),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

// =================================================================
// Reusable Icon Button
// =================================================================
class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _IconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.surfaceBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}
