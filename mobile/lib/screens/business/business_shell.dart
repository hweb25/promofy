import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../widgets/effects.dart';

class BusinessShell extends StatelessWidget {
  final Widget child;
  const BusinessShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          boxShadow: AppTheme.navShadow,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: Icons.dashboard_rounded,
                  label: 'Dashboard',
                  isSelected: location == '/business',
                  onTap: () => context.go('/business'),
                ),
                _NavItem(
                  icon: Icons.bar_chart_rounded,
                  label: 'Analytics',
                  isSelected: location == '/business/analytics',
                  onTap: () => context.go('/business/analytics'),
                ),
                _NavItem(
                  icon: Icons.qr_code_scanner_rounded,
                  label: 'Scan',
                  isSelected: location == '/business/scanner',
                  onTap: () => context.go('/business/scanner'),
                  isHighlighted: true,
                ),
                _NavItem(
                  icon: Icons.store_rounded,
                  label: 'Profile',
                  isSelected: location == '/business/profile',
                  onTap: () => context.go('/business/profile'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final bool isHighlighted;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    // The Scan action is the business owner's most frequent task, so it gets a
    // raised, gradient "FAB-style" treatment in the centre of the bar.
    if (isHighlighted) {
      return PressableScale(
        haptic: false,
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(18),
            boxShadow: AppTheme.floatingShadow,
          ),
          child: Icon(icon, color: Colors.white, size: 28),
        ),
      );
    }

    final color = isSelected ? AppTheme.primaryColor : AppTheme.textLight;
    return PressableScale(
      haptic: false,
      onTap: () {
        if (!isSelected) HapticFeedback.selectionClick();
        onTap();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: Icon(icon, key: ValueKey(isSelected), color: color, size: 24),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
