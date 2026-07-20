// ============================================================
// ProjectDetailScreen (프로젝트 상세 화면)
// ------------------------------------------------------------
// 프로젝트 카드를 탭하면 열리는 화면입니다.
// 상단에 프로젝트 정보(이름·진행률·기간·설명)를 보여주고,
// 본문에 그 프로젝트에 속한 할 일 목록을 표시합니다.
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

class ProjectDetailScreen extends StatelessWidget {
  final String projectId;

  const ProjectDetailScreen({super.key, required this.projectId});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    // 프로젝트를 목록에서 찾는다. 삭제된 경우 대비.
    Project? project;
    for (final p in appState.allProjects) {
      if (p.id == projectId) {
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
    // 미완료를 위로, 완료를 아래로 정렬
    final sorted = [...tasks]..sort((a, b) {
        if (a.isDone != b.isDone) return a.isDone ? 1 : -1;
        return a.date.compareTo(b.date);
      });
    final doneCount = tasks.where((t) => t.isDone).length;
    final progress = appState.projectProgress(project.id);

    return Scaffold(
      appBar: AppBar(
        title: Text(project.name),
        actions: [
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
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '할 일 (${tasks.length})',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
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
