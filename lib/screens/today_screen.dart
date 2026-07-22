// ============================================================
// TodayScreen (오늘 화면 = 홈)
// ------------------------------------------------------------
// 앱을 열면 가장 먼저 보이는 화면입니다.
// - 상단: 날짜 이동(좌우 화살표)
// - "오늘 집중할 3가지" 강조 카드
// - 시간순 일정 리스트 (시간 있는 일 → 시간순 / 없는 일 → 시간 미정 묶음)
// ============================================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../models/task.dart';
import '../theme/app_theme.dart';
import '../widgets/task_tile.dart';
import 'task_edit_screen.dart';



class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final selectedDate = appState.selectedDate;
    final isToday = _isSameDay(selectedDate, DateTime.now());

    final dateFormat = DateFormat('yyyy년 M월 d일 (E)', 'ko_KR');

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // ---------- 상단 날짜 이동 헤더 ----------
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.coral.withValues(alpha: 0.9),
                    AppColors.teal.withValues(alpha: 0.85),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                 Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.chevron_left,
                        color: Colors.white,
                        size: 28,
                      ),
                      onPressed: appState.goToPreviousDay,
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: appState.goToToday,
                      child: Column(
                        children: [
                          Text(
                            dateFormat.format(selectedDate),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (!isToday)
                            const Padding(
                              padding: EdgeInsets.only(top: 2),
                              child: Text(
                                '탭하여 오늘로 돌아가기',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(
                        Icons.chevron_right,
                        color: Colors.white,
                        size: 28,
                      ),
                      onPressed: appState.goToNextDay,
                    ),
                  ],
                ),



                  const SizedBox(height: 14),
                  _buildTop3Card(context, appState),
                ],
              ),
            ),
            
            // ---------- 장소 필터 바 ----------
            _buildLocationFilterBar(context, appState),
            // ---------- 카테고리 필터 바 ----------
            _buildCategoryFilterBar(context, appState),
            // ---------- 시간순 일정 리스트 ----------
            Expanded(child: _buildTaskList(context, appState)),

          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'today_fab',
        onPressed: () => _openAddTask(context, appState.selectedDate),
        child: const Icon(Icons.add),
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  // "오늘 집중할 3가지" 강조 카드
  Widget _buildTop3Card(BuildContext context, AppState appState) {
    final top3 = appState.top3Tasks;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.flag_rounded, color: Colors.white, size: 18),
              SizedBox(width: 6),
              Text(
                '오늘 집중할 3가지',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (top3.isEmpty)
            const Text(
              '아래 목록에서 ☆ 아이콘을 눌러 오늘 집중할 3가지를 골라보세요.',
              style: TextStyle(color: Colors.white, fontSize: 12.5),
            )
          else
            ...top3.map(
              (task) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Icon(
                      task.isDone
                          ? Icons.check_circle_rounded
                          : Icons.circle_outlined,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        task.title,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          decoration: task.isDone
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // 장소 필터 바 (전체 / 🏠 집 / 🚶 외부)
  Widget _buildLocationFilterBar(BuildContext context, AppState appState) {
    final current = appState.locationFilter; // null / 'home' / 'outside'

    Widget chip(String label, String? value) {
      final selected = current == value;
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          label: Text(label),
          selected: selected,
          onSelected: (_) => appState.setLocationFilter(value),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
      child: Row(
        children: [
          chip('전체', null),
          chip('🏠 집', 'home'),
          chip('🚶 외부', 'outside'),
        ],
      ),
    );
  }

  // 카테고리 필터 바 (전체 / 💼 업무 / 🚀 부업 / 🏡 개인 / 📈 투자)
  Widget _buildCategoryFilterBar(BuildContext context, AppState appState) {
    final current = appState.categoryFilter; // null / 'work' / 'side' / 'private' / 'invest'

    Widget chip(String label, String? value) {
      final selected = current == value;
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          label: Text(label),
          selected: selected,
          onSelected: (_) => appState.setCategoryFilter(value),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            chip('전체', null),
            chip('💼 업무', 'work'),
            chip('🚀 부업', 'side'),
            chip('🏡 개인', 'private'),
            chip('📈 투자', 'invest'),
          ],
        ),
      ),
    );
  }


  // 시간순/시간미정 리스트 전체
  Widget _buildTaskList(BuildContext context, AppState appState) {
    final timed = appState.timedTasks;
    final untimed = appState.untimedTasks;

    if (timed.isEmpty && untimed.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.event_available_rounded,
                size: 56,
                color: Colors.grey.withValues(alpha: 0.4),
              ),
              const SizedBox(height: 12),
              Text(
                '이 날의 할 일이 없어요.\n오른쪽 아래 + 버튼으로 추가해보세요.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.withValues(alpha: 0.8)),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 90),
      children: [
        if (timed.isNotEmpty) ...[
          _sectionLabel('⏰ 시간순 일정'),
          ...timed.map(
            (task) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: TaskTile(
                task: task,
                onToggleDone: () => appState.toggleTaskDone(task),
                onToggleTop3: () => _handleToggleTop3(context, appState, task),
                onTap: () => _openEditTask(context, task),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (untimed.isNotEmpty) ...[
          _sectionLabel('🗒 시간 미정'),
          ...untimed.map(
            (task) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: TaskTile(
                task: task,
                onToggleDone: () => appState.toggleTaskDone(task),
                onToggleTop3: () => _handleToggleTop3(context, appState, task),
                onTap: () => _openEditTask(context, task),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _sectionLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8, left: 4),
    child: Text(
      text,
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
    ),
  );

  Future<void> _handleToggleTop3(
    BuildContext context,
    AppState appState,
    Task task,
  ) async {
    final ok = await appState.toggleTop3(task);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('오늘의 3가지는 최대 3개까지만 고를 수 있어요.')),
      );
    }
  }

  void _openAddTask(BuildContext context, DateTime date) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TaskEditScreen(initialDate: date)),
    );
  }

  void _openEditTask(BuildContext context, Task task) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TaskEditScreen(existingTask: task)),
    );
  }
}
