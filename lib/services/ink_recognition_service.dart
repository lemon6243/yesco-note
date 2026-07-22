// ============================================================
// InkRecognitionService (손글씨 → 텍스트 변환 서비스)
// ------------------------------------------------------------
// 우리 앱의 DrawnStroke 목록을 ML Kit의 Ink 형식으로 변환하고,
// 한국어 필기 인식 모델로 텍스트를 인식합니다.
//
// 주의: ML Kit에도 StrokePoint / Stroke 클래스가 있어서
//       우리 모델과 이름이 겹칩니다. 그래서 ML Kit 쪽은
//       'mlkit' 별칭으로 import 해서 충돌을 피합니다.
// ============================================================

import 'package:google_mlkit_digital_ink_recognition/google_mlkit_digital_ink_recognition.dart'
    as mlkit;
import '../models/drawn_stroke.dart';

class InkRecognitionService {
  // 한국어 모델. (BCP-47 코드)
  static const String _languageCode = 'ko';

  final mlkit.DigitalInkRecognizerModelManager _modelManager =
      mlkit.DigitalInkRecognizerModelManager();
  final mlkit.DigitalInkRecognizer _recognizer =
      mlkit.DigitalInkRecognizer(languageCode: _languageCode);

  // 모델이 없으면 다운로드. (최초 1회, 네트워크 필요)
  Future<bool> ensureModelDownloaded() async {
    final bool downloaded =
        await _modelManager.isModelDownloaded(_languageCode);
    if (downloaded) return true;
    return await _modelManager.downloadModel(_languageCode);
  }

  // DrawnStroke 목록 → 텍스트. 인식 실패/결과 없으면 null.
  Future<String?> recognize(List<DrawnStroke> strokes) async {
    if (strokes.isEmpty) return null;

    // 1) 모델 준비
    final ready = await ensureModelDownloaded();
    if (!ready) return null;

    // 2) DrawnStroke → ML Kit Ink 변환
    final ink = mlkit.Ink();
    final List<mlkit.Stroke> mlStrokes = [];

    // [수정된 부분] 획(Stroke)들이 동시에 그려진 것으로 인식되지 않도록
    // 전체 획에 대해 연속적으로 증가하는 타임스탬프를 적용합니다.
    int currentTimeMs = DateTime.now().millisecondsSinceEpoch;

    for (final s in strokes) {
      // 지우개 획(흰색)은 인식에서 제외
      if (s.colorValue == 0xFFFFFFFF) continue;
      if (s.points.length < 2) continue;

      final mlStroke = mlkit.Stroke();
      final List<mlkit.StrokePoint> pts = [];
      
      for (final p in s.points) {
        pts.add(mlkit.StrokePoint(
          x: p.x,
          y: p.y,
          t: currentTimeMs, 
        ));
        // 점과 점 사이의 시간 간격(10ms)
        currentTimeMs += 10; 
      }
      mlStroke.points = pts;
      mlStrokes.add(mlStroke);

      // 한 획(Stroke)이 끝나고 다음 획을 그릴 때까지의 시간 간격(100ms)
      currentTimeMs += 100;
    }

    if (mlStrokes.isEmpty) return null;
    ink.strokes = mlStrokes;

    // 3) 인식
    final candidates = await _recognizer.recognize(ink);
    if (candidates.isEmpty) return null;

    // 가장 유력한 후보 반환
    return candidates.first.text;
  }

  void dispose() {
    _recognizer.close();
  }
}
