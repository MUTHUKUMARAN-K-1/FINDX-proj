import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:speech_to_text/speech_recognition_result.dart';

/// Service for speech-to-text functionality
class SpeechService {
  static final SpeechService _instance = SpeechService._internal();
  factory SpeechService() => _instance;
  SpeechService._internal();

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isInitialized = false;
  bool _isListening = false;
  String _lastWords = '';
  String _currentLocaleId = 'en_US';

  bool get isListening => _isListening;
  bool get isInitialized => _isInitialized;
  String get lastWords => _lastWords;

  /// Initialize the speech recognition service
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      _isInitialized = await _speech.initialize(
        onStatus: (status) {
          print('🎤 Speech status: $status');
          _isListening = status == 'listening';
        },
        onError: (error) {
          print('🎤 Speech error: ${error.errorMsg}');
          _isListening = false;
        },
      );

      if (_isInitialized) {
        // Get available locales
        final locales = await _speech.locales();
        print(
          '🎤 Available locales: ${locales.map((l) => l.localeId).join(', ')}',
        );

        // Try to find a suitable locale
        final enLocale = locales.firstWhere(
          (l) => l.localeId.startsWith('en'),
          orElse: () => locales.isNotEmpty
              ? locales.first
              : stt.LocaleName('en_US', 'English'),
        );
        _currentLocaleId = enLocale.localeId;
        print('🎤 Using locale: $_currentLocaleId');
      }

      print('🎤 Speech initialized: $_isInitialized');
      return _isInitialized;
    } catch (e) {
      print('🎤 Speech init error: $e');
      return false;
    }
  }

  /// Start listening for speech
  Future<void> startListening({
    required Function(String text) onResult,
    Function(String text)? onPartialResult,
  }) async {
    if (!_isInitialized) {
      final success = await initialize();
      if (!success) {
        print('🎤 Failed to initialize speech');
        return;
      }
    }

    if (_isListening) {
      print('🎤 Already listening');
      return;
    }

    _lastWords = '';
    _isListening = true;

    try {
      await _speech.listen(
        onResult: (SpeechRecognitionResult result) {
          _lastWords = result.recognizedWords;
          print(
            '🎤 Recognized: ${result.recognizedWords} (final: ${result.finalResult})',
          );

          if (result.finalResult) {
            onResult(result.recognizedWords);
          } else if (onPartialResult != null) {
            onPartialResult(result.recognizedWords);
          }
        },
        localeId: _currentLocaleId,
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        cancelOnError: true,
        listenMode: stt.ListenMode.dictation,
      );
      print('🎤 Started listening...');
    } catch (e) {
      print('🎤 Listen error: $e');
      _isListening = false;
    }
  }

  /// Stop listening
  Future<void> stopListening() async {
    if (!_isListening) return;

    try {
      await _speech.stop();
      _isListening = false;
      print('🎤 Stopped listening');
    } catch (e) {
      print('🎤 Stop error: $e');
    }
  }

  /// Cancel listening
  Future<void> cancelListening() async {
    try {
      await _speech.cancel();
      _isListening = false;
      _lastWords = '';
      print('🎤 Cancelled listening');
    } catch (e) {
      print('🎤 Cancel error: $e');
    }
  }

  /// Check if speech recognition is available
  Future<bool> isAvailable() async {
    if (!_isInitialized) {
      return await initialize();
    }
    return _isInitialized;
  }
}
