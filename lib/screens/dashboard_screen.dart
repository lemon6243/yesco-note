import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:confetti/confetti.dart'; // 폭죽 패키지
import '../services/app_state.dart';
import '../services/export_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // 폭죽 컨트롤러
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    // 폭죽 재생 시간 설정 (1.5초간 발사)
    _confettiController = ConfettiController(duration: const Duration(milliseconds: 1500));
    
    // 화면이 켜지자마자 축하용으로 한 번 터뜨리려면 아래 주석을 해제하세요.
    // _confettiController.play(); 
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final days = appState.last7Days;
    final taskCounts = appState.last7DaysCompletedTasks;
    final morningMinutes = appState.last7DaysMorningMinutes;
    final totalMorningMin = (appState.totalMorningSeconds / 60).round();

    return Scaffold(
      appBar: AppBar(title: const Text('통계 대시보드')),
      body: SafeArea(
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ---- 성장 마스코트 카드 ----
                // 캐릭터 카드를 탭하면 폭죽이 터지도록 GestureDetector로 감쌉니다.
                GestureDetector(
                  onTap: () {
                    _confettiController.play(); // 탭할 때마다 폭죽 발사!
                  },
                  child: _growthCard(context, appState),
                ),
                const SizedBox(height: 24),

                // ---- 요약 카드 4개 ----
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.5,
                  children: [
                    _summaryCard(icon: Icons.check_circle_outline, color: Colors.teal, label: '완료한 할 일', value: '${appState.totalCompletedTasks}개'),
                    _summaryCard(icon: Icons.local_fire_department_outlined, color: Colors.deepOrange, label: '습관 최고 연속', value: '${appState.bestHabitStreak}일'),
                    _summaryCard(icon: Icons.wb_twilight, color: Colors.indigo, label: '아침 총 시간', value: '$totalMorningMin분'),
                    _summaryCard(icon: Icons.event_repeat, color: Colors.purple, label: '아침 연속', value: '${appState.morningStreak}일'),
                  ],
                ),
                const SizedBox(height: 24),

                // ---- 최근 7일 그래프 및 카테고리 (기존 로직 동일) ----
                _sectionTitle('최근 7일 · 완료한 할 일'),
                const SizedBox(height: 12),
                _barChart(context: context, days: days, values: taskCounts, barColor: Colors.teal, unit: '개'),
                const SizedBox(height: 24),
                _sectionTitle('최근 7일 · 아침 집중 시간(분)'),
                const SizedBox(height: 12),
                _barChart(context: context, days: days, values: morningMinutes, barColor: Colors.indigo, unit: '분'),
                const SizedBox(height: 24),
                _sectionTitle('이번 주 · 카테고리별 완료'),
                const SizedBox(height: 12),
                _categoryCard(context, appState),
                const SizedBox(height: 16),

                // ---- 데이터 내보내기 버튼 ----
                const Divider(height: 48, thickness: 1),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.file_download_outlined),
                    label: const Text('모든 데이터 백업 (CSV 내보내기)'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.primary,
                      side: BorderSide(color: Theme.of(context).colorScheme.primary),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('데이터를 추출하는 중입니다...'), duration: Duration(seconds: 1)));
                      try {
                        final exportService = ExportService(appState.storage);
                        await exportService.exportAllDataToCsv();
                      } catch (e) {
                        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('내보내기 실패: $e')));
                      }
                    },
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
            
            // [추가된 부분] 화면 맨 위에 폭죽 발사기 배치
            ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: 3.14 / 2, // 아래로 발사 (Pi / 2)
              maxBlastForce: 5,  // 발사 세기
              minBlastForce: 2,
              emissionFrequency: 0.05, // 뿜어내는 빈도
              numberOfParticles: 50, // 파티클 개수
              gravity: 0.1, // 떨어지는 속도
            ),
          ],
        ),
      ),
    );
  }

  // --- 기존의 하단 헬퍼 메서드들은 그대로 유지합니다 ---
  // (_growthCard, _summaryCard, _sectionTitle, _barChart, _categoryCard)
  // (참고: 너무 길어서 생략했습니다. 기존 파일에 있던 헬퍼 위젯 코드를 이 아래에 그대로 두시면 됩니다!)


  // 성장 마스코트 카드 (예스코 이미지 + 레벨 + 진행바)
  Widget _growthCard(BuildContext context, AppState appState) {
    final imagePath = appState.growthImagePath;
    final level = appState.growthLevel;
    final stageName = appState.growthStageName;
    final progress = appState.growthProgress;
    final pointsToNext = appState.pointsToNextLevel;

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
          // 왼쪽: 마스코트 이미지
          Image.asset(
            imagePath,
            width: 72,
            height: 72,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 18),
          // 오른쪽: 레벨/단계/진행바
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '예스코 · $stageName',
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
    // 이번 주 카테고리별 완료 개수 (가로 막대)
  Widget _categoryCard(BuildContext context, AppState appState) {
    final counts = appState.weeklyCategoryCounts;
    final total = appState.weeklyCategoryTotal;

    // 표시 순서 + 라벨 + 색상 정의
    const order = ['work', 'side', 'private', 'invest'];
    const labels = {
      'work': '💼 업무',
      'side': '🚀 부업',
      'private': '🏡 개인',
      'invest': '📈 투자',
    };
    const colors = {
      'work': Color(0xFF3B82F6),
      'side': Color(0xFF8B5CF6),
      'private': Color(0xFF10B981),
      'invest': Color(0xFFF59E0B),
    };

    // 막대 비율 계산용 최대값 (0이면 1로)
    final maxCount = counts.values.fold<int>(0, (m, v) => v > m ? v : m);
    final safeMax = maxCount == 0 ? 1 : maxCount;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: total == 0
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                '이번 주에 완료한 할 일이 아직 없어요.\n할 일에 카테고리를 지정하면 여기 통계가 쌓여요.',
                style: TextStyle(fontSize: 13, color: Colors.black54),
                textAlign: TextAlign.center,
              ),
            )
          : Column(
              children: order.map((key) {
                final count = counts[key] ?? 0;
                final ratio = count / safeMax;
                final color = colors[key]!;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      // 라벨
                      SizedBox(
                        width: 68,
                        child: Text(
                          labels[key]!,
                          style: const TextStyle(fontSize: 12.5),
                        ),
                      ),
                      // 가로 막대
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: ratio,
                            minHeight: 14,
                            backgroundColor:
                                Colors.grey.withValues(alpha: 0.15),
                            valueColor:
                                AlwaysStoppedAnimation<Color>(color),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // 개수
                      SizedBox(
                        width: 32,
                        child: Text(
                          '$count',
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }
}
