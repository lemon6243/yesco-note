// ============================================================
// ProjectTimelineScreen (프로젝트 타임라인 / 간트 뷰)
// ------------------------------------------------------------
// 기간(시작일~마감일)이 설정된 프로젝트들을 가로 막대(간트)로
// 보여줍니다. 하루 = 약 20픽셀 폭으로 그리고, 가로 스크롤로
// 넘겨 봅니다. 막대 위에는 진행률을 겹쳐 표시합니다.
// 막대를 탭하면 기간 수정 / 프로젝트 열기를 고를 수 있습니다.
// 기간이 없는 프로젝트는 아래쪽에 "기간 미설정"으로 따로 나열합니다.
// ============================================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../models/project.dart';
import 'project_detail_screen.dart';

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
                        '기간(시작일·마감일)이 설정된 프로젝트가 없어요.\n아래 목록에서 프로젝트를 눌러 기간을 넣으면 여기에 막대로 표시됩니다.',
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
                        '기간 미설정 (눌러서 기간 추가)',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).disabledColor,
                        ),
                      ),
                    ),
                    ...undated.map((p) => _buildUndatedTile(context, appState, p)),
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

  // 프로젝트 한 개의 간트 행 (왼쪽 이름 + 오른쪽 막대). 탭하면 메뉴.
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

    return InkWell(
      onTap: () => _showProjectActions(context, appState, project),
      child: SizedBox(
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
      ),
    );
  }

  // 기간 미설정 프로젝트 한 줄. 탭하면 기간 수정 다이얼로그.
  Widget _buildUndatedTile(
    BuildContext context,
    AppState appState,
    Project project,
  ) {
    return ListTile(
      dense: true,
      onTap: () => _showEditPeriodDialog(context, appState, project),
      leading: Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: Color(project.colorValue),
          shape: BoxShape.circle,
        ),
      ),
      title: Text(project.name, style: const TextStyle(fontSize: 13.5)),
      subtitle: const Text('기간 미설정 · 눌러서 추가', style: TextStyle(fontSize: 11)),
      trailing: const Icon(Icons.edit_calendar, size: 18),
    );
  }

  // 막대 탭 → 동작 선택 바텀시트
  void _showProjectActions(
    BuildContext context,
    AppState appState,
    Project project,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                project.name,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.date_range),
              title: const Text('기간 수정'),
              onTap: () {
                Navigator.pop(ctx);
                _showEditPeriodDialog(context, appState, project);
              },
            ),
            ListTile(
              leading: const Icon(Icons.open_in_new),
              title: const Text('프로젝트 열기'),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        ProjectDetailScreen(projectId: project.id),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // 시작일·마감일 편집 다이얼로그
  void _showEditPeriodDialog(
    BuildContext context,
    AppState appState,
    Project project,
  ) {
    DateTime? startDate = project.startDate;
    DateTime? dueDate = project.dueDate;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text('${project.name} 기간'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _dateRow(
                ctx: ctx,
                label: '시작일',
                value: startDate,
                onPick: (d) => setState(() => startDate = d),
              ),
              _dateRow(
                ctx: ctx,
                label: '마감일',
                value: dueDate,
                onPick: (d) => setState(() => dueDate = d),
              ),
              if (startDate != null &&
                  dueDate != null &&
                  dueDate!.isBefore(startDate!))
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    '마감일이 시작일보다 빠릅니다.',
                    style: TextStyle(fontSize: 12, color: Colors.red),
                  ),
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
                // 마감일이 시작일보다 빠르면 저장 막기
                if (startDate != null &&
                    dueDate != null &&
                    dueDate!.isBefore(startDate!)) {
                  return;
                }
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

  // 날짜 한 줄 (라벨 + 선택 버튼 + 지우기)
  Widget _dateRow({
    required BuildContext ctx,
    required String label,
    required DateTime? value,
    required ValueChanged<DateTime?> onPick,
  }) {
    final fmt = DateFormat('yyyy.M.d');
    return Row(
      children: [
        SizedBox(
          width: 52,
          child: Text(label, style: const TextStyle(fontSize: 13)),
        ),
        Expanded(
          child: TextButton(
            onPressed: () async {
              final now = DateTime.now();
              final picked = await showDatePicker(
                context: ctx,
                initialDate: value ?? now,
                firstDate: DateTime(now.year - 3),
                lastDate: DateTime(now.year + 5),
              );
              if (picked != null) onPick(picked);
            },
            child: Text(
              value != null ? fmt.format(value) : '날짜 선택',
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ),
        if (value != null)
          IconButton(
            icon: const Icon(Icons.clear, size: 18),
            onPressed: () => onPick(null),
          ),
      ],
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
