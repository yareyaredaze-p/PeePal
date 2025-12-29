import 'dart:ui';
import 'package:flutter/material.dart';
import '../config/themes/app_theme.dart';

/// Glass-styled bottom navigation bar
/// Consistent navigation component across main screens
class GlassBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const GlassBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  static const List<_NavItem> _items = [
    _NavItem(icon: Icons.home_rounded, label: 'Home'),
    _NavItem(icon: Icons.list_rounded, label: 'List'),
    _NavItem(icon: Icons.calendar_month_rounded, label: 'Calendar'),
    _NavItem(icon: Icons.person_rounded, label: 'Account'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(AppTheme.spacingM),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(35),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Stack(
            children: [
              // Liquid Background
              Container(
                height: 70,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingM,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.0, 0.4, 1.0],
                    colors: [
                      AppTheme.glassSurface.withValues(alpha: 0.35),
                      AppTheme.glassSurface.withValues(alpha: 0.15),
                      AppTheme.glassSurface.withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(35),
                  border: Border.all(
                    color: AppTheme.glassBorder.withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(
                    _items.length,
                    (index) => _NavBarItem(
                      icon: _items[index].icon,
                      label: _items[index].label,
                      isSelected: currentIndex == index,
                      onTap: () => onTap(index),
                    ),
                  ),
                ),
              ),

              // Top Highlight Edge
              Positioned(
                top: 0,
                left: 35,
                right: 35,
                height: 1.5,
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.0),
                          Colors.white.withValues(alpha: 0.4),
                          Colors.white.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;

  const _NavItem({required this.icon, required this.label});
}

class _NavBarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      splashColor: AppTheme.lightBlue.withValues(alpha: 0.1),
      highlightColor: Colors.transparent,
      child: AnimatedContainer(
        duration: AppTheme.animationFast,
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingM,
          vertical: AppTheme.spacingS,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.glassSurface.withValues(alpha: 0.3)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(35),
        ),
        child: Icon(
          icon,
          size: 28,
          color: isSelected ? AppTheme.textPrimary : AppTheme.textMuted,
        ),
      ),
    );
  }
}
