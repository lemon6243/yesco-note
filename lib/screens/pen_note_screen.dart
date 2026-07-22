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
  
  // 로딩 상태 변수들
  bool _isLoading = false;
  String _loadingText = ''; // 현재 어떤 작업 중인지 표시

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
    
    // 모델 다운로드 상태 먼저 표시
    setState(() {
      _isLoading = true;
      _loadingText = '언어 모델 확인 중...';
    });

    try {
      // 1) 모델 다운로드 (첫 실행 시 20~30MB 다운로드)
      final ready = await _inkService.ensureModelDownloaded();
      if (!mounted) return;
      if (!ready) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('언어 모델을 다운로드할 수 없습니다. 인터넷 연결을 확인해주세요.')),
        );
        return;
      }

      // 2) 실제 인식 상태로 텍스트 변경
      setState(() {
        _loadingText = '필기 인식 중...';
      });

      // 3) 텍스트 변환 실행
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
            existing.isEmpty ? text : '$existing\n$text'; // 줄바꿈 추가해서 더 깔끔하게
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
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadingText = '';
        });
      }
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
          // 로딩 중일 때 로딩 인디케이터, 아닐 때 버튼
          _isLoading
              ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _loadingText,
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : TextButton(
                  onPressed: _convertToText,
                  child: const Text('텍스트로'),
                ),
          TextButton(
            onPressed: _isLoading ? null : _save, // 로딩 중에는 저장 버튼 비활성화
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
                child: Stack(
                  children: [
                    PenCanvas(
                      initialStrokes: _strokes,
                      onChanged: (strokes) => _strokes = strokes,
                    ),
                    
                    // 로딩 중일 때 화면 중앙에도 반투명한 로딩창 표시 (선택사항, 사용성을 위해 추가)
                    if (_isLoading)
                      Container(
                        color: Colors.black.withOpacity(0.1), // 캔버스 터치 방지용 반투명 막
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const CircularProgressIndicator(),
                                const SizedBox(height: 16),
                                Text(_loadingText, style: const TextStyle(fontWeight: FontWeight.bold)),
                                if (_loadingText.contains('모델'))
                                  const Padding(
                                    padding: EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      '최초 1회 약 30MB를 다운로드합니다.',
                                      style: TextStyle(fontSize: 12, color: Colors.grey),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
