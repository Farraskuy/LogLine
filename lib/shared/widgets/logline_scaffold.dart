import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_route_paths.dart';
import '../../core/theme/app_theme.dart';

class LogLineScaffold extends StatelessWidget {
  const LogLineScaffold({
    super.key,
    required this.child,
    this.title,
    this.actions,
    this.showBack = false,
    this.currentIndex,
    this.floatingActionButton,
    this.backgroundColor,
  });

  final Widget child;
  final String? title;
  final List<Widget>? actions;
  final bool showBack;
  final int? currentIndex;
  final Widget? floatingActionButton;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor ?? AppColors.background,
      appBar: title == null
          ? null
          : AppBar(
              leading: showBack
                  ? IconButton(
                      onPressed: () => context.canPop()
                          ? context.pop()
                          : context.go(AppRoutePaths.notes),
                      icon: const Icon(Icons.arrow_back_rounded),
                    )
                  : null,
              title: Text(
                title!,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              actions: actions,
            ),
      body: SafeArea(child: child),
      bottomNavigationBar: currentIndex == null
          ? null
          : LogLineBottomNav(currentIndex: currentIndex!),
      floatingActionButton: floatingActionButton,
    );
  }
}

class LogLineBottomNav extends StatelessWidget {
  const LogLineBottomNav({super.key, required this.currentIndex});

  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: (index) {
        switch (index) {
          case 0:
          case 1:
            context.go(AppRoutePaths.notes);
          case 2:
            context.go(AppRoutePaths.scanner);
          case 3:
            context.go(AppRoutePaths.profile);
        }
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.note_alt_outlined),
          selectedIcon: Icon(Icons.note_alt),
          label: 'Notes',
        ),
        NavigationDestination(
          icon: Icon(Icons.document_scanner_outlined),
          selectedIcon: Icon(Icons.document_scanner),
          label: 'Scan',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }
}
