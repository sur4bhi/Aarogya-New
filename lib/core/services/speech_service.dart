import 'package:speech_to_text/speech_to_text.dart' as stt;

class SpeechService {
  static final stt.SpeechToText _speech = stt.SpeechToText();
  static bool _available = false;

  static Future<bool> ensureInitialized({String? localeId}) async {
    if (_available) return true;
    _available = await _speech.initialize(
      onError: (e) {},
      onStatus: (s) {},
      debugLogging: false,
    );
    return _available;
  }

  static Future<String?> listenOnce({String? localeId, Duration timeout = const Duration(seconds: 6)}) async {
    final ok = await ensureInitialized(localeId: localeId);
    if (!ok) return null;

    String? result;
    await _speech.listen(
      localeId: localeId,
      listenFor: timeout,
      pauseFor: const Duration(seconds: 2),
      onResult: (res) {
        if (res.finalResult) {
          result = res.recognizedWords;
        }
      },
    );
    await Future.delayed(timeout + const Duration(milliseconds: 300));
    await _speech.stop();
    return result;
  }
}
