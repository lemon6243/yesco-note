// ============================================================
// NotesScreen (생각 노트 = 브레인덤프 화면)
// ------------------------------------------------------------
// "빈 종이" 방식: 유도 질문 없이 위쪽 입력창에 자유롭게 적으면
// 아래에 카드로 쌓입니다. 각 카드는 '할 일로 전환' / '아이디어 보관' /
// '삭제' 액션을 가집니다. 손그림 노트도 추가할 수 있습니다.
// ============================================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../models/note.dart';
import '../models/drawn_stroke.dart';
import '../theme/app_theme.dart';
import '../widgets/pen_canvas.dart';
import 'pen_note_screen.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final notes = appState.allNotes;

    return Scaffold(
      appBar: AppBar(title: const Text('생각 노트')),
      body: SafeArea(
        child: Column(
          children: [
            // ---------- 상단 입력창 (빈 종이) ----------
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: '떠오르는 대로 무엇이든 적어보세요',
                      ),
                      onSubmitted: (_) => _handleAdd(appState),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // 텍스트 노트 추가 버튼
                  IconButton.filled(
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.coral,
                    ),
                    icon: const Icon(Icons.arrow_upward_rounded),
                    onPressed: () => _handleAdd(appState),
                  ),
                  const SizedBox(width: 8),
                  // 손그림 노트 진입 버튼
                  IconButton.filledTonal(
                    icon: const Icon(Icons.draw_outlined),
                    tooltip: '손그림 노트',
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PenNoteScreen()),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // ---------- 노트 카드 목록 ----------
            Expanded(
              child: notes.isEmpty
                  ? Center(
                      child: Text(
                        '아직 적은 생각이 없어요.\n위 입력창에 자유롭게 적어보세요.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey.withValues(alpha: 0.7),
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 20),
                      itemCount: notes.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _noteCard(context, appState, notes[index]),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _noteCard(BuildContext context, AppState appState, Note note) {
    Color statusColor;
    String statusLabel;
    switch (note.status) {
      case NoteStatus.archived:
        statusColor = AppColors.lavender;
        statusLabel = '아이디어 보관';
        break;
      case NoteStatus.converted:
        statusColor = AppColors.teal;
        statusLabel = '할 일로 전환됨';
        break;
      default:
        statusColor = Colors.grey;
        statusLabel = '미분류';
    }

    final bool hasPen = note.penStrokes != null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      fontSize: 11,
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  DateFormat('M/d HH:mm').format(note.createdAt),
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(note.content, style: const TextStyle(fontSize: 14.5)),
            // 손그림이 있으면 미리보기 표시 (탭하면 편집)
            if (hasPen) ...[
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PenNoteScreen(note: note),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    height: 140,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(
                        color: Colors.grey.withValues(alpha: 0.3),
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: CustomPaint(
                      painter: StrokePreviewPainter(
                        decodeStrokes(note.penStrokes),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(
                    Icons.touch_app_outlined,
                    size: 13,
                    color: Colors.grey.withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 3),
                  Text(
                    '탭하여 수정',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ],
            if (note.status == NoteStatus.unclassified) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.task_alt_rounded, size: 16),
                      label: const Text(
                        '할 일로 전환',
                        style: TextStyle(fontSize: 12.5),
                      ),
                      onPressed: () async {
                        await appState.convertNoteToTask(note);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('할 일로 전환했어요! 오늘 화면에서 확인해보세요.'),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.archive_outlined, size: 16),
                      label: const Text(
                        '아이디어 보관',
                        style: TextStyle(fontSize: 12.5),
                      ),
                      onPressed: () => appState.archiveNote(note),
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    onPressed: () => appState.deleteNote(note.id),
                  ),
                ],
              ),
            ] else
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  onPressed: () => appState.deleteNote(note.id),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleAdd(AppState appState) async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    await appState.addNote(text);
    _controller.clear();
  }
}
