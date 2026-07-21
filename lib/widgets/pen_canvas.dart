// ============================================================
// PenCanvas (펜 그림 캔버스 — 재사용 위젯)
// ------------------------------------------------------------
// 손가락/스타일러스로 그림을 그리는 캔버스입니다.
// - 색상 선택, 굵기 조절, 지우개, 되돌리기, 전체 지우기
// - 획이 바뀔 때마다 onChanged로 현재 획 목록을 상위에 전달
// - initialStrokes로 이전에 저장한 그림을 이어서 편집 가능
// 저장·불러오기는 이 위젯을 쓰는 화면(생각노트 등)이 담당합니다.
// ============================================================

import 'package:flutter/material.dart';
import '../models/drawn_stroke.dart';

class PenCanvas extends StatefulWidget {
  final List<DrawnStroke> initialStrokes;
  final ValueChanged<List<DrawnStroke>> onChanged;
  final double height;

  const PenCanvas({
    super.key,
    this.initialStrokes = const [],
    required this.onChanged,
    this.height = 360,
  });

  @override
  State<PenCanvas> createState() => _PenCanvasState();
}

class _PenCanvasState extends State<PenCanvas> {
  late List<DrawnStroke> _strokes;
  List<StrokePoint> _currentPoints = [];

  // 팔레트와 현재 선택된 색·굵기
  static const List<Color> _palette = [
    Colors.black,
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.orange,
  ];
  Color _selectedColor = Colors.black;
  double _selectedWidth = 3.0;
  bool _eraserMode = false;

  @override
  void initState() {
    super.initState();
    // 원본을 건드리지 않도록 복사해서 시작
    _strokes = List<DrawnStroke>.from(widget.initialStrokes);
  }

  void _notify() => widget.onChanged(_strokes);

  void _startStroke(Offset p) {
    _currentPoints = [StrokePoint(p.dx, p.dy)];
  }

  void _appendPoint(Offset p) {
    setState(() {
      _currentPoints.add(StrokePoint(p.dx, p.dy));
    });
  }

  void _endStroke() {
    if (_currentPoints.length > 1) {
      _strokes.add(DrawnStroke(
        points: List<StrokePoint>.from(_currentPoints),
        colorValue: (_eraserMode ? Colors.white : _selectedColor).value,
        width: _eraserMode ? _selectedWidth * 4 : _selectedWidth,
      ));
      _notify();
    }
    _currentPoints = [];
  }

  void _undo() {
    if (_strokes.isEmpty) return;
    setState(() => _strokes.removeLast());
    _notify();
  }

  void _clearAll() {
    if (_strokes.isEmpty) return;
    setState(() => _strokes.clear());
    _notify();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ---- 도구 막대 ----
        Row(
          children: [
            // 색상 팔레트
            ..._palette.map((c) => GestureDetector(
                  onTap: () => setState(() {
                    _selectedColor = c;
                    _eraserMode = false;
                  }),
                  child: Container(
                    margin: const EdgeInsets.only(right: 6),
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: c,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: (!_eraserMode && _selectedColor == c)
                            ? Colors.blueAccent
                            : Colors.grey.withValues(alpha: 0.4),
                        width: (!_eraserMode && _selectedColor == c) ? 3 : 1,
                      ),
                    ),
                  ),
                )),
            const Spacer(),
            // 지우개
            IconButton(
              icon: Icon(
                Icons.auto_fix_normal,
                color: _eraserMode ? Colors.blueAccent : null,
              ),
              tooltip: '지우개',
              onPressed: () => setState(() => _eraserMode = !_eraserMode),
            ),
            // 되돌리기
            IconButton(
              icon: const Icon(Icons.undo),
              tooltip: '되돌리기',
              onPressed: _undo,
            ),
            // 전체 지우기
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: '전체 지우기',
              onPressed: _clearAll,
            ),
          ],
        ),
        // ---- 굵기 슬라이더 ----
        Row(
          children: [
            const Icon(Icons.line_weight, size: 18),
            Expanded(
              child: Slider(
                min: 1,
                max: 12,
                value: _selectedWidth,
                onChanged: (v) => setState(() => _selectedWidth = v),
              ),
            ),
            SizedBox(
              width: 28,
              child: Text('${_selectedWidth.round()}',
                  style: const TextStyle(fontSize: 12)),
            ),
          ],
        ),
        // ---- 그리는 영역 ----
        Container(
          height: widget.height,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey.withValues(alpha: 0.4)),
            borderRadius: BorderRadius.circular(8),
          ),
          clipBehavior: Clip.antiAlias,
          child: Listener(
            onPointerDown: (e) => _startStroke(e.localPosition),
            onPointerMove: (e) => _appendPoint(e.localPosition),
            onPointerUp: (e) => _endStroke(),
            child: CustomPaint(
              painter: _CanvasPainter(
                strokes: _strokes,
                currentPoints: _currentPoints,
                currentColor: _eraserMode ? Colors.white : _selectedColor,
                currentWidth:
                    _eraserMode ? _selectedWidth * 4 : _selectedWidth,
              ),
              size: Size.infinite,
            ),
          ),
        ),
      ],
    );
  }
}

// 실제 그림을 그리는 페인터
class _CanvasPainter extends CustomPainter {
  final List<DrawnStroke> strokes;
  final List<StrokePoint> currentPoints;
  final Color currentColor;
  final double currentWidth;

  _CanvasPainter({
    required this.strokes,
    required this.currentPoints,
    required this.currentColor,
    required this.currentWidth,
  });

  void _drawPoints(
    Canvas canvas,
    List<StrokePoint> pts,
    Color color,
    double width,
  ) {
    if (pts.length < 2) return;
    final paint = Paint()
      ..color = color
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final path = Path()..moveTo(pts.first.x, pts.first.y);
    for (int i = 1; i < pts.length; i++) {
      path.lineTo(pts[i].x, pts[i].y);
    }
    canvas.drawPath(path, paint);
  }

  @override
  void paint(Canvas canvas, Size size) {
    // 저장된 획들
    for (final s in strokes) {
      _drawPoints(canvas, s.points, s.color, s.width);
    }
    // 지금 그리는 중인 획
    _drawPoints(canvas, currentPoints, currentColor, currentWidth);
  }

  @override
  bool shouldRepaint(_CanvasPainter old) => true;
}
