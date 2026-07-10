// ============================================================
// AppState (앱 전체 상태 관리)
// ------------------------------------------------------------
// Provider 패턴을 사용해서 앱 전체에서 공유해야 하는 데이터
// (할 일 목록, 노트 목록, 현재 선택된 날짜, 다크모드 여부 등)를
// 한 곳에서 관리합니다.
//
// 화면들은 이 클래스의 함수를 호출해서 데이터를 바꾸고,
// notifyListeners()가 호출되면 화면이 자동으로 다시 그려집니다.
// ============================================================

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/task.dart';
import '../models/note.dart';
import '../models/reflection.dart';
import 'storage_service.dart';

class AppState extends ChangeNotifier {
  final StorageService storage;
  final _uuid = const Uuid();

  AppState(this.storage);

  // ---------------- 다크모드 ----------------
  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;

  static const String _darkModeKey = 'is_dark_mode';

  // 저장된 다크모드 설정을 불러옵니다. (앱 시작 시 1회 호출)
  Future<void> loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool(_darkModeKey) ?? false;
    notifyListeners();
  }

  // 다크모드를 켜고 끄고, 그 설정을 기기에 저장합니다.
  Future<void> toggleDarkMode() async {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_darkModeKey, _isDarkMode);
  }

  // ---------------- 오늘 화면에서 보고 있는 날짜 ----------------
  DateTime _selectedDate = DateTime.now();
  DateTime get selectedDate => _selectedDate;

  void goToPreviousDay() {
    _selectedDate = _selectedDate.subtract(const Duration(days: 1));
    notifyListeners();
  }

  void goToNextDay() {
    _selectedDate = _selectedDate.add(const Duration(days: 1));
    notifyListeners();
  }

  void goToToday() {
    _selectedDate = DateTime.now();
    notifyListeners();
  }

  // ---------------- 초기 데이터 로드 + 미완료 이월 ----------------

  // 앱을 시작할 때 호출합니다.
  // "어제까지 완료하지 못한 할 일"을 오늘 날짜로 자동 이월시킵니다.
  Future<void> initializeAndCarryOverTasks() async {
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);

    // 오늘보다 이전 날짜이면서 아직 완료되지 않은 할 일들을 찾습니다.
    final overdue = storage.getAllTasks().where((task) {
      final taskDateOnly = DateTime(
        task.date.year,
        task.date.month,
        task.date.day,
      );
      return taskDateOnly.isBefore(todayOnly) && !task.isDone;
    }).toList();

    for (final oldTask in overdue) {
      // 이미 오늘 날짜로 같은 제목의 이월 항목이 있으면 중복 이월하지 않습니다.
      final alreadyCarried = storage.getAllTasks().any(
        (t) =>
            t.carriedOverFromId == oldTask.id &&
            t.date.year == todayOnly.year &&
            t.date.month == todayOnly.month &&
            t.date.day == todayOnly.day,
      );
      if (alreadyCarried) continue;

      // 원본 할 일은 그대로 두고(과거 기록 보존), 오늘 날짜로 복사본을 새로 만듭니다.
      final newTask = Task(
        id: _uuid.v4(),
        title: oldTask.title,
        memo: oldTask.memo,
        startTime: null, // 이월된 항목은 시간 미정으로 다시 배치
        date: todayOnly,
        isImportant: oldTask.isImportant,
        isUrgent: oldTask.isUrgent,
        isTop3: false,
        isDone: false,
        createdAt: DateTime.now(),
        carriedOverFromId: oldTask.id,
      );
      await storage.saveTask(newTask);
    }
    notifyListeners();
  }

  // ---------------- Task(할 일) 관련 ----------------

  // 선택된 날짜의 할 일 목록 (실시간으로 storage에서 다시 읽어옴)
  List<Task> get tasksForSelectedDate => storage.getTasksByDate(_selectedDate);

  // 시간이 지정된 할 일만, 시간순으로 정렬해서 반환
  List<Task> get timedTasks {
    final list = tasksForSelectedDate
        .where((t) => t.startTime != null)
        .toList();
    list.sort((a, b) => a.startTime!.compareTo(b.startTime!));
    return list;
  }

  // 시간이 지정되지 않은 할 일 (시간 미정 묶음)
  List<Task> get untimedTasks =>
      tasksForSelectedDate.where((t) => t.startTime == null).toList();

  // "오늘 집중할 3가지"로 선택된 할 일들
  List<Task> get top3Tasks =>
      tasksForSelectedDate.where((t) => t.isTop3).toList();

  Future<void> addTask(Task task) async {
    await storage.saveTask(task);
    notifyListeners();
  }

  Future<void> updateTask(Task task) async {
    await storage.saveTask(task);
    notifyListeners();
  }

  Future<void> deleteTask(String id) async {
    await storage.deleteTask(id);
    notifyListeners();
  }

  Future<void> toggleTaskDone(Task task) async {
    task.isDone = !task.isDone;
    await storage.saveTask(task);
    notifyListeners();
  }

  // "오늘의 3가지"에 추가/제거. 이미 3개가 선택된 상태에서 추가를 시도하면
  // false를 반환해서 화면에서 안내 메시지를 띄울 수 있게 합니다.
  Future<bool> toggleTop3(Task task) async {
    if (!task.isTop3 && top3Tasks.length >= 3) {
      return false; // 이미 3개 다 채워짐
    }
    task.isTop3 = !task.isTop3;
    await storage.saveTask(task);
    notifyListeners();
    return true;
  }

  // ---------------- 우선순위 매트릭스용 ----------------

  // 완료되지 않은 모든 할 일을 사분면별로 묶어서 반환 (날짜 무관, 전체 기준)
  Map<int, List<Task>> get matrixTasks {
    final Map<int, List<Task>> result = {0: [], 1: [], 2: [], 3: []};
    // 모든 날짜가 아니라, 지금 보고 있는 날짜의 할 일만 매트릭스에 담습니다.
    for (final task in tasksForSelectedDate.where((t) => !t.isDone)) {
      result[task.quadrant]!.add(task);
    }
    return result;
  }


  // ---------------- Note(생각 노트) 관련 ----------------

  List<Note> get allNotes => storage.getAllNotes();

  Future<void> addNote(String content) async {
    final note = Note(
      id: _uuid.v4(),
      content: content,
      createdAt: DateTime.now(),
    );
    await storage.saveNote(note);
    notifyListeners();
  }

  Future<void> archiveNote(Note note) async {
    note.status = NoteStatus.archived;
    await storage.saveNote(note);
    notifyListeners();
  }

  Future<void> deleteNote(String id) async {
    await storage.deleteNote(id);
    notifyListeners();
  }

  // 노트를 실제 할 일(Task)로 전환합니다.
  Future<void> convertNoteToTask(Note note) async {
    final newTask = Task(
      id: _uuid.v4(),
      title: note.content.length > 50
          ? '${note.content.substring(0, 50)}...'
          : note.content,
      memo: note.content,
      date: DateTime.now(),
      createdAt: DateTime.now(),
    );
    await storage.saveTask(newTask);

    note.status = NoteStatus.converted;
    note.convertedTaskId = newTask.id;
    await storage.saveNote(note);
    notifyListeners();
  }

  // ---------------- Reflection(저녁 회고) 관련 ----------------

  Reflection? reflectionFor(DateTime date) => storage.getReflectionByDate(date);

  Future<void> saveReflectionMemo(DateTime date, String memo) async {
    final existing = storage.getReflectionByDate(date);
    if (existing != null) {
      existing.memo = memo;
      existing.updatedAt = DateTime.now();
      await storage.saveReflection(existing);
    } else {
      final newReflection = Reflection(
        id: _uuid.v4(),
        date: DateTime(date.year, date.month, date.day),
        memo: memo,
        updatedAt: DateTime.now(),
      );
      await storage.saveReflection(newReflection);
    }
    notifyListeners();
  }

  // ---------------- 검색 ----------------

  // 할 일 제목/메모, 노트 내용을 함께 검색합니다.
  List<Task> searchTasks(String keyword) {
    if (keyword.trim().isEmpty) return [];
    final lower = keyword.toLowerCase();
    return storage.getAllTasks().where((t) {
      final inTitle = t.title.toLowerCase().contains(lower);
      final inMemo = (t.memo ?? '').toLowerCase().contains(lower);
      return inTitle || inMemo;
    }).toList();
  }

  List<Note> searchNotes(String keyword) {
    if (keyword.trim().isEmpty) return [];
    final lower = keyword.toLowerCase();
    return storage
        .getAllNotes()
        .where((n) => n.content.toLowerCase().contains(lower))
        .toList();
  }
}
