// ============================================================
// TaskEditScreen (할 일 추가/편집 화면)
// ------------------------------------------------------------
// existingTask가 주어지면 "수정 모드", 없으면 "새로 추가 모드"로 동작합니다.
// 제목, 메모, 시작 시간, 날짜, 중요도, 긴급도를 입력받습니다.
// ============================================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt; // 음성 인식 패키지 추가
import '../services/app_state.dart';
import '../models/task.dart';
import '../theme/app_theme.dart';

class TaskEditScreen extends StatefulWidget {
  final Task? existingTask; // 수정할 할 일 (없으면 새로 추가)
  final DateTime? initialDate; // 새로 추가할 때 기본으로 들어갈 날짜
  final String? initialProjectId; // 새로 추가할 때 미리 연결할 프로젝트 id

  const TaskEditScreen({
    super.key,
    this.existingTask,
    this.initialDate,
    this.initialProjectId,
  });

  @override
  State<TaskEditScreen> createState() => _TaskEditScreenState();
}

class _TaskEditScreenState extends State<TaskEditScreen> {
  // 기본 입력 컨트롤러
  final _titleController = TextEditingController();
  final _memoController = TextEditingController();

  DateTime _date = DateTime.now();
  TimeOfDay? _startTime; // 시작 시간 (선택 사항)
  bool _isImportant = false;
  bool _isUrgent = false;
  String? _location; // 장소: 'home'(집) / 'outside'(외부) / null(미지정)
  String? _category; // 카테고리: 'work'(업무)/'side'(부업)/'private'(개인)/'invest'(투자)/null
  String? _projectId; // 이 할 일이 속한 프로젝트 id (null = 미분류)

  // 반복 설정
  String? _repeatRule; // null(반복 없음) / 'daily'(매일) / 'weekly'(매주)
  final List<int> _repeatWeekdays = []; // 매주 반복 시 선택된 요일 (월=1 ~ 일=7)
  
  // 5W2H 구체화 입력용 컨트롤러
  final _whyController = TextEditingController();
  final _howController = TextEditingController();
  final _howMuchController = TextEditingController();

  bool get _isEditMode => widget.existingTask != null;

  // 음성 인식(STT) 관련 변수 추가
  late stt.SpeechToText _speech;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    
    // STT 객체 초기화
    _speech = stt.SpeechToText();

    final task = widget.existingTask;
    if (task != null) {
      _titleController.text = task.title;
      _memoController.text = task.memo ?? '';
      _date = task.date;
      _isImportant = task.isImportant;
      _isUrgent = task.isUrgent;
      _location = task.location;
      _category = task.category;
      _projectId = task.projectId;
      _repeatRule = task.repeatRule;
      _repeatWeekdays
        ..clear()
        ..addAll(task.repeatWeekdays);
      _whyController.text = task.why ?? '';
      _howController.text = task.how ?? '';
      _howMuchController.text = task.howMuch ?? '';

      if (task.startTime != null) {
        _startTime = TimeOfDay.fromDateTime(task.startTime!);
      }
    } else {
      if (widget.initialDate != null) {
        _date = widget.initialDate!;
      }
      _projectId = widget.initialProjectId;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _memoController.dispose();
    _whyController.dispose();
    _howController.dispose();
    _howMuchController.dispose();
    super.dispose();
  }

  // 음성 듣기 시작/종료 함수
  void _listen() async {
    if (!_isListening) {
      // 마이크 권한 허용 및 초기화 시도
      bool available = await _speech.initialize(
        onStatus: (val) => debugPrint('onStatus: $val'),
        onError: (val) => debugPrint('onError: $val'),
      );
      if (available) {
        setState(() => _isListening = true);
        // 한국어 인식 시작
        _speech.listen(
          localeId: 'ko_KR',
          onResult: (val) => setState(() {
            _titleController.text = val.recognizedWords; // 결과값을 제목 칸에 넣음
          }),
        );
      }
    } else {
      // 이미 듣고 있는 중이면 중지
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? '할 일 수정' : '할 일 추가'),
        actions: [
          if (_isEditMode)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _handleDelete,
            ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 제목 입력 (음성 인식 마이크 버튼 포함)
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: '제목 *',
                hintText: '무슨 일을 해야 하나요?',
                suffixIcon: IconButton(
                  icon: Icon(
                    _isListening ? Icons.mic : Icons.mic_none, 
                    color: _isListening ? Colors.red : Colors.grey, 
                  ),
                  onPressed: _listen, 
                  tooltip: '음성으로 제목 입력',
                ),
              ),
              autofocus: !_isEditMode,
            ),
            const SizedBox(height: 14),
            // 메모 입력
            TextField(
              controller: _memoController,
              decoration: const InputDecoration(labelText: '상세 메모 (선택)'),
              maxLines: 3,
            ),
            const SizedBox(height: 20),

            // 날짜 선택
            _buildRowSelector(
              icon: Icons.calendar_today_rounded,
              label: '날짜',
              value: DateFormat('yyyy년 M월 d일 (E)', 'ko_KR').format(_date),
              onTap: _pickDate,
            ),
            const SizedBox(height: 10),

            // 시작 시간 선택
            _buildRowSelector(
              icon: Icons.access_time_rounded,
              label: '시작 시간',
              value: _startTime != null
                  ? _startTime!.format(context)
                  : '시간 미정 (탭하여 설정)',
              onTap: _pickTime,
              trailing: _startTime != null
                  ? IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => setState(() => _startTime = null),
                    )
                  : null,
            ),

            const SizedBox(height: 24),
            const Text(
              '중요도 · 긴급도',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 10),

            // 중요도 및 긴급도 스위치
            _buildSwitchRow(
              label: '중요한 일인가요?',
              value: _isImportant,
              activeColor: AppColors.teal,
              onChanged: (v) => setState(() => _isImportant = v),
            ),
            const SizedBox(height: 8),
            _buildSwitchRow(
              label: '긴급한 일인가요?',
              value: _isUrgent,
              activeColor: AppColors.coral,
              onChanged: (v) => setState(() => _isUrgent = v),
            ),

            const SizedBox(height: 24),
            const Text(
              '장소',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('🏠 집'),
                  selected: _location == 'home',
                  onSelected: (sel) => setState(() => _location = sel ? 'home' : null),
                ),
                ChoiceChip(
                  label: const Text('🚶 외부'),
                  selected: _location == 'outside',
                  onSelected: (sel) => setState(() => _location = sel ? 'outside' : null),
                ),
              ],
            ),

            const SizedBox(height: 24),
            const Text(
              '카테고리',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('💼 업무'),
                  selected: _category == 'work',
                  onSelected: (sel) => setState(() => _category = sel ? 'work' : null),
                ),
                ChoiceChip(
                  label: const Text('🚀 부업'),
                  selected: _category == 'side',
                  onSelected: (sel) => setState(() => _category = sel ? 'side' : null),
                ),
                ChoiceChip(
                  label: const Text('🏡 개인'),
                  selected: _category == 'private',
                  onSelected: (sel) => setState(() => _category = sel ? 'private' : null),
                ),
                ChoiceChip(
                  label: const Text('📈 투자'),
                  selected: _category == 'invest',
                  onSelected: (sel) => setState(() => _category = sel ? 'invest' : null),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            const Text(
              '프로젝트',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 10),
            Builder(
              builder: (context) {
                final projects = context.read<AppState>().activeProjects;
                if (projects.isEmpty) {
                  return Text(
                    '아직 프로젝트가 없어요. 오른쪽 위 폴더 아이콘에서 만들 수 있어요.',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: Colors.grey.withValues(alpha: 0.9),
                    ),
                  );
                }
                final validValue = projects.any((p) => p.id == _projectId) ? _projectId : null;
                return Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String?>(
                        isExpanded: true,
                        value: validValue,
                        hint: const Text('프로젝트 없음'),
                        items: [
                          const DropdownMenuItem<String?>(value: null, child: Text('프로젝트 없음')),
                          ...projects.map(
                            (p) => DropdownMenuItem<String?>(
                              value: p.id,
                              child: Row(
                                children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(color: Color(p.colorValue), shape: BoxShape.circle),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(child: Text(p.name, overflow: TextOverflow.ellipsis)),
                                ],
                              ),
                            ),
                          ),
                        ],
                        onChanged: (value) => setState(() => _projectId = value),
                      ),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 24),
            const Text('반복', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('반복 없음'),
                  selected: _repeatRule == null,
                  onSelected: (_) => setState(() {
                    _repeatRule = null;
                    _repeatWeekdays.clear();
                  }),
                ),
                ChoiceChip(
                  label: const Text('매일'),
                  selected: _repeatRule == 'daily',
                  onSelected: (_) => setState(() {
                    _repeatRule = 'daily';
                    _repeatWeekdays.clear();
                  }),
                ),
                ChoiceChip(
                  label: const Text('매주'),
                  selected: _repeatRule == 'weekly',
                  onSelected: (_) => setState(() => _repeatRule = 'weekly'),
                ),
              ],
            ),
            if (_repeatRule == 'weekly') ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                children: List.generate(7, (i) {
                  final weekday = i + 1; // 월=1 ... 일=7
                  const labels = ['월', '화', '수', '목', '금', '토', '일'];
                  final selected = _repeatWeekdays.contains(weekday);
                  return FilterChip(
                    label: Text(labels[i]),
                    selected: selected,
                    onSelected: (sel) => setState(() {
                      if (sel) {
                        _repeatWeekdays.add(weekday);
                      } else {
                        _repeatWeekdays.remove(weekday);
                      }
                    }),
                  );
                }),
              ),
            ],

            const SizedBox(height: 20),
            Card(
              margin: EdgeInsets.zero,
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(horizontal: 14),
                childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                leading: const Icon(Icons.center_focus_strong_rounded),
                title: const Text('구체화 (5W2H)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: const Text('막연한 일을 구체적인 예정으로', style: TextStyle(fontSize: 11)),
                children: [
                  TextField(
                    controller: _whyController,
                    decoration: const InputDecoration(labelText: '왜 (목적·동기)', hintText: '이 일을 왜 하나요?'),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _howController,
                    decoration: const InputDecoration(labelText: '어떻게 (방법·수단)', hintText: '어떤 방법으로 할까요?'),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _howMuchController,
                    decoration: const InputDecoration(labelText: '얼마나 (분량·기준)', hintText: '예: 30분, 10페이지, 3세트'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _handleSave,
              child: SizedBox(
                width: double.infinity,
                child: Text(
                  _isEditMode ? '수정 완료' : '추가하기',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRowSelector({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Icon(icon, size: 20, color: AppColors.coral),
              const SizedBox(width: 12),
              Text(label, style: const TextStyle(fontSize: 14)),
              const Spacer(),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.withValues(alpha: 0.9),
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchRow({
    required String label,
    required bool value,
    required Color activeColor,
    required ValueChanged<bool> onChanged,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        child: Row(
          children: [
            Expanded(child: Text(label, style: const TextStyle(fontSize: 14))),
            Switch(
              value: value,
              activeThumbColor: activeColor,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime ?? TimeOfDay.now(),
    );
    if (picked != null) setState(() => _startTime = picked);
  }

  Future<void> _handleSave() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('제목을 입력해주세요.')));
      return;
    }

    final appState = context.read<AppState>();

    DateTime? startDateTime;
    if (_startTime != null) {
      startDateTime = DateTime(
        _date.year,
        _date.month,
        _date.day,
        _startTime!.hour,
        _startTime!.minute,
      );
    }

    if (_isEditMode) {
      final task = widget.existingTask!;
      task.title = title;
      task.memo = _memoController.text.trim().isEmpty ? null : _memoController.text.trim();
      task.date = _date;
      task.startTime = startDateTime;
      task.isImportant = _isImportant;
      task.isUrgent = _isUrgent;
      task.location = _location;
      task.category = _category;
      task.projectId = _projectId;
      task.repeatRule = _repeatRule;
      task.repeatWeekdays = _repeatRule == 'weekly' ? List<int>.from(_repeatWeekdays) : [];
      task.why = _textOrNull(_whyController.text);
      task.how = _textOrNull(_howController.text);
      task.howMuch = _textOrNull(_howMuchController.text);

      await appState.updateTask(task);
    } else {
      final newTask = Task(
        id: const Uuid().v4(),
        title: title,
        memo: _memoController.text.trim().isEmpty ? null : _memoController.text.trim(),
        date: _date,
        startTime: startDateTime,
        isImportant: _isImportant,
        isUrgent: _isUrgent,
        location: _location,
        category: _category,
        projectId: _projectId,
        repeatRule: _repeatRule,
        repeatWeekdays: _repeatRule == 'weekly' ? List<int>.from(_repeatWeekdays) : [],
        why: _textOrNull(_whyController.text),
        how: _textOrNull(_howController.text),
        howMuch: _textOrNull(_howMuchController.text),
        createdAt: DateTime.now(),
      );
      await appState.addTask(newTask);
    }

    if (mounted) Navigator.pop(context);
  }

  Future<void> _handleDelete() async {
    final appState = context.read<AppState>(); 
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('삭제할까요?'),
        content: const Text('이 할 일을 삭제하면 되돌릴 수 없어요.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await appState.deleteTask(widget.existingTask!.id);
      if (mounted) Navigator.pop(context);
    }
  }

  String? _textOrNull(String text) {
    final trimmed = text.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
