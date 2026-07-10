// ============================================================
// MatrixScreen (우선순위 매트릭스 화면)
// ------------------------------------------------------------
// 중요도(위/아래)와 긴급도(왼쪽/오른쪽) 두 축으로 할 일을
// 2x2 사분면에 나눠서 보여줍니다.
// - 왼쪽 위: 긴급하면서 중요 (즉시 처리)
// - 오른쪽 위: 중요하지만 긴급하지 않음 (계획해서 처리)
// - 왼쪽 아래: 긴급하지만 중요하지 않음 (위임 고려)
// - 오른쪽 아래: 둘 다 낮음 (나중에 또는 생략)
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../models/task.dart';
import '../theme/app_theme.dart';
import 'task_edit_screen.dart';

class MatrixScreen extends StatelessWidget {
  const MatrixScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final matrix = appState.matrixTasks;

    return Scaffold(
      appBar: AppBar(title: const Text('우선순위 매트릭스'), centerTitle: true),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // 태블릿처럼 화면이 넓으면 2x2를 크게, 폰이면 화면 채우기
            return Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: _quadrantCard(
                            context,
                            title: '🔥 즉시 처리',
                            subtitle: '중요 · 긴급',
                            color: AppColors.quadrantUrgentImportant,
                            tasks: matrix[0]!,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _quadrantCard(
                            context,
                            title: '📅 계획해서 처리',
                            subtitle: '중요 · 여유 있음',
                            color: AppColors.quadrantImportantOnly,
                            tasks: matrix[1]!,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: _quadrantCard(
                            context,
                            title: '⚡ 빠르게 처리·위임',
                            subtitle: '급하지만 덜 중요',
                            color: AppColors.quadrantUrgentOnly,
                            tasks: matrix[2]!,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _quadrantCard(
                            context,
                            title: '🌙 나중에',
                            subtitle: '급하지도 중요하지도 않음',
                            color: AppColors.quadrantNeither,
                            tasks: matrix[3]!,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _quadrantCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required Color color,
    required List<Task> tasks,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13.5,
              color: color,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(fontSize: 11, color: color.withValues(alpha: 0.8)),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: tasks.isEmpty
                ? Center(
                    child: Text(
                      '없음',
                      style: TextStyle(
                        fontSize: 12,
                        color: color.withValues(alpha: 0.4),
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      final task = tasks[index];
                      return InkWell(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TaskEditScreen(existingTask: task),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  task.title,
                                  style: const TextStyle(fontSize: 12.5),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
