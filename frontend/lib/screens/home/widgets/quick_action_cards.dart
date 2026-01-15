import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class QuickActionCards extends StatelessWidget {
  const QuickActionCards({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildActionCard(
            context,
            title: 'Report Lost',
            subtitle: 'Item, Pet, or Person',
            backgroundColor: const Color(0xFFFEE2E2),
            iconColor: const Color(0xFFEF4444),
            onTap: () => context.push('/report-lost-item'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildActionCard(
            context,
            title: 'Report Found',
            subtitle: 'Help someone today',
            backgroundColor: const Color(0xFFD1FAE5),
            iconColor: const Color(0xFF10B981),
            onTap: () => context.push('/report-found-item'),
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required Color backgroundColor,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          color: isDark ? backgroundColor.withOpacity(0.2) : backgroundColor,
          borderRadius: BorderRadius.circular(20),
          border: isDark ? Border.all(color: iconColor.withOpacity(0.3)) : null,
        ),
        child: Column(
          children: [
            // Glowing orb icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: iconColor,
                boxShadow: [
                  BoxShadow(
                    color: iconColor.withAlpha(100),
                    blurRadius: 20,
                    spreadRadius: 4,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
