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
import '../services/ink_recognition_service.dart';


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

  final InkRecognitionService _inkService = InkRecognitionService();
  bool _recognizing = false;

  @override
  void dispose() {
    _textController.dispose();
    _inkService.dispose();
    super.dispose();
  }

  Future<void> _convertToText() async {
    if (_strokes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('먼저 손글씨를 써주세요.')),
      );
      return;
    }
    setState(() => _recognizing = true);
    try {
      final text = await _inkService.recognize(_strokes);
      if (!mounted) return;
      if (text == null || text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('글씨를 인식하지 못했어요. 더 또박또박 써보세요.')),
        );
      } else {
        // 인식 결과를 메모창에 채움 (기존 내용 뒤에 붙임)
        final existing = _textController.text.trim();
        _textController.text =
            existing.isEmpty ? text : '$existing $text';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('인식됨: $text')),
        );
      }
    } catch (e, st) {
      debugPrint('필기인식 오류: $e');
      debugPrint('스택: $st');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('인식 오류: $e')),
      );
    } finally {
      if (mounted) setState(() => _recognizing = false);
    }
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
          // 손글씨 → 텍스트 변환
          _recognizing
              ? const Padding(
                  padding: EdgeInsets.all(14),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : TextButton(
                  onPressed: _convertToText,
                  child: const Text('텍스트로'),
                ),
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
