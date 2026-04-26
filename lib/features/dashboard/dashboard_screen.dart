import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/units.dart';
import '../../state/providers.dart';
import '../suggestions/suggestion_engine.dart';
import 'dashboard_stats.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final checkinsAsync = ref.watch(checkinsProvider);
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(checkinsProvider);
          ref.invalidate(profileProvider);
          await ref.read(checkinsProvider.future);
        },
        child: checkinsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ListView(children: [Center(child: Text('Error: $e'))]),
          data: (checkins) {
            final profile = profileAsync.valueOrNull;
            final units = profile?.unitSystem ?? UnitSystem.metric;
            final converter = UnitConverter(units);
            final stats = DashboardCalculator(checkins, profile).compute();
            final suggestion =
                const SuggestionEngine().evaluate(checkins, profile);

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _StatCard(
                  title: 'Current weight',
                  value: converter.formatWeight(stats.currentWeightKg),
                ),
                _StatCard(
                  title: '7-day avg weight',
                  value: converter.formatWeight(stats.avg7dWeightKg),
                ),
                _StatCard(
                  title: '30-day weight change',
                  value: _delta(stats.weightChange30dKg, converter.formatWeight),
                ),
                _StatCard(
                  title: '30-day waist change',
                  value: _delta(stats.waistChange30dCm, converter.formatLength),
                ),
                _StatCard(
                  title: '30-day body fat change',
                  value: stats.bodyFatChange30d == null
                      ? '—'
                      : '${stats.bodyFatChange30d!.toStringAsFixed(1)} %',
                ),
                if (stats.goalProgressPct != null)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Goal progress'),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(value: stats.goalProgressPct),
                          const SizedBox(height: 8),
                          Text(
                            '${(stats.goalProgressPct! * 100).toStringAsFixed(0)}% toward target',
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                _SuggestionCard(suggestion: suggestion),
                const SizedBox(height: 16),
                Text(
                  'Logged ${stats.checkinCount} check-ins total.',
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  String _delta(double? value, String Function(double?) format) {
    if (value == null) return '—';
    final sign = value > 0 ? '+' : '';
    return '$sign${format(value)}';
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.title, required this.value});
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(title),
        trailing: Text(
          value,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  const _SuggestionCard({required this.suggestion});
  final Suggestion suggestion;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = switch (suggestion.level) {
      SuggestionLevel.warn => scheme.errorContainer,
      SuggestionLevel.positive => scheme.primaryContainer,
      SuggestionLevel.info => scheme.secondaryContainer,
    };
    final icon = switch (suggestion.level) {
      SuggestionLevel.warn => Icons.warning_amber,
      SuggestionLevel.positive => Icons.check_circle_outline,
      SuggestionLevel.info => Icons.info_outline,
    };
    return Card(
      color: color,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    suggestion.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(suggestion.body),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
