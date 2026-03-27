import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/foundation.dart';

/// Configurable timing constants
const int navIntervalSeconds = 6;
const int objectRepeatCooldownSeconds = 3;
const int objectNavGapSeconds = 2;

/// Central speech coordinator that manages all TTS output.
///
/// Rules:
///  - Navigation speech: at most once every [navIntervalSeconds] seconds,
///    skipped if currently speaking or if object spoke recently.
///  - Object speech: higher priority, can interrupt nav speech,
///    but will NOT interrupt another object speech.
///  - General object cooldown: at most one object speech every
///    [objectRepeatCooldownSeconds] seconds (any message, not just same).
///  - No overlapping speech of the same priority.
class SpeechCoordinator {
  final FlutterTts _tts = FlutterTts();

  DateTime? lastNavSpoken;
  DateTime? lastObjectSpoken;
  String? lastObjectMessage;
  bool _voiceEnabled = true;

  // Speech state tracking
  bool _isSpeaking = false;
  String _currentSpeechType = ''; // 'nav' or 'object'

  bool get voiceEnabled => _voiceEnabled;
  bool get isSpeaking => _isSpeaking;

  Future<void> init() async {
    await _tts.setLanguage("en-US");
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
    await _tts.awaitSpeakCompletion(false);

    _tts.setCompletionHandler(() {
      _isSpeaking = false;
      _currentSpeechType = '';
    });
    _tts.setCancelHandler(() {
      _isSpeaking = false;
      _currentSpeechType = '';
    });
  }

  Future<void> dispose() async {
    await _tts.stop();
  }

  void setVoiceEnabled(bool enabled) {
    _voiceEnabled = enabled;
    if (!enabled) {
      _tts.stop();
      _isSpeaking = false;
      _currentSpeechType = '';
    }
  }

  /// Speak a navigation instruction.
  ///
  /// Skipped if:
  ///   - Currently speaking anything (won't interrupt)
  ///   - Within [navIntervalSeconds] of last nav speech
  ///   - Within [objectNavGapSeconds] of last object speech
  Future<void> speakNavigation(String text) async {
    if (!_voiceEnabled) return;
    if (text.trim().isEmpty) return;

    // Don't interrupt any ongoing speech
    if (_isSpeaking) {
      debugPrint("SpeechCoordinator: Skipping NAV - currently speaking ($_currentSpeechType)");
      return;
    }

    final now = DateTime.now();

    // Check nav cooldown
    if (lastNavSpoken != null &&
        now.difference(lastNavSpoken!).inSeconds < navIntervalSeconds) {
      debugPrint("SpeechCoordinator: Skipping NAV - cooldown active");
      return;
    }

    // Check gap after object speech
    if (lastObjectSpoken != null &&
        now.difference(lastObjectSpoken!).inSeconds < objectNavGapSeconds) {
      debugPrint("SpeechCoordinator: Skipping NAV - gap after object active");
      return;
    }

    debugPrint("SpeechCoordinator: Speaking NAV: $text");
    // Mark speaking BEFORE calling tts.speak to avoid race conditions
    _isSpeaking = true;
    _currentSpeechType = 'nav';
    lastNavSpoken = now;
    await _tts.speak(text);
  }

  /// Speak an object detection narrative.
  ///
  ///
  /// Equal priority to navigation — will NOT interrupt nav speech.
  /// Will NOT interrupt another object speech (let it finish).
  /// General cooldown: at most one object speech every [objectRepeatCooldownSeconds].
  Future<void> speakObject(String text) async {
    if (!_voiceEnabled) return;
    if (text.trim().isEmpty) return;

    final now = DateTime.now();

    // General cooldown — don't speak ANY object message within cooldown
    if (lastObjectSpoken != null &&
        now.difference(lastObjectSpoken!).inSeconds <
            objectRepeatCooldownSeconds) {
      debugPrint("SpeechCoordinator: Skipping OBJ - repeat cooldown");
      return;
    }

    // If currently speaking an object message, let it finish (don't interrupt)
    if (_isSpeaking && _currentSpeechType == 'object') {
      debugPrint("SpeechCoordinator: Skipping OBJ - already speaking object");
      return;
    }

    // If currently speaking nav, do NOT interrupt it
    if (_isSpeaking && _currentSpeechType == 'nav') {
      debugPrint("SpeechCoordinator: Skipping OBJ - already speaking NAV");
      return;
    }

    debugPrint("SpeechCoordinator: Speaking OBJ: $text");
    // Mark speaking BEFORE calling tts.speak to avoid race conditions
    _isSpeaking = true;
    _currentSpeechType = 'object';
    lastObjectSpoken = now;
    lastObjectMessage = text;
    await _tts.speak(text);
  }
}
