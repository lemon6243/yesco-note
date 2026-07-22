// ============================================================
// MatrixScreen (우선순위 매트릭스 화면)
// ------------------------------------------------------------
// 중요도(위/아래)와 긴급도(왼쪽/오른쪽) 두 축으로 할 일을
// 2x2 사분면에 나눠서 보여줍니다.
// [추가된 기능] 할 일을 길게 눌러(Drag) 다른 사분면에 놓으면(Drop)
// 자동으로 중요도와 긴급도 상태가 변경됩니다.
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
                            quadrantIndex: 0,
                            appState: appState,
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
                            quadrantIndex: 1,
                            appState: appState,
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
                            quadrantIndex: 2,
                            appState: appState,
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
                            quadrantIndex: 3,
                            appState: appState,
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
    required int quadrantIndex, // 어떤 사분면인지 식별하기 위해 추가
    required AppState appState, // 상태 변경을 위해 추가
  }) {
    // 💡 DragTarget: 할 일을 드롭할 수 있는 영역
    return DragTarget<Task>(
      onAcceptWithDetails: (details) async {
        final task = details.data;
        // 같은 사분면에 놓았다면 무시
        if (task.quadrant == quadrantIndex) return;

        bool newImportant = task.isImportant;
        bool newUrgent = task.isUrgent;

        // 드롭된 사분면에 맞춰 속성 업데이트
        if (quadrantIndex == 0) {
          newImportant = true;
          newUrgent = true;
        } else if (quadrantIndex == 1) {
          newImportant = true;
          newUrgent = false;
        } else if (quadrantIndex == 2) {
          newImportant = false;
          newUrgent = true;
        } else if (quadrantIndex == 3) {
          newImportant = false;
          newUrgent = false;
        }

        task.isImportant = newImportant;
        task.isUrgent = newUrgent;

        // 상태 저장 및 알림 (Provider 갱신)
        await appState.updateTask(task);
      },
      builder: (context, candidateData, rejectedData) {
        // 할 일을 끌고(Hover) 카드 위로 올라오면 시각적 피드백(색상 진해짐) 제공
        final isHovering = candidateData.isNotEmpty;
        final bgColor = isHovering
            ? color.withValues(alpha: 0.25)
            : color.withValues(alpha: 0.10);
        final borderColor = isHovering
            ? color.withValues(alpha: 0.8)
            : color.withValues(alpha: 0.35);

        return Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: isHovering ? 2 : 1),
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

                          // 실제 화면에 보이는 할 일 위젯
                          final taskWidget = InkWell(
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
                                  // 시각적으로 끌어서 옮길 수 있다는 것을 나타내는 핸들 아이콘
                                  Icon(Icons.drag_indicator, size: 14, color: color.withValues(alpha: 0.7)),
                                  const SizedBox(width: 4),
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

                          // 💡 LongPressDraggable: 길게 누르면 끌어다 놓을 수 있게 감싸줌
                          return LongPressDraggable<Task>(
                            data: task, // 드래그할 때 가지고 다닐 데이터
                            delay: const Duration(milliseconds: 150), // 짧게 꾹 누르면 바로 드래그 모드
                            // 드래그 중일 때 사용자 손가락 밑에 떠다니는 위젯
                            feedback: Material(
                              color: Colors.transparent,
                              child: Container(
                                width: 160,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).cardColor,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.15),
                                      blurRadius: 10,
                                      spreadRadius: 2,
                                    )
                                  ],
                                ),
                                child: Text(
                                  task.title,
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            // 드래그해서 빠져나간 원래 자리의 위젯 모양 (반투명하게 처리)
                            childWhenDragging: Opacity(
                              opacity: 0.3,
                              child: taskWidget,
                            ),
                            // 평상시 위젯
                            child: taskWidget,
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
