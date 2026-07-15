// ============================================================
// HabitDetailScreen (습관 상세 · 월간 달력 뷰)
// ------------------------------------------------------------
// 습관 하나를 골라서 "이번 달 어느 날 체크했는지"를
// 달력 형태로 한눈에 보여주는 화면입니다.
// - 체크한 날은 색이 채워진 원으로 표시
// - 날짜를 탭하면 그 날의 체크를 켜고 끌 수 있음 (오늘까지만)
// - 위쪽에 이번 달 달성 횟수 / 현재 연속일수 요약
// - 이전 달 / 다음 달로 이동 가능
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../models/habit.dart';
import '../theme/app_theme.dart';

class HabitDetailScreen extends StatefulWidget {
  final Habit habit;
  const HabitDetailScreen({super.key, required this.habit});

  @override
  State<HabitDetailScreen> createState() => _HabitDetailScreenState();
}

class _HabitDetailScreenState extends State<HabitDetailScreen> {
  // 지금 달력에서 보고 있는 '달'의 기준 날짜 (그 달의 1일)
  late DateTime _visibleMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _visibleMonth = DateTime(now.year, now.month, 1);
  }

  // 이전 달로 이동
  void _goPrevMonth() {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month - 1, 1);
    });
  }

  // 다음 달로 이동
  void _goNextMonth() {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + 1, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    // 화면이 항상 최신 상태를 반영하도록 watch로 구독합니다.
    final appState = context.watch<AppState>();
    final habit = widget.habit;

    // 이번 달에 체크한 횟수 계산
    final checksThisMonth = habit.checkedDates.where((d) {
      final parts = d.split('-');
      if (parts.length != 3) return false;
      final y = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      return y == _visibleMonth.year && m == _visibleMonth.month;
    }).length;

    return Scaffold(
      appBar: AppBar(
        title: Text('${habit.emoji} ${habit.name}'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ----- 요약 카드 (이번 달 달성 / 연속일수) -----
            _buildSummaryCard(context, habit, checksThisMonth),
            const SizedBox(height: 16),
            // ----- 월 이동 헤더 -----
            _buildMonthHeader(context),
            const SizedBox(height: 8),
            // ----- 요일 헤더 (일~토) -----
            _buildWeekdayHeader(context),
            const SizedBox(height: 4),
            // ----- 달력 본체 -----
            _buildCalendarGrid(context, appState, habit),
            const SizedBox(height: 20),
            Text(
              '날짜를 눌러 체크를 켜고 끌 수 있어요. (오늘까지만 가능)',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                color: Theme.of(context).disabledColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 이번 달 달성 횟수 + 현재 연속일수 + 최장 연속 + 총 실천 횟수 요약 카드
  Widget _buildSummaryCard(
    BuildContext context,
    Habit habit,
    int checksThisMonth,
  ) {
    final streak = habit.currentStreak;
    final longest = habit.longestStreak;
    final total = habit.totalCheckCount;
    final weeklyGoal = habit.weeklyGoal;
    final checksThisWeek = habit.checksThisWeek;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
        child: Column(
          children: [
            // 좁은 폰 화면에서도 겹치지 않도록 2행 2열(2x2)로 배치합니다.
            // 1행: 이번 달 / 연속   2행: 최장 연속 / 총 실천
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _summaryItem(
                  context,
                  '이번 달',
                  '$checksThisMonth일',
                  Icons.check_circle_outline,
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Theme.of(context).dividerColor,
                ),
                _summaryItem(
                  context,
                  '연속',
                  streak > 0 ? '🔥 $streak일' : '-',
                  Icons.local_fire_department_outlined,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Divider(height: 1, color: Theme.of(context).dividerColor),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _summaryItem(
                  context,
                  '최장 연속',
                  longest > 0 ? '$longest일' : '-',
                  Icons.emoji_events_outlined,
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Theme.of(context).dividerColor,
                ),
                _summaryItem(
                  context,
                  '총 실천',
                  '$total회',
                  Icons.military_tech_outlined,
                ),
              ],
            ),
            // 주간 목표가 설정된 경우, 아래에 이번 주 진행 상황을 추가로 보여줍니다.
            if (weeklyGoal != null && weeklyGoal > 0) ...[
              const SizedBox(height: 16),
              Divider(height: 1, color: Theme.of(context).dividerColor),
              const SizedBox(height: 14),
              _buildWeeklyGoalRow(context, checksThisWeek, weeklyGoal),
            ],
          ],
        ),
      ),
    );
  }

  // "이번 주 목표: 2/3회" + 진행률 바 (상세 화면용)
  Widget _buildWeeklyGoalRow(
    BuildContext context,
    int checksThisWeek,
    int weeklyGoal,
  ) {
    final achieved = checksThisWeek >= weeklyGoal;
    final progress = (checksThisWeek / weeklyGoal).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '이번 주 목표',
              style: TextStyle(
                fontSize: 12.5,
                color: Theme.of(context).disabledColor,
              ),
            ),
            Text(
              achieved
                  ? '🎉 $checksThisWeek/$weeklyGoal회 달성!'
                  : '$checksThisWeek/$weeklyGoal회',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: achieved
                    ? AppColors.teal
                    : Theme.of(context).disabledColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: Colors.grey.withValues(alpha: 0.15),
            valueColor: AlwaysStoppedAnimation(
              achieved ? AppColors.teal : AppColors.gold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _summaryItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            color: Theme.of(context).disabledColor,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  // "2026년 7월" + 이전/다음 달 버튼
  Widget _buildMonthHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: _goPrevMonth,
        ),
        Text(
          '${_visibleMonth.year}년 ${_visibleMonth.month}월',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: _goNextMonth,
        ),
      ],
    );
  }

  // 요일 헤더 (일 월 화 수 목 금 토)
  Widget _buildWeekdayHeader(BuildContext context) {
    const labels = ['일', '월', '화', '수', '목', '금', '토'];
    return Row(
      children: labels.map((label) {
        final isSun = label == '일';
        final isSat = label == '토';
        return Expanded(
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: isSun
                    ? Colors.red.shade400
                    : isSat
                    ? Colors.blue.shade400
                    : Theme.of(context).disabledColor,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // 달력 본체 (날짜 칸들)
  Widget _buildCalendarGrid(
    BuildContext context,
    AppState appState,
    Habit habit,
  ) {
    // 이번 달 1일이 무슨 요일인지 (Dart: 월=1 ~ 일=7)
    final firstDay = DateTime(_visibleMonth.year, _visibleMonth.month, 1);
    // 일요일을 맨 앞(0)으로 두기 위한 빈 칸 개수 계산
    final leadingEmpty = firstDay.weekday % 7; // 일요일이면 0칸
    // 이번 달의 총 일수
    final daysInMonth = DateTime(
      _visibleMonth.year,
      _visibleMonth.month + 1,
      0,
    ).day;

    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);

    // 앞쪽 빈 칸 + 실제 날짜들로 셀 목록을 만듭니다.
    final cells = <Widget>[];
    for (int i = 0; i < leadingEmpty; i++) {
      cells.add(const SizedBox());
    }
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(_visibleMonth.year, _visibleMonth.month, day);
      final checked = habit.isCheckedOn(date);
      final isToday = date == todayOnly;
      final isFuture = date.isAfter(todayOnly);

      cells.add(
        GestureDetector(
          onTap: isFuture
              ? null
              : () => appState.toggleHabitOnDate(habit, date),
          child: Container(
            margin: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: checked ? AppColors.teal : Colors.transparent,
              border: isToday && !checked
                  ? Border.all(color: AppColors.coral, width: 2)
                  : null,
            ),
            child: Center(
              child: Text(
                '$day',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
                  color: checked
                      ? Colors.white
                      : isFuture
                      ? Theme.of(context).disabledColor.withValues(alpha: 0.4)
                      : null,
                ),
              ),
            ),
          ),
        ),
      );
    }

    // 7칸씩 줄바꿈하는 그리드로 표시
    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: cells,
    );
  }
}
