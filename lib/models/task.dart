// ============================================================
// Task 모델 (할 일 / 일정)
// ------------------------------------------------------------
// 이 파일은 앱에서 다루는 "할 일 하나"를 표현하는 데이터 모델입니다.
// Hive라는 로컬 데이터베이스에 저장하기 위해 @HiveType, @HiveField
// 어노테이션을 붙여줍니다. (build_runner가 이 파일을 읽고
// task.g.dart 라는 자동 코드를 만들어 줍니다)
// ============================================================

import 'package:hive/hive.dart';

part 'task.g.dart';

// typeId: 0번 → Hive가 여러 종류의 모델을 구분하기 위한 고유 번호.
// Note 모델은 1번을 사용합니다. (절대 겹치면 안 됨)
@HiveType(typeId: 0)
class Task extends HiveObject {
  // 할 일의 고유 ID (다른 할 일과 절대 겹치지 않는 문자열)
  @HiveField(0)
  String id;

  // 할 일 제목 (필수 입력)
  @HiveField(1)
  String title;

  // 상세 메모 (선택 입력, 없으면 null)
  @HiveField(2)
  String? memo;

  // 시작 시간 (선택). 값이 있으면 "몇 시 몇 분에 할 일"이 되고,
  // 없으면 오늘 화면에서 "시간 미정" 묶음에 표시됩니다.
  // 날짜 정보도 포함되어 있지만 실제로 화면에 쓸 때는 시:분만 사용합니다.
  @HiveField(3)
  DateTime? startTime;

  // 이 할 일이 속한 날짜 (예: 오늘 할 일이면 오늘 날짜).
  // 날짜를 앞뒤로 넘기면서 볼 수 있도록 하기 위한 핵심 필드입니다.
  @HiveField(4)
  DateTime date;

  // 중요도: true = 높음, false = 낮음
  @HiveField(5)
  bool isImportant;

  // 긴급도: true = 높음, false = 낮음
  @HiveField(6)
  bool isUrgent;

  // "오늘 집중할 3가지"에 포함된 할 일인지 여부
  @HiveField(7)
  bool isTop3;

  // 완료 여부
  @HiveField(8)
  bool isDone;

  // 이 할 일이 처음 만들어진 시각 (자동 기록, 수정 불가)
  @HiveField(9)
  DateTime createdAt;

  // 이 할 일이 예전 어떤 할 일에서 "미완료 이월"되어 온 것인지
  // 표시하기 위한 필드 (원본 할 일의 id를 저장). 이월이 아니면 null.
  @HiveField(10)
  String? carriedOverFromId;

  // 이 할 일을 하는 장소(맥락). 'home' = 집, 'outside' = 외부,
  // null 이면 아직 지정 안 함. 집/밖에서 할 일을 구분해서 보기 위한 필드입니다.
  @HiveField(11)
  String? location;
  // ---------------- 5W2H 구체화 (선택 입력) ----------------
  // 막연한 할 일을 구체적인 예정으로 바꾸기 위한 항목들.
  // 모두 선택 입력이며, 안 쓰면 null 입니다.

  // 왜 하는가 (목적·동기)
  @HiveField(12)
  String? why;

  // 어떻게 할 것인가 (방법·수단)
  @HiveField(13)
  String? how;

  // 얼마나 (분량·횟수·기준. 예: 30분, 10페이지, 3세트)
  @HiveField(14)
  String? howMuch;

    // ---------------- 반복 설정 (선택) ----------------
  // 반복 종류. null = 반복 안 함, 'daily' = 매일, 'weekly' = 매주 특정 요일
  @HiveField(15)
  String? repeatRule;

  // 매주 반복일 때 어떤 요일에 반복할지. (월=1 ~ 일=7, Dart weekday 기준)
  // 예: [1, 3, 5] = 월·수·금. 매일('daily')이거나 반복 없음이면 비어 있음.
  @HiveField(16)
  List<int> repeatWeekdays;

  // 이 할 일이 어떤 '반복 원본'에서 자동 생성된 것인지 추적하는 id.
  // 반복 원본(사용자가 직접 만든 규칙 있는 할 일)이면 null,
  // 자동 생성된 하루짜리 인스턴스면 원본의 id가 들어감.
  @HiveField(17)
  String? repeatSourceId;

  
  // ---------------- 카테고리 분류 (선택) ----------------
  // 이 할 일이 어떤 영역인지. 'work' = 업무, 'side' = 부업,
  // 'private' = 개인, 'invest' = 투자. null 이면 미지정.
  @HiveField(18)
  String? category;

  // ---------------- 프로젝트 연결 (선택) ----------------
  // 이 할 일이 어느 프로젝트에 속하는지 가리키는 id.
  // Project.id 값을 저장하며, null 이면 어떤 프로젝트에도
  // 묶이지 않은 일반 할 일입니다.
  @HiveField(19)
  String? projectId;


  Task({
    required this.id,
    required this.title,
    this.memo,
    this.startTime,
    required this.date,
    this.isImportant = false,
    this.isUrgent = false,
    this.isTop3 = false,
    this.isDone = false,
    required this.createdAt,
    this.carriedOverFromId,
    this.location,
    this.why,
    this.how,
    this.howMuch,
    this.repeatRule,
    this.category,
    this.projectId,
    List<int>? repeatWeekdays,
    this.repeatSourceId,
  }) : repeatWeekdays = repeatWeekdays ?? [];


  // 중요도+긴급도 조합으로 어떤 사분면(매트릭스 칸)에 속하는지 계산합니다.
  // 0: 긴급&중요 / 1: 중요만 / 2: 긴급만 / 3: 둘 다 낮음
  int get quadrant {
    if (isImportant && isUrgent) return 0;
    if (isImportant && !isUrgent) return 1;
    if (!isImportant && isUrgent) return 2;
    return 3;
  }
}
