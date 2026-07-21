// ============================================================
// PenNoteScreen (손그림 노트 작성 화면)
// ------------------------------------------------------------
// PenCanvas를 전체 화면으로 띄워 손그림을 그리고,
// 선택적으로 텍스트도 함께 붙여 생각노트로 저장합니다.
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../models/drawn_stroke.dart';
import '../widgets/pen_canvas.dart';

class PenNoteScreen extends StatefulWidget {
  final Note? note;   // 편집할 노트 (null이면 새 노트)
  const PenNoteScreen({super.key, this.note});

  @override
  State<PenNoteScreen> createState() => _PenNoteScreenState();
}

class _PenNoteScreenState extends State<PenNoteScreen> {
  late List<DrawnStroke> _strokes;
  late final TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    // 편집이면 기존 획/텍스트를 불러옴
    _strokes = widget.note?.penStrokes != null
        ? decodeStrokes(widget.note!.penStrokes)
        : [];
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
    if (_strokes.isEmpty && text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('그림을 그리거나 내용을 적어주세요.')),
      );
      return;
    }
    final appState = context.read<AppState>();
    final content = text.isEmpty ? '(손그림 노트)' : text;
    final strokesJson = encodeStrokes(_strokes);

    if (widget.note != null) {
      // 편집: 기존 노트 갱신
      await appState.updateNotePen(widget.note!, content, strokesJson);
    } else {
      // 신규
      await appState.addNote(content, penStrokesJson: strokesJson);
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('손그림 노트'),
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
              // 캔버스 (남은 공간 전부 사용)
              Expanded(
                child: PenCanvas(
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
