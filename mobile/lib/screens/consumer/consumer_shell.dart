import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';

class ConsumerShell extends StatelessWidget {
  final Widget child;
  const ConsumerShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: child,
      bottomNavigationBar: _FloatingNavBar(),
    );
  }
}

class _FloatingNavBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;

    final items = [
      _NavItemData(
        icon: Icons.home_rounded,
        outlinedIcon: Icons.home_outlined,
        label: 'Home',
        route: '/consumer',
      ),
      _NavItemData(
        icon: Icons.explore_rounded,
        outlinedIcon: Icons.explore_outlined,
        label: 'Explore',
        route: '/consumer/map',
      ),
      _NavItemData(
        icon: Icons.local_offer_rounded,
        outlinedIcon: Icons.local_offer_outlined,
        label: 'Deals',
        route: '/consumer/promotions',
      ),
      _NavItemData(
        icon: Icons.person_rounded,
        outlinedIcon: Icons.person_outline_rounded,
        label: 'Profile',
        route: '/consumer/profile',
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
        boxShadow: AppTheme.navShadow,
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: items.map((item) {
              final isSelected = location == item.route;
              return _NavItemWidget(
                item: item,
                isSelected: isSelected,
                onTap: () {
                  if (!isSelected) HapticFeedback.selectionClick();
                  context.go(item.route);
                },
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _NavItemData {
  final IconData icon;
  final IconData outlinedIcon;
  final String label;
  final String route;

  const _NavItemData({
    required this.icon,
    required this.outlinedIcon,
    required this.label,
    required this.route,
  });
}

class _NavItemWidget extends StatelessWidget {
  final _NavItemData item;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItemWidget({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 72,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              width: isSelected ? 52 : 44,
              height: isSelected ? 52 : 44,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primaryColor.withOpacity(0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      isSelected ? item.icon : item.outlinedIcon,
                      key: ValueKey(isSelected),
                      size: isSelected ? 26 : 24,
                      color: isSelected ? AppTheme.primaryColor : AppTheme.textLight,
                    ),
                  ),

                  // Active dot indicator
                  if (isSelected)
                    Positioned(
                      bottom: 6,
                      child: Container(
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(
                          color: AppTheme.primaryColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 4),

            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                color: isSelected ? AppTheme.primaryColor : AppTheme.textLight,
              ),
              child: Text(item.label),
            ),
          ],
        ),
      ),
    );
  }
}
