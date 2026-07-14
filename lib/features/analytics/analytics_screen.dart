import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../providers/app_providers.dart';
import '../../shared/widgets/progress_ring.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(analyticsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Analytics')),
      body: analyticsAsync.when(
        data: (analytics) => ListView(
          padding: AppSpacing.pagePadding,
          children: [
            Center(
              child: ProgressRing(
                percent: analytics.successProbability,
                size: 160,
                strokeWidth: 14,
                color: AppColors.success,
                center: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${analytics.successProbability.toInt()}%',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      'Success Probability',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
            if (analytics.predictionExplanation != null) ...[
              const SizedBox(height: AppSpacing.md),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Text(analytics.predictionExplanation!),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: AppSpacing.sm,
              crossAxisSpacing: AppSpacing.sm,
              childAspectRatio: 1.4,
              children: [
                StatCard(
                  label: 'Consistency',
                  value: '${analytics.consistencyPercent.toInt()}%',
                  icon: Icons.calendar_today,
                  color: AppColors.primary,
                ),
                StatCard(
                  label: 'Goal Progress',
                  value: '${analytics.goalCompletionPercent.toInt()}%',
                  icon: Icons.flag,
                  color: AppColors.secondary,
                ),
                StatCard(
                  label: 'Focus Score',
                  value: '${analytics.focusScore.toInt()}%',
                  icon: Icons.center_focus_strong,
                  color: AppColors.info,
                ),
                StatCard(
                  label: 'Recovery',
                  value: '${analytics.recoveryScore.toInt()}%',
                  icon: Icons.healing,
                  color: AppColors.warning,
                ),
                StatCard(
                  label: 'Avg Daily Hours',
                  value: analytics.averageDailyHours.toStringAsFixed(1),
                  icon: Icons.schedule,
                ),
                StatCard(
                  label: 'Missed Days',
                  value: '${analytics.missedDays}',
                  icon: Icons.event_busy,
                  color: AppColors.error,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Predictions',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: _PredictionCard(
                    label: 'If you continue',
                    value: analytics.probabilityIfContinues ?? 0,
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _PredictionCard(
                    label: 'If you skip',
                    value: analytics.probabilityIfSkips ?? 0,
                    color: AppColors.error,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Weekly Trend',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: 200,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: LineChart(
                    LineChartData(
                      gridData: const FlGridData(show: false),
                      titlesData: const FlTitlesData(show: false),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: analytics.weeklyTrend
                              .asMap()
                              .entries
                              .map((e) => FlSpot(
                                    e.key.toDouble(),
                                    e.value,
                                  ))
                              .toList(),
                          isCurved: true,
                          color: AppColors.primary,
                          barWidth: 3,
                          dotData: const FlDotData(show: true),
                          belowBarData: BarAreaData(
                            show: true,
                            color: AppColors.primary.withValues(alpha: 0.1),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _PredictionCard extends StatelessWidget {
  const _PredictionCard({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            Text(
              '${value.toInt()}%',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
