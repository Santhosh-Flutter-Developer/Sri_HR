class WorkShiftModel {
  final String id;
  final String companyId;
  final String workStartTime; // e.g. "09:00"
  final String workEndTime;   // e.g. "18:00"
  final String? lunchStartTime; // e.g. "13:00"
  final String? lunchEndTime;   // e.g. "14:00"
  final DateTime createdAt;

  WorkShiftModel({
    required this.id,
    required this.companyId,
    required this.workStartTime,
    required this.workEndTime,
    this.lunchStartTime,
    this.lunchEndTime,
    required this.createdAt,
  });

  /// Normalises a Supabase `time` value (e.g. "09:00:00" or "09:00") to "HH:mm".
  static String _normaliseTime(String? raw, String fallback) {
    if (raw == null || raw.isEmpty) return fallback;
    final parts = raw.split(':');
    if (parts.length < 2) return fallback;
    return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}';
  }

  static String? _normaliseTimeNullable(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final parts = raw.split(':');
    if (parts.length < 2) return null;
    return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}';
  }

  factory WorkShiftModel.fromJson(Map<String, dynamic> j) => WorkShiftModel(
        id: (j['id'] as String?) ?? '',
        companyId: (j['company_id'] as String?) ?? '',
        workStartTime: _normaliseTime(j['work_start_time'] as String?, '09:00'),
        workEndTime: _normaliseTime(j['work_end_time'] as String?, '18:00'),
        lunchStartTime: _normaliseTimeNullable(j['lunch_start_time'] as String?),
        lunchEndTime: _normaliseTimeNullable(j['lunch_end_time'] as String?),
        createdAt: j['created_at'] != null
            ? (DateTime.tryParse(j['created_at'] as String) ?? DateTime.now())
            : DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'company_id': companyId,
        'work_start_time': workStartTime,
        'work_end_time': workEndTime,
        'lunch_start_time': lunchStartTime,
        'lunch_end_time': lunchEndTime,
      };

  /// Expected working minutes (excluding lunch break)
  int get expectedWorkMinutes {
    final start = _timeToMins(workStartTime);
    final end = _timeToMins(workEndTime);
    int workMins = end - start;
    if (lunchStartTime != null && lunchEndTime != null) {
      final ls = _timeToMins(lunchStartTime!);
      final le = _timeToMins(lunchEndTime!);
      workMins -= (le - ls);
    }
    return workMins > 0 ? workMins : 0;
  }

  /// Shift display string e.g. "09:00 AM - 06:00 PM"
  String get shiftDisplay => '${_to12h(workStartTime)} - ${_to12h(workEndTime)}';

  /// Lunch display string e.g. "01:00 PM - 02:00 PM"
  String? get lunchDisplay =>
      (lunchStartTime != null && lunchEndTime != null)
          ? '${_to12h(lunchStartTime!)} - ${_to12h(lunchEndTime!)}'
          : null;

  static int _timeToMins(String t) {
    final parts = t.split(':');
    if (parts.length < 2) return 0;
    return int.tryParse(parts[0])! * 60 + int.tryParse(parts[1])!;
  }

  static String _to12h(String t) {
    final parts = t.split(':');
    if (parts.length < 2) return t;
    int h = int.tryParse(parts[0]) ?? 0;
    final m = parts[1];
    final ampm = h < 12 ? 'AM' : 'PM';
    if (h == 0) h = 12;
    if (h > 12) h -= 12;
    return '${h.toString().padLeft(2, '0')}:$m $ampm';
  }

  WorkShiftModel copyWith({
    String? workStartTime,
    String? workEndTime,
    String? lunchStartTime,
    String? lunchEndTime,
  }) => WorkShiftModel(
        id: id,
        companyId: companyId,
        workStartTime: workStartTime ?? this.workStartTime,
        workEndTime: workEndTime ?? this.workEndTime,
        lunchStartTime: lunchStartTime ?? this.lunchStartTime,
        lunchEndTime: lunchEndTime ?? this.lunchEndTime,
        createdAt: createdAt,
      );
}