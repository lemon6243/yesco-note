// ============================================================
// HabitsScreen (습관 / 챌린지 화면)
// ------------------------------------------------------------
// 반복 습관(독서·운동 등)을 카드로 보여주고,
// '오늘 했는지'를 체크하며 연속일수(streak)를 쌓아가는 화면입니다.
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../models/habit.dart';
import '../theme/app_theme.dart';
import 'habit_detail_screen.dart';

class HabitsScreen extends StatelessWidget {
  const HabitsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final habits = appState.activeHabits;

    return Scaffold(
      appBar: AppBar(title: const Text('습관 · 챌린지'), centerTitle: true),
      // 우측 하단 + 버튼: 새 습관 추가
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddHabitDialog(context, appState),
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: habits.isEmpty
            // 습관이 하나도 없을 때 안내 문구
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🌱', style: TextStyle(fontSize: 48)),
                      const SizedBox(height: 12),
                      Text(
                        '아직 습관이 없어요.\n오른쪽 아래 + 버튼으로\n첫 습관을 추가해 보세요.',
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
            // 습관 목록
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 90),
                itemCount: habits.length,
                itemBuilder: (context, index) {
                  final habit = habits[index];
                  return _buildHabitCard(context, appState, habit);
                },
              ),
      ),
    );
  }

  // 습관 한 개를 표시하는 카드
  Widget _buildHabitCard(BuildContext context, AppState appState, Habit habit) {
    final checkedToday = habit.isCheckedToday;
    final streak = habit.currentStreak;
    final weeklyGoal = habit.weeklyGoal;
    final checksThisWeek = habit.checksThisWeek;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        // 카드를 탭하면 달력 상세 화면으로 이동
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => HabitDetailScreen(habit: habit)),
        ),
        // 길게 누르면 수정/삭제 메뉴
        onLongPress: () => _showHabitMenu(context, appState, habit),

        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // 이모지
                  Text(habit.emoji, style: const TextStyle(fontSize: 26)),
                  const SizedBox(width: 14),
                  // 이름 + 연속일수
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          habit.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          streak > 0 ? '🔥 $streak일 연속' : '아직 시작 전',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: streak > 0
                                ? AppColors.coral
                                : Theme.of(context).disabledColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 오늘 체크 버튼 (원형)
                  GestureDetector(
                    onTap: () => appState.toggleHabitToday(habit),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: checkedToday
                            ? AppColors.teal
                            : Colors.transparent,
                        border: Border.all(
                          color: checkedToday ? AppColors.teal : Colors.grey,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        Icons.check_rounded,
                        color: checkedToday ? Colors.white : Colors.grey,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
              // 주간 목표가 설정된 습관만 진행률 바를 보여줍니다.
              if (weeklyGoal != null && weeklyGoal > 0) ...[
                const SizedBox(height: 12),
                _buildWeeklyGoalBar(context, checksThisWeek, weeklyGoal),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // 이번 주 진행률 바: "이번 주 2/3회" + 진행 바
  Widget _buildWeeklyGoalBar(
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
                fontSize: 11.5,
                color: Theme.of(context).disabledColor,
              ),
            ),
            Text(
              achieved
                  ? '🎉 $checksThisWeek/$weeklyGoal회 달성!'
                  : '$checksThisWeek/$weeklyGoal회',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: achieved
                    ? AppColors.teal
                    : Theme.of(context).disabledColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
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

  // 습관에 자주 쓰이는 예시 이모지 목록. 탭해서 바로 선택할 수 있습니다.
  static const List<String> _emojiOptions = [
    '⭐', '📚', '🏃', '💪', '🧘', '💧', '😴', '🥗',
    '✍️', '💻', '🎨', '🎵', '🚶', '🚴', '☕', '🚭',
    '💰', '🧹', '🙏', '🌅', '🌙', '🐾', '🎯', '📝',
    '🦷', '🌿',
  ];

  // 이모지 선택 그리드: 큰 미리보기 원 + 예시 아이콘들 + 직접입력(✏️) 옵션
  Widget _buildEmojiPicker({
    required BuildContext context,
    required String selected,
    required void Function(String) onSelect,
  }) {
    // 목록에 없는 값(직접 입력했던 이전 값 등)이라도 선택 상태를 표시할 수 있도록
    // 선택값이 목록 밖이면 맨 앞에 미리보기만 추가로 보여줍니다.
    final isCustomSelected = !_emojiOptions.contains(selected);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 현재 선택된 이모지 큰 미리보기
        Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.teal.withValues(alpha: 0.12),
                border: Border.all(color: AppColors.teal, width: 2),
              ),
              alignment: Alignment.center,
              child: Text(selected, style: const TextStyle(fontSize: 26)),
            ),
            const SizedBox(width: 10),
            Text(
              '아래에서 선택하세요',
              style: TextStyle(
                fontSize: 12.5,
                color: Theme.of(context).disabledColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // 예시 이모지 그리드 (탭해서 선택)
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ..._emojiOptions.map((emoji) {
              final isSelected = selected == emoji;
              return GestureDetector(
                onTap: () => onSelect(emoji),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected
                        ? AppColors.teal.withValues(alpha: 0.15)
                        : Colors.grey.withValues(alpha: 0.08),
                    border: isSelected
                        ? Border.all(color: AppColors.teal, width: 2)
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: Text(emoji, style: const TextStyle(fontSize: 20)),
                ),
              );
            }),
            // 직접 입력 버튼: 목록에 없는 이모지를 원할 경우
            GestureDetector(
              onTap: () => _showCustomEmojiInput(context, selected, onSelect),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCustomSelected
                      ? AppColors.teal.withValues(alpha: 0.15)
                      : Colors.grey.withValues(alpha: 0.08),
                  border: isCustomSelected
                      ? Border.all(color: AppColors.teal, width: 2)
                      : null,
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.edit_outlined, size: 18),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // '직접 입력' 아이콘을 눌렀을 때 나오는 작은 입력 다이얼로그
  Future<void> _showCustomEmojiInput(
    BuildContext context,
    String current,
    void Function(String) onSelect,
  ) async {
    final controller = TextEditingController(text: current);
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('이모지 직접 입력'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: '예: 🎮 🧑\u200d💻 🍎'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              final value = controller.text.trim();
              if (value.isNotEmpty) onSelect(value);
              Navigator.pop(ctx);
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  // 주간 목표 선택용 칩 목록: null(없음) / 2~5회 / 7(매일)
  static const List<int?> _weeklyGoalOptions = [null, 2, 3, 4, 5, 7];

  String _weeklyGoalLabel(int? value) {
    if (value == null) return '없음';
    if (value >= 7) return '매일';
    return '주 $value회';
  }

  // 주간 목표 선택 칩 한 줄 (다이얼로그 안에서 공용으로 사용)
  Widget _buildWeeklyGoalChips({
    required int? selected,
    required void Function(int?) onSelect,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _weeklyGoalOptions.map((option) {
        final isSelected = selected == option;
        return ChoiceChip(
          label: Text(_weeklyGoalLabel(option)),
          selected: isSelected,
          onSelected: (_) => onSelect(option),
          selectedColor: AppColors.teal.withValues(alpha: 0.2),
          labelStyle: TextStyle(
            color: isSelected ? AppColors.teal : null,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        );
      }).toList(),
    );
  }

  // 새 습관 추가 다이얼로그 (이름 + 이모지 + 주간 목표 입력)
  Future<void> _showAddHabitDialog(
    BuildContext context,
    AppState appState,
  ) async {
    final nameController = TextEditingController();
    String selectedEmoji = '⭐';
    int? selectedGoal; // 기본은 목표 없음

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('새 습관 추가'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: '습관 이름',
                    hintText: '예: 독서, 운동',
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '아이콘',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Theme.of(ctx).disabledColor,
                  ),
                ),
                const SizedBox(height: 8),
                _buildEmojiPicker(
                  context: ctx,
                  selected: selectedEmoji,
                  onSelect: (value) => setState(() => selectedEmoji = value),
                ),
                const SizedBox(height: 16),
                Text(
                  '주간 목표 (선택)',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Theme.of(ctx).disabledColor,
                  ),
                ),
                const SizedBox(height: 8),
                _buildWeeklyGoalChips(
                  selected: selectedGoal,
                  onSelect: (value) => setState(() => selectedGoal = value),
                ),
              ],
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
                if (name.isEmpty) return; // 이름 없으면 추가 안 함
                appState.addHabit(name, selectedEmoji, weeklyGoal: selectedGoal);
                Navigator.pop(ctx);
              },
              child: const Text('추가'),
            ),
          ],
        ),
      ),
    );
  }

  // 카드를 길게 눌렀을 때 나오는 수정/삭제 메뉴
  Future<void> _showHabitMenu(
    BuildContext context,
    AppState appState,
    Habit habit,
  ) async {
    await showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('이름·이모지 수정'),
              onTap: () {
                Navigator.pop(ctx);
                _showEditHabitDialog(context, appState, habit);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('삭제', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(ctx);
                appState.deleteHabit(habit.id);
              },
            ),
          ],
        ),
      ),
    );
  }

  // 습관 수정 다이얼로그 (이름 + 이모지 + 주간 목표 수정)
  Future<void> _showEditHabitDialog(
    BuildContext context,
    AppState appState,
    Habit habit,
  ) async {
    final nameController = TextEditingController(text: habit.name);
    String selectedEmoji = habit.emoji;
    // 기존 목표값 중 선택지에 없는 값이면(예: 6) null로 취급하지 않고 그대로 유지하도록
    // 옵션 목록에 없어도 우선 현재값으로 시작합니다.
    int? selectedGoal = habit.weeklyGoal;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('습관 수정'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  autofocus: true,
                  decoration: const InputDecoration(labelText: '습관 이름'),
                ),
                const SizedBox(height: 16),
                Text(
                  '아이콘',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Theme.of(ctx).disabledColor,
                  ),
                ),
                const SizedBox(height: 8),
                _buildEmojiPicker(
                  context: ctx,
                  selected: selectedEmoji,
                  onSelect: (value) => setState(() => selectedEmoji = value),
                ),
                const SizedBox(height: 16),
                Text(
                  '주간 목표 (선택)',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Theme.of(ctx).disabledColor,
                  ),
                ),
                const SizedBox(height: 8),
                _buildWeeklyGoalChips(
                  selected: selectedGoal,
                  onSelect: (value) => setState(() => selectedGoal = value),
                ),
              ],
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
                habit.name = name;
                habit.emoji = selectedEmoji;
                habit.weeklyGoal = selectedGoal;
                appState.updateHabit(habit);
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
