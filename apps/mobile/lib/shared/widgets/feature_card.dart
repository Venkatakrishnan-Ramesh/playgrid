import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';

class FeatureCard extends StatelessWidget {
  const FeatureCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.accent = AppConstants.indigo,
    this.trailing,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(icon, color: accent),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text(subtitle,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant)),
                  ],
                ),
              ),
              if (trailing != null)
                trailing!
              else
                const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}
