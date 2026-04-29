class DashboardStats {
  final int totalEmployees;
  final int presentCount;
  final int absentCount;
  final int leaveCount;
  final int permissionCount;
  final List<Map<String, dynamic>> attendanceByDate;
  final List<Map<String, dynamic>> departmentWiseCount;

  DashboardStats({
    required this.totalEmployees,
    required this.presentCount,
    required this.absentCount,
    required this.leaveCount,
    required this.permissionCount,
    required this.attendanceByDate,
    required this.departmentWiseCount,
  });
}
