import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'liquid_glass_surface.dart';

class FloatingNavbar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;

  const FloatingNavbar({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: LiquidGlassSurface(
        blurBehind: true,
        sigma: 35,
        borderRadius: BorderRadius.circular(50),
        tintColor: const Color(0xFF1E1E1E).withValues(alpha: 0.7), // Slightly darker to make white pill pop
        shadowElevation: 20,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _NavItem(
              iconData: HugeIcons.strokeRoundedHome02,
              label: 'Home',
              isSelected: currentIndex == 0,
              onTap: () => onTabSelected(0),
            ),
            const SizedBox(width: 4),
            _NavItem(
              iconData: HugeIcons.strokeRoundedSearch01,
              label: 'Search',
              isSelected: currentIndex == 1,
              onTap: () => onTabSelected(1),
            ),
            const SizedBox(width: 4),
            _NavItem(
              iconData: HugeIcons.strokeRoundedFolderLibrary,
              label: 'Library',
              isSelected: currentIndex == 2,
              onTap: () => onTabSelected(2),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final String? assetPath;
  final dynamic iconData;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    this.assetPath,
    this.iconData,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutExpo,
        width: 86, // Wide enough for text
        height: 56, // Reduced height
        decoration: BoxDecoration(
          color: isSelected ? Colors.white.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(28), // Perfect pill shape
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (iconData != null)
              HugeIcon(
                icon: iconData!,
                size: 22,
                color: isSelected ? Colors.white : Colors.white60,
                strokeWidth: isSelected ? 2.5 : 2.0, // Bold when selected
              )
            else if (assetPath != null)
              Image.asset(
                assetPath!,
                width: 22,
                height: 22,
                color: isSelected ? Colors.white : Colors.white60,
              ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white60,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
