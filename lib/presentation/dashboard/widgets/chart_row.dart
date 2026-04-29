import 'package:flutter/material.dart';
import 'package:sri_hr/presentation/dashboard/controller/dashboard_controller.dart';
import 'package:sri_hr/presentation/dashboard/widgets/attendance_pie_chart.dart';
import 'package:sri_hr/presentation/dashboard/widgets/dept_bar_chart.dart';

class ChartsRow extends StatelessWidget {
  final DashboardController ctrl;
  const ChartsRow({super.key, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 960;
    final charts = [
      AttendancePieChart(stats: ctrl.stats.value),
      DeptBarChart(stats: ctrl.stats.value),
    ];

    return isWide
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: charts[0]),
              const SizedBox(width: 20),
              Expanded(child: charts[1]),
            ],
          )
        : Column(children: [charts[0], const SizedBox(height: 16), charts[1]]);
  }
}
