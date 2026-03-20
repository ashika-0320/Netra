import 'package:flutter_tts/flutter_tts.dart';
import '../depth_services/detect_json.dart';

class SpeechCoordinator {
  static final SpeechCoordinator _instance = SpeechCoordinator._internal();
  factory SpeechCoordinator() => _instance;
  SpeechCoordinator._internal();

  final FlutterTts _tts = FlutterTts();

  // Configurable Constants
  static const int NAV_COOLDOWN_SECONDS = 8;
  static const int OBJECT_REPEAT_COOLDOWN_SECONDS = 4;
  static const int OBJECT_BLOCK_NAV_SECONDS = 2;
  static const int NAV_PROTECTION_SECONDS = 4; // Time to protect nav speech from basic objects

  String? lastObjectMessage;
  DateTime? lastObjectSpoken;
  DateTime? lastNavSpoken;
  DateTime? lastNavStarted;

  bool _isSpeaking = false;
  bool get isSpeaking => _isSpeaking;

  // Optional: callbacks when speaking state changes
  void Function()? onSpeakingStarted;
  void Function()? onSpeakingStopped;

  Future<void> init() async {
    await _tts.setLanguage("en-US");
    await _tts.setSpeechRate(0.5);
    await _tts.setPitch(1.0);
    await _tts.awaitSpeakCompletion(true);
    
    _tts.setStartHandler(() {
      _isSpeaking = true;
      if (onSpeakingStarted != null) onSpeakingStarted!();
    });
    
    _tts.setCompletionHandler(() {
      _isSpeaking = false;
      if (onSpeakingStopped != null) onSpeakingStopped!();
    });
  }

  Future<void> stop() async {
    await _tts.stop();
  }

  Future<void> handleObjectMessage(String message, {List<Detection> detections = const []}) async {
    if (message.trim().isEmpty) return;

    final now = DateTime.now();

    // Determine if dangerous
    bool isDangerous = false;
    for (var det in detections) {
      if (det.depthBucket == "very_close" ||
          (det.depthBucket == "close" && det.direction == "centre") ||
          det.label == "unknown_obstacle") {
        isDangerous = true;
        break;
      }
    }

    // ABSOLUTE PROTECTION FOR NAVIGATION: Let Navigation finish its sentence!
    // No object (even dangerous) can cut off Navigation mid-sentence during its 4-second window.
    if (lastNavStarted != null) {
      if (now.difference(lastNavStarted!).inSeconds < NAV_PROTECTION_SECONDS) {
        return; 
      }
    }

    // Generic cooldown against ALL object messages to prevent 0ms API jitter spam stuttering TTS
    if (lastObjectSpoken != null) {
      final diff = now.difference(lastObjectSpoken!).inSeconds;
      
      if (isDangerous) {
        // Dangerous objects can speak more often, but give an absolute minimum 2-second 
        // gap so they don't stutter TTs into oblivion if testing stationary at 0ms.
        if (diff < 2) return;
      } else {
        // Non-dangerous objects wait 4 seconds.
        if (diff < OBJECT_REPEAT_COOLDOWN_SECONDS) return;
      }
    }

    // Otherwise speak
    await stop();
    await _speakObject(message, now);
  }

  Future<void> _speakObject(String message, DateTime now) async {
    lastObjectMessage = message;
    lastObjectSpoken = now;
    await _tts.speak(message);
  }

  Future<bool> handleNavigationInstruction(String instruction, {bool force = false}) async {
    if (instruction.trim().isEmpty) return false;
    
    final now = DateTime.now();

    // BLOCK navigation if: object was spoken within last ~2 seconds
    if (lastObjectSpoken != null) {
      if (now.difference(lastObjectSpoken!).inSeconds < OBJECT_BLOCK_NAV_SECONDS) {
        return false; 
      }
    }

    // Navigation cooldown: wait ~8s since last nav instruction
    if (!force && lastNavSpoken != null) {
      if (now.difference(lastNavSpoken!).inSeconds < NAV_COOLDOWN_SECONDS) {
        return false;
      }
    }

    // Allowed: speak navigation instruction safely!
    await stop();
    lastNavSpoken = now;
    lastNavStarted = now; 
    await _tts.speak(instruction);
    return true;
  }
}
