import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

class VisionBoardScreen extends StatelessWidget {
  const VisionBoardScreen({super.key});

  static const _placeholders = [
    ('Dream Career', Icons.work_outline, 'Your dream company'),
    ('Dream Salary', Icons.payments_outlined, 'Your target package'),
    ('Dream Lifestyle', Icons.home_outlined, 'Your dream home'),
    ('Dream Car', Icons.directions_car_outlined, 'Your dream ride'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vision Board'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_photo_alternate_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Image upload with Firebase Storage coming soon'),
                ),
              );
            },
          ),
        ],
      ),
      body: GridView.builder(
        padding: AppSpacing.pagePadding,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: AppSpacing.sm,
          mainAxisSpacing: AppSpacing.sm,
          childAspectRatio: 0.85,
        ),
        itemCount: _placeholders.length,
        itemBuilder: (context, index) {
          final (title, icon, subtitle) = _placeholders[index];
          return Card(
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () {},
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary.withValues(alpha: 0.2),
                      AppColors.secondary.withValues(alpha: 0.1),
                    ],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 48, color: AppColors.primary),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.upload, size: 16),
                      label: const Text('Add image'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
