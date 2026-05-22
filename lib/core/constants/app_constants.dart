class AppConstants {
  static const String appName = 'Sri HR';
  static const String appVersion = '1.0.0';

  // Supabase – set in .env
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
  );

  // ─── Licences ──────────────────────────────────────────────
  static const String androidfacesdkLicence =
      "wWevuh/4kYz0O/XvtfJv0O0IvTJao7E4XWnKBLpQ32+bwH3GRmBGgY3RXHjQlukOsZiW/Y8uhGr8"
      "zFGb/I3AoO53qLRUbGX8BV50AF3fGXTmmoY8uj8ZKqOF7OJWZZgSEyZs36r+0kxDRiApdZa20jhq"
      "fZ56VbL+TDkA9fWu4w0EJYKsSr/t5k9hE2vfuPDczPigr0q3aZyqCvXm1foKDsCzJ2WFD2MBZy/F"
      "g/smbQLFXJmo/o8e+F64bzMc4Hf/qWvXzzCbnVVdaZPr2BTWXZ2SEpPLf6triL+tvURcUVaVP0M2"
      "qPB27Gja5dunn4PhEEtTDn1RWtFPfk7vJAmhyg==";

  static const String iosfacesdkLicence =
      "Z6g7MbPXuE/V8YKMxJI60L+SdnAjz6rgtyZ4CWFa2xwU3P91D6Ih0jg70qxcT856LI7TwUlQbfYs0"
      "LrEW+9B2gAeSzYHa6LQIRbSNJ5BBZ13WmOPJglJSB7G1CSYTc6YPl1ioKS0o0Vh5SwSKh5oXhavSq"
      "c2ClL6Uu4kAxKO/jE+l/EC8ifvVX5oo8HUQ/H76I0eMig8yDq9Wvci6U7IxWMZlRjCtTiZvE/nC73"
      "6sY7d/DgYhu7/i9BkRkdslvEAfi6Mcc2tOcGHX3TpZ0dv5K8bOunVt6Fe6aDAtwypeovE8nL+NRpt"
      "8L90fO1s6MRMT6gez2der2aiv2vSSo+J0g==";

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
    'designation': 'Designations',
    'company': 'Company',
    'department': 'Departments',
    'employee_status': 'Employee Status',
    'salary_type': 'Salary Types',
    'employee': 'Employee',
    'holiday': 'Holiday Entry',
    'leave_request': 'Leave Requests',
    'permission_request': 'Permission Requests',
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
