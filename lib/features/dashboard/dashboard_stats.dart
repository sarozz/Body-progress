import '../../data/models/body_checkin.dart';
import '../../data/models/profile.dart';

/// Aggregated stats derived from a user's check-ins for the dashboard.
class DashboardStats {
  DashboardStats({
    required this.checkinCount,
    this.currentWeightKg,
    this.avg7dWeightKg,
    this.weightChange30dKg,
    this.waistChange30dCm,
    this.bodyFatChange30d,
    this.goalProgressPct,
  });

  final int checkinCount;
  final double? currentWeightKg;
  final double? avg7dWeightKg;
  final double? weightChange30dKg;
  final double? waistChange30dCm;
  final double? bodyFatChange30d;

  /// 0..1 progress toward the primary goal target weight, if set.
  final double? goalProgressPct;
}

class DashboardCalculator {
  DashboardCalculator(this.checkins, this.profile);
  final List<BodyCheckin> checkins; // expected newest-first
  final Profile? profile;

  DashboardStats compute() {
    if (checkins.isEmpty) {
      return DashboardStats(checkinCount: 0);
    }

    final sorted = [...checkins]
      ..sort((a, b) => b.checkinDate.compareTo(a.checkinDate));
    final latest = sorted.first;
    final now = DateTime.now();

    final last7d = sorted
        .where((c) => now.difference(c.checkinDate).inDays <= 7)
        .map((c) => c.weightKg)
        .whereType<double>()
        .toList();
    final avg7 = last7d.isEmpty
        ? null
        : last7d.reduce((a, b) => a + b) / last7d.length;

    final ref30 = _closestBefore(sorted, now.subtract(const Duration(days: 30)));

    final weightDelta = (latest.weightKg != null && ref30?.weightKg != null)
        ? latest.weightKg! - ref30!.weightKg!
        : null;
    final waistDelta = (latest.waistCm != null && ref30?.waistCm != null)
        ? latest.waistCm! - ref30!.waistCm!
        : null;
    final bfDelta = (latest.bodyFatPct != null && ref30?.bodyFatPct != null)
        ? latest.bodyFatPct! - ref30!.bodyFatPct!
        : null;

    double? goalProgress;
    final target = profile?.goalTargetWeightKg;
    if (target != null && latest.weightKg != null && sorted.length >= 2) {
      final start = sorted.last.weightKg;
      if (start != null && (start - target).abs() > 0.01) {
        final progressed = start - latest.weightKg!;
        final needed = start - target;
        goalProgress = (progressed / needed).clamp(0.0, 1.0);
      }
    }

    return DashboardStats(
      checkinCount: sorted.length,
      currentWeightKg: latest.weightKg,
      avg7dWeightKg: avg7,
      weightChange30dKg: weightDelta,
      waistChange30dCm: waistDelta,
      bodyFatChange30d: bfDelta,
      goalProgressPct: goalProgress,
    );
  }

  static BodyCheckin? _closestBefore(List<BodyCheckin> sorted, DateTime when) {
    BodyCheckin? best;
    for (final c in sorted) {
      if (!c.checkinDate.isAfter(when)) {
        best = c;
        break;
      }
    }
    return best ?? (sorted.length >= 2 ? sorted.last : null);
  }
}
