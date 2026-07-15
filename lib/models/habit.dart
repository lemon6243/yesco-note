// ============================================================
// Habit 모델 (습관 / 챌린지)
// ------------------------------------------------------------
// "매일 반복하며 꾸준함을 쌓는 활동"을 표현하는 모델입니다.
// 예: 독서, 운동, 자기계발 등.
//
// Task(할 일)와 다른 점:
//   - Task는 특정 날짜의 일회성 일 (완료하면 끝)
//   - Habit은 매일 체크하며 "며칠 연속했는지"가 쌓이는 것
//
// 체크 기록은 '날짜 문자열 목록'으로 저장합니다.
// 예: ["2026-07-13", "2026-07-14", "2026-07-15"]
// (시:분:초 없이 날짜만 저장해서 "같은 날인지" 비교를 쉽게 하기 위함)
// ============================================================

import 'package:hive/hive.dart';

part 'habit.g.dart';

// typeId: 4번
// (Task=0, Note=1, NoteStatus=2, Reflection=3 을 이미 쓰고 있으므로 4번을 사용. 절대 겹치면 안 됨)
@HiveType(typeId: 4)
class Habit extends HiveObject {
  // 습관의 고유 ID (다른 습관과 절대 겹치지 않는 문자열)
  @HiveField(0)
  String id;

  // 습관 이름 (예: "독서", "운동")
  @HiveField(1)
  String name;

  // 습관을 나타내는 이모지 아이콘 (예: "📚", "🏃"). 시각적 구분용.
  @HiveField(2)
  String emoji;

  // 색상 값 (선택). 지금은 자리만 마련해 둡니다. (나중에 카드 색 등에 활용)
  @HiveField(3)
  int? colorValue;

  // 체크한 날짜들의 목록. "yyyy-MM-dd" 형식 문자열로 저장.
  // 예: ["2026-07-14", "2026-07-15"]
  @HiveField(4)
  List<String> checkedDates;

  // 이 습관이 처음 만들어진 시각 (자동 기록)
  @HiveField(5)
  DateTime createdAt;

  // 보관 여부. true면 목록에서 숨김(삭제 대신 보관). 기본은 false(활성).
  @HiveField(6)
  bool isArchived;

  // 주간 목표 횟수 (선택). 예: 3이면 "주 3회"가 목표.
  // null이면 목표를 설정하지 않은 습관 (통계 표시만, 진행률 바는 안 보임).
  @HiveField(7)
  int? weeklyGoal;

  Habit({
    required this.id,
    required this.name,
    this.emoji = '⭐',
    this.colorValue,
    List<String>? checkedDates,
    required this.createdAt,
    this.isArchived = false,
    this.weeklyGoal,
  }) : checkedDates = checkedDates ?? [];

  // ----------------------------------------------------------
  // 아래는 저장되는 데이터가 아니라, 데이터를 가지고 계산해 주는 도우미들입니다.
  // ----------------------------------------------------------

  // 날짜 하나를 "yyyy-MM-dd" 문자열로 바꿔줍니다. (내부용)
  static String dateKey(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  // 특정 날짜에 이 습관을 체크했는지 여부
  bool isCheckedOn(DateTime date) {
    return checkedDates.contains(dateKey(date));
  }

  // 오늘 체크했는지 여부
  bool get isCheckedToday => isCheckedOn(DateTime.now());

  // 현재 연속일수(streak)를 계산합니다.
  // 규칙: 오늘부터 거꾸로 하루씩 내려가며 연속으로 체크된 날을 셉니다.
  //   - 오늘 체크했으면 오늘부터 셈
  //   - 오늘 아직 안 했으면, 어제부터 이어진 기록을 보여줌
  //     (오늘 체크하면 그만큼 하루 늘어나는 자연스러운 방식)
  int get currentStreak {
    // 오늘을 체크했는지에 따라 세기 시작하는 날을 정합니다.
    DateTime cursor = DateTime.now();
    if (!isCheckedOn(cursor)) {
      // 오늘 안 했으면 어제부터 확인 시작
      cursor = cursor.subtract(const Duration(days: 1));
    }

    int streak = 0;
    // 체크된 날이 계속 이어지는 동안 하루씩 뒤로 가며 셈
    while (isCheckedOn(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  // ----------------------------------------------------------
  // 통계용 헬퍼 (2단계: 습관 심화)
  // ----------------------------------------------------------

  // 지금까지 통틀어 총 몇 번 체크했는지 (전체 실천 횟수)
  int get totalCheckCount => checkedDates.length;

  // 지금까지 가장 길었던 연속일수(최장 기록).
  // checkedDates 문자열들을 날짜로 바꿔 정렬한 뒤, 하루씩 이어지는 구간을 찾습니다.
  int get longestStreak {
    if (checkedDates.isEmpty) return 0;

    // "yyyy-MM-dd" 문자열들을 DateTime으로 변환하고 오름차순 정렬
    final dates =
        checkedDates
            .map((s) {
              final parts = s.split('-');
              if (parts.length != 3) return null;
              final y = int.tryParse(parts[0]);
              final m = int.tryParse(parts[1]);
              final d = int.tryParse(parts[2]);
              if (y == null || m == null || d == null) return null;
              return DateTime(y, m, d);
            })
            .whereType<DateTime>()
            .toList()
          ..sort();

    int longest = 1;
    int current = 1;
    for (int i = 1; i < dates.length; i++) {
      final diff = dates[i].difference(dates[i - 1]).inDays;
      if (diff == 1) {
        // 바로 다음 날이면 연속 구간이 이어짐
        current++;
        if (current > longest) longest = current;
      } else if (diff > 1) {
        // 하루 이상 비었으면 연속 구간이 끊김 → 다시 1부터 셈
        current = 1;
      }
      // diff == 0 (중복 날짜)인 경우는 그냥 무시
    }
    return longest;
  }

  // "이번 주(월요일~일요일)" 동안 체크한 횟수.
  // 주간 목표(weeklyGoal) 달성률을 계산할 때 사용합니다.
  int checksInWeekOf(DateTime anyDayInWeek) {
    // 그 주의 월요일 날짜를 구합니다. (Dart weekday: 월=1 ~ 일=7)
    final weekday = anyDayInWeek.weekday;
    final monday = anyDayInWeek.subtract(Duration(days: weekday - 1));
    final mondayOnly = DateTime(monday.year, monday.month, monday.day);

    int count = 0;
    for (int i = 0; i < 7; i++) {
      final day = mondayOnly.add(Duration(days: i));
      if (isCheckedOn(day)) count++;
    }
    return count;
  }

  // 이번 주 체크 횟수 (오늘 기준)
  int get checksThisWeek => checksInWeekOf(DateTime.now());
}
