// ============================================================
// Reflection 모델 (저녁 회고)
// ------------------------------------------------------------
// 하루가 끝날 때 "오늘 집중할 3가지"를 잘 해냈는지, 그리고
// 오늘 하루에 대한 짧은 소감을 적어두는 모델입니다.
// 날짜(date) 하나당 회고는 1개만 존재합니다.
// ============================================================

import 'package:hive/hive.dart';

part 'reflection.g.dart';

// typeId: 3번 (Task=0, Note=1, NoteStatus=2 다음이라 3번 사용)
@HiveType(typeId: 3)
class Reflection extends HiveObject {
  // 고유 ID
  @HiveField(0)
  String id;

  // 이 회고가 어느 날짜에 대한 것인지 (하루에 1개)
  @HiveField(1)
  DateTime date;

  // 오늘 하루를 돌아보며 적는 한 줄 소감 (선택)
  @HiveField(2)
  String? memo;

  // 이 회고를 작성한(마지막으로 수정한) 시각
  @HiveField(3)
  DateTime updatedAt;

  Reflection({
    required this.id,
    required this.date,
    this.memo,
    required this.updatedAt,
  });
}
