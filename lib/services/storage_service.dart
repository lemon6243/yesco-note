// ============================================================
// StorageService (로컬 저장소 서비스)
// ------------------------------------------------------------
// Hive 데이터베이스를 초기화하고, Task/Note/Reflection 데이터를
// 저장·조회·수정·삭제하는 역할을 모아둔 클래스입니다.
// 앱의 다른 부분(화면들)은 이 클래스를 통해서만 데이터에 접근합니다.
// ============================================================

import 'package:hive_flutter/hive_flutter.dart';
import '../models/task.dart';
import '../models/note.dart';
import '../models/reflection.dart';
import '../models/habit.dart';
import '../models/morning_session.dart';

class StorageService {
  // Hive의 "박스(Box)"는 하나의 테이블(엑셀 시트)이라고 생각하면 됩니다.
  static const String taskBoxName = 'tasks';
  static const String noteBoxName = 'notes';
  static const String reflectionBoxName = 'reflections';
  static const String habitBoxName = 'habits';
  static const String morningSessionBoxName = 'morning_sessions';

  late Box<Task> taskBox;
  late Box<Note> noteBox;
  late Box<Reflection> reflectionBox;
  late Box<Habit> habitBox;
  late Box<MorningSession> morningSessionBox;

  // 앱이 시작될 때 한 번 호출해서 Hive를 준비시킵니다.
  Future<void> init() async {
    await Hive.initFlutter();

    // 모델별 어댑터 등록 (이미 등록된 경우 중복 등록하지 않도록 체크)
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(TaskAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(NoteAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(NoteStatusAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(ReflectionAdapter());
    }
    if (!Hive.isAdapterRegistered(4)) {
      Hive.registerAdapter(HabitAdapter());
    }
    if (!Hive.isAdapterRegistered(5)) {
      Hive.registerAdapter(MorningSessionAdapter());
    }

    taskBox = await Hive.openBox<Task>(taskBoxName);
    noteBox = await Hive.openBox<Note>(noteBoxName);
    reflectionBox = await Hive.openBox<Reflection>(reflectionBoxName);
    habitBox = await Hive.openBox<Habit>(habitBoxName);
    morningSessionBox = await Hive.openBox<MorningSession>(
      morningSessionBoxName,
    );
  }

  // ---------------- Task 관련 함수들 ----------------

  // 모든 할 일 목록을 가져옵니다.
  List<Task> getAllTasks() => taskBox.values.toList();

  // 특정 날짜(연/월/일이 같은)의 할 일만 가져옵니다.
  List<Task> getTasksByDate(DateTime date) {
    return taskBox.values.where((task) {
      return task.date.year == date.year &&
          task.date.month == date.month &&
          task.date.day == date.day;
    }).toList();
  }

  // 할 일 저장 (새로 추가하거나 기존 것을 수정할 때 모두 사용)
  Future<void> saveTask(Task task) async {
    await taskBox.put(task.id, task);
  }

  // 할 일 삭제
  Future<void> deleteTask(String id) async {
    await taskBox.delete(id);
  }

  // ---------------- Note 관련 함수들 ----------------

  // 모든 노트를 최신순으로 가져옵니다.
  List<Note> getAllNotes() {
    final list = noteBox.values.toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  Future<void> saveNote(Note note) async {
    await noteBox.put(note.id, note);
  }

  Future<void> deleteNote(String id) async {
    await noteBox.delete(id);
  }

  // ---------------- Reflection 관련 함수들 ----------------

  // 특정 날짜의 회고를 가져옵니다. 없으면 null.
  Reflection? getReflectionByDate(DateTime date) {
    try {
      return reflectionBox.values.firstWhere(
        (r) =>
            r.date.year == date.year &&
            r.date.month == date.month &&
            r.date.day == date.day,
      );
    } catch (e) {
      return null;
    }
  }

  Future<void> saveReflection(Reflection reflection) async {
    await reflectionBox.put(reflection.id, reflection);
  }
  // ---------------- Habit(습관) 관련 함수들 ----------------

  // 모든 습관을 가져옵니다. (보관된 것 포함)
  List<Habit> getAllHabits() => habitBox.values.toList();

  // 습관 저장 (새로 추가하거나 기존 것을 수정할 때 모두 사용)
  Future<void> saveHabit(Habit habit) async {
    await habitBox.put(habit.id, habit);
  }

  // 습관 삭제
  Future<void> deleteHabit(String id) async {
    await habitBox.delete(id);
  }

  // ---------------- MorningSession(아침 1시간) 관련 함수들 ----------------

  // 모든 기록을 최신순(완료 시각 내림차순)으로 가져옵니다.
  List<MorningSession> getAllMorningSessions() {
    final list = morningSessionBox.values.toList();
    list.sort((a, b) => b.completedAt.compareTo(a.completedAt));
    return list;
  }

  // 특정 날짜(연/월/일이 같은)의 기록만 가져옵니다.
  List<MorningSession> getMorningSessionsByDate(DateTime date) {
    return morningSessionBox.values.where((s) {
      return s.date.year == date.year &&
          s.date.month == date.month &&
          s.date.day == date.day;
    }).toList();
  }

  Future<void> saveMorningSession(MorningSession session) async {
    await morningSessionBox.put(session.id, session);
  }

  Future<void> deleteMorningSession(String id) async {
    await morningSessionBox.delete(id);
  }
}
