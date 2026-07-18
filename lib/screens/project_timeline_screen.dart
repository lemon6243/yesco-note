// ============================================================
// ProjectTimelineScreen (프로젝트 타임라인 / 간트 뷰)
// ------------------------------------------------------------
// 기간(시작일~마감일)이 설정된 프로젝트들을 가로 막대(간트)로
// 보여줍니다. 하루 = 약 20픽셀 폭으로 그리고, 가로 스크롤로
// 넘겨 봅니다. 막대 위에는 진행률을 겹쳐 표시합니다.
// 기간이 없는 프로젝트는 아래쪽에 "기간 미설정"으로 따로 나열합니다.
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../models/project.dart';

class ProjectTimelineScreen extends StatelessWidget {
  const ProjectTimelineScreen({super.key});

  static const double _dayWidth = 20; // 하루당 가로 픽셀
  static const double _rowHeight = 44; // 프로젝트 한 줄 높이
  static const double _labelWidth = 110; // 왼쪽 프로젝트 이름 칸 너비
  static const double _headerHeight = 36; // 상단 날짜 눈금 높이

  // 날짜의 시:분:초를 버리고 날짜만 남깁니다.
  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final all = appState.allProjects;

    // 기간이 설정된 프로젝트 (시작일·마감일 둘 다 있고 순서가 맞는 것)
    final dated = all
        .where((p) =>
            p.startDate != null &&
            p.dueDate != null &&
            !p.dueDate!.isBefore(p.startDate!))
        .toList();
    // 기간이 없는(또는 불완전한) 프로젝트
    final undated = all.where((p) => !dated.contains(p)).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('프로젝트 타임라인'), centerTitle: true),
      body: SafeArea(
        child: all.isEmpty
            ? _emptyMessage(context, '아직 프로젝트가 없어요.')
            : ListView(
                children: [
                  if (dated.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        '기간(시작일·마감일)이 설정된 프로젝트가 없어요.\n프로젝트를 수정해서 기간을 넣으면 여기에 막대로 표시됩니다.',
                        style: TextStyle(
                          fontSize: 13.5,
                          color: Theme.of(context).disabledColor,
                        ),
                      ),
                    )
                  else
                    _buildGantt(context, appState, dated),
                  if (undated.isNotEmpty) ...[
                    const Divider(height: 32),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: Text(
                        '기간 미설정',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).disabledColor,
                        ),
                      ),
                    ),
                    ...undated.map((p) => _buildUndatedTile(context, p)),
                    const SizedBox(height: 24),
                  ],
                ],
              ),
      ),
    );
  }

  // ---------------- 간트 본체 ----------------
  Widget _buildGantt(
    BuildContext context,
    AppState appState,
    List<Project> projects,
  ) {
    // 전체 범위: 가장 이른 시작일 ~ 가장 늦은 마감일, 앞뒤 3일씩 여백
    DateTime minStart = _dateOnly(projects.first.startDate!);
    DateTime maxDue = _dateOnly(projects.first.dueDate!);
    for (final p in projects) {
      final s = _dateOnly(p.startDate!);
      final e = _dateOnly(p.dueDate!);
      if (s.isBefore(minStart)) minStart = s;
      if (e.isAfter(maxDue)) maxDue = e;
    }
    final rangeStart = minStart.subtract(const Duration(days: 3));
    final rangeEnd = maxDue.add(const Duration(days: 3));
    final totalDays = rangeEnd.difference(rangeStart).inDays + 1;
    final chartWidth = totalDays * _dayWidth;
    final today = _dateOnly(DateTime.now());

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 상단 날짜 눈금
          Row(
            children: [
              SizedBox(width: _labelWidth, height: _headerHeight),
              _buildDateHeader(context, rangeStart, totalDays),
            ],
          ),
          // 프로젝트별 막대 행
          ...projects.map(
            (p) => _buildGanttRow(
              context,
              appState,
              p,
              rangeStart,
              chartWidth,
              today,
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // 상단 날짜 눈금 (7일마다 날짜 라벨)
  Widget _buildDateHeader(
    BuildContext context,
    DateTime rangeStart,
    int totalDays,
  ) {
    final marks = <Widget>[];
    for (int i = 0; i < totalDays; i++) {
      final date = rangeStart.add(Duration(days: i));
      // 7일 간격 또는 매월 1일에 라벨 표시
      final showLabel = i % 7 == 0 || date.day == 1;
      marks.add(
        SizedBox(
          width: _dayWidth,
          height: _headerHeight,
          child: showLabel
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${date.month}/${date.day}',
                      style: const TextStyle(fontSize: 9),
                    ),
                  ],
                )
              : null,
        ),
      );
    }
    return Row(children: marks);
  }

  // 프로젝트 한 개의 간트 행 (왼쪽 이름 + 오른쪽 막대)
  Widget _buildGanttRow(
    BuildContext context,
    AppState appState,
    Project project,
    DateTime rangeStart,
    double chartWidth,
    DateTime today,
  ) {
    final color = Color(project.colorValue);
    final start = _dateOnly(project.startDate!);
    final end = _dateOnly(project.dueDate!);

    final offsetDays = start.difference(rangeStart).inDays;
    final durationDays = end.difference(start).inDays + 1; // 마감일 포함
    final barLeft = offsetDays * _dayWidth;
    final barWidth = durationDays * _dayWidth;
    final progress = appState.projectProgress(project.id);

    // 오늘 위치 (범위 안일 때만 세로선 표시)
    final todayOffset = today.difference(rangeStart).inDays;
    final showToday = todayOffset >= 0 &&
        todayOffset < (chartWidth / _dayWidth).round();

    return SizedBox(
      height: _rowHeight,
      child: Row(
        children: [
          // 왼쪽 이름 칸
          SizedBox(
            width: _labelWidth,
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                project.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  decoration:
                      project.isDone ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
          ),
          // 오른쪽 막대 영역
          SizedBox(
            width: chartWidth,
            child: Stack(
              children: [
                // 오늘 세로선
                if (showToday)
                  Positioned(
                    left: todayOffset * _dayWidth,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      width: 1.5,
                      color: Colors.red.withValues(alpha: 0.5),
                    ),
                  ),
                // 막대 배경 (전체 기간)
                Positioned(
                  left: barLeft,
                  top: 8,
                  child: Container(
                    width: barWidth,
                    height: _rowHeight - 16,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
                // 진행률만큼 채운 막대
                Positioned(
                  left: barLeft,
                  top: 8,
                  child: Container(
                    width: barWidth * progress,
                    height: _rowHeight - 16,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
                // 막대 위 진행률 텍스트
                Positioned(
                  left: barLeft + 6,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: Text(
                      '${(progress * 100).round()}%',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 기간 미설정 프로젝트 한 줄
  Widget _buildUndatedTile(BuildContext context, Project project) {
    return ListTile(
      dense: true,
      leading: Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: Color(project.colorValue),
          shape: BoxShape.circle,
        ),
      ),
      title: Text(project.name, style: const TextStyle(fontSize: 13.5)),
      subtitle: const Text('기간 미설정', style: TextStyle(fontSize: 11)),
    );
  }

  Widget _emptyMessage(BuildContext context, String msg) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          msg,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            color: Theme.of(context).disabledColor,
          ),
        ),
      ),
    );
  }
}
