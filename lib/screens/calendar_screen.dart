// ============================================================
// CalendarScreen (월간 캘린더 · 날짜 점프용)
// ------------------------------------------------------------
// 오늘 화면에서 하루씩 넘기는 대신, 한 달을 한눈에 보고
// 원하는 날짜로 바로 이동하기 위한 화면입니다.
// - 각 날짜 아래에 그날의 할 일 개수만큼 작은 점(dot) 표시
//   (전부 완료된 날은 teal 점, 미완료가 남은 날은 coral 점)
// - 날짜를 탭하면 그 날짜로 이동하면서 이 화면을 닫음
// - 아래쪽에 선택한 날짜의 할 일 목록을 간단히 미리보기
// ============================================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../services/app_state.dart';
import '../models/task.dart';
import '../theme/app_theme.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  // 캘린더에서 지금 보고 있는 '달'의 기준 (스와이프로 바뀜)
  DateTime _focusedDay = DateTime.now();
  // 캘린더에서 지금 선택(하이라이트)된 날
  DateTime _selectedDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    // 처음 열 때는 오늘 화면에서 보고 있던 날짜에 맞춥니다.
    final appState = context.read<AppState>();
    _focusedDay = appState.selectedDate;
    _selectedDay = appState.selectedDate;
  }

  // 특정 날짜의 할 일 목록을 storage에서 가져오는 도우미
  List<Task> _tasksOn(AppState appState, DateTime day) {
    return appState.storage.getTasksByDate(day);
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    // 현재 선택된 날짜의 할 일 (아래 미리보기용)
    final selectedTasks = _tasksOn(appState, _selectedDay)
      ..sort((a, b) {
        // 시간 있는 일 먼저(시간순), 시간 없는 일은 뒤로
        if (a.startTime == null && b.startTime == null) return 0;
        if (a.startTime == null) return 1;
        if (b.startTime == null) return -1;
        return a.startTime!.compareTo(b.startTime!);
      });

    return Scaffold(
      appBar: AppBar(title: const Text('캘린더'), centerTitle: true),
      body: SafeArea(
        child: Column(
          children: [
            // ---------- 월간 캘린더 ----------
            Card(
              margin: const EdgeInsets.all(12),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: TableCalendar<Task>(
                  locale: 'ko_KR',
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2035, 12, 31),
                  focusedDay: _focusedDay,
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  // 각 날짜에 그날의 할 일 목록을 연결 (점 개수 계산에 사용)
                  eventLoader: (day) => _tasksOn(appState, day),
                  startingDayOfWeek: StartingDayOfWeek.monday,
                  calendarStyle: CalendarStyle(
                    // 오늘 날짜 표시
                    todayDecoration: BoxDecoration(
                      color: AppColors.coral.withValues(alpha: 0.4),
                      shape: BoxShape.circle,
                    ),
                    // 선택한 날짜 표시
                    selectedDecoration: const BoxDecoration(
                      color: AppColors.teal,
                      shape: BoxShape.circle,
                    ),
                    markersMaxCount: 4,
                  ),
                  headerStyle: const HeaderStyle(
                    formatButtonVisible: false, // 2주/월 전환 버튼 숨김 (단순하게)
                    titleCentered: true,
                  ),
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                  },
                  onPageChanged: (focusedDay) {
                    // 달을 넘길 때 기준 달만 갱신 (선택은 유지)
                    _focusedDay = focusedDay;
                  },
                  // 날짜 아래 점(marker)을 직접 그려서 완료/미완료 색을 구분
                  calendarBuilders: CalendarBuilders<Task>(
                    markerBuilder: (context, day, tasks) {
                      if (tasks.isEmpty) return null;
                      // 미완료가 하나라도 있으면 coral, 전부 완료면 teal
                      final hasUndone = tasks.any((t) => !t.isDone);
                      final color = hasUndone
                          ? AppColors.coral
                          : AppColors.teal;
                      return Positioned(
                        bottom: 4,
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),

            // ---------- 선택한 날짜로 이동 버튼 ----------
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  icon: const Icon(Icons.arrow_forward),
                  label: Text(
                    '${DateFormat('M월 d일 (E)', 'ko_KR').format(_selectedDay)} 일정 보기',
                  ),
                  onPressed: () {
                    // 선택한 날짜로 오늘 화면을 이동시키고 캘린더를 닫음
                    appState.goToDate(_selectedDay);
                    Navigator.pop(context);
                  },
                ),
              ),
            ),
            const SizedBox(height: 8),

            // ---------- 선택한 날짜의 할 일 미리보기 ----------
            Expanded(
              child: selectedTasks.isEmpty
                  ? Center(
                      child: Text(
                        '이 날에는 등록된 할 일이 없어요.',
                        style: TextStyle(color: Theme.of(context).disabledColor),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                      itemCount: selectedTasks.length,
                      itemBuilder: (context, index) {
                        final task = selectedTasks[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 6),
                          child: ListTile(
                            dense: true,
                            leading: Icon(
                              task.isDone
                                  ? Icons.check_circle
                                  : Icons.radio_button_unchecked,
                              color: task.isDone
                                  ? AppColors.teal
                                  : Theme.of(context).disabledColor,
                              size: 20,
                            ),
                            title: Text(
                              task.title,
                              style: TextStyle(
                                fontSize: 14,
                                decoration: task.isDone
                                    ? TextDecoration.lineThrough
                                    : null,
                                color: task.isDone
                                    ? Theme.of(context).disabledColor
                                    : null,
                              ),
                            ),
                            trailing: task.startTime != null
                                ? Text(
                                    task.startTime!,
                                    style: const TextStyle(fontSize: 12),
                                  )
                                : null,
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
