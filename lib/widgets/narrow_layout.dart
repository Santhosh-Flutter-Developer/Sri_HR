import 'package:flutter/material.dart';
import 'package:sri_hr/core/theme/app_colors.dart';
import 'package:sri_hr/widgets/sidebar_widget.dart';

class NarrowLayout extends StatelessWidget {
  final Widget child;
  final String currentModule;
  final String title;
  final List<Widget>? actions;
  final Widget? fab;
  const NarrowLayout({
    super.key,
    required this.child,
    required this.currentModule,
    required this.title,
    this.actions,
    this.fab,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      drawer: Drawer(
        backgroundColor: AppColors.sidebarBg,
        width: 280,
        child: SidebarWidget(currentModule: currentModule),
      ),
      appBar: AppBar(
        title: Text(title),
        centerTitle: true,
        actions: actions,
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
      ),
      body: child,
      floatingActionButton: fab,
    );
  }
}
