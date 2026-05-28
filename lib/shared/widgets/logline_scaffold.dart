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
    final body = SafeArea(child: child);
    return Scaffold(
      backgroundColor: backgroundColor ?? AppColors.background,
      extendBody: true,
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
      body: currentIndex == null
          ? body
          : Stack(
              fit: StackFit.expand,
              children: [
                body,
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: LogLineBottomNav(currentIndex: currentIndex!),
                ),
              ],
            ),
      floatingActionButton: floatingActionButton,
    );
  }
}

class LogLineBottomNav extends StatelessWidget {
  const LogLineBottomNav({super.key, required this.currentIndex});

  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(28, 0, 28, 28),
      child: Align(
        alignment: Alignment.bottomCenter,
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: Container(
            height: 76,
            padding: const EdgeInsets.symmetric(horizontal: 28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(42),
              border: Border.all(color: AppColors.border.withAlpha(120)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.ink.withAlpha(34),
                  blurRadius: 34,
                  spreadRadius: -6,
                  offset: const Offset(0, 18),
                ),
                BoxShadow(
                  color: AppColors.primary.withAlpha(18),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _NavIconButton(
                  icon: currentIndex == 0
                      ? Icons.home_rounded
                      : Icons.home_outlined,
                  selected: currentIndex == 0,
                  onTap: () => context.go(AppRoutePaths.notes),
                ),
                _CameraNavButton(
                  selected: currentIndex == 1,
                  onTap: () => context.go(AppRoutePaths.scanner),
                ),
                _NavIconButton(
                  icon: currentIndex == 2
                      ? Icons.person_rounded
                      : Icons.person_outline_rounded,
                  selected: currentIndex == 2,
                  onTap: () => context.go(AppRoutePaths.profile),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavIconButton extends StatelessWidget {
  const _NavIconButton({
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 48,
      child: IconButton(
        tooltip: selected ? 'Aktif' : null,
        onPressed: onTap,
        icon: Icon(icon),
        color: selected ? AppColors.primary : const Color(0xFF8AA4C7),
        iconSize: 26,
      ),
    );
  }
}

class _CameraNavButton extends StatelessWidget {
  const _CameraNavButton({required this.selected, required this.onTap});

  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 60,
      height: 60,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: selected ? AppColors.ink : AppColors.primary,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withAlpha(92),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: IconButton(
          tooltip: 'Buka kamera',
          onPressed: onTap,
          icon: const Icon(Icons.add_rounded),
          color: Colors.white,
          iconSize: 30,
        ),
      ),
    );
  }
}
