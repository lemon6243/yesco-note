import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../services/app_state.dart';
import '../models/note.dart';


class MeetingNoteScreen extends StatefulWidget {
  final Note? meeting; // null이면 새 회의록, 있으면 편집
  const MeetingNoteScreen({super.key, this.meeting});

  @override
  State<MeetingNoteScreen> createState() => _MeetingNoteScreenState();
}

class _MeetingNoteScreenState extends State<MeetingNoteScreen> {
  late final TextEditingController _bodyController;
  late DateTime _meetingDate;

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isRecording = false; // 사용자가 켠 "연속 녹음" 상태
  String _liveText = '';     // 현재 말하는 중인(아직 확정 안 된) 텍스트

  bool get _isEditing => widget.meeting != null;

  @override
  void initState() {
    super.initState();
    _bodyController =
        TextEditingController(text: widget.meeting?.content ?? '');
    _meetingDate = widget.meeting?.meetingDate ?? DateTime.now();
  }

  @override
  void dispose() {
    _speech.stop();
    _bodyController.dispose();
    super.dispose();
  }

  // 연속 녹음 시작/정지 토글
  Future<void> _toggleRecording() async {
    if (_isRecording) {
      // 정지
      setState(() => _isRecording = false);
      await _speech.stop();
      return;
    }

    final available = await _speech.initialize(
      onStatus: (status) {
        // 한 세션이 끝나면(침묵으로 끊김) → 아직 녹음 모드면 자동 재시작
        if (status == 'done' || status == 'notListening') {
          if (_isRecording) {
            _startListeningSession();
          }
        }
      },
      onError: (err) {
        // 오류가 나도 녹음 모드면 다시 시도
        if (_isRecording) {
          _startListeningSession();
        }
      },
    );

    if (!available) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('마이크를 사용할 수 없습니다. 권한을 확인해주세요.')),
        );
      }
      return;
    }

    setState(() => _isRecording = true);
    _startListeningSession();
  }

  // 한 번의 인식 세션 시작
  void _startListeningSession() {
    _speech.listen(
      listenOptions: stt.SpeechListenOptions(localeId: 'ko_KR'),
      onResult: (result) {
        setState(() {
          if (result.finalResult) {
            // 확정된 문장 → 문단으로 본문에 추가
            final line = result.recognizedWords.trim();
            if (line.isNotEmpty) {
              final existing = _bodyController.text.trim();
              _bodyController.text =
                  existing.isEmpty ? line : '$existing\n\n$line';
              _bodyController.selection = TextSelection.fromPosition(
                TextPosition(offset: _bodyController.text.length),
              );
            }
            _liveText = '';
          } else {
            // 아직 말하는 중 → 미리보기만
            _liveText = result.recognizedWords;
          }
        });
      },
    );
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
    // 저장 전 녹음 중이면 멈춤
    if (_isRecording) {
      setState(() => _isRecording = false);
      await _speech.stop();
    }
    final content = _bodyController.text.trim();
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('회의 내용을 입력하거나 음성으로 기록해주세요.')),
      );
      return;
    }
    final appState = context.read<AppState>();
    if (_isEditing) {
      await appState.updateMeeting(widget.meeting!,
          content: content, meetingDate: _meetingDate);
    } else {
      await appState.addMeeting(content: content, meetingDate: _meetingDate);
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
          TextButton(onPressed: _save, child: const Text('저장')),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 회의 날짜
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
            // 녹음 상태 + 라이브 미리보기
            Row(
              children: [
                const Text('회의 내용',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const Spacer(),
                if (_isRecording)
                  const Text('● 녹음 중',
                      style: TextStyle(color: Colors.red, fontSize: 13)),
              ],
            ),
            if (_isRecording && _liveText.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('“$_liveText”',
                    style: const TextStyle(
                        color: Colors.grey, fontStyle: FontStyle.italic)),
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
                  hintText: '녹음 버튼을 누르면 말이 끊길 때마다 문단으로 나뉘어 기록됩니다.',
                ),
              ),
            ),
          ],
        ),
      ),
      // 큰 녹음 시작/정지 버튼
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _isRecording ? Colors.red : null,
        icon: Icon(_isRecording ? Icons.stop : Icons.mic),
        label: Text(_isRecording ? '정지' : '녹음 시작'),
        onPressed: _toggleRecording,
      ),
    );
  }
}
