import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide Border, BorderStyle;
import 'package:intl/intl.dart';
import 'package:sri_hr/data/helper/download_helper.dart';
import 'package:sri_hr/data/helper/file_helper_native.dart';
import 'package:sri_hr/data/models/attendance_log_model.dart';

// ─── PDF ─────────────────────────────────────────────────────────────────────
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

// ─── Excel ───────────────────────────────────────────────────────────────────
import 'package:excel/excel.dart';

class AttendanceExportService {
  // ─────────────────────────── helpers ──────────────────────────────────────

  static String _fmtTime(DateTime dt) => DateFormat('HH:mm').format(dt);
  static String _fmtDate(DateTime d)  => DateFormat('dd/MM/yyyy').format(d);

  static String _totalHrs(int totalMins) {
    if (totalMins <= 0) return '-';
    final h = totalMins ~/ 60;
    final m = totalMins % 60;
    return '${h}h ${m.toString().padLeft(2, '0')}m';
  }

  static bool _isSingleDay(DateTime from, DateTime to) =>
      from.year == to.year && from.month == to.month && from.day == to.day;

  // ═══════════════════════════════════════════════════════════════════════════
  //  PDF EXPORT
  // ═══════════════════════════════════════════════════════════════════════════

  static Future<void> exportPDF({
    required BuildContext context,
    required List<Map<String, dynamic>> rows,
    required DateTime fromDate,
    required DateTime toDate,
    required String companyName,
  }) async {
    final pdf = pw.Document(
    );

    // ── colours ───────────────────────────────────────────────────────────────
    const headerBg   = PdfColor(0.231, 0.357, 0.859);
    const rowAltBg   = PdfColor(0.973, 0.980, 0.988);
    const successClr = PdfColor(0.086, 0.639, 0.369);
    const errorClr   = PdfColor(0.863, 0.149, 0.149);
    const mutedClr   = PdfColor(0.580, 0.639, 0.722);
    const txtPrimary = PdfColor(0.059, 0.090, 0.165);
    const txtSec     = PdfColor(0.282, 0.337, 0.412);
    const greenBadge = PdfColor(0.863, 0.988, 0.902);
    const redBadge   = PdfColor(0.995, 0.882, 0.882);
    const greyBadge  = PdfColor(0.930, 0.930, 0.930);

    final font     = pw.Font.helvetica();
    final fontBold = pw.Font.helveticaBold();

    // ── stats ─────────────────────────────────────────────────────────────────
    final totalMinsAll =
        rows.fold<int>(0, (s, r) => s + (r['totalMins'] as int? ?? 0));
    final avgMins = rows.isNotEmpty ? totalMinsAll ~/ rows.length : 0;
    final singleDay    = _isSingleDay(fromDate, toDate);
    final presentCount = rows.where((r) => !(r['isAbsent'] as bool? ?? false)).length;
    final absentCount  = rows.where((r) =>  (r['isAbsent'] as bool? ?? false)).length;

    final dateRange =
        '${DateFormat('dd MMM yyyy').format(fromDate)} to ${DateFormat('dd MMM yyyy').format(toDate)}';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.symmetric(horizontal: 30, vertical: 26),

        // ── header ─────────────────────────────────────────────────────────
        header: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Brand banner — unchanged
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: const pw.BoxDecoration(
                color: headerBg,
                borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Sri HR',
                          style: pw.TextStyle(
                              font: fontBold, fontSize: 14,
                              color: PdfColors.white)),
                      pw.SizedBox(height: 2),
                      pw.Text(companyName,
                          style: pw.TextStyle(
                              font: font, fontSize: 9,
                              color: PdfColors.white)),
                    ],
                  ),
                  pw.Text(dateRange,
                      style: pw.TextStyle(
                          font: fontBold, fontSize: 9,
                          color: PdfColors.white)),
                ],
              ),
            ),
            pw.SizedBox(height: 8),

            // Stat cards — add Present/Absent only on single day
            pw.Row(
              children: [
                _statCard('Records', '${rows.length}', fontBold, font),
                pw.SizedBox(width: 8),
                _statCard('Total Hours', _totalHrs(totalMinsAll), fontBold, font),
                pw.SizedBox(width: 8),
                _statCard('Avg / Day', _totalHrs(avgMins), fontBold, font),
                if (singleDay) ...[
                  pw.SizedBox(width: 8),
                  _statCard('Present', '$presentCount', fontBold, font,
                      valuColor: successClr, bg: greenBadge),
                  pw.SizedBox(width: 8),
                  _statCard('Absent', '$absentCount', fontBold, font,
                      valuColor: errorClr, bg: redBadge),
                ],
              ],
            ),
            pw.SizedBox(height: 4),
          ],
        ),

        // ── footer ─────────────────────────────────────────────────────────
        footer: (ctx) => pw.Container(
          padding: const pw.EdgeInsets.only(top: 6),
          decoration: const pw.BoxDecoration(
            border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Generated: ${DateFormat('dd MMM yyyy, HH:mm').format(DateTime.now())}',
                style: pw.TextStyle(font: font, fontSize: 7.5, color: PdfColors.grey500),
              ),
              pw.Text(
                'Page ${ctx.pageNumber} of ${ctx.pagesCount}',
                style: pw.TextStyle(font: font, fontSize: 7.5, color: PdfColors.grey500),
              ),
            ],
          ),
        ),

        build: (_) => [
          pw.SizedBox(height: 10),

          // ── Table header ──────────────────────────────────────────────────
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            decoration: const pw.BoxDecoration(
              color: headerBg,
              borderRadius: pw.BorderRadius.only(
                topLeft:  pw.Radius.circular(6),
                topRight: pw.Radius.circular(6),
              ),
            ),
            child: pw.Row(
              children: [
                pw.Expanded(flex: 3, child: _th('Employee', fontBold)),
                pw.Expanded(flex: 2, child: _th('Date', fontBold)),
                pw.Expanded(flex: 2, child: _th('First In', fontBold, center: true)),
                pw.Expanded(flex: 2, child: _th('Last Out', fontBold, center: true)),
                pw.Expanded(flex: 4, child: _th('In Records', fontBold)),
                pw.Expanded(flex: 4, child: _th('Out Records', fontBold)),
                pw.Expanded(flex: 2, child: _th('Expected', fontBold, center: true)),
                pw.Expanded(flex: 2, child: _th('Actual Hrs', fontBold, center: true)),
                pw.Expanded(flex: 2, child: _th('Difference', fontBold, center: true)),
                pw.Expanded(flex: 2, child: _th('Late', fontBold, center: true)),
                pw.Expanded(flex: 3, child: _th('Permission', fontBold)),
                pw.Expanded(flex: 2, child: _th('Leave', fontBold, center: true)),
                pw.Expanded(flex: 2, child: _th('Status', fontBold, center: true)),
              ],
            ),
          ),

          // ── Data rows ─────────────────────────────────────────────────────
          ...rows.asMap().entries.map((entry) {
            final idx          = entry.key;
            final row          = entry.value;
            final emp          = row['employee']     as dynamic;
            final date         = row['date']         as DateTime;
            final inLogs       = row['inLogs']       as List<AttendanceLogModel>;
            final outLogs      = row['outLogs']      as List<AttendanceLogModel>;
            final totalMins    = row['totalMins']    as int? ?? 0;
            final isAbsent     = row['isAbsent']     as bool? ?? false;
            final expectedMins = row['expectedMins'] as int?;
            final lateMinutes  = row['lateMinutes']  as int?;
            final permStatus   = row['permStatus']   as String?;
            final permTimings  = row['permTimings']  as String?;
            final leaveStatus  = row['leaveStatus']  as String?;

            final empName = emp?.fullName         as String? ?? 'Unknown';
            final empCode = emp?.employeeCode     as String? ?? '';
            final dept    = emp?.department?.name as String? ?? '';
            final bg = idx.isEven ? PdfColors.white : rowAltBg;

            final diffMins = (expectedMins != null && expectedMins > 0)
                ? (totalMins - expectedMins) : null;

            final firstIn  = inLogs.isNotEmpty  ? _fmtTime(inLogs.first.punchTime)  : '-';
            final lastOut  = outLogs.isNotEmpty ? _fmtTime(outLogs.last.punchTime)  : '-';
            final inStr    = inLogs.isEmpty  ? '-'
                : inLogs.map((l)  => '${_fmtTime(l.punchTime)}${l.isManual ? "(M)" : "(F)"}').join('  ');
            final outStr   = outLogs.isEmpty ? '-'
                : outLogs.map((l) => '${_fmtTime(l.punchTime)}${l.isManual ? "(M)" : "(F)"}').join('  ');

            // Status
            final String statusLabel;
            final PdfColor statusClr;
            final PdfColor statusBg;
            if (leaveStatus == 'approved' && inLogs.isEmpty) {
              statusLabel = 'Leave';
              statusClr = const PdfColor(0.059, 0.412, 0.863);
              statusBg  = const PdfColor(0.878, 0.937, 0.992);
            } else if (isAbsent) {
              statusLabel = 'Absent'; statusClr = errorClr; statusBg = redBadge;
            } else {
              statusLabel = 'Present'; statusClr = successClr; statusBg = greenBadge;
            }

            String fmtDiff(int d) {
              if (d == 0) return '±0h';
              final sign = d > 0 ? '+' : '-'; final a = d.abs();
              return '$sign${a ~/ 60}h ${(a % 60).toString().padLeft(2,'0')}m';
            }
            String fmtLate(int m) =>
                '${m ~/ 60}h ${(m % 60).toString().padLeft(2, '0')}m';

            pw.Widget _cell(pw.Widget child) => pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 1), child: child);

            return pw.Container(
              decoration: pw.BoxDecoration(
                color: bg,
                border: const pw.Border(
                  bottom: pw.BorderSide(color: PdfColors.grey200),
                  left:   pw.BorderSide(color: PdfColors.grey200),
                  right:  pw.BorderSide(color: PdfColors.grey200),
                ),
              ),
              padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Employee
                  pw.Expanded(flex: 3, child: _cell(pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(empName, style: pw.TextStyle(font: fontBold, fontSize: 8.5, color: txtPrimary)),
                      if (empCode.isNotEmpty)
                        pw.Text(empCode, style: pw.TextStyle(font: font, fontSize: 7, color: mutedClr)),
                      if (dept.isNotEmpty)
                        pw.Text(dept, style: pw.TextStyle(font: font, fontSize: 7, color: mutedClr)),
                    ],
                  ))),

                  // Date
                  pw.Expanded(flex: 2, child: _cell(
                    pw.Text(_fmtDate(date), style: pw.TextStyle(font: fontBold, fontSize: 8.5, color: txtSec)))),

                  // First In
                  pw.Expanded(flex: 2, child: _cell(pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: pw.BoxDecoration(color: inLogs.isNotEmpty ? greenBadge : greyBadge,
                        borderRadius: pw.BorderRadius.circular(4)),
                    child: pw.Text(firstIn, textAlign: pw.TextAlign.center,
                        style: pw.TextStyle(font: fontBold, fontSize: 8.5,
                            color: inLogs.isNotEmpty ? successClr : mutedClr)),
                  ))),

                  // Last Out
                  pw.Expanded(flex: 2, child: _cell(pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: pw.BoxDecoration(color: outLogs.isNotEmpty ? redBadge : greyBadge,
                        borderRadius: pw.BorderRadius.circular(4)),
                    child: pw.Text(lastOut, textAlign: pw.TextAlign.center,
                        style: pw.TextStyle(font: fontBold, fontSize: 8.5,
                            color: outLogs.isNotEmpty ? errorClr : mutedClr)),
                  ))),

                  // In Records
                  pw.Expanded(flex: 4, child: _cell(
                    pw.Text(inStr, style: pw.TextStyle(font: font, fontSize: 8,
                        color: inLogs.isNotEmpty ? successClr : mutedClr)))),

                  // Out Records
                  pw.Expanded(flex: 4, child: _cell(
                    pw.Text(outStr, style: pw.TextStyle(font: font, fontSize: 8,
                        color: outLogs.isNotEmpty ? errorClr : mutedClr)))),

                  // Expected
                  pw.Expanded(flex: 2, child: _cell(
                    pw.Text(expectedMins != null ? _totalHrs(expectedMins) : '-',
                        textAlign: pw.TextAlign.center,
                        style: pw.TextStyle(font: font, fontSize: 8.5, color: txtSec)))),

                  // Actual
                  pw.Expanded(flex: 2, child: _cell(pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: pw.BoxDecoration(
                        color: () {
                          if (totalMins <= 0) return greyBadge;
                          if (expectedMins == null || expectedMins <= 0) return greenBadge;
                          final pct = totalMins / expectedMins;
                          if (pct >= 1.0) return greenBadge;
                          if (pct >= 0.75) return const PdfColor(1.0, 0.95, 0.85);
                          return redBadge;
                        }(),
                        borderRadius: pw.BorderRadius.circular(4)),
                    child: pw.Text(_totalHrs(totalMins), textAlign: pw.TextAlign.center,
                        style: pw.TextStyle(font: fontBold, fontSize: 8.5,
                            color: () {
                              if (totalMins <= 0) return mutedClr;
                              if (expectedMins == null || expectedMins <= 0) return successClr;
                              final pct = totalMins / expectedMins;
                              if (pct >= 1.0) return successClr;
                              if (pct >= 0.75) return const PdfColor(0.8, 0.5, 0.1);
                              return errorClr;
                            }())),
                  ))),

                  // Difference
                  pw.Expanded(flex: 2, child: _cell(diffMins == null
                      ? pw.Text('-', style: pw.TextStyle(font: font, fontSize: 8.5, color: mutedClr))
                      : pw.Container(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: pw.BoxDecoration(
                              color: diffMins >= 0 ? greenBadge : redBadge,
                              borderRadius: pw.BorderRadius.circular(4)),
                          child: pw.Text(fmtDiff(diffMins), textAlign: pw.TextAlign.center,
                              style: pw.TextStyle(font: fontBold, fontSize: 8.5,
                                  color: diffMins >= 0 ? successClr : errorClr)),
                        ))),

                  // Late Arrival
                  pw.Expanded(flex: 2, child: _cell(
                    (lateMinutes == null || lateMinutes == 0)
                        ? pw.Text(inLogs.isEmpty ? '-' : 'On Time',
                            textAlign: pw.TextAlign.center,
                            style: pw.TextStyle(font: font, fontSize: 8.5,
                                color: inLogs.isEmpty ? mutedClr : successClr))
                        : pw.Container(
                            padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            decoration: pw.BoxDecoration(
                                color: const PdfColor(1.0, 0.95, 0.85),
                                borderRadius: pw.BorderRadius.circular(4)),
                            child: pw.Text(fmtLate(lateMinutes), textAlign: pw.TextAlign.center,
                                style: pw.TextStyle(font: fontBold, fontSize: 8.5,
                                    color: const PdfColor(0.8, 0.5, 0.1)))))),

                  // Permission
                  pw.Expanded(flex: 3, child: _cell(permStatus == null
                      ? pw.Text('-', style: pw.TextStyle(font: font, fontSize: 8.5, color: mutedClr))
                      : pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                          if (permTimings != null && permTimings.isNotEmpty)
                            pw.Text(permTimings.replaceAll('–', '-'), style: pw.TextStyle(font: font, fontSize: 7.5, color: txtSec)),
                          pw.Text(_capitalize(permStatus),
                              style: pw.TextStyle(font: fontBold, fontSize: 8,
                                  color: permStatus.toLowerCase() == 'approved'
                                      ? successClr : permStatus.toLowerCase() == 'rejected'
                                          ? errorClr : const PdfColor(0.8, 0.55, 0.1))),
                        ]))),

                  // Leave Status
                  pw.Expanded(flex: 2, child: _cell(leaveStatus == null
                      ? pw.Text('-', style: pw.TextStyle(font: font, fontSize: 8.5, color: mutedClr))
                      : pw.Text(_capitalize(leaveStatus), textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(font: fontBold, fontSize: 8.5,
                              color: leaveStatus == 'approved'
                                  ? const PdfColor(0.059, 0.412, 0.863)
                                  : leaveStatus == 'rejected' ? errorClr
                                      : const PdfColor(0.8, 0.55, 0.1))))),

                  // Status
                  pw.Expanded(flex: 2, child: _cell(pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                    decoration: pw.BoxDecoration(color: statusBg, borderRadius: pw.BorderRadius.circular(8)),
                    child: pw.Row(mainAxisSize: pw.MainAxisSize.min,
                        mainAxisAlignment: pw.MainAxisAlignment.center,
                        children: [
                          pw.Container(width: 5, height: 5,
                              decoration: pw.BoxDecoration(color: statusClr, shape: pw.BoxShape.circle)),
                          pw.SizedBox(width: 4),
                          pw.Text(statusLabel,
                              style: pw.TextStyle(font: fontBold, fontSize: 8, color: statusClr)),
                        ]),
                  ))),
                ],
              ),
            );
          }),

          pw.SizedBox(height: 10),
          // Legend — unchanged
          pw.Row(
            children: [
              _dot(successClr), pw.SizedBox(width: 3),
              pw.Text('IN   ',
                  style: pw.TextStyle(font: font, fontSize: 8, color: mutedClr)),
              _dot(errorClr), pw.SizedBox(width: 3),
              pw.Text('OUT   ',
                  style: pw.TextStyle(font: font, fontSize: 8, color: mutedClr)),
              pw.Text('  (M) = Manual   (F) = Face/Device',
                  style: pw.TextStyle(font: font, fontSize: 8, color: mutedClr)),
            ],
          ),
        ],
      ),
    );

    final filename =
        'Attendance_${DateFormat('ddMMyyyy').format(fromDate)}_${DateFormat('ddMMyyyy').format(toDate)}.pdf';
    final pdfBytes = await pdf.save();

    await _saveAndOpen(
      context: context,
      bytes: Uint8List.fromList(pdfBytes),
      filename: filename,
      mimeType: 'application/pdf',
    );
  }

  // ── PDF widget helpers ─────────────────────────────────────────────────────

  static pw.Widget _statCard(
      String label, String value, pw.Font fontBold, pw.Font font,
      {PdfColor? valuColor, PdfColor? bg}) {
    const defaultTxt = PdfColor(0.059, 0.090, 0.165);
    const defaultBg  = PdfColors.grey100;
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: pw.BoxDecoration(
        color: bg ?? defaultBg,
        borderRadius: pw.BorderRadius.circular(5),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text(value,
              style: pw.TextStyle(
                  font: fontBold, fontSize: 11,
                  color: valuColor ?? defaultTxt)),
          pw.Text(label,
              style: pw.TextStyle(
                  font: font, fontSize: 7.5,
                  color: const PdfColor(0.580, 0.639, 0.722))),
        ],
      ),
    );
  }

  static pw.Widget _th(String label, pw.Font font, {bool center = false}) {
    return pw.Text(label,
        style: pw.TextStyle(font: font, fontSize: 9, color: PdfColors.white),
        textAlign: center ? pw.TextAlign.center : pw.TextAlign.left);
  }

  static pw.Widget punchLine({
    required String label,
    required String times,
    required PdfColor labelBg,
    required pw.Font font,
    required pw.Font fontBold,
  }) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Container(
          width: 24,
          padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 1),
          decoration: pw.BoxDecoration(
            color: labelBg,
            borderRadius: pw.BorderRadius.circular(3),
          ),
          child: pw.Text(label,
              style: pw.TextStyle(
                  font: fontBold, fontSize: 7,
                  color: PdfColors.white),
              textAlign: pw.TextAlign.center),
        ),
        pw.SizedBox(width: 5),
        pw.Flexible(
          child: pw.Text(times,
              style: pw.TextStyle(
                  font: font, fontSize: 8.5,
                  color: const PdfColor(0.059, 0.090, 0.165))),
        ),
      ],
    );
  }

  static String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  static pw.Widget _dot(PdfColor color) {
    return pw.Container(
      width: 7, height: 7,
      decoration: pw.BoxDecoration(color: color, shape: pw.BoxShape.circle),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  EXCEL EXPORT
  // ═══════════════════════════════════════════════════════════════════════════

  static Future<void> exportExcel({
    required BuildContext context,
    required List<Map<String, dynamic>> rows,
    required DateTime fromDate,
    required DateTime toDate,
    required String companyName,
  }) async {
    final excel = Excel.createExcel();

    final sheet = excel['Attendance Report'];
    _writeAttendanceSheet(sheet, rows, fromDate, toDate, companyName);

    for (final defaultName in ['Sheet1', 'FlutterExcel']) {
      if (excel.sheets.containsKey(defaultName)) {
        excel.delete(defaultName);
      }
    }

    final bytes = excel.encode();
    if (bytes == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to generate Excel file'),
            backgroundColor: Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    final filename =
        'Attendance_${DateFormat("ddMMyyyy").format(fromDate)}_${DateFormat("ddMMyyyy").format(toDate)}.xlsx';

    await _saveAndOpen(
      context: context,
      bytes: Uint8List.fromList(bytes),
      filename: filename,
      mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    );
  }

  // ─── Single-sheet writer ───────────────────────────────────────────────────

  static void _writeAttendanceSheet(
    Sheet sheet,
    List<Map<String, dynamic>> rows,
    DateTime fromDate,
    DateTime toDate,
    String companyName,
  ) {
    final singleDay    = _isSingleDay(fromDate, toDate);
    final presentCount = rows.where((r) => !(r['isAbsent'] as bool? ?? false)).length;
    final absentCount  = rows.where((r) =>  (r['isAbsent'] as bool? ?? false)).length;
    final dateRange    =
        '${DateFormat('dd MMM yyyy').format(fromDate)} - ${DateFormat('dd MMM yyyy').format(toDate)}';
    final totalMinsAll =
        rows.fold<int>(0, (s, r) => s + (r['totalMins'] as int? ?? 0));
    final avgMins = rows.isNotEmpty ? totalMinsAll ~/ rows.length : 0;

    // ── Row 0: title ─────────────────────────────────────────────────────────
    final t = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0));
    t.value = TextCellValue('Sri HR - ATTENDANCE REPORT  |  $dateRange');
    sheet.merge(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
        CellIndex.indexByColumnRow(columnIndex: 14, rowIndex: 0));
    t.cellStyle = CellStyle(
      bold: true, fontSize: 13,
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      backgroundColorHex: ExcelColor.fromHexString('#3B5BDB'),
      verticalAlign: VerticalAlign.Center,
      horizontalAlign: HorizontalAlign.Left,
    );
    sheet.setRowHeight(0, 32);

    // ── Row 1: stats ─────────────────────────────────────────────────────────
    String statsText =
        'Records: ${rows.length}     '
        'Total Hours: ${_totalHrs(totalMinsAll)}     '
        'Avg/Day: ${_totalHrs(avgMins)}';
    if (singleDay) {
      statsText += '     Present: $presentCount     Absent: $absentCount';
    }
    statsText += '     Generated: ${DateFormat('dd MMM yyyy, HH:mm').format(DateTime.now())}';

    final s = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1));
    s.value = TextCellValue(statsText);
    s.cellStyle = CellStyle(
      italic: true, fontSize: 9,
      fontColorHex: ExcelColor.fromHexString('#475569'),
      backgroundColorHex: ExcelColor.fromHexString('#EEF2FF'),
      verticalAlign: VerticalAlign.Center,
    );
    sheet.merge(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1),
        CellIndex.indexByColumnRow(columnIndex: 14, rowIndex: 1));
    sheet.setRowHeight(1, 22);

    // ── Row 2: spacer ─────────────────────────────────────────────────────────
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 2))
        .value = TextCellValue('');
    sheet.setRowHeight(2, 8);

    // ── Row 3: column headers ─────────────────────────────────────────────────
    const headers = [
      'Emp Code', 'Employee Name', 'Date',
      'First In', 'Last Out', 'In Records', 'Out Records',
      'Expected Hrs', 'Actual Hrs', 'Difference',
      'Late Arrival', 'Permission Timings', 'Permission Status',
      'Leave Status', 'Status',
    ];
    for (var c = 0; c < headers.length; c++) {
      final cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 3));
      cell.value = TextCellValue(headers[c]);
      cell.cellStyle = CellStyle(
        bold: true, fontSize: 10,
        fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
        backgroundColorHex: ExcelColor.fromHexString('#3B5BDB'),
        verticalAlign: VerticalAlign.Center,
        horizontalAlign: c >= 3 ? HorizontalAlign.Center : HorizontalAlign.Left,
        bottomBorder: Border(
          borderStyle: BorderStyle.Thin,
          borderColorHex: ExcelColor.white,
        ),
        rightBorder: Border(
          borderStyle: BorderStyle.Thin,
          borderColorHex: ExcelColor.white,
        ),
      );
    }
    sheet.setRowHeight(3, 26);

    // ── Rows 4+: data ─────────────────────────────────────────────────────────
    for (var i = 0; i < rows.length; i++) {
      final row      = rows[i];
      final emp      = row['employee']  as dynamic;
      final date     = row['date']      as DateTime;
      final inLogs   = row['inLogs']    as List<AttendanceLogModel>;
      final outLogs  = row['outLogs']   as List<AttendanceLogModel>;
      final totalMins = row['totalMins'] as int? ?? 0;
      final isAbsent  = row['isAbsent'] as bool? ?? false;
      final r = 4 + i;
      final rowBg = (i.isEven
              ? ExcelColor.fromHexString('#FFFFFF')
              : ExcelColor.fromHexString('#F8FAFC'));

      final borderColor = ExcelColor.fromHexString('#E2E8F0');
      final cellBorder = Border(
        borderStyle: BorderStyle.Thin,
        borderColorHex: borderColor,
      );

      final inStr  = inLogs.isEmpty  ? '-'
          : inLogs.map((l)  => '${_fmtTime(l.punchTime)}${l.isManual ? "(M)" : "(F)"}').join('   ');
      final outStr = outLogs.isEmpty ? '-'
          : outLogs.map((l) => '${_fmtTime(l.punchTime)}${l.isManual ? "(M)" : "(F)"}').join('   ');

      void writeCell(int col, String val, {
        bool bold = false,
        String fgHex = '#0F172A',
        HorizontalAlign halign = HorizontalAlign.Left,
      }) {
        final cell = sheet.cell(
            CellIndex.indexByColumnRow(columnIndex: col, rowIndex: r));
        cell.value = TextCellValue(val);
        cell.cellStyle = CellStyle(
          bold: bold, fontSize: 10,
          backgroundColorHex: rowBg,
          fontColorHex: ExcelColor.fromHexString(fgHex),
          verticalAlign: VerticalAlign.Center,
          horizontalAlign: halign,
          topBorder: cellBorder,
          bottomBorder: cellBorder,
          leftBorder: cellBorder,
          rightBorder: cellBorder,
        );
      }

      final expectedMins = row['expectedMins'] as int?;
      final lateMinutes  = row['lateMinutes']  as int?;
      final permStatus   = row['permStatus']   as String?;
      final permTimings  = row['permTimings']  as String?;
      final leaveStatus  = row['leaveStatus']  as String?;

      final diffMins = (expectedMins != null && expectedMins > 0)
          ? (totalMins - expectedMins) : null;

      final firstIn  = inLogs.isNotEmpty  ? _fmtTime(inLogs.first.punchTime)  : '-';
      final lastOut  = outLogs.isNotEmpty ? _fmtTime(outLogs.last.punchTime)  : '-';
      

      String fmtDiff(int d) {
        if (d == 0) return '±0h 00m';
        final sign = d > 0 ? '+' : '-'; final a = d.abs();
        return '${sign}${a ~/ 60}h ${(a % 60).toString().padLeft(2, '0')}m';
      }
      String fmtLate(int m) =>
          '${m ~/ 60}h ${(m % 60).toString().padLeft(2, '0')}m';

      // Status
      final String statusLabel;
      final String statusFg;
      final String statusBg2;
      if (leaveStatus == 'approved' && inLogs.isEmpty) {
        statusLabel = 'Leave'; statusFg = '#1D4ED8'; statusBg2 = '#DBEAFE';
      } else if (isAbsent) {
        statusLabel = 'Absent'; statusFg = '#DC2626'; statusBg2 = '#FEE2E2';
      } else {
        statusLabel = 'Present'; statusFg = '#16A34A'; statusBg2 = '#DCFCE7';
      }

      writeCell(0, emp?.employeeCode as String? ?? '', fgHex: '#64748B');
      writeCell(1, emp?.fullName     as String? ?? 'Unknown', bold: true);
      writeCell(2, _fmtDate(date),   fgHex: '#475569');
      writeCell(3, firstIn,  fgHex: inLogs.isNotEmpty  ? '#16A34A' : '#94A3B8', halign: HorizontalAlign.Center);
      writeCell(4, lastOut,  fgHex: outLogs.isNotEmpty ? '#DC2626' : '#94A3B8', halign: HorizontalAlign.Center);
      writeCell(5, inStr,    fgHex: inLogs.isNotEmpty  ? '#16A34A' : '#94A3B8');
      writeCell(6, outStr,   fgHex: outLogs.isNotEmpty ? '#DC2626' : '#94A3B8');
      writeCell(7, expectedMins != null ? _totalHrs(expectedMins) : '-',
          fgHex: '#475569', halign: HorizontalAlign.Center);
      // Actual Hrs color — mirrors UI: pct>=1.0 green, pct>=0.75 orange/warning, <0.75 red
      final String actualFg;
      if (totalMins <= 0) {
        actualFg = '#94A3B8';
      } else if (expectedMins == null || expectedMins <= 0) {
        actualFg = '#16A34A';
      } else {
        final pct = totalMins / expectedMins;
        actualFg = pct >= 1.0 ? '#16A34A' : pct >= 0.75 ? '#B45309' : '#DC2626';
      }

      writeCell(8, _totalHrs(totalMins),
          bold: totalMins > 0,
          fgHex: actualFg,
          halign: HorizontalAlign.Center);
      writeCell(9, diffMins == null ? '-' : fmtDiff(diffMins),
          bold: diffMins != null,
          fgHex: diffMins == null ? '#94A3B8' : diffMins >= 0 ? '#16A34A' : '#DC2626',
          halign: HorizontalAlign.Center);
      writeCell(10,
          (lateMinutes == null || lateMinutes == 0)
              ? (inLogs.isEmpty ? '-' : 'On Time')
              : fmtLate(lateMinutes),
          fgHex: (lateMinutes == null || lateMinutes == 0)
              ? (inLogs.isEmpty ? '#94A3B8' : '#16A34A')
              : '#B45309',
          halign: HorizontalAlign.Center);
      writeCell(11, permTimings ?? '-',   fgHex: '#475569', halign: HorizontalAlign.Center);
      writeCell(12, permStatus != null ? (permStatus[0].toUpperCase() + permStatus.substring(1)) : '-',
          fgHex: permStatus == null ? '#94A3B8'
              : permStatus.toLowerCase() == 'approved' ? '#16A34A'
              : permStatus.toLowerCase() == 'rejected' ? '#DC2626' : '#B45309',
          halign: HorizontalAlign.Center);
      writeCell(13, leaveStatus != null ? (leaveStatus[0].toUpperCase() + leaveStatus.substring(1)) : '-',
          fgHex: leaveStatus == null ? '#94A3B8'
              : leaveStatus.toLowerCase() == 'approved' ? '#1D4ED8'
              : leaveStatus.toLowerCase() == 'rejected' ? '#DC2626' : '#B45309',
          halign: HorizontalAlign.Center);

      // Status cell (col 14) with colored background
      final statusCell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: 14, rowIndex: r));
      statusCell.value = TextCellValue(statusLabel);
      statusCell.cellStyle = CellStyle(
        bold: true, fontSize: 10,
        fontColorHex: ExcelColor.fromHexString(statusFg),
        backgroundColorHex: ExcelColor.fromHexString(statusBg2),
        verticalAlign: VerticalAlign.Center,
        horizontalAlign: HorizontalAlign.Center,
        topBorder: cellBorder, bottomBorder: cellBorder,
        leftBorder: cellBorder, rightBorder: cellBorder,
      );

      sheet.setRowHeight(r, 22);
    }

    // ── Column widths ─────────────────────────────────────────────────────────
    // 0:EmpCode 1:Name 2:Date 3:FirstIn 4:LastOut 5:InRec 6:OutRec
    // 7:Expected 8:Actual 9:Diff 10:Late 11:PermTimings 12:PermStatus 13:Leave 14:Status
    sheet.setColumnWidth(0, 14);
    sheet.setColumnWidth(1, 24);
    sheet.setColumnWidth(2, 14);
    sheet.setColumnWidth(3, 12);
    sheet.setColumnWidth(4, 12);
    sheet.setColumnWidth(5, 36);
    sheet.setColumnWidth(6, 36);
    sheet.setColumnWidth(7, 14);
    sheet.setColumnWidth(8, 14);
    sheet.setColumnWidth(9, 14);
    sheet.setColumnWidth(10, 12);
    sheet.setColumnWidth(11, 16);
    sheet.setColumnWidth(12, 14);
    sheet.setColumnWidth(13, 14);
    sheet.setColumnWidth(14, 12);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  SHARED SAVE + OPEN
  // ═══════════════════════════════════════════════════════════════════════════

  static Future<void> _saveAndOpen({
    required BuildContext context,
    required Uint8List bytes,
    required String filename,
    required String mimeType,
  }) async {
    if (kIsWeb) {
      _webDownload(bytes: bytes, filename: filename, mimeType: mimeType);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Downloading $filename...'),
            backgroundColor: const Color(0xFF22C55E),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else {
      await saveToDownloadsAndShare(bytes, filename);
    }
  }

  static void _webDownload({
    required Uint8List bytes,
    required String filename,
    required String mimeType,
  }) {
    triggerWebDownload(bytes: bytes, filename: filename, mimeType: mimeType);
  }
}