// ============================================================
// ProjectListScreen (프로젝트 목록 화면)
// ------------------------------------------------------------
// 회사 프로젝트들을 카드로 보여주고, 각 프로젝트의 진행률
// (속한 할 일 중 완료 비율)을 표시합니다.
// 우측 하단 + 버튼으로 새 프로젝트를 추가할 수 있습니다.
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../models/project.dart';

class ProjectListScreen extends StatelessWidget {
  const ProjectListScreen({super.key});

  // 프로젝트 색상 선택지 (파랑/보라/초록/주황/빨강/청록/분홍/회색)
  static const List<int> _colorOptions = [
    0xFF3B82F6, 0xFF8B5CF6, 0xFF10B981, 0xFFF59E0B,
    0xFFEF4444, 0xFF06B6D4, 0xFFEC4899, 0xFF6B7280,
  ];

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final projects = appState.allProjects;

    return Scaffold(
      appBar: AppBar(title: const Text('프로젝트'), centerTitle: true),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddProjectDialog(context, appState),
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: projects.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('📁', style: TextStyle(fontSize: 48)),
                      const SizedBox(height: 12),
                      Text(
                        '아직 프로젝트가 없어요.\n오른쪽 아래 + 버튼으로\n첫 프로젝트를 만들어 보세요.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          color: Theme.of(context).disabledColor,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 90),
                itemCount: projects.length,
                itemBuilder: (context, index) {
                  return _buildProjectCard(context, appState, projects[index]);
                },
              ),
      ),
    );
  }

  // 프로젝트 한 개 카드
  Widget _buildProjectCard(
    BuildContext context,
    AppState appState,
    Project project,
  ) {
    final color = Color(project.colorValue);
    final tasks = appState.tasksOfProject(project.id);
    final doneCount = tasks.where((t) => t.isDone).length;
    final progress = appState.projectProgress(project.id);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onLongPress: () => _showProjectMenu(context, appState, project),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // 프로젝트 색상 표시 점
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      project.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        decoration: project.isDone
                            ? TextDecoration.lineThrough
                            : null,
                        color: project.isDone
                            ? Theme.of(context).disabledColor
                            : null,
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
                const SizedBox(height: 6),
                Text(
                  project.description!,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Theme.of(context).disabledColor,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              // 진행률 바
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
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
    );
  }

  // 색상 선택 그리드 (다이얼로그 안에서 공용)
  Widget _buildColorPicker({
    required int selected,
    required void Function(int) onSelect,
  }) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _colorOptions.map((value) {
        final isSelected = selected == value;
        return GestureDetector(
          onTap: () => onSelect(value),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Color(value),
              shape: BoxShape.circle,
              border: isSelected
                  ? Border.all(color: Colors.black87, width: 3)
                  : null,
            ),
            child: isSelected
                ? const Icon(Icons.check, color: Colors.white, size: 20)
                : null,
          ),
        );
      }).toList(),
    );
  }

  
  // 날짜 선택 행 (시작일/마감일 공용). 값이 없으면 "선택 안 함" 표시.
  Widget _buildDateRow({
    required BuildContext context,
    required String label,
    required DateTime? value,
    required void Function(DateTime?) onPick,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 52,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).disabledColor,
            ),
          ),
        ),
        Expanded(
          child: OutlinedButton(
            onPressed: () async {
              final now = DateTime.now();
              final picked = await showDatePicker(
                context: context,
                initialDate: value ?? now,
                firstDate: DateTime(now.year - 2),
                lastDate: DateTime(now.year + 5),
              );
              if (picked != null) onPick(picked);
            },
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                value == null
                    ? '선택 안 함'
                    : '${value.year}.${value.month}.${value.day}',
              ),
            ),
          ),
        ),
        if (value != null)
          IconButton(
            icon: const Icon(Icons.clear, size: 18),
            onPressed: () => onPick(null),
            tooltip: '날짜 지우기',
          ),
      ],
    );
  }
  
  // 새 프로젝트 추가 다이얼로그
  Future<void> _showAddProjectDialog(
    BuildContext context,
    AppState appState,
  ) async {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    int selectedColor = _colorOptions.first;
    DateTime? startDate;
    DateTime? dueDate;


    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('새 프로젝트'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: '프로젝트 이름',
                    hintText: '예: 봄 신제품 출시',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(
                    labelText: '설명 (선택)',
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '색상',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Theme.of(ctx).disabledColor,
                  ),
                ),
                const SizedBox(height: 8),
                _buildColorPicker(
                  selected: selectedColor,
                  onSelect: (value) => setState(() => selectedColor = value),
                ),
              ],
                              const SizedBox(height: 16),
                Text(
                  '기간 (선택)',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Theme.of(ctx).disabledColor,
                  ),
                ),
                const SizedBox(height: 8),
                _buildDateRow(
                  context: ctx,
                  label: '시작일',
                  value: startDate,
                  onPick: (d) => setState(() => startDate = d),
                ),
                _buildDateRow(
                  context: ctx,
                  label: '마감일',
                  value: dueDate,
                  onPick: (d) => setState(() => dueDate = d),
                ),

            ),
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
                appState.addProject(
                  name,
                  description: descController.text.trim().isEmpty
                      ? null
                      : descController.text.trim(),
                  colorValue: selectedColor,
                  startDate: startDate,
                  dueDate: dueDate,

                );
                Navigator.pop(ctx);
              },
              child: const Text('추가'),
            ),
          ],
        ),
      ),
    );
  }

  // 카드 길게 누르면 나오는 메뉴 (완료 토글 / 수정 / 삭제)
  Future<void> _showProjectMenu(
    BuildContext context,
    AppState appState,
    Project project,
  ) async {
    await showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                project.isDone
                    ? Icons.replay_rounded
                    : Icons.check_circle_outline,
              ),
              title: Text(project.isDone ? '진행 중으로 되돌리기' : '완료로 표시'),
              onTap: () {
                Navigator.pop(ctx);
                appState.toggleProjectDone(project);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('수정'),
              onTap: () {
                Navigator.pop(ctx);
                _showEditProjectDialog(context, appState, project);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('삭제', style: TextStyle(color: Colors.red)),
              subtitle: const Text('속한 할 일은 삭제되지 않고 미분류로 남아요'),
              onTap: () {
                Navigator.pop(ctx);
                appState.deleteProject(project.id);
              },
            ),
          ],
        ),
      ),
    );
  }

  // 프로젝트 수정 다이얼로그
  Future<void> _showEditProjectDialog(
    BuildContext context,
    AppState appState,
    Project project,
  ) async {
    final nameController = TextEditingController(text: project.name);
    final descController =
        TextEditingController(text: project.description ?? '');
    int selectedColor = project.colorValue;
    DateTime? startDate = project.startDate;
    DateTime? dueDate = project.dueDate;


    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('프로젝트 수정'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
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
                const SizedBox(height: 16),
                Text(
                  '색상',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Theme.of(ctx).disabledColor,
                  ),
                ),
                const SizedBox(height: 8),
                _buildColorPicker(
                  selected: selectedColor,
                  onSelect: (value) => setState(() => selectedColor = value),
                ),
              ],
                const SizedBox(height: 16),
                Text(
                  '기간 (선택)',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Theme.of(ctx).disabledColor,
                  ),
                ),
                const SizedBox(height: 8),
                _buildDateRow(
                  context: ctx,
                  label: '시작일',
                  value: startDate,
                  onPick: (d) => setState(() => startDate = d),
                ),
                _buildDateRow(
                  context: ctx,
                  label: '마감일',
                  value: dueDate,
                  onPick: (d) => setState(() => dueDate = d),
                ),

            ),
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
                project.description =
                    descController.text.trim().isEmpty
                        ? null
                        : descController.text.trim();
                project.colorValue = selectedColor;
                project.startDate = startDate;
                project.dueDate = dueDate;
                appState.updateProject(project);
                Navigator.pop(ctx);
              },
              child: const Text('저장'),
            ),
          ],
        ),
      ),
    );
  }
}
