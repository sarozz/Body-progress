import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/units.dart';
import '../../state/providers.dart';
import 'checkin_form_screen.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final checkinsAsync = ref.watch(checkinsProvider);
    final units = ref.watch(profileProvider).valueOrNull?.unitSystem ??
        UnitSystem.metric;
    final converter = UnitConverter(units);
    final df = DateFormat.yMMMd();

    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: checkinsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (items) {
          if (items.isEmpty) {
            return const Center(
              child: Text('No check-ins yet. Tap + to add one.'),
            );
          }
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final c = items[i];
              return Dismissible(
                key: ValueKey(c.id),
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                direction: DismissDirection.endToStart,
                confirmDismiss: (_) async {
                  return await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Delete check-in?'),
                          content: const Text('This cannot be undone.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Cancel'),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      ) ??
                      false;
                },
                onDismissed: (_) {
                  ref.read(checkinsProvider.notifier).delete(c.id);
                },
                child: ListTile(
                  title: Text(df.format(c.checkinDate)),
                  subtitle: Text([
                    if (c.weightKg != null)
                      converter.formatWeight(c.weightKg),
                    if (c.waistCm != null)
                      'waist ${converter.formatLength(c.waistCm)}',
                    if (c.bodyFatPct != null)
                      'BF ${c.bodyFatPct!.toStringAsFixed(1)}%',
                  ].join(' · ')),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => CheckinFormScreen(existing: c),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
