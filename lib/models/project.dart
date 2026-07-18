// ============================================================
// Project 모델 (프로젝트 = 여러 할 일을 묶는 상위 그릇)
// ------------------------------------------------------------
// 회사 프로젝트 업무를 관리하기 위한 모델입니다.
// 예: "봄 신제품 출시" 프로젝트 아래에 "기획서 작성", "샘플 검토",
//     "패키지 디자인" 같은 여러 할 일(Task)을 묶을 수 있습니다.
//
// Task 쪽에 projectId 필드를 두어, 각 할 일이 어느 프로젝트에
// 속하는지 연결합니다. (projectId가 null이면 어디에도 안 묶인 일반 할 일)
// ============================================================

import 'package:hive/hive.dart';

part 'project.g.dart';

// typeId: 6번
// (Task=0, Note=1, NoteStatus=2, Reflection=3, Habit=4, MorningSession=5 를
//  이미 쓰고 있으므로 6번을 사용. 절대 겹치면 안 됨)
@HiveType(typeId: 6)
class Project extends HiveObject {
  // 고유 ID (Task의 projectId가 이 값을 가리킴)
  @HiveField(0)
  String id;

  // 프로젝트 이름 (필수). 예: "봄 신제품 출시"
  @HiveField(1)
  String name;

  // 프로젝트 설명·메모 (선택)
  @HiveField(2)
  String? description;

  // 색상값 (프로젝트를 시각적으로 구분). ARGB 정수로 저장. 예: 0xFF3B82F6
  @HiveField(3)
  int colorValue;

  // 시작일 (선택). 타임라인/간트 뷰에서 막대 시작점으로 사용
  @HiveField(4)
  DateTime? startDate;

  // 마감일 (선택). 타임라인/간트 뷰에서 막대 끝점으로 사용
  @HiveField(5)
  DateTime? dueDate;

  // 완료 여부 (진행 중 / 완료 구분)
  @HiveField(6)
  bool isDone;

  // 생성 날짜 (자동 기록. 목록 정렬 기준)
  @HiveField(7)
  DateTime createdAt;

  Project({
    required this.id,
    required this.name,
    this.description,
    this.colorValue = 0xFF3B82F6, // 기본 파랑
    this.startDate,
    this.dueDate,
    this.isDone = false,
    required this.createdAt,
  });
}
