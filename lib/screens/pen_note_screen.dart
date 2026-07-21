// ============================================================
// PenNoteScreen (손그림 노트 작성/편집 화면)
// ------------------------------------------------------------
// PenCanvas를 전체 화면으로 띄워 손그림을 그리고,
// 선택적으로 텍스트도 함께 붙여 생각노트로 저장합니다.
// note를 넘기면 기존 노트를 불러와 이어서 수정합니다.
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../models/note.dart';
import '../models/drawn_stroke.dart';
import '../widgets/pen_canvas.dart';

class PenNoteScreen extends StatefulWidget {
  final Note? note; // 편집할 노트 (null이면 새 노트)
  const PenNoteScreen({super.key, this.note});

  @override
  State<PenNoteScreen> createState() => _PenNoteScreenState();
}

class _PenNoteScreenState extends State<PenNoteScreen> {
  late List<DrawnStroke> _strokes;
  late final TextEditingController _textController;

  bool get _isEditing => widget.note != null;

  @override
  void initState() {
    super.initState();
    // 편집이면 기존 획을 불러오고, 새 노트면 빈 상태로 시작
    _strokes = widget.note?.penStrokes != null
        ? decodeStrokes(widget.note!.penStrokes)
        : [];
    // 편집이면 기존 텍스트를 불러옴. '(손그림 노트)'는 자동 라벨이므로 비움
    _textController = TextEditingController(
      text: (widget.note?.content == '(손그림 노트)')
          ? ''
          : (widget.note?.content ?? ''),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final text = _textController.text.trim();
    // 그림도 없고 글자도 없으면 저장하지 않음
    if (_strokes.isEmpty && text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('그림을 그리거나 내용을 적어주세요.')),
      );
      return;
    }
    final appState = context.read<AppState>();
    final content = text.isEmpty ? '(손그림 노트)' : text;
    final strokesJson = encodeStrokes(_strokes) ?? '[]';

    if (_isEditing) {
      // 편집: 기존 노트 갱신
      await appState.updateNotePen(widget.note!, content, strokesJson);
    } else {
      // 신규 저장
      await appState.addNote(content, penStrokesJson: strokesJson);
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? '손그림 노트 편집' : '손그림 노트'),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('저장'),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              // 선택 텍스트 입력
              TextField(
                controller: _textController,
                minLines: 1,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: '메모(선택) — 그림에 대한 설명을 적어도 됩니다',
                ),
              ),
              const SizedBox(height: 12),
              // 캔버스 (남은 공간 전부 사용, 편집이면 기존 획을 불러옴)
              Expanded(
                child: PenCanvas(
                  initialStrokes: _strokes,
                  onChanged: (strokes) => _strokes = strokes,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
