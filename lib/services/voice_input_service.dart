import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';

/// Voice input service using speech recognition
class VoiceInputService extends ChangeNotifier {
  final stt.SpeechToText _speech = stt.SpeechToText();
  
  bool _isAvailable = false;
  bool _isListening = false;
  String _lastWords = '';
  double _confidence = 0.0;

  bool get isAvailable => _isAvailable;
  bool get isListening => _isListening;
  String get lastWords => _lastWords;
  double get confidence => _confidence;

  /// Initialize speech recognition
  Future<bool> initialize() async {
    try {
      // Check and request microphone permission
      final status = await Permission.microphone.request();
      if (!status.isGranted) {
        debugPrint('Microphone permission denied');
        return false;
      }

      _isAvailable = await _speech.initialize(
        onStatus: (status) {
          debugPrint('Speech recognition status: $status');
          if (status == 'done' || status == 'notListening') {
            _isListening = false;
            notifyListeners();
          }
        },
        onError: (error) {
          debugPrint('Speech recognition error: $error');
          _isListening = false;
          notifyListeners();
        },
      );

      return _isAvailable;
    } catch (e) {
      debugPrint('Error initializing speech recognition: $e');
      return false;
    }
  }

  /// Start listening
  Future<void> startListening({
    required Function(String) onResult,
  }) async {
    if (!_isAvailable) {
      final initialized = await initialize();
      if (!initialized) {
        throw Exception('Speech recognition not available');
      }
    }

    _lastWords = '';
    _confidence = 0.0;
    _isListening = true;
    notifyListeners();

    await _speech.listen(
      onResult: (result) {
        _lastWords = result.recognizedWords;
        _confidence = result.confidence;
        
        if (result.finalResult) {
          onResult(_lastWords);
          _isListening = false;
        }
        notifyListeners();
      },
      listenMode: stt.ListenMode.confirmation,
      cancelOnError: true,
      partialResults: true,
    );
  }

  /// Stop listening
  Future<void> stopListening() async {
    if (_isListening) {
      await _speech.stop();
      _isListening = false;
      notifyListeners();
    }
  }

  /// Cancel listening
  Future<void> cancelListening() async {
    if (_isListening) {
      await _speech.cancel();
      _isListening = false;
      _lastWords = '';
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _speech.cancel();
    super.dispose();
  }
}
