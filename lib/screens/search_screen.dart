// ============================================================
// SearchScreen (검색 화면)
// ------------------------------------------------------------
// 할 일의 제목/메모, 생각 노트의 내용을 함께 검색합니다.
// ============================================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';
import 'task_edit_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  String _keyword = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final taskResults = appState.searchTasks(_keyword);
    final noteResults = appState.searchNotes(_keyword);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '할 일 · 노트 검색',
            border: InputBorder.none,
          ),
          onChanged: (v) => setState(() => _keyword = v),
        ),
      ),
      body: SafeArea(
        child: _keyword.trim().isEmpty
            ? Center(
                child: Text(
                  '검색어를 입력해보세요.',
                  style: TextStyle(color: Colors.grey.withValues(alpha: 0.7)),
                ),
              )
            : (taskResults.isEmpty && noteResults.isEmpty)
            ? Center(
                child: Text(
                  '검색 결과가 없어요.',
                  style: TextStyle(color: Colors.grey.withValues(alpha: 0.7)),
                ),
              )
            : ListView(
                padding: const EdgeInsets.all(14),
                children: [
                  if (taskResults.isNotEmpty) ...[
                    _sectionLabel('할 일 (${taskResults.length})'),
                    ...taskResults.map(
                      (task) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Icon(
                            task.isDone
                                ? Icons.check_circle_rounded
                                : Icons.circle_outlined,
                            color: AppColors.teal,
                          ),
                          title: Text(task.title),
                          subtitle: Text(
                            DateFormat('yyyy-MM-dd').format(task.date),
                          ),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  TaskEditScreen(existingTask: task),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  if (noteResults.isNotEmpty) ...[
                    _sectionLabel('생각 노트 (${noteResults.length})'),
                    ...noteResults.map(
                      (note) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: const Icon(
                            Icons.sticky_note_2_outlined,
                            color: AppColors.lavender,
                          ),
                          title: Text(
                            note.content,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            DateFormat(
                              'yyyy-MM-dd HH:mm',
                            ).format(note.createdAt),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8, left: 4),
    child: Text(
      text,
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
    ),
  );
}
