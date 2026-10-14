class DashboardStats {
  final int totalEmployees;
  final int presentCount;
  final int absentCount;
  final int leaveCount;
  final int permissionCount;
  final int pendingLeaveCount;
  final int pendingPermissionCount;
  final int lateCount;
  final List<Map<String, dynamic>> attendanceByDate;
  final List<Map<String, dynamic>> departmentWiseCount;

  DashboardStats({
    required this.totalEmployees,
    required this.presentCount,
    required this.absentCount,
    required this.leaveCount,
    required this.permissionCount,
    this.pendingLeaveCount = 0,
    this.pendingPermissionCount = 0,
    this.lateCount = 0,
    required this.attendanceByDate,
    required this.departmentWiseCount,
  });
}