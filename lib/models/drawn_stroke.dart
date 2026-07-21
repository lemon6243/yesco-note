// ============================================================
// DrawnStroke / StrokePoint (펜 획 데이터 — 순수 Dart 모델)
// ------------------------------------------------------------
// 펜으로 그린 그림을 "획(stroke)들의 목록"으로 표현합니다.
// 한 획 = 점(point)들의 연속 + 색상 + 굵기.
// Hive에 직접 저장하지 않고, JSON 문자열로 바꿔서
// Note.penStrokes(String?) 한 칸에 통째로 저장합니다.
// 나중에 손글씨 인식(ML Kit)에 넘길 때도 이 좌표를 재사용합니다.
// ============================================================

import 'dart:convert';
import 'package:flutter/material.dart';

// 획을 이루는 한 점 (캔버스 좌표)
class StrokePoint {
  final double x;
  final double y;

  const StrokePoint(this.x, this.y);

  Map<String, dynamic> toJson() => {'x': x, 'y': y};

  factory StrokePoint.fromJson(Map<String, dynamic> json) =>
      StrokePoint(
        (json['x'] as num).toDouble(),
        (json['y'] as num).toDouble(),
      );
}

// 한 획 (점들의 연속 + 색 + 굵기)
class DrawnStroke {
  final List<StrokePoint> points;
  final int colorValue; // Color.value (ARGB 정수)
  final double width;

  DrawnStroke({
    required this.points,
    required this.colorValue,
    required this.width,
  });

  Color get color => Color(colorValue);

  Map<String, dynamic> toJson() => {
        'color': colorValue,
        'width': width,
        'points': points.map((p) => p.toJson()).toList(),
      };

  factory DrawnStroke.fromJson(Map<String, dynamic> json) => DrawnStroke(
        colorValue: json['color'] as int,
        width: (json['width'] as num).toDouble(),
        points: (json['points'] as List)
            .map((e) => StrokePoint.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

// ---- 전체 그림(획 목록) ↔ JSON 문자열 변환 헬퍼 ----

// 획 목록을 저장용 JSON 문자열로 변환. 비어 있으면 null 반환.
String? encodeStrokes(List<DrawnStroke> strokes) {
  if (strokes.isEmpty) return null;
  return jsonEncode(strokes.map((s) => s.toJson()).toList());
}

// 저장된 JSON 문자열을 획 목록으로 복원. null/빈값이면 빈 목록.
List<DrawnStroke> decodeStrokes(String? raw) {
  if (raw == null || raw.trim().isEmpty) return [];
  final decoded = jsonDecode(raw) as List;
  return decoded
      .map((e) => DrawnStroke.fromJson(e as Map<String, dynamic>))
      .toList();
}
