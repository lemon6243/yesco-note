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
import '../models/habit.dart';
import '../models/morning_session.dart';
import '../models/project.dart';
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

  
  // ---------------- 성장 동물 선택 ----------------
  // 저장되는 값: 'cat' / 'dog' / 'panda' / 'bear'
  String _growthAnimal = 'cat';
  String get growthAnimal => _growthAnimal;

  static const String _growthAnimalKey = 'growth_animal';

  // 저장된 동물 선택을 불러옵니다. (앱 시작 시 1회 호출)
  Future<void> loadGrowthAnimal() async {
    final prefs = await SharedPreferences.getInstance();
    _growthAnimal = prefs.getString(_growthAnimalKey) ?? 'cat';
    notifyListeners();
  }

  // 동물을 바꾸고 기기에 저장합니다.
  Future<void> setGrowthAnimal(String animal) async {
    _growthAnimal = animal;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_growthAnimalKey, animal);
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

  // 캘린더에서 특정 날짜를 골랐을 때, 그 날짜로 바로 이동합니다.
  // (시:분:초는 버리고 날짜만 사용)
  void goToDate(DateTime date) {
    _selectedDate = DateTime(date.year, date.month, date.day);
    notifyListeners();
  }


  // ---------------- 초기 데이터 로드 + 미완료 이월 ---------------- 

  // ---------------- Task(할 일) 관련 ----------------
  // ---------------- 반복 할 일 자동 생성 ----------------

  // 앱을 시작할 때 호출합니다.
  // 반복 규칙이 있는 "원본 할 일"을 보고, 오늘 날짜에 해당하면
  // 그날짜용 하루짜리 인스턴스를 자동으로 만들어 줍니다.
  // (이미 만들어진 날은 건너뜀 → 중복 생성 방지)
  Future<void> generateRepeatingTasks() async {
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);

    // 반복 규칙이 있는 원본 할 일들만 골라냅니다.
    // (repeatSourceId가 null = 사용자가 직접 만든 원본, 자동 생성 인스턴스가 아님)
    final sources = storage.getAllTasks().where((t) {
      return t.repeatRule != null && t.repeatSourceId == null;
    }).toList();

    for (final source in sources) {
      // 이 원본이 오늘 반복되어야 하는지 판단합니다.
      if (!_shouldRepeatOn(source, todayOnly)) continue;

      // 이미 오늘 날짜로 이 원본에서 생성된 인스턴스가 있으면 건너뜁니다.
      final alreadyMade = storage.getAllTasks().any(
        (t) =>
            t.repeatSourceId == source.id &&
            t.date.year == todayOnly.year &&
            t.date.month == todayOnly.month &&
            t.date.day == todayOnly.day,
      );
      if (alreadyMade) continue;

      // 오늘 날짜용 하루짜리 인스턴스를 새로 만듭니다.
      // (인스턴스 자체는 반복 규칙을 갖지 않음 → 그냥 평범한 하루치 할 일)
      final instance = Task(
        id: _uuid.v4(),
        title: source.title,
        memo: source.memo,
        startTime: source.startTime,
        date: todayOnly,
        isImportant: source.isImportant,
        isUrgent: source.isUrgent,
        isTop3: false,
        isDone: false,
        createdAt: DateTime.now(),
        location: source.location,
        why: source.why,
        how: source.how,
        howMuch: source.howMuch,
        repeatRule: null, // 인스턴스는 반복 규칙 없음
        repeatSourceId: source.id, // 어떤 원본에서 나왔는지 기록
      );
      await storage.saveTask(instance);
    }
    notifyListeners();
  }

  // 특정 원본 할 일이 주어진 날짜에 반복되어야 하는지 판단하는 도우미.
  bool _shouldRepeatOn(Task source, DateTime date) {
    if (source.repeatRule == 'daily') {
      // 매일 반복: 원본을 만든 날짜부터 그 이후 매일
      final srcDateOnly = DateTime(
        source.date.year,
        source.date.month,
        source.date.day,
      );
      return !date.isBefore(srcDateOnly);
    }
    if (source.repeatRule == 'weekly') {
      // 매주 특정 요일 반복: 오늘 요일이 선택된 요일 목록에 있는지 확인
      return source.repeatWeekdays.contains(date.weekday);
    }
    return false;
  }

  // ---------------- 장소 필터 (전체 / 집 / 외부) ----------------
  // null = 전체 보기, 'home' = 집만, 'outside' = 외부만
  String? _locationFilter;
  String? get locationFilter => _locationFilter;

  void setLocationFilter(String? location) {
    _locationFilter = location;
    notifyListeners();
  }

  // ---------------- 카테고리 필터 (전체 / 업무 / 부업 / 개인 / 투자) ----------------
  // null = 전체 보기, 'work'/'side'/'private'/'invest' = 해당 카테고리만
  String? _categoryFilter;
  String? get categoryFilter => _categoryFilter;

  void setCategoryFilter(String? category) {
    _categoryFilter = category;
    notifyListeners();
  }


  // 선택된 날짜의 할 일 목록 (실시간으로 storage에서 다시 읽어옴)
  // 장소 필터가 켜져 있으면 해당 장소의 할 일만 걸러서 반환합니다.
  List<Task> get tasksForSelectedDate {
  // 반복 규칙이 있는 "원본"은 목록에 표시하지 않습니다.
  // (매일/매주 반복을 위한 설정용일 뿐, 실제로 보여줄 건 자동 생성된 인스턴스)
   final all = storage
       .getTasksByDate(_selectedDate)
       .where((t) => t.repeatRule == null)
       .toList();
    var filtered = all;
    if (_locationFilter != null) {
      filtered = filtered.where((t) => t.location == _locationFilter).toList();
    }
    if (_categoryFilter != null) {
      filtered = filtered.where((t) => t.category == _categoryFilter).toList();
    }
    return filtered;
 }

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

  // 선택된 날짜의 완료되지 않은 할 일을 사분면(0~3)별로 묶어서 반환
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

  // 노트 추가. 텍스트만, 그림만, 또는 둘 다 저장 가능.
  // penStrokesJson은 drawn_stroke.dart의 encodeStrokes() 결과(JSON 문자열).
  Future<void> addNote(String content, {String? penStrokesJson}) async {
    final note = Note(
      id: _uuid.v4(),
      content: content,
      createdAt: DateTime.now(),
      penStrokes: penStrokesJson,
    );
    await storage.saveNote(note);
    notifyListeners();
  }

  Future<void> updateNotePen(
    Note note,
    String content,
    String penStrokesJson,
  ) async {
    note.content = content;
    note.penStrokes = penStrokesJson;
    await storage.saveNote(note);   // 다른 노트 함수들과 동일하게 통일
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
      date: _selectedDate, // 지금 보고 있는 날짜의 할 일로 만듭니다.
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
  // ---------------- Habit(습관) 관련 ----------------

  // 활성 습관 목록 (보관된 것은 제외). 만든 순서대로 반환.
  List<Habit> get activeHabits {
    final list = storage.getAllHabits().where((h) => !h.isArchived).toList();
    list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return list;
  }

  // 새 습관 추가 (weeklyGoal은 선택 입력. null이면 목표 없이 등록)
  Future<void> addHabit(String name, String emoji, {int? weeklyGoal}) async {
    final habit = Habit(
      id: _uuid.v4(),
      name: name,
      emoji: emoji,
      createdAt: DateTime.now(),
      weeklyGoal: weeklyGoal,
    );
    await storage.saveHabit(habit);
    notifyListeners();
  }

  // 습관 정보 수정 (이름·이모지 변경 등)
  Future<void> updateHabit(Habit habit) async {
    await storage.saveHabit(habit);
    notifyListeners();
  }

  // 습관 삭제
  Future<void> deleteHabit(String id) async {
    await storage.deleteHabit(id);
    notifyListeners();
  }

  // 오늘 체크를 켜고 끕니다. (이미 체크돼 있으면 해제, 아니면 체크)
  Future<void> toggleHabitToday(Habit habit) async {
    final key = Habit.dateKey(DateTime.now());
    if (habit.checkedDates.contains(key)) {
      habit.checkedDates.remove(key); // 체크 해제
    } else {
      habit.checkedDates.add(key); // 체크
    }
    await storage.saveHabit(habit);
    notifyListeners();
  }

  // 특정 날짜의 체크를 켜고 끕니다. (달력에서 과거 날짜를 수정할 때 사용)
  Future<void> toggleHabitOnDate(Habit habit, DateTime date) async {
    // 미래 날짜는 체크할 수 없게 막습니다. (오늘까지만 허용)
    final today = DateTime.now();
    final dateOnly = DateTime(date.year, date.month, date.day);
    final todayOnly = DateTime(today.year, today.month, today.day);
    if (dateOnly.isAfter(todayOnly)) return;

    final key = Habit.dateKey(date);
    if (habit.checkedDates.contains(key)) {
      habit.checkedDates.remove(key); // 체크 해제
    } else {
      habit.checkedDates.add(key); // 체크
    }
    await storage.saveHabit(habit);
    notifyListeners();
  }

  // ---------------- 검색 ----------------

  // 할 일 제목/메모, 노트 내용을 함께 검색합니다.
  List<Task> searchTasks(String keyword) {
    if (keyword.trim().isEmpty) return [];
    final lower = keyword.toLowerCase();
    final results = storage.getAllTasks().where((t) {
      final inTitle = t.title.toLowerCase().contains(lower);
      final inMemo = (t.memo ?? '').toLowerCase().contains(lower);
      return inTitle || inMemo;
    }).toList();
    // 최근에 만든 할 일이 위로 오도록 생성일 기준 내림차순 정렬
    results.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return results;
  }

  List<Note> searchNotes(String keyword) {
    if (keyword.trim().isEmpty) return [];
    final lower = keyword.toLowerCase();
    return storage
        .getAllNotes()
        .where((n) => n.content.toLowerCase().contains(lower))
        .toList();
  }

  // ---------------- MorningSession(아침 1시간 타이머) 관련 ----------------

  // 오늘 기록한 모든 세션들 (하루에 여러 번 기록 가능)
  List<MorningSession> get todayMorningSessions =>
      storage.getMorningSessionsByDate(DateTime.now());

  // 오늘 지금까지 누적한 시간(초). 여러 번 기록했으면 합산.
  int get todayMorningSeconds => todayMorningSessions.fold(
    0,
    (sum, s) => sum + s.durationSeconds,
  );

  // 전체 기록 (최신순)
  List<MorningSession> get allMorningSessions =>
      storage.getAllMorningSessions();

  // 지금까지 누적한 총 시간(초). 통계 화면용.
  int get totalMorningSeconds => storage.getAllMorningSessions().fold(
    0,
    (sum, s) => sum + s.durationSeconds,
  );

  // 지금까지 기록한 총 횟수(세션 수). 통계 화면용.
  int get totalMorningSessionCount => storage.getAllMorningSessions().length;

  // "아침 시간을 실천한 날"의 연속일수(streak)를 계산합니다.
  // 하루에 최소 1번 이상 기록이 있으면 그날은 "실천한 날"로 간주합니다.
  // 오늘 아직 안 했으면 어제부터 거꾸로 셉니다. (습관 streak와 동일한 규칙)
  int get morningStreak {
    final sessions = storage.getAllMorningSessions();
    if (sessions.isEmpty) return 0;

    final doneDateKeys = sessions
        .map((s) => MorningSession.dateKey(s.date))
        .toSet();

    bool isDoneOn(DateTime date) =>
        doneDateKeys.contains(MorningSession.dateKey(date));

    DateTime cursor = DateTime.now();
    if (!isDoneOn(cursor)) {
      cursor = cursor.subtract(const Duration(days: 1));
    }

    int streak = 0;
    while (isDoneOn(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  // 새 아침 세션 기록을 저장합니다. (타이머를 멈추고 "저장"했을 때 호출)
  Future<void> addMorningSession({
    required int durationSeconds,
    required int targetSeconds,
    String? memo,
  }) async {
    final now = DateTime.now();
    final session = MorningSession(
      id: _uuid.v4(),
      date: DateTime(now.year, now.month, now.day),
      durationSeconds: durationSeconds,
      targetSeconds: targetSeconds,
      memo: (memo == null || memo.trim().isEmpty) ? null : memo.trim(),
      completedAt: now,
    );
    await storage.saveMorningSession(session);
    notifyListeners();
  }

    Future<void> deleteMorningSession(String id) async {
    await storage.deleteMorningSession(id);
    notifyListeners();
  }

  // ---------------- 통합 통계 (대시보드용) ----------------

  // 최근 7일 날짜 목록을 반환합니다. (오래된 날 → 오늘 순서)
  // 예: 오늘이 16일이면 [10,11,12,13,14,15,16]
  List<DateTime> get last7Days {
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    return List.generate(7, (i) => todayOnly.subtract(Duration(days: 6 - i)));
  }

  // --- 할 일(Task) 통계 ---

  // 지금까지 완료한 할 일 총 개수
  int get totalCompletedTasks =>
      storage.getAllTasks().where((t) => t.isDone).length;

  // 특정 날짜에 완료한 할 일 개수
  int completedTaskCountOn(DateTime date) {
    return storage.getAllTasks().where((t) {
      return t.isDone &&
          t.date.year == date.year &&
          t.date.month == date.month &&
          t.date.day == date.day;
    }).length;
  }

  // 오늘의 완료율(0.0~1.0). 오늘 할 일이 없으면 0.
  // (반복 원본은 제외하고, 오늘 날짜의 실제 할 일 기준)
  double get todayCompletionRate {
    final today = DateTime.now();
    final todays = storage
        .getTasksByDate(today)
        .where((t) => t.repeatRule == null)
        .toList();
    if (todays.isEmpty) return 0;
    final done = todays.where((t) => t.isDone).length;
    return done / todays.length;
  }

  // 최근 7일간 하루별 완료한 할 일 개수 (그래프용)
  List<int> get last7DaysCompletedTasks =>
      last7Days.map((d) => completedTaskCountOn(d)).toList();

  // --- 습관(Habit) 통계 ---

  // 활성 습관 개수
  int get activeHabitCount => activeHabits.length;

  // 특정 날짜에 체크된 습관 개수 (활성 습관 기준)
  int habitCheckCountOn(DateTime date) {
    return activeHabits.where((h) => h.isCheckedOn(date)).length;
  }

  // 최근 7일간 하루별 습관 체크 개수 (그래프용)
  List<int> get last7DaysHabitChecks =>
      last7Days.map((d) => habitCheckCountOn(d)).toList();

  // 모든 활성 습관의 연속일수 중 가장 긴 값 (대표 스트릭)
  int get bestHabitStreak {
    if (activeHabits.isEmpty) return 0;
    return activeHabits
        .map((h) => h.currentStreak)
        .reduce((a, b) => a > b ? a : b);
  }

  // --- 아침 세션 통계 ---

  // 특정 날짜의 아침 집중 시간(초 합계)
  int morningSecondsOn(DateTime date) {
    return storage
        .getMorningSessionsByDate(date)
        .fold(0, (sum, s) => sum + s.durationSeconds);
  }

  // 최근 7일간 하루별 아침 집중 시간(분 단위, 그래프용)
  List<int> get last7DaysMorningMinutes =>
      last7Days.map((d) => (morningSecondsOn(d) / 60).round()).toList();
  
  // ---------------- 카테고리 통계 (대시보드용) ----------------
  // 카테고리: 'work'(업무) / 'side'(부업) / 'private'(개인) / 'invest'(투자)

  // 이번 주(최근 7일) 완료한 할 일을 카테고리별로 카운트.
  // 반환 예: {'work': 12, 'side': 5, 'private': 3, 'invest': 2}
  // (카테고리 미지정 할 일은 집계에서 제외)
  Map<String, int> get weeklyCategoryCounts {
    final counts = <String, int>{
      'work': 0,
      'side': 0,
      'private': 0,
      'invest': 0,
    };
    final days = last7Days;
    final first = days.first; // 7일 전
    final last = days.last;   // 오늘

    for (final t in storage.getAllTasks()) {
      if (!t.isDone) continue;
      if (t.category == null) continue;
      if (!counts.containsKey(t.category)) continue;

      final d = DateTime(t.date.year, t.date.month, t.date.day);
      // first ~ last 범위(양끝 포함)에 드는지 확인
      if (d.isBefore(first) || d.isAfter(last)) continue;

      counts[t.category!] = counts[t.category!]! + 1;
    }
    return counts;
  }

  // 이번 주 카테고리별 완료 합계 (그래프 최대값 계산 등에 사용)
  int get weeklyCategoryTotal =>
      weeklyCategoryCounts.values.fold(0, (sum, v) => sum + v);

  
  // ---------------- 성장 시스템 (다마고치식) ----------------
  // 점수: 할 일 1개=2점, 습관 체크 1회=3점, 아침 세션 1회=5점
  // 레벨: 100점마다 +1 (레벨 1부터 시작)
  // 성장 단계: 알 → 아기 → 성체 → 다 큰 → 마스터 (레벨 구간별)

  int get growthPoints {
    final taskPoints = totalCompletedTasks * 2;
    final habitChecks =
        activeHabits.fold<int>(0, (sum, h) => sum + h.checkedDates.length);
    final habitPoints = habitChecks * 3;
    final morningPoints = totalMorningSessionCount * 5;
    return taskPoints + habitPoints + morningPoints;
  }

  int get growthLevel => (growthPoints ~/ 100) + 1;
  double get growthProgress => (growthPoints % 100) / 100;
  int get pointsToNextLevel => 100 - (growthPoints % 100);

  // 성장 단계 인덱스 (0~4): 0=알, 1=아기, 2=성체, 3=다 큰, 4=마스터
  int get growthStageIndex {
    final level = growthLevel;
    if (level >= 20) return 4;
    if (level >= 12) return 3;
    if (level >= 7) return 2;
    if (level >= 3) return 1;
    return 0;
  }

  // 현재 성장 단계에 맞는 마스코트 이미지 경로
  // 0단계(알)는 공통 egg.png, 1~4단계는 yesco1~4.png
  String get growthImagePath {
    final stageFiles = [
      'assets/growth/egg.png',    // 0: 알
      'assets/growth/yesco1.png', // 1: 아기
      'assets/growth/yesco2.png', // 2: 성체
      'assets/growth/yesco3.png', // 3: 다 큰
      'assets/growth/yesco4.png', // 4: 마스터
    ];
    return stageFiles[growthStageIndex];
  }

  // 현재 성장 단계 이름
  String get growthStageName {
    const names = ['알', '아기', '성체', '다 큰', '마스터'];
    return names[growthStageIndex];
  }

  // 동물별 5단계 이모지 (알 → 아기 → 성체 → 다 큰 → 마스터)
  // 나중에 이미지로 교체할 때 이 부분만 바꾸면 됩니다.
  static const Map<String, List<String>> animalStages = {
    'cat': ['🥚', '🐱', '🐈', '🐈✨', '🐈👑'],
    'dog': ['🥚', '🐶', '🐕', '🦮✨', '🐕👑'],
    'panda': ['🥚', '🐼', '🐼', '🐼✨', '🐼👑'],
    'bear': ['🥚', '🐻', '🐻', '🐻✨', '🐻👑'],
  };

  // 선택 가능한 동물 목록 (선택 UI에서 사용)
  static const Map<String, String> availableAnimals = {
    'cat': '고양이',
    'dog': '강아지',
    'panda': '판다',
    'bear': '곰',
  };
  
  // ---------------- Project(프로젝트) 관련 ----------------

  // 모든 프로젝트 목록 (최신 생성순). storage에서 실시간으로 읽어옴.
  List<Project> get allProjects => storage.getAllProjects();

  // 진행 중인 프로젝트만 (완료되지 않은 것)
  List<Project> get activeProjects =>
      storage.getAllProjects().where((p) => !p.isDone).toList();

  // 새 프로젝트 추가.
  // name은 필수, 나머지는 선택. 색상은 기본값(파랑)을 쓰거나 지정 가능.
  Future<void> addProject(
    String name, {
    String? description,
    int colorValue = 0xFF3B82F6,
    DateTime? startDate,
    DateTime? dueDate,
  }) async {
    final project = Project(
      id: _uuid.v4(),
      name: name,
      description: description,
      colorValue: colorValue,
      startDate: startDate,
      dueDate: dueDate,
      createdAt: DateTime.now(),
    );
    await storage.saveProject(project);
    notifyListeners();
  }

  // 프로젝트 정보 수정 (이름·색상·기간·완료여부 등 변경 후 호출)
  Future<void> updateProject(Project project) async {
    await storage.saveProject(project);
    notifyListeners();
  }

  // 프로젝트 삭제. 이 프로젝트에 묶여 있던 할 일들은
  // storage 쪽에서 projectId가 null로 되돌려져 "미분류"로 남습니다.
  Future<void> deleteProject(String id) async {
    await storage.deleteProject(id);
    notifyListeners();
  }

  // 프로젝트 완료/미완료를 토글합니다.
  Future<void> toggleProjectDone(Project project) async {
    project.isDone = !project.isDone;
    await storage.saveProject(project);
    notifyListeners();
  }

  // 특정 프로젝트에 속한 할 일 목록.
  List<Task> tasksOfProject(String projectId) =>
      storage.getTasksByProject(projectId);

  // 특정 프로젝트의 진행률(0.0~1.0). 속한 할 일 중 완료 비율.
  // 할 일이 하나도 없으면 0을 반환.
  double projectProgress(String projectId) {
    final tasks = storage.getTasksByProject(projectId);
    if (tasks.isEmpty) return 0;
    final done = tasks.where((t) => t.isDone).length;
    return done / tasks.length;
  }
}
