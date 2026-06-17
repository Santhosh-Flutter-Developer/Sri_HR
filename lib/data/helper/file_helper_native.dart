import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

Future<void> writeFileBytes(String path, Uint8List bytes) async {
  await File(path).writeAsBytes(bytes, flush: true);
}

/// Saves the file to the public Downloads folder (Android) or temp dir (iOS),
/// then triggers the OS share/save sheet so the user can save it to Files.
/// Shows a friendly error toast instead of crashing on permission denial.
Future<void> saveToDownloadsAndShare(Uint8List bytes, String filename) async {
  try {
    String filePath;

    if (Platform.isAndroid) {
      // Try the public Downloads folder first; fall back to app-docs dir.
      const downloadsPath = '/storage/emulated/0/Download';
      final dir = Directory(downloadsPath);
      if (dir.existsSync()) {
        filePath = '$downloadsPath/$filename';
      } else {
        final appDir = await getApplicationDocumentsDirectory();
        filePath = '${appDir.path}/$filename';
      }
    } else {
      // iOS: save to temp then share so user can pick destination (Files, etc.)
      final tempDir = await getTemporaryDirectory();
      filePath = '${tempDir.path}/$filename';
    }

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