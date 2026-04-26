import '../../core/units.dart';

enum GoalType { loseFat, gainMuscle, recomp, maintain }

extension GoalTypeX on GoalType {
  String get id => switch (this) {
        GoalType.loseFat => 'lose_fat',
        GoalType.gainMuscle => 'gain_muscle',
        GoalType.recomp => 'recomp',
        GoalType.maintain => 'maintain',
      };

  String get label => switch (this) {
        GoalType.loseFat => 'Lose fat',
        GoalType.gainMuscle => 'Gain muscle',
        GoalType.recomp => 'Recomposition',
        GoalType.maintain => 'Maintain',
      };

  static GoalType? fromId(String? id) => switch (id) {
        'lose_fat' => GoalType.loseFat,
        'gain_muscle' => GoalType.gainMuscle,
        'recomp' => GoalType.recomp,
        'maintain' => GoalType.maintain,
        _ => null,
      };
}

class Profile {
  Profile({
    required this.id,
    this.displayName,
    this.sex,
    this.birthDate,
    this.heightCm,
    this.unitSystem = UnitSystem.metric,
    this.goalType,
    this.goalTargetWeightKg,
    this.goalTargetWaistCm,
    this.goalTargetBodyFat,
    this.goalDeadline,
    this.updatedAt,
  });

  final String id;
  final String? displayName;
  final String? sex;
  final DateTime? birthDate;
  final double? heightCm;
  final UnitSystem unitSystem;
  final GoalType? goalType;
  final double? goalTargetWeightKg;
  final double? goalTargetWaistCm;
  final double? goalTargetBodyFat;
  final DateTime? goalDeadline;
  final DateTime? updatedAt;

  Profile copyWith({
    String? displayName,
    String? sex,
    DateTime? birthDate,
    double? heightCm,
    UnitSystem? unitSystem,
    GoalType? goalType,
    double? goalTargetWeightKg,
    double? goalTargetWaistCm,
    double? goalTargetBodyFat,
    DateTime? goalDeadline,
  }) =>
      Profile(
        id: id,
        displayName: displayName ?? this.displayName,
        sex: sex ?? this.sex,
        birthDate: birthDate ?? this.birthDate,
        heightCm: heightCm ?? this.heightCm,
        unitSystem: unitSystem ?? this.unitSystem,
        goalType: goalType ?? this.goalType,
        goalTargetWeightKg: goalTargetWeightKg ?? this.goalTargetWeightKg,
        goalTargetWaistCm: goalTargetWaistCm ?? this.goalTargetWaistCm,
        goalTargetBodyFat: goalTargetBodyFat ?? this.goalTargetBodyFat,
        goalDeadline: goalDeadline ?? this.goalDeadline,
        updatedAt: updatedAt,
      );

  factory Profile.fromMap(Map<String, dynamic> map) => Profile(
        id: map['id'] as String,
        displayName: map['display_name'] as String?,
        sex: map['sex'] as String?,
        birthDate: _date(map['birth_date']),
        heightCm: _num(map['height_cm']),
        unitSystem: UnitSystemX.fromId(map['unit_system'] as String?),
        goalType: GoalTypeX.fromId(map['goal_type'] as String?),
        goalTargetWeightKg: _num(map['goal_target_weight_kg']),
        goalTargetWaistCm: _num(map['goal_target_waist_cm']),
        goalTargetBodyFat: _num(map['goal_target_body_fat']),
        goalDeadline: _date(map['goal_deadline']),
        updatedAt: _ts(map['updated_at']),
      );

  Map<String, dynamic> toUpsertMap() => {
        'id': id,
        'display_name': displayName,
        'sex': sex,
        'birth_date': birthDate?.toIso8601String().split('T').first,
        'height_cm': heightCm,
        'unit_system': unitSystem.id,
        'goal_type': goalType?.id,
        'goal_target_weight_kg': goalTargetWeightKg,
        'goal_target_waist_cm': goalTargetWaistCm,
        'goal_target_body_fat': goalTargetBodyFat,
        'goal_deadline':
            goalDeadline?.toIso8601String().split('T').first,
      };

  static double? _num(Object? v) =>
      v == null ? null : (v is num ? v.toDouble() : double.tryParse('$v'));
  static DateTime? _date(Object? v) =>
      v == null ? null : DateTime.tryParse('$v');
  static DateTime? _ts(Object? v) =>
      v == null ? null : DateTime.tryParse('$v');
}
