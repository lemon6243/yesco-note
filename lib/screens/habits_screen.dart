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
  Widget _buildHabitCard(
    BuildContext context,
    AppState appState,
    Habit habit,
  ) {
    final checkedToday = habit.isCheckedToday;
    final streak = habit.currentStreak;

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
          child: Row(
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
        ),
      ),
    );
  }

  // 새 습관 추가 다이얼로그 (이름 + 이모지 입력)
  Future<void> _showAddHabitDialog(
    BuildContext context,
    AppState appState,
  ) async {
    final nameController = TextEditingController();
    final emojiController = TextEditingController(text: '⭐');

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('새 습관 추가'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: '습관 이름',
                hintText: '예: 독서, 운동',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: emojiController,
              decoration: const InputDecoration(
                labelText: '이모지 (선택)',
                hintText: '예: 📚 🏃 💪',
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
              final name = nameController.text.trim();
              if (name.isEmpty) return; // 이름 없으면 추가 안 함
              final emoji = emojiController.text.trim().isEmpty
                  ? '⭐'
                  : emojiController.text.trim();
              appState.addHabit(name, emoji);
              Navigator.pop(ctx);
            },
            child: const Text('추가'),
          ),
        ],
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

  // 습관 수정 다이얼로그
  Future<void> _showEditHabitDialog(
    BuildContext context,
    AppState appState,
    Habit habit,
  ) async {
    final nameController = TextEditingController(text: habit.name);
    final emojiController = TextEditingController(text: habit.emoji);

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('습관 수정'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              autofocus: true,
              decoration: const InputDecoration(labelText: '습관 이름'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: emojiController,
              decoration: const InputDecoration(labelText: '이모지'),
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
              final name = nameController.text.trim();
              if (name.isEmpty) return;
              habit.name = name;
              habit.emoji = emojiController.text.trim().isEmpty
                  ? '⭐'
                  : emojiController.text.trim();
              appState.updateHabit(habit);
              Navigator.pop(ctx);
            },
            child: const Text('저장'),
          ),
        ],
      ),
    );
  }
}
