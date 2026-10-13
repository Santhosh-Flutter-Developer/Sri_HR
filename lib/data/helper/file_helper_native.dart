import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

Future<void> writeFileBytes(String path, Uint8List bytes) async {
  await File(path).writeAsBytes(bytes, flush: true);
}

/// Writes the file to the app's own temp directory (needs no storage
/// permission on Android or iOS), then triggers the OS share/save sheet
/// so the user can save it to Downloads, Files, Drive, etc. themselves.
/// Shows a friendly error toast instead of crashing on failure.
Future<void> saveToDownloadsAndShare(Uint8List bytes, String filename) async {
  try {
    // Always write to the app's own temp dir — this needs no storage
    // permission on any Android version (unlike a raw path such as
    // /storage/emulated/0/Download, which scoped storage on Android 10+
    // blocks with EACCES even when WRITE_EXTERNAL_STORAGE is granted).
    // The share sheet below is what actually lets the user save it to
    // Downloads, Drive, WhatsApp, etc. — the permission was never needed.
    final tempDir = await getTemporaryDirectory();
    final filePath = '${tempDir.path}/$filename';

    final file = File(filePath);
    await file.writeAsBytes(bytes, flush: true);

    // Share sheet — on Android lets user open/save; on iOS lets user pick Files
    await Share.shareXFiles([XFile(filePath)], subject: filename);
  } on FileSystemException catch (e) {
    final isPermission =
        e.osError?.errorCode == 13 || (e.message.toLowerCase().contains('permission'));
    _showExportError(
      isPermission
          ? 'Storage permission denied.\n'
              'Go to Settings → Apps → Sri HR → Permissions → Storage and allow access.'
          : 'Could not save file: ${e.message}',
    );
  } catch (e) {
    final msg = e.toString();
    if (msg.contains('Permission denied') || msg.contains('errno = 13')) {
      _showExportError(
        'Storage permission denied.\n'
        'Go to Settings → Apps → Sri HR → Permissions → Storage and allow access.',
      );
    } else {
      _showExportError('Export failed: ${msg.replaceAll('Exception: ', '')}');
    }
  }
}

void _showExportError(String message) {
  if (Get.isSnackbarOpen) Get.closeCurrentSnackbar();
  Get.snackbar(
    'Export Failed',
    message,
    snackPosition: SnackPosition.TOP,
    backgroundColor: const Color(0xFFEF4444),
    colorText: Colors.white,
    duration: const Duration(seconds: 6),
    icon: const Icon(Icons.file_download_off_rounded, color: Colors.white),
    margin: const EdgeInsets.all(12),
  );
}