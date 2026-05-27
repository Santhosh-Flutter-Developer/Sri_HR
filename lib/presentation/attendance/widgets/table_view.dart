import 'package:flutter/material.dart';
import 'package:sri_hr/core/theme/app_colors.dart';
import 'package:sri_hr/presentation/attendance/controller/attendance_controller.dart';
import 'package:sri_hr/presentation/attendance/widgets/attend_table_row.dart';
import 'package:sri_hr/presentation/attendance/widgets/th.dart';
import 'package:sri_hr/presentation/auth/controller/auth_controller.dart';

class TableView extends StatelessWidget {
  final List<Map<String, dynamic>> rows;
  final AttendanceController controller;
  final AuthController auth;
  const TableView({
    super.key,
    required this.rows,
    required this.controller,
    required this.auth,
  });

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 800;
    return SingleChildScrollView(
      padding: EdgeInsets.all(isWide ? 20.0 : 10.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: isWide ? MediaQuery.of(context).size.width * 0.8 : 850,
          child: Column(
            children: [
              // Table header
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                ),
                child: const Row(
                  children: [
                    Expanded(flex: 3, child: TH('Employee')),
                    Expanded(flex: 2, child: TH('Date')),
                    Expanded(flex: 2, child: TH('IN')),
                    Expanded(flex: 2, child: TH('OUT')),
                    Expanded(flex: 2, child: TH('Hours')),
                    SizedBox(width: 36, child: TH('', center: true)),
                  ],
                ),
              ),
              // Table rows
              ...rows.map(
                (row) => AttendTableRow(
                  row: row,
                  canDelete: auth.canDelete('attendance_report'),
                  onDeleteLog: (id) => controller.confirmDelete(context, id),
                ),
              ),
              // Table footer border
              // Container(
              //   height: 8,
              //   decoration: BoxDecoration(
              //     color: AppColors.surfaceVariant,
              //     borderRadius: const BorderRadius.vertical(
              //       bottom: Radius.circular(12),
              //     ),
              //     border: Border.all(color: AppColors.border),
              //   ),
              // ),
            ],
          ),
        ),
      ),
    );
  }
}
