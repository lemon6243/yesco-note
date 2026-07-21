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
  const PenNoteScreen({super.key});

  @override
  State<PenNoteScreen> createState() => _PenNoteScreenState();
}

class _PenNoteScreenState extends State<PenNoteScreen> {
  List<DrawnStroke> _strokes = [];
  final _textController = TextEditingController();

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
    await appState.addNote(
      text.isEmpty ? '(손그림 노트)' : text,
      penStrokesJson: encodeStrokes(_strokes),
    );
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
