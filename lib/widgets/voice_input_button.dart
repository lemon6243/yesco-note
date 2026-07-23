import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

/// 어디서든 재사용하는 음성 입력 마이크 버튼.
/// 인식된 텍스트를 onResult 콜백으로 넘겨줍니다.
class VoiceInputButton extends StatefulWidget {
  /// 인식 결과를 받아서 처리 (예: 컨트롤러에 추가)
  final void Function(String recognizedText) onResult;

  /// true면 말할 때마다 누적, false면 최종 결과만 (기본 누적)
  final bool appendMode;

  const VoiceInputButton({
    super.key,
    required this.onResult,
    this.appendMode = true,
  });

  @override
  State<VoiceInputButton> createState() => _VoiceInputButtonState();
}

class _VoiceInputButtonState extends State<VoiceInputButton> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;

  Future<void> _toggle() async {
    if (_isListening) {
      await _speech.stop();
      if (mounted) setState(() => _isListening = false);
      return;
    }

    final available = await _speech.initialize(
      onStatus: (status) {
        // 인식이 끝나거나 멈추면 아이콘 원상복구
        if (status == 'done' || status == 'notListening') {
          if (mounted) setState(() => _isListening = false);
        }
      },
      onError: (err) {
        if (mounted) {
          setState(() => _isListening = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('음성 인식 오류: ${err.errorMsg}')),
          );
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

    if (mounted) setState(() => _isListening = true);
    _speech.listen(
      listenOptions: stt.SpeechListenOptions(localeId: 'ko_KR'),
      onResult: (result) {
        if (result.finalResult) {
          widget.onResult(result.recognizedWords);
        }
      },
    );
  }

  @override
  void dispose() {
    _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        _isListening ? Icons.mic : Icons.mic_none,
        color: _isListening ? Colors.red : Colors.grey,
      ),
      onPressed: _toggle,
      tooltip: '음성으로 입력',
    );
  }
}
