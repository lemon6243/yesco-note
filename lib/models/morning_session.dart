// ============================================================
// MorningSession 모델 (아침 1시간 루틴 기록)
// ------------------------------------------------------------
// 이케다 지에의 "매일 아침 1시간" 방법론에 따라, 아침에 집중해서
// 계획을 세우거나 자기투자를 한 시간을 기록하는 모델입니다.
//
// 하루에 여러 번 기록할 수 있습니다(예: 아침에 25분 하고, 나중에
// 다시 20분 이어서 하는 경우). 화면에서는 하루 총합을 보여줍니다.
// ============================================================

import 'package:hive/hive.dart';

part 'morning_session.g.dart';

// typeId: 5번
// (Task=0, Note=1, NoteStatus=2, Reflection=3, Habit=4 를 이미 쓰고 있으므로
//  5번을 사용. 절대 겹치면 안 됨)
@HiveType(typeId: 5)
class MorningSession extends HiveObject {
  // 고유 ID
  @HiveField(0)
  String id;

  // 이 기록이 속한 날짜 (시:분:초 없이 날짜만). "그날의 아침" 기준.
  @HiveField(1)
  DateTime date;

  // 실제로 집중한 시간(초 단위)
  @HiveField(2)
  int durationSeconds;

  // 목표로 설정했던 시간(초 단위). 예: 3600 = 60분
  @HiveField(3)
  int targetSeconds;

  // 이 시간 동안 무엇을 했는지 (선택 입력)
  @HiveField(4)
  String? memo;

  // 이 기록이 저장(완료)된 시각
  @HiveField(5)
  DateTime completedAt;

  MorningSession({
    required this.id,
    required this.date,
    required this.durationSeconds,
    required this.targetSeconds,
    this.memo,
    required this.completedAt,
  });

  // 날짜 하나를 "yyyy-MM-dd" 문자열로 바꿔줍니다. (내부/비교용)
  static String dateKey(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
