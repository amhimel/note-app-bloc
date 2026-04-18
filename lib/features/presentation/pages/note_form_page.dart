import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:note_app_bloc/core/constants/app_colors.dart';
import '../../domain/entities/note_entity.dart';
import '../bloc/note_bloc.dart';
import '../bloc/note_event.dart';


// =================================================================
// ✏️ note_form_page.dart — Create ও Edit Screen
// =================================================================
//
// Design: Editor.png ও Editor__1_.png অনুযায়ী
//
// দুটো mode:
//   Create → noteToEdit = null   → NoteAdded Event
//   Edit   → noteToEdit = entity → NoteUpdated Event

class NoteFormPage extends StatefulWidget {
  final NoteEntity? noteToEdit;

  const NoteFormPage({super.key, this.noteToEdit});

  @override
  State<NoteFormPage> createState() => _NoteFormPageState();
}

class _NoteFormPageState extends State<NoteFormPage> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _contentCtrl;
  bool _isPreview = false;

  bool get _isEditing => widget.noteToEdit != null;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.noteToEdit?.title ?? '');
    _contentCtrl = TextEditingController(
      text: widget.noteToEdit?.content ?? '',
    );
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(child: _isPreview ? _buildPreview() : _buildEditor()),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════
  // Top Bar — Back | Preview | Save
  // ══════════════════════════════════════════════
  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // ← Back
          _TopBtn(icon: Icons.chevron_left, onTap: _handleBack),
          Row(
            children: [
              // 👁 Preview toggle
              _TopBtn(
                icon: _isPreview
                    ? Icons.edit_outlined
                    : Icons.remove_red_eye_outlined,
                onTap: () => setState(() => _isPreview = !_isPreview),
              ),
              const SizedBox(width: 10),
              // 💾 Save
              _TopBtn(icon: Icons.save_outlined, onTap: _handleSave),
            ],
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════
  // Editor — Design: Editor.png
  // ══════════════════════════════════════════════
  Widget _buildEditor() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          TextField(
            controller: _titleCtrl,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.bold,
              height: 1.3,
            ),
            decoration: InputDecoration(
              hintText: 'Title',
              hintStyle: TextStyle(
                color: Colors.white.withOpacity(0.3),
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
              border: InputBorder.none,
            ),
            maxLines: null,
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 12),
          // Content
          TextField(
            controller: _contentCtrl,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              height: 1.7,
            ),
            decoration: InputDecoration(
              hintText: 'Type something...',
              hintStyle: TextStyle(
                color: Colors.white.withOpacity(0.3),
                fontSize: 16,
              ),
              border: InputBorder.none,
            ),
            maxLines: null,
            keyboardType: TextInputType.multiline,
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════
  // Preview — Design: Sample_Note.png
  // ══════════════════════════════════════════════
  Widget _buildPreview() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _titleCtrl.text.isEmpty ? '(No title)' : _titleCtrl.text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.bold,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _contentCtrl.text.isEmpty ? '(No content)' : _contentCtrl.text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              height: 1.7,
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════
  // Save — BLoC Event পাঠাও
  // ══════════════════════════════════════════════
  void _handleSave() {
    final title = _titleCtrl.text.trim();
    final content = _contentCtrl.text.trim();

    if (title.isEmpty && content.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Note cannot be empty!')));
      return;
    }

    if (_isEditing) {
      // ✅ Edit mode → NoteUpdated Event
      context.read<NoteBloc>().add(
        NoteUpdated(
          widget.noteToEdit!.copyWith(
            title: title,
            content: content,
            updatedAt: DateTime.now(),
          ),
        ),
      );
    } else {
      // ✅ Create mode → NoteAdded Event
      final color = context.read<NoteBloc>().getNextColor();
      context.read<NoteBloc>().add(
        NoteAdded(title: title, content: content, color: color),
      );
    }

    Navigator.pop(context);
  }

  // ══════════════════════════════════════════════
  // Back — "Save changes?" Dialog
  // ══════════════════════════════════════════════
  // Design: Editor__1_.png অনুযায়ী
  void _handleBack() {
    final hasContent =
        _titleCtrl.text.isNotEmpty || _contentCtrl.text.isNotEmpty;

    // Content নেই → সরাসরি back
    if (!hasContent) {
      Navigator.pop(context);
      return;
    }

    // Content আছে → Confirm dialog
    showDialog(
      context: context,
      builder: (dialogCtx) => Dialog(
        backgroundColor: AppColors.surfaceBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.info_outline, color: Colors.white54, size: 32),
              const SizedBox(height: 16),
              const Text(
                'Save changes ?',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  // ❌ Discard
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.discardRed,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(dialogCtx); // dialog বন্ধ
                        Navigator.pop(context); // page বন্ধ
                      },
                      child: const Text(
                        'Discard',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // ✅ Save
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.saveGreen,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(dialogCtx); // dialog বন্ধ
                        _handleSave(); // save করো
                      },
                      child: const Text(
                        'Save',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =================================================================
// Reusable Top Button
// =================================================================
class _TopBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _TopBtn({required this.icon, required this.onTap});

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
