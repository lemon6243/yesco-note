// ============================================================
// TaskTile (할 일 한 줄을 표시하는 위젯)
// ------------------------------------------------------------
// 오늘 화면의 시간순 리스트, 시간 미정 목록, 매트릭스 화면 등에서
// 공통으로 사용하는 "할 일 한 줄" UI입니다.
// ============================================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../theme/app_theme.dart';

class TaskTile extends StatelessWidget {
  final Task task;
  final VoidCallback onToggleDone; // 완료 체크박스를 눌렀을 때
  final VoidCallback onTap; // 항목 전체를 눌렀을 때 (수정 화면으로 이동 등)
  final VoidCallback? onToggleTop3; // 별 아이콘을 눌러 오늘의 3가지 지정/해제

  const TaskTile({
    super.key,
    required this.task,
    required this.onToggleDone,
    required this.onTap,
    this.onToggleTop3,
  });

  // 사분면(중요도/긴급도 조합)에 따른 색상 점 표시용
  Color get _quadrantColor {
    switch (task.quadrant) {
      case 0:
        return AppColors.quadrantUrgentImportant;
      case 1:
        return AppColors.quadrantImportantOnly;
      case 2:
        return AppColors.quadrantUrgentOnly;
      default:
        return AppColors.quadrantNeither;
    }
  }

  @override
  Widget build(BuildContext context) {
    final timeText = task.startTime != null
        ? DateFormat('HH:mm').format(task.startTime!)
        : null;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              // 시간 표시 (있을 때만)
              if (timeText != null)
                Container(
                  width: 54,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    timeText,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              // 완료 체크박스
              Checkbox(
                value: task.isDone,
                onChanged: (_) => onToggleDone(),
                activeColor: AppColors.teal,
                shape: const CircleBorder(),
              ),
              // 우선순위 색상 점
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  color: _quadrantColor,
                  shape: BoxShape.circle,
                ),
              ),
              // 제목
              Expanded(
                child: Text(
                  task.title,
                  style: TextStyle(
                    fontSize: 15,
                    decoration: task.isDone ? TextDecoration.lineThrough : null,
                    color: task.isDone ? Theme.of(context).disabledColor : null,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // 오늘의 3가지 지정 별 아이콘
              if (onToggleTop3 != null)
                IconButton(
                  icon: Icon(
                    task.isTop3
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    color: task.isTop3 ? AppColors.gold : Colors.grey,
                  ),
                  onPressed: onToggleTop3,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
