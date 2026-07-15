// ============================================================
// ReflectionScreen (저녁 회고 화면)
// ------------------------------------------------------------
// 하루가 끝날 때 "오늘 집중할 3가지"를 잘 해냈는지 점검하고,
// 짧은 소감을 적어두는 화면입니다.
// ============================================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';

class ReflectionScreen extends StatefulWidget {
  const ReflectionScreen({super.key});

  @override
  State<ReflectionScreen> createState() => _ReflectionScreenState();
}

class _ReflectionScreenState extends State<ReflectionScreen> {
  final _memoController = TextEditingController();
  DateTime? _lastLoadedDate; // 마지막으로 메모를 불러온 날짜

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final selectedDate = appState.selectedDate;
    final top3 = appState.top3Tasks;

    // 날짜가 바뀔 때마다 그 날짜의 회고 메모를 입력창에 다시 불러옵니다.
    if (_lastLoadedDate == null ||
        !_isSameDay(_lastLoadedDate!, selectedDate)) {
      final reflection = appState.reflectionFor(selectedDate);
      _memoController.text = reflection?.memo ?? '';
      _lastLoadedDate = selectedDate;
    }

    final doneCount = top3.where((t) => t.isDone).length;

    return Scaffold(
      appBar: AppBar(title: const Text('저녁 회고')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              DateFormat('yyyy년 M월 d일 (E)', 'ko_KR').format(selectedDate),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              '오늘 하루를 돌아볼까요?',
              style: TextStyle(color: Colors.grey.withValues(alpha: 0.8)),
            ),
            const SizedBox(height: 20),

            // 오늘의 3가지 달성 현황 카드
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.flag_rounded,
                          color: AppColors.coral,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          '오늘 집중할 3가지',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        Text(
                          '$doneCount / ${top3.length}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.teal,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (top3.isEmpty)
                      Text(
                        '이 날은 오늘의 3가지를 선정하지 않았어요.',
                        style: TextStyle(
                          color: Colors.grey.withValues(alpha: 0.7),
                          fontSize: 13,
                        ),
                      )
                    else
                      ...top3.map(
                        (task) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Icon(
                                task.isDone
                                    ? Icons.check_circle_rounded
                                    : Icons.radio_button_unchecked,
                                size: 18,
                                color: task.isDone
                                    ? AppColors.teal
                                    : Colors.grey,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  task.title,
                                  style: TextStyle(
                                    decoration: task.isDone
                                        ? TextDecoration.lineThrough
                                        : null,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),
            const Text(
              '오늘 하루 소감',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _memoController,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: '오늘 하루는 어땠나요? 자유롭게 적어보세요.',
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await context.read<AppState>().saveReflectionMemo(
                  selectedDate,
                  _memoController.text.trim(),
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('회고를 저장했어요.')));
                }
              },
              child: const SizedBox(
                width: double.infinity,
                child: Text('회고 저장', textAlign: TextAlign.center),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 두 날짜가 같은 '날'인지 비교 (시/분은 무시)
  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  void dispose() {
    _memoController.dispose();
    super.dispose();
  }
}
