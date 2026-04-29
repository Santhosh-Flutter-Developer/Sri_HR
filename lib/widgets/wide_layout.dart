import 'package:flutter/material.dart';
import 'package:sri_hr/core/theme/app_colors.dart';
import 'package:sri_hr/widgets/sidebar_widget.dart';
import 'package:sri_hr/widgets/top_bar.dart';

class WideLayout extends StatelessWidget {
  final Widget child;
  final String currentModule;
  final String title;
  final List<Widget>? actions;
  final Widget? fab;
  const WideLayout({
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
      body: Row(
        children: [
          SidebarWidget(currentModule: currentModule),
          Expanded(
            child: Column(
              children: [
                TopBar(title: title, actions: actions),
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: fab,
    );
  }
}
