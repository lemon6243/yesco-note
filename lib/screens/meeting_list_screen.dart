import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import 'meeting_note_screen.dart';

class MeetingListScreen extends StatelessWidget {
  const MeetingListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final meetings = appState.allMeetings;

    return Scaffold(
      appBar: AppBar(title: const Text('회의록')),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('새 회의록'),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MeetingNoteScreen()),
        ),
      ),
      body: meetings.isEmpty
          ? const Center(
              child: Text(
                '아직 회의록이 없어요.\n오른쪽 아래 버튼으로 새 회의록을 만들어보세요.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 90),
              itemCount: meetings.length,
              itemBuilder: (context, index) {
                final m = meetings[index];
                final dateLabel = DateFormat('yyyy.M.d (E)', 'ko_KR')
                    .format(m.meetingDate ?? m.createdAt);
                // 본문 미리보기 (첫 두 줄 정도)
                final preview = m.content.replaceAll('\n', ' ');
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: const Icon(Icons.event_note),
                    title: Text(dateLabel,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(
                      preview,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20),
                      onPressed: () => _confirmDelete(context, appState, m.id),
                    ),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MeetingNoteScreen(meeting: m),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, AppState appState, String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('회의록을 삭제할까요?'),
        content: const Text('삭제하면 되돌릴 수 없어요.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('취소')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('삭제', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      await appState.deleteNote(id); // 회의록도 note라 기존 삭제 재사용
    }
  }
}
