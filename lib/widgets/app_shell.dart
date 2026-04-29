import 'package:flutter/material.dart';
import 'package:sri_hr/widgets/narrow_layout.dart';
import 'package:sri_hr/widgets/wide_layout.dart';

class AppShell extends StatelessWidget {
  final Widget child;
  final String currentModule;
  final String title;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  const AppShell({
    super.key,
    required this.child,
    required this.currentModule,
    required this.title,
    this.actions,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 800;
    return isWide
        ? WideLayout(
            currentModule: currentModule,
            title: title,
            actions: actions,
            fab: floatingActionButton,
            child: child,
          )
        : NarrowLayout(
            currentModule: currentModule,
            title: title,
            actions: actions,
            fab: floatingActionButton,
            child: child,
          );
  }
}
