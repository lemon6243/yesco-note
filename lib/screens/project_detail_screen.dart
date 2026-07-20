// ============================================================
// ProjectDetailScreen (프로젝트 상세 화면)
// ------------------------------------------------------------
// 프로젝트 카드를 탭하면 열리는 화면입니다.
// 상단에 프로젝트 정보(이름·진행률·기간·기간대비 진척·설명)를 보여주고,
// 본문에 그 프로젝트에 속한 할 일 목록을 정렬해서 표시합니다.
// 우측 하단 + 버튼으로 이 프로젝트에 바로 할 일을 추가합니다.
// ============================================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../models/project.dart';
import '../models/task.dart';
import '../widgets/task_tile.dart';
import 'task_edit_screen.dart';

// 할 일 정렬 방식
enum _SortMode { priority, date, done }

class ProjectDetailScreen extends StatefulWidget {
  final String projectId;

  const ProjectDetailScreen({super.key, required this.projectId});

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  _SortMode _sortMode = _SortMode.priority;

  String _sortLabel(_SortMode mode) {
    switch (mode) {
      case _SortMode.priority:
        return '우선순위순';
      case _SortMode.date:
        return '날짜순';
      case _SortMode.done:
        return '완료순';
    }
  }

  // 정렬 방식에 따라 할 일 목록을 정렬해서 돌려줍니다.
  List<Task> _sortTasks(List<Task> tasks) {
    final list = [...tasks];
    switch (_sortMode) {
      case _SortMode.priority:
        // 미완료 먼저 → 사분면(0=긴급&중요가 최우선) → 날짜
        list.sort((a, b) {
          if (a.isDone != b.isDone) return a.isDone ? 1 : -1;
          if (a.quadrant != b.quadrant) {
            return a.quadrant.compareTo(b.quadrant);
          }
          return a.date.compareTo(b.date);
        });
        break;
      case _SortMode.date:
        // 미완료 먼저 → 날짜 오름차순
        list.sort((a, b) {
          if (a.isDone != b.isDone) return a.isDone ? 1 : -1;
          return a.date.compareTo(b.date);
        });
        break;
      case _SortMode.done:
        // 완료 먼저 → 날짜
        list.sort((a, b) {
          if (a.isDone != b.isDone) return a.isDone ? -1 : 1;
          return a.date.compareTo(b.date);
        });
        break;
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    // 프로젝트를 목록에서 찾는다. 삭제된 경우 대비.
    Project? project;
    for (final p in appState.allProjects) {
      if (p.id == widget.projectId) {
        project = p;
        break;
      }
    }

    if (project == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('프로젝트')),
        body: const Center(child: Text('삭제되었거나 찾을 수 없는 프로젝트예요.')),
      );
    }

    final color = Color(project.colorValue);
    final tasks = appState.tasksOfProject(project.id);
    final sorted = _sortTasks(tasks);
    final doneCount = tasks.where((t) => t.isDone).length;
    final progress = appState.projectProgress(project.id);

    return Scaffold(
      appBar: AppBar(
        title: Text(project.name),
        actions: [
          // 정렬 방식 선택
          PopupMenuButton<_SortMode>(
            icon: const Icon(Icons.sort),
            tooltip: '정렬',
            initialValue: _sortMode,
            onSelected: (mode) => setState(() => _sortMode = mode),
            itemBuilder: (ctx) => _SortMode.values
                .map(
                  (mode) => PopupMenuItem(
                    value: mode,
                    child: Text(_sortLabel(mode)),
                  ),
                )
                .toList(),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: '프로젝트 수정',
            onPressed: () => _showEditDialog(context, appState, project!),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TaskEditScreen(
              initialDate: DateTime.now(),
              initialProjectId: project!.id,
            ),
          ),
        ),
        icon: const Icon(Icons.add),
        label: const Text('할 일 추가'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
          children: [
            // ── 상단 정보 카드 ──
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            project.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Text(
                          '$doneCount/${tasks.length}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Theme.of(context).disabledColor,
                          ),
                        ),
                      ],
                    ),
                    if (project.description != null &&
                        project.description!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        project.description!,
                        style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context).disabledColor,
                        ),
                      ),
                    ],
                    if (project.startDate != null ||
                        project.dueDate != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.date_range,
                            size: 15,
                            color: Theme.of(context).disabledColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _periodText(project),
                            style: TextStyle(
                              fontSize: 12.5,
                              color: Theme.of(context).disabledColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 14),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        backgroundColor: Colors.grey.withValues(alpha: 0.15),
                        valueColor: AlwaysStoppedAnimation(color),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${(progress * 100).round()}% 완료',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Theme.of(context).disabledColor,
                      ),
                    ),
                    // ── 기간 대비 진척 (시작일·마감일이 둘 다 있을 때만) ──
                    ..._buildPaceSection(context, project, progress),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  '할 일 (${tasks.length})',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  _sortLabel(_sortMode),
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).disabledColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // ── 할 일 목록 ──
            if (sorted.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Column(
                    children: [
                      const Text('🗒️', style: TextStyle(fontSize: 40)),
                      const SizedBox(height: 10),
                      Text(
                        '아직 이 프로젝트에 할 일이 없어요.\n아래 + 버튼으로 추가해 보세요.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).disabledColor,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...sorted.map(
                (task) => TaskTile(
                  task: task,
                  onToggleDone: () => appState.toggleTaskDone(task),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TaskEditScreen(existingTask: task),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // 기간 대비 진척 위젯. 시작일·마감일이 모두 있을 때만 표시.
  // "기간이 X% 지났는데 진행률은 Y%" 형태로, 뒤처지면 빨강/앞서면 초록 안내.
  List<Widget> _buildPaceSection(
    BuildContext context,
    Project project,
    double progress,
  ) {
    final start = project.startDate;
    final due = project.dueDate;
    if (start == null || due == null) return [];
    if (!due.isAfter(start)) return []; // 기간이 유효하지 않으면 생략

    final now = DateTime.now();
    final total = due.difference(start).inMinutes;
    final elapsed = now.difference(start).inMinutes;
    double timeRatio = total == 0 ? 1 : elapsed / total;
    if (timeRatio < 0) timeRatio = 0;
    if (timeRatio > 1) timeRatio = 1;

    final timePct = (timeRatio * 100).round();
    final donePct = (progress * 100).round();

    // 안내 문구/색상 결정
    String msg;
    Color msgColor;
    if (now.isBefore(start)) {
      msg = '아직 시작 전이에요.';
      msgColor = Theme.of(context).disabledColor;
    } else if (progress >= 1.0) {
      msg = '완료했어요! 🎉';
      msgColor = const Color(0xFF10B981);
    } else if (progress + 0.05 >= timeRatio) {
      msg = '일정보다 앞서 있어요 👍';
      msgColor = const Color(0xFF10B981);
    } else {
      msg = '일정보다 조금 뒤처져 있어요';
      msgColor = const Color(0xFFEF4444);
    }

    return [
      const SizedBox(height: 12),
      Divider(height: 1, color: Colors.grey.withValues(alpha: 0.2)),
      const SizedBox(height: 10),
      Text(
        '기간 대비 진척',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).disabledColor,
        ),
      ),
      const SizedBox(height: 6),
      Text(
        '기간 $timePct% 경과 · 진행 $donePct%',
        style: const TextStyle(fontSize: 12.5),
      ),
      const SizedBox(height: 4),
      Text(
        msg,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: msgColor,
        ),
      ),
    ];
  }

  String _periodText(Project project) {
    final fmt = DateFormat('yyyy.M.d');
    final start =
        project.startDate != null ? fmt.format(project.startDate!) : '?';
    final due = project.dueDate != null ? fmt.format(project.dueDate!) : '?';
    return '$start ~ $due';
  }

  // 상단 연필 아이콘 → 간단 수정(이름·설명). 색상·기간은 목록 화면에서 관리.
  Future<void> _showEditDialog(
    BuildContext context,
    AppState appState,
    Project project,
  ) async {
    final nameController = TextEditingController(text: project.name);
    final descController =
        TextEditingController(text: project.description ?? '');

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('프로젝트 수정'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              autofocus: true,
              decoration: const InputDecoration(labelText: '프로젝트 이름'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              decoration: const InputDecoration(labelText: '설명 (선택)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isEmpty) return;
              project.name = name;
              project.description = descController.text.trim().isEmpty
                  ? null
                  : descController.text.trim();
              appState.updateProject(project);
              Navigator.pop(ctx);
            },
            child: const Text('저장'),
          ),
        ],
      ),
    );
  }
}
