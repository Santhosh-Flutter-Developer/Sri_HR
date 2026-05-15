import 'package:ntp/ntp.dart';

class NetworkTime {
  static DateTime? _serverTime;
  static DateTime? _deviceTimeAtSync;

  /// Call this once (init)
  static Future<void> syncTime() async {
    try {
      _serverTime = await NTP.now();
      _deviceTimeAtSync = DateTime.now();
    } catch (e) {
      _serverTime = DateTime.now(); // fallback
      _deviceTimeAtSync = DateTime.now();
    }
  }

  /// Use this everywhere instead of DateTime.now()
  static DateTime now() {
    if (_serverTime == null || _deviceTimeAtSync == null) {
      return DateTime.now(); // fallback safety
    }

    final diff = DateTime.now().difference(_deviceTimeAtSync!);
    return _serverTime!.add(diff);
  }
}