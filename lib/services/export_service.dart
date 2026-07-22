// ============================================================
// ExportService (데이터 내보내기 서비스)
// ------------------------------------------------------------
// 사용자의 데이터를 CSV 형식으로 변환하여 기기에 저장하거나
// 외부 앱(카카오톡, 메일 등)으로 공유할 수 있게 도와줍니다.
// ============================================================

import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/task.dart';
import '../models/habit.dart';
import '../models/morning_session.dart';
import 'storage_service.dart';

class ExportService {
  final StorageService storage;

  ExportService(this.storage);

  // 모든 데이터를 담은 하나의 CSV 파일을 생성하고 공유 창을 띄웁니다.
  Future<void> exportAllDataToCsv() async {
    // 1. 데이터를 가져옵니다.
    final tasks = storage.getAllTasks();
    final habits = storage.getAllHabits();
    final morningSessions = storage.getAllMorningSessions();

    // 2. CSV에 들어갈 행(Row) 데이터를 만듭니다.
    List<List<dynamic>> rows = [];

    // --- 할 일(Task) 데이터 ---
    rows.add(['--- 할 일 (Tasks) ---']);
    rows.add([
      '제목',
      '날짜',
      '완료여부',
      '중요',
      '긴급',
      '카테고리',
      '메모',
      '작성일시'
    ]);
    for (var task in tasks) {
      rows.add([
        task.title,
        task.date.toIso8601String().substring(0, 10),
        task.isDone ? 'O' : 'X',
        task.isImportant ? 'O' : 'X',
        task.isUrgent ? 'O' : 'X',
        task.category ?? '없음',
        task.memo ?? '',
        task.createdAt.toIso8601String(),
      ]);
    }
    rows.add([]); // 빈 줄 추가

    // --- 습관(Habit) 데이터 ---
    rows.add(['--- 습관 (Habits) ---']);
    rows.add(['습관명', '성격', '총 완료일수', '최근 기록일']);
    for (var habit in habits) {
      final dates = habit.completedDates.toList()..sort();
      final lastDate = dates.isNotEmpty ? dates.last : '기록 없음';
      rows.add([
        habit.name,
        habit.isGood ? '좋은 습관' : '나쁜 습관',
        habit.completedDates.length,
        lastDate,
      ]);
    }
    rows.add([]);

    // --- 아침 세션(Morning Session) 데이터 ---
    rows.add(['--- 아침 집중 시간 (Morning Sessions) ---']);
    rows.add(['날짜', '목표 시간(초)', '실제 시간(초)', '메모']);
    for (var session in morningSessions) {
      rows.add([
        session.completedAt.toIso8601String().substring(0, 10),
        session.targetSeconds,
        session.durationSeconds,
        session.memo ?? '',
      ]);
    }

    // 3. 리스트 데이터를 CSV 문자열로 변환합니다.
    String csvString = const ListToCsvConverter().convert(rows);

    // 4. 기기의 임시 폴더에 파일을 저장합니다.
    final directory = await getTemporaryDirectory();
    final path = '${directory.path}/yesco_data_export.csv';
    final file = File(path);
    
    // 한글이 엑셀에서 깨지지 않도록 UTF-8 BOM을 추가하여 저장합니다.
    await file.writeAsBytes([0xEF, 0xBB, 0xBF, ...csvString.codeUnits]);

    // 5. 저장한 파일을 Share 패키지로 공유 창을 띄웁니다.
    await Share.shareXFiles(
      [XFile(path)],
      text: '예스코 노트 데이터 백업입니다.',
    );
  }
}
