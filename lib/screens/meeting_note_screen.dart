import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../models/note.dart';
import '../widgets/voice_input_button.dart';

class MeetingNoteScreen extends StatefulWidget {
  final Note? meeting; // null이면 새 회의록, 있으면 편집
  const MeetingNoteScreen({super.key, this.meeting});

  @override
  State<MeetingNoteScreen> createState() => _MeetingNoteScreenState();
}

class _MeetingNoteScreenState extends State<MeetingNoteScreen> {
  late final TextEditingController _bodyController;
  late DateTime _meetingDate;

  bool get _isEditing => widget.meeting != null;

  @override
  void initState() {
    super.initState();
    _bodyController =
        TextEditingController(text: widget.meeting?.content ?? '');
    _meetingDate =
        widget.meeting?.meetingDate ?? DateTime.now();
  }

  @override
  void dispose() {
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _meetingDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _meetingDate = picked);
    }
  }

  Future<void> _save() async {
    final content = _bodyController.text.trim();
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('회의 내용을 입력하거나 음성으로 기록해주세요.')),
      );
      return;
    }
    final appState = context.read<AppState>();
    if (_isEditing) {
      await appState.updateMeeting(
        widget.meeting!,
        content: content,
        meetingDate: _meetingDate,
      );
    } else {
      await appState.addMeeting(
        content: content,
        meetingDate: _meetingDate,
      );
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel =
        DateFormat('yyyy년 M월 d일 (E)', 'ko_KR').format(_meetingDate);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? '회의록 편집' : '새 회의록'),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('저장'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 회의 날짜 선택
            InkWell(
              onTap: _pickDate,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.event, size: 20),
                    const SizedBox(width: 8),
                    Text('회의 날짜: $dateLabel',
                        style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    const Icon(Icons.edit, size: 16, color: Colors.grey),
                  ],
                ),
              ),
            ),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('회의 내용',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const Spacer(),
                const Text('음성 기록', style: TextStyle(color: Colors.grey)),
                VoiceInputButton(
                  onResult: (text) {
                    setState(() {
                      final existing = _bodyController.text.trim();
                      _bodyController.text =
                          existing.isEmpty ? text : '$existing\n$text';
                      // 커서를 맨 끝으로
                      _bodyController.selection = TextSelection.fromPosition(
                        TextPosition(offset: _bodyController.text.length),
                      );
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: TextField(
                controller: _bodyController,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: '마이크 버튼을 눌러 말하거나 직접 입력하세요.\n말이 끝날 때마다 줄바꿈으로 기록됩니다.',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
