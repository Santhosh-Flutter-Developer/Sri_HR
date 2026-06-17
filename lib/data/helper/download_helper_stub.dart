import 'dart:typed_data';

/// No-op stub for non-web platforms.
/// On mobile/desktop, [AttendanceExportService] uses path_provider + open_file
/// so this function is never called.
void triggerWebDownload({
  required Uint8List bytes,
  required String filename,
  required String mimeType,
}) {
  // intentionally empty — non-web builds never call this
}