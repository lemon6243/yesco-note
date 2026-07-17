// ============================================================
// DashboardScreen (통합 통계 대시보드)
// ------------------------------------------------------------
// 그동안 쌓인 기록을 한눈에 보여주는 화면입니다.
// - 상단: 요약 카드 4개 (완료한 할 일 / 습관 최고 연속 / 아침 총시간 / 아침 연속)
// - 중간: 최근 7일 완료한 할 일 막대그래프
// - 하단: 최근 7일 아침 집중 시간(분) 막대그래프
// 새 데이터를 저장하지 않고, AppState의 통계 getter만 읽어서 보여줍니다.
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    // 최근 7일 데이터 준비
    final days = appState.last7Days;
    final taskCounts = appState.last7DaysCompletedTasks;
    final morningMinutes = appState.last7DaysMorningMinutes;

    // 아침 총 시간(분)으로 환산
    final totalMorningMin = (appState.totalMorningSeconds / 60).round();

    return Scaffold(
      appBar: AppBar(title: const Text('통계 대시보드')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ---- 성장 캐릭터 카드 ----
            _growthCard(context, appState),
            const SizedBox(height: 24),

            

            // ---- 요약 카드 4개 (2x2 그리드) ----
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true, // ListView 안에서 높이를 내용에 맞춤
              physics: const NeverScrollableScrollPhysics(), // 자체 스크롤 끔
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: [
                _summaryCard(
                  icon: Icons.check_circle_outline,
                  color: Colors.teal,
                  label: '완료한 할 일',
                  value: '${appState.totalCompletedTasks}개',
                ),
                _summaryCard(
                  icon: Icons.local_fire_department_outlined,
                  color: Colors.deepOrange,
                  label: '습관 최고 연속',
                  value: '${appState.bestHabitStreak}일',
                ),
                _summaryCard(
                  icon: Icons.wb_twilight,
                  color: Colors.indigo,
                  label: '아침 총 시간',
                  value: '$totalMorningMin분',
                ),
                _summaryCard(
                  icon: Icons.event_repeat,
                  color: Colors.purple,
                  label: '아침 연속',
                  value: '${appState.morningStreak}일',
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ---- 최근 7일: 완료한 할 일 ----
            _sectionTitle('최근 7일 · 완료한 할 일'),
            const SizedBox(height: 12),
            _barChart(
              context: context,
              days: days,
              values: taskCounts,
              barColor: Colors.teal,
              unit: '개',
            ),
            const SizedBox(height: 24),

            // ---- 최근 7일: 아침 집중 시간 ----
            _sectionTitle('최근 7일 · 아침 집중 시간(분)'),
            const SizedBox(height: 12),
            _barChart(
              context: context,
              days: days,
              values: morningMinutes,
              barColor: Colors.indigo,
              unit: '분',
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

    // 성장 캐릭터 카드 (동물 이모지 + 레벨 + 진행바)
  Widget _growthCard(BuildContext context, AppState appState) {
    final emoji = appState.growthEmoji;
    final level = appState.growthLevel;
    final stageName = appState.growthStageName;
    final progress = appState.growthProgress;
    final pointsToNext = appState.pointsToNextLevel;
    final animalName =
        AppState.availableAnimals[appState.growthAnimal] ?? '고양이';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.green.withValues(alpha: 0.15),
            Colors.teal.withValues(alpha: 0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.green.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          // 왼쪽: 큰 동물 이모지
          Text(emoji, style: const TextStyle(fontSize: 56)),
          const SizedBox(width: 18),
          // 오른쪽: 레벨/단계/진행바
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$animalName · $stageName',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Lv. $level',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                // 다음 레벨까지 진행바
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 10,
                    backgroundColor: Colors.grey.withValues(alpha: 0.2),
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Colors.green),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '다음 레벨까지 $pointsToNext점',
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }



  // 요약 카드 한 장
  Widget _summaryCard({
    required IconData icon,
    required Color color,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 12.5)),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
    );
  }

  // 최근 7일 막대그래프 (기본 위젯만으로 그림)
  Widget _barChart({
    required BuildContext context,
    required List<DateTime> days,
    required List<int> values,
    required Color barColor,
    required String unit,
  }) {
    // 가장 큰 값을 기준으로 막대 높이 비율을 정함 (0이면 1로 둬서 나눗셈 오류 방지)
    final maxValue = values.fold<int>(0, (m, v) => v > m ? v : m);
    final safeMax = maxValue == 0 ? 1 : maxValue;
    const chartHeight = 120.0;
    const weekdayLabels = ['월', '화', '수', '목', '금', '토', '일'];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(days.length, (i) {
          final value = values[i];
          final barHeight = chartHeight * (value / safeMax);
          final day = days[i];
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 값 숫자 (0이면 표시 안 함)
              Text(
                value > 0 ? '$value' : '',
                style: const TextStyle(fontSize: 11),
              ),
              const SizedBox(height: 4),
              // 막대
              Container(
                width: 22,
                height: value > 0 ? barHeight.clamp(6, chartHeight) : 6,
                decoration: BoxDecoration(
                  color: value > 0
                      ? barColor
                      : Colors.grey.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(height: 6),
              // 요일 라벨 (월=1 ~ 일=7 → 배열 인덱스 weekday-1)
              Text(
                weekdayLabels[day.weekday - 1],
                style: const TextStyle(fontSize: 11),
              ),
            ],
          );
        }),
      ),
    );
  }
}
