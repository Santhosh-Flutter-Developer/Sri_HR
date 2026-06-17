// lib/data/services/attendance_audio_service.dart
//
// Plays TTS audio for every message shown during face attendance.
// Language is driven by the company's notification_language ('en' or 'ta').

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

enum AttendanceAudioEvent {
  // ── Success ───────────────────────────────────────────────
  verificationSuccess,
  punchInSuccess,
  punchOutSuccess,

  // ── Warnings ──────────────────────────────────────────────
  multipleFaceDetected,
  faceNotRegistered,
  noFaceMatched,
  outsideOffice,
  configureLocation,

  // ── Errors ────────────────────────────────────────────────
  gpsUnavailable,
  employeeNotFound,
  punchFailed,
  invalidLicense,
  licenseExpired,
  notActivated,
  initError,
}

class AttendanceAudioService {
  static final AttendanceAudioService _instance =
      AttendanceAudioService._internal();
  factory AttendanceAudioService() => _instance;
  AttendanceAudioService._internal();

  final FlutterTts _tts = FlutterTts();

  // ── TTS locale codes ──────────────────────────────────────
  static const _locale = {'en': 'en-IN', 'ta': 'ta-IN'};

  // ── All messages in English and Tamil ────────────────────
  static const Map<AttendanceAudioEvent, Map<String, String>> _messages = {
    // Success
    AttendanceAudioEvent.verificationSuccess: {
      'en': 'Verification Successful',
      'ta': 'சரிபார்ப்பு வெற்றிகரமாக முடிந்தது',
    },
    AttendanceAudioEvent.punchInSuccess: {
      'en': 'Punch In recorded successfully',
      'ta': 'வருகை பதிவு செய்யப்பட்டது',
    },
    AttendanceAudioEvent.punchOutSuccess: {
      'en': 'Punch Out recorded successfully',
      'ta': 'வெளியேற்றம் பதிவு செய்யப்பட்டது',
    },

    // Warnings
    AttendanceAudioEvent.multipleFaceDetected: {
      'en': 'Multiple faces detected. Please ensure only one face is visible',
      'ta':
          'பல முகங்கள் கண்டறியப்பட்டன. ஒரே ஒரு முகம் மட்டும் இருக்கும்படி பார்க்கவும்',
    },
    AttendanceAudioEvent.faceNotRegistered: {
      'en': 'Face not registered. Please contact your administrator',
      'ta': 'முகம் பதிவு செய்யப்படவில்லை. நிர்வாகியை தொடர்பு கொள்ளவும்',
    },
    AttendanceAudioEvent.noFaceMatched: {
      'en': 'Face not recognized. Please try again',
      'ta': 'முகம் அங்கீகரிக்கப்படவில்லை. மீண்டும் முயற்சிக்கவும்',
    },
    AttendanceAudioEvent.outsideOffice: {
      'en': 'You are outside the office location',
      'ta': 'நீங்கள் அலுவலக இடத்திற்கு வெளியே இருக்கிறீர்கள்',
    },
    AttendanceAudioEvent.configureLocation: {
      'en': 'Office location not configured. Please contact your administrator',
      'ta': 'அலுவலக இடம் அமைக்கப்படவில்லை. நிர்வாகியை தொடர்பு கொள்ளவும்',
    },

    // Errors
    AttendanceAudioEvent.gpsUnavailable: {
      'en':
          'Unable to get location. Please enable location services and try again',
      'ta': 'இடம் கிடைக்கவில்லை. இட சேவைகளை இயக்கி மீண்டும் முயற்சிக்கவும்',
    },
    AttendanceAudioEvent.employeeNotFound: {
      'en': 'Employee record not found. Please contact your administrator',
      'ta': 'பணியாளர் பதிவு கிடைக்கவில்லை. நிர்வாகியை தொடர்பு கொள்ளவும்',
    },
    AttendanceAudioEvent.punchFailed: {
      'en': 'Failed to record attendance. Please try again',
      'ta': 'வருகையை பதிவு செய்வதில் தோல்வி. மீண்டும் முயற்சிக்கவும்',
    },
    AttendanceAudioEvent.invalidLicense: {
      'en': 'Invalid license. Please contact your administrator',
      'ta': 'தவறான உரிமம். நிர்வாகியை தொடர்பு கொள்ளவும்',
    },
    AttendanceAudioEvent.licenseExpired: {
      'en': 'License expired. Please contact your administrator',
      'ta': 'உரிமம் காலாவதியானது. நிர்வாகியை தொடர்பு கொள்ளவும்',
    },
    AttendanceAudioEvent.notActivated: {
      'en': 'System not activated. Please contact your administrator',
      'ta': 'கணினி செயல்படுத்தப்படவில்லை. நிர்வாகியை தொடர்பு கொள்ளவும்',
    },
    AttendanceAudioEvent.initError: {
      'en': 'System initialization failed. Please restart the application',
      'ta': 'கணினி தொடக்கம் தோல்வியடைந்தது. பயன்பாட்டை மறுதொடக்கம் செய்யவும்',
    },
  };

  Future<void> _init(String lang) async {
    try {
      final locale = _locale[lang] ?? 'en-IN';
      await _tts.setLanguage(locale);
      await _tts.setSpeechRate(0.45);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
    } catch (e) {
      debugPrint('[AttendanceAudio] init error: $e');
    }
  }

  /// Play audio for the given event in the given language ('en' or 'ta').
  Future<void> play(AttendanceAudioEvent event, String lang) async {
    try {
      final effectiveLang = (lang == 'ta') ? 'ta' : 'en';
      await _init(effectiveLang);
      final text =
          _messages[event]?[effectiveLang] ?? _messages[event]?['en'] ?? '';
      if (text.isEmpty) return;
      await _tts.stop();
       final locale = _locale[effectiveLang] ?? 'en-IN';
    await _tts.setLanguage(locale);
    await _tts.setSpeechRate(0.45);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
      await _tts.speak(text);
    } catch (e) {
      debugPrint('[AttendanceAudio] play error: $e');
    }
  }

  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {}
  }

  void dispose() => _tts.stop();
}
