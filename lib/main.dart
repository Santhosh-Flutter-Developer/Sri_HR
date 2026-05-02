import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:sri_hr/core/constants/app_constants.dart';
import 'package:sri_hr/core/theme/app_theme.dart';
import 'package:sri_hr/presentation/auth/bindings/initial_binding.dart';
import 'package:sri_hr/presentation/not_found/ui/not_found.dart';
import 'package:sri_hr/routes/app_pages.dart';
import 'package:sri_hr/routes/app_routes.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const supabaseUrl = String.fromEnvironment(
  'SUPABASE_URL',
  defaultValue: 'https://whitusrdpprsxgtntvrw.supabase.co',
);
const supabaseAnonKey = String.fromEnvironment(
  'SUPABASE_ANON_KEY',
  defaultValue:
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndoaXR1c3JkcHByc3hndG50dnJ3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc1NjU1MTQsImV4cCI6MjA5MzE0MTUxNH0.RTAuE8ZhH5Uh6RRKA17znXRiCzllTuKDx89KDx0OxkQ',
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  //INIT GETSTORAGE

  await GetStorage.init();

  // INIT SUPABASE
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );

  runApp(const SriHRApp());
}

class SriHRApp extends StatelessWidget {
  const SriHRApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialBinding: InitialBinding(),
      initialRoute: AppRoutes.routeLogin,
      defaultTransition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 250),
      getPages: AppPages.pages,
      unknownRoute: GetPage(name: '/404', page: () => const NotFound()),
    );
  }
}
