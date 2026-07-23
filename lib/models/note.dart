// ============================================================
// Note 모델 (생각 노트 / 브레인덤프)
// ------------------------------------------------------------
// "빈 종이 방식"으로 자유롭게 적는 생각/아이디어를 표현하는 모델입니다.
// 나중에 이 노트를 눌러서 실제 할 일(Task)로 전환할 수 있습니다.
//
// ※ 펜 그림, 손글씨 인식 텍스트 필드는 3단계(뒤 단계) 기능이지만,
//   지금 데이터 구조에 미리 자리를 마련해 둡니다. (설계도 원칙 준수)
// ============================================================

import 'package:hive/hive.dart';

part 'note.g.dart';

// 노트의 상태를 나타내는 열거형(enum)
// - unclassified : 아직 분류하지 않은 상태 (기본값)
// - archived     : 아이디어로만 보관 (할 일로 만들지 않음)
// - converted    : 할 일로 전환 완료됨
@HiveType(typeId: 2)
enum NoteStatus {
  @HiveField(0)
  unclassified,
  @HiveField(1)
  archived,
  @HiveField(2)
  converted,
}

// typeId: 1번 (Task는 0번을 사용하므로 겹치지 않게 1번 지정)
@HiveType(typeId: 1)
class Note extends HiveObject {
  // 노트의 고유 ID
  @HiveField(0)
  String id;

  // 노트 내용 (키보드로 입력한 텍스트)
  @HiveField(1)
  String content;

  // 노트 상태 (미분류 / 아이디어 보관 / 할 일로 전환됨)
  @HiveField(2)
  NoteStatus status;

  // 노트가 처음 만들어진 시각 (자동 기록)
  @HiveField(3)
  DateTime createdAt;

  // ---- 아래 두 필드는 "3단계(펜 캔버스) 기능"을 위해 미리 열어둔 자리입니다 ----
  // 손으로 그린 펜 그림 파일의 경로 또는 URL (지금은 항상 null)
  @HiveField(4)
  String? penImagePath;

  // 손글씨를 텍스트로 변환한 결과 (지금은 항상 null)
  @HiveField(5)
  String? convertedText;

  // 이 노트가 전환되어 만들어진 할 일(Task)의 id.
  // "할 일로 전환" 되었을 때만 값이 채워집니다.
  @HiveField(6)
  String? convertedTaskId;

  // ---- 펜 그림(획 좌표) 저장 ----
  // 손으로 그린 획들을 JSON 문자열로 직렬화해서 저장합니다.
  // (drawn_stroke.dart의 encodeStrokes/decodeStrokes로 변환)
  // null이면 그림 없는 순수 텍스트 노트입니다.
  @HiveField(7)
  String? penStrokes;

  // 이 노트가 회의록인지 여부 (기본값 false = 일반 생각 노트)
  @HiveField(8)
  bool isMeeting;

  // 회의가 열린 날짜 (회의록일 때만 사용, 일반 노트는 null)
  @HiveField(9)
  DateTime? meetingDate;



  Note({
    required this.id,
    required this.content,
    this.status = NoteStatus.unclassified,
    required this.createdAt,
    this.penImagePath,
    this.convertedText,
    this.convertedTaskId,
    this.penStrokes,
    this.isMeeting = false,   // 추가
    this.meetingDate,          // 추가
  });
}
