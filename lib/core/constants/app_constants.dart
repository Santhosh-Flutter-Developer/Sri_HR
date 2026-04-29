class AppConstants {
  static const String appName = 'Sri HR';
  static const String appVersion = '1.0.0';

  // Supabase – set in .env
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
  );

  // Storage Buckets
  static const String profilesBucket = 'profiles';
  static const String documentsBucket = 'documents';
  static const String logosBucket = 'logos';

  // Subscription
  static const int trialDays = 3;
  static const int trialMaxUsers = 3;

  // Modules (must match role_permissions.module)
  static const List<String> modules = [
    'dashboard',
    'designation',
    'company',
    'department',
    'employee_status',
    'salary_type',
    'employee',
    'holiday',
    'leave_request',
    'permission_request',
    'attendance_report',
    'punch_adjustment',
    'subscription',
  ];

  static const Map<String, String> moduleLabels = {
    'dashboard': 'Dashboard',
    'designation': 'Designation',
    'company': 'Company',
    'department': 'Department',
    'employee_status': 'Employee Status',
    'salary_type': 'Salary Type',
    'employee': 'Employee',
    'holiday': 'Holiday Entry',
    'leave_request': 'Leave Request',
    'permission_request': 'Permission Request',
    'attendance_report': 'Attendance Report',
    'punch_adjustment': 'Punch Adjustment',
    'subscription': 'Subscription',
  };

  static const Map<String, String> moduleIcons = {
    'dashboard': 'dashboard',
    'designation': 'badge',
    'company': 'business',
    'department': 'account_tree',
    'employee_status': 'toggle_on',
    'salary_type': 'payments',
    'employee': 'people',
    'holiday': 'celebration',
    'leave_request': 'event_busy',
    'permission_request': 'timer',
    'attendance_report': 'assessment',
    'punch_adjustment': 'tune',
    'subscription': 'card_membership',
  };
}
