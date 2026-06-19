// lib/presentation/attendance/widgets/table_view_v2.dart
// Columns: Employee | Date | First In | Last Out | In Records | Out Records
//          Expected | Actual | Difference | Late Arrival | Permission | Leave | Status
import 'package:flutter/material.dart';
import 'package:sri_hr/core/theme/app_colors.dart';
import 'package:sri_hr/presentation/attendance/controller/attendance_controller.dart';
import 'package:sri_hr/presentation/attendance/widgets/attend_table_row_v2.dart';
import 'package:sri_hr/presentation/auth/controller/auth_controller.dart';

// ── Column widths (px) — synced with attend_table_row_v2.dart ─────────────────
class AttendCols {
  static const employee   = 190.0;
  static const date       = 100.0;
  static const firstIn    = 76.0;
  static const lastOut    = 76.0;
  static const inRec      = 110.0;
  static const outRec     = 110.0;
  static const expected   = 88.0;
  static const actual     = 88.0;
  static const diff       = 88.0;
  static const late       = 88.0;
  static const permission = 140.0;
  static const leave      = 88.0;
  static const status     = 88.0;
  static const action     = 36.0;

  static double get total =>
      employee + date + firstIn + lastOut + inRec + outRec +
      expected + actual + diff + late + permission + leave + status + action + 24;
}

class TableViewV2 extends StatelessWidget {
  final List<Map<String, dynamic>> rows;
  final AttendanceController controller;
  final AuthController auth;

  const TableViewV2({
    super.key, required this.rows,
    required this.controller, required this.auth,
  });

  static Widget _th(String t) => Text(t,
      style: const TextStyle(color: Colors.white, fontSize: 10.5,
          fontWeight: FontWeight.w700, letterSpacing: 0.2),
      overflow: TextOverflow.ellipsis);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: AttendCols.total,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ───────────────────────────────────────────────────
              Container(
                width: AttendCols.total,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 11),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: Row(
                  children: [
                    SizedBox(width: AttendCols.employee,   child: _th('Employee')),
                    SizedBox(width: AttendCols.date,        child: _th('Date')),
                    SizedBox(width: AttendCols.firstIn,     child: _th('First In')),
                    SizedBox(width: AttendCols.lastOut,     child: _th('Last Out')),
                    SizedBox(width: AttendCols.inRec,       child: _th('In Records')),
                    SizedBox(width: AttendCols.outRec,      child: _th('Out Records')),
                    SizedBox(width: AttendCols.expected,    child: _th('Expected')),
                    SizedBox(width: AttendCols.actual,      child: _th('Actual Hrs')),
                    SizedBox(width: AttendCols.diff,        child: _th('Difference')),
                    SizedBox(width: AttendCols.late,        child: _th('Late Arrival')),
                    SizedBox(width: AttendCols.permission,  child: _th('Permission')),
                    SizedBox(width: AttendCols.leave,       child: _th('Leave')),
                    SizedBox(width: AttendCols.status,      child: _th('Status')),
                  ],
                ),
              ),

              // ── Empty state ───────────────────────────────────────────────
              if (rows.isEmpty)
                Container(
                  width: AttendCols.total,
                  padding: const EdgeInsets.symmetric(vertical: 56),
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    border: Border(
                      left: BorderSide(color: AppColors.border),
                      right: BorderSide(color: AppColors.border),
                      bottom: BorderSide(color: AppColors.border),
                    ),
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.inbox_rounded, size: 34, color: AppColors.textMuted),
                      SizedBox(height: 8),
                      Text('No attendance records',
                          style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
                    ],
                  ),
                )
              else
                ...rows.asMap().entries.map((e) => AttendTableRowV2(
                  row: e.value,
                  isAlternate: e.key.isOdd,
                  canDelete: auth.canDelete('attendance_report'),
                  onDeleteLog: (id) => controller.confirmDelete(context, id),
                )),
            ],
          ),
        ),
      ),
    );
  }
}