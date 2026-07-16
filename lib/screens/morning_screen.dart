// ============================================================
// MorningScreen (아침 1시간 타이머 화면)
// ------------------------------------------------------------
// 이케다 지에의 "매일 아침 1시간이 나를 바꾼다" 방법론에 따라
// 아침에 집중해서 계획을 세우거나 자기투자를 할 시간을
// 원형 타이머로 재는 화면입니다.
//
// - 목표 시간(15/30/45/60/90분) 선택
// - 시작 / 일시정지 / 리셋
// - 멈추면 "무엇을 했는지" 메모를 남기고 기록으로 저장
// - 오늘 누적 시간, 연속일수, 총 실천 시간/횟수 요약
// - 최근 기록 리스트
// ============================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../models/morning_session.dart';
import '../theme/app_theme.dart';

class MorningScreen extends StatefulWidget {
  const MorningScreen({super.key});

  @override
  State<MorningScreen> createState() => _MorningScreenState();
}

class _MorningScreenState extends State<MorningScreen> {
  // 선택 가능한 목표 시간(분)
  static const List<int> _targetOptions = [15, 30, 45, 60, 90];

    int _targetMinutes = 60; // 기본 목표: 60분 ("아침 1시간")

  // 타이머가 "돌기 시작한 시각". 이 값과 현재 시각의 차이로 흐른 시간을 계산합니다.
  // 이렇게 하면 앱이 백그라운드로 가거나 화면이 꺼져도 실제 시간이 정확히 반영됩니다.
  DateTime? _startTime;

  // 일시정지하기 전까지 이미 쌓아둔 시간(초). 시작~일시정지를 반복해도 누적됩니다.
  int _accumulatedSeconds = 0;

  bool _isRunning = false;
  Timer? _timer; // 화면의 숫자를 1초마다 새로 그리기 위한 용도(시간 계산과 무관)

  // 지금까지 흐른 총 시간(초)을 계산합니다.
  // = 이전에 쌓아둔 시간 + (돌고 있는 중이면 시작 시각부터 지금까지의 시간)
  int get _elapsedSeconds {
    int extra = 0;
    if (_isRunning && _startTime != null) {
      extra = DateTime.now().difference(_startTime!).inSeconds;
    }
    return _accumulatedSeconds + extra;
  }


  int get _targetSeconds => _targetMinutes * 60;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

    void _startPause() {
    if (_isRunning) {
      // 일시정지: 지금까지 흐른 시간을 누적값에 더해 저장하고 멈춤
      _accumulatedSeconds = _elapsedSeconds;
      _startTime = null;
      _timer?.cancel();
      setState(() => _isRunning = false);
    } else {
      // 시작(또는 이어서 시작): 시작 시각을 기록하고, 화면 갱신용 타이머를 돌림
      _startTime = DateTime.now();
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        // 시간 자체는 _startTime 기준으로 계산되므로, 여기선 화면만 다시 그림
        setState(() {});
      });
      setState(() => _isRunning = true);
    }
  }


    void _reset() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _accumulatedSeconds = 0;
      _startTime = null;
    });
  }


  // 타이머를 멈추고 기록을 저장합니다. (0초면 저장하지 않음)
    Future<void> _finishAndSave(AppState appState) async {
    // 저장할 시간을 먼저 확정해 둡니다. (이후 계산값이 흔들리지 않도록)
    final savedSeconds = _elapsedSeconds;
    if (savedSeconds < 1) return;

    // 타이머를 멈춤
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _accumulatedSeconds = savedSeconds;
      _startTime = null;
    });

    final memo = await _showMemoDialog(context);
    // 다이얼로그에서 뒤로가기(취소)해도 기록 자체는 저장합니다.
    // (메모는 선택사항일 뿐, 실천한 시간은 그대로 남겨야 하니까요.)
    await appState.addMorningSession(
      durationSeconds: savedSeconds,
      targetSeconds: _targetSeconds,
      memo: memo,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('🌅 ${_formatDuration(savedSeconds)} 기록 완료!')),
      );
      // 저장 후 타이머 초기화
      setState(() {
        _accumulatedSeconds = 0;
        _startTime = null;
      });
    }
  }


  // "무엇을 했는지" 메모 입력 다이얼로그
    Future<String?> _showMemoDialog(BuildContext context) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('오늘 아침, 무엇을 하셨나요?'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: '예: 하루 계획 정리, 독서, 자기계발 (선택)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('건너뛰기'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('저장'),
          ),
        ],
      ),
    );
    controller.dispose(); // 다이얼로그가 닫힌 뒤 컨트롤러 정리 (메모리 누수 방지)
    return result;
  }

  String _formatDuration(int totalSeconds) {
    final m = totalSeconds ~/ 60;
    final s = totalSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(title: const Text('아침 1시간'), centerTitle: true),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
          children: [
            _buildStatsCard(context, appState),
            const SizedBox(height: 24),
            _buildTargetPicker(context),
            const SizedBox(height: 24),
            _buildTimerCircle(context),
            const SizedBox(height: 24),
            _buildControlButtons(context, appState),
            const SizedBox(height: 28),
            _buildHistorySection(context, appState),
          ],
        ),
      ),
    );
  }

  // 오늘 누적 / 연속일수 / 총 실천 요약 카드
  Widget _buildStatsCard(BuildContext context, AppState appState) {
    final todaySeconds = appState.todayMorningSeconds;
    final streak = appState.morningStreak;
    final totalCount = appState.totalMorningSessionCount;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _statItem(
              context,
              '오늘',
              '${todaySeconds ~/ 60}분',
              Icons.wb_twilight_outlined,
            ),
            Container(
              width: 1,
              height: 40,
              color: Theme.of(context).dividerColor,
            ),
            _statItem(
              context,
              '연속',
              streak > 0 ? '🔥 $streak일' : '-',
              Icons.local_fire_department_outlined,
            ),
            Container(
              width: 1,
              height: 40,
              color: Theme.of(context).dividerColor,
            ),
            _statItem(
              context,
              '총 실천',
              '$totalCount회',
              Icons.military_tech_outlined,
            ),
          ],
        ),
      ),
    );
  }

  Widget _statItem(
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
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  // 목표 시간 선택 칩 (타이머가 돌고 있으면 변경 불가)
  Widget _buildTargetPicker(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: _targetOptions.map((minutes) {
        final isSelected = _targetMinutes == minutes;
        return ChoiceChip(
          label: Text('$minutes분'),
          selected: isSelected,
          onSelected: (_isRunning || _elapsedSeconds > 0)
              ? null // 타이머가 진행 중이면 목표 변경 방지 (혼란 방지)
              : (_) => setState(() => _targetMinutes = minutes),
          selectedColor: AppColors.coral.withValues(alpha: 0.2),
          labelStyle: TextStyle(
            color: isSelected ? AppColors.coral : null,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        );
      }).toList(),
    );
  }

  // 원형 타이머 (진행률 링 + 남은/흐른 시간 텍스트)
  Widget _buildTimerCircle(BuildContext context) {
    final progress = (_elapsedSeconds / _targetSeconds).clamp(0.0, 1.0);
    final achieved = _elapsedSeconds >= _targetSeconds;

    return Center(
      child: SizedBox(
        width: 240,
        height: 240,
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 240,
              height: 240,
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 10,
                backgroundColor: Colors.grey.withValues(alpha: 0.15),
                valueColor: AlwaysStoppedAnimation(
                  achieved ? AppColors.teal : AppColors.coral,
                ),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatDuration(_elapsedSeconds),
                  style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  achieved ? '🎉 목표 달성!' : '목표 $_targetMinutes분',
                  style: TextStyle(
                    fontSize: 13,
                    color: achieved
                        ? AppColors.teal
                        : Theme.of(context).disabledColor,
                    fontWeight: achieved ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 시작/일시정지 + 완료(저장) + 리셋 버튼들
  Widget _buildControlButtons(BuildContext context, AppState appState) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 리셋 (진행 중인 게 있을 때만 표시)
        if (_elapsedSeconds > 0)
          IconButton(
            iconSize: 28,
            onPressed: _reset,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: '리셋',
          ),
        const SizedBox(width: 8),
        // 시작 / 일시정지 (큰 원형 버튼)
        GestureDetector(
          onTap: _startPause,
          child: Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.coral,
            ),
            child: Icon(
              _isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
              color: Colors.white,
              size: 36,
            ),
          ),
        ),
        const SizedBox(width: 8),
        // 완료(저장) - 기록이 조금이라도 있을 때만 표시
        if (_elapsedSeconds > 0)
          IconButton(
            iconSize: 28,
            onPressed: () => _finishAndSave(appState),
            icon: const Icon(
              Icons.check_circle_rounded,
              color: AppColors.teal,
            ),
            tooltip: '완료하고 저장',
          ),
      ],
    );
  }

  // 최근 기록 히스토리
  Widget _buildHistorySection(BuildContext context, AppState appState) {
    final sessions = appState.allMorningSessions.take(10).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '최근 기록',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).disabledColor,
          ),
        ),
        const SizedBox(height: 10),
        if (sessions.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: Text(
                '아직 기록이 없어요.\n오늘 아침, 첫 1시간을 시작해 보세요.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).disabledColor),
              ),
            ),
          )
        else
          ...sessions.map((s) => _historyTile(context, appState, s)),
      ],
    );
  }

  Widget _historyTile(
    BuildContext context,
    AppState appState,
    MorningSession session,
  ) {
    final dateFormat = DateFormat('M월 d일 (E) HH:mm', 'ko_KR');
    final achieved = session.durationSeconds >= session.targetSeconds;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: (achieved ? AppColors.teal : AppColors.gold)
              .withValues(alpha: 0.15),
          child: Icon(
            Icons.wb_twilight_outlined,
            color: achieved ? AppColors.teal : AppColors.gold,
          ),
        ),
        title: Text(
          '${session.durationSeconds ~/ 60}분 ${session.durationSeconds % 60}초',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          session.memo?.isNotEmpty == true
              ? '${dateFormat.format(session.completedAt)}\n${session.memo}'
              : dateFormat.format(session.completedAt),
        ),
        isThreeLine: session.memo?.isNotEmpty == true,
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
          onPressed: () => appState.deleteMorningSession(session.id),
        ),
      ),
    );
  }
}
