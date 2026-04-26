import 'package:uuid/uuid.dart';

/// A single body check-in entry. All numeric values are stored in metric.
class BodyCheckin {
  BodyCheckin({
    required this.id,
    required this.userId,
    required this.checkinDate,
    this.weightKg,
    this.bodyFatPct,
    this.chestCm,
    this.waistCm,
    this.hipsCm,
    this.neckCm,
    this.shouldersCm,
    this.bicepLeftCm,
    this.bicepRightCm,
    this.tricepLeftCm,
    this.tricepRightCm,
    this.forearmLeftCm,
    this.forearmRightCm,
    this.thighLeftCm,
    this.thighRightCm,
    this.calfLeftCm,
    this.calfRightCm,
    this.notes,
    this.photoPath,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now().toUtc(),
        updatedAt = updatedAt ?? DateTime.now().toUtc();

  final String id;
  final String userId;
  final DateTime checkinDate;
  final double? weightKg;
  final double? bodyFatPct;
  final double? chestCm;
  final double? waistCm;
  final double? hipsCm;
  final double? neckCm;
  final double? shouldersCm;
  final double? bicepLeftCm;
  final double? bicepRightCm;
  final double? tricepLeftCm;
  final double? tricepRightCm;
  final double? forearmLeftCm;
  final double? forearmRightCm;
  final double? thighLeftCm;
  final double? thighRightCm;
  final double? calfLeftCm;
  final double? calfRightCm;
  final String? notes;
  final String? photoPath;
  final DateTime createdAt;
  final DateTime updatedAt;

  static String newId() => const Uuid().v4();

  BodyCheckin copyWith({
    DateTime? checkinDate,
    double? weightKg,
    double? bodyFatPct,
    double? chestCm,
    double? waistCm,
    double? hipsCm,
    double? neckCm,
    double? shouldersCm,
    double? bicepLeftCm,
    double? bicepRightCm,
    double? tricepLeftCm,
    double? tricepRightCm,
    double? forearmLeftCm,
    double? forearmRightCm,
    double? thighLeftCm,
    double? thighRightCm,
    double? calfLeftCm,
    double? calfRightCm,
    String? notes,
    String? photoPath,
    DateTime? updatedAt,
  }) =>
      BodyCheckin(
        id: id,
        userId: userId,
        checkinDate: checkinDate ?? this.checkinDate,
        weightKg: weightKg ?? this.weightKg,
        bodyFatPct: bodyFatPct ?? this.bodyFatPct,
        chestCm: chestCm ?? this.chestCm,
        waistCm: waistCm ?? this.waistCm,
        hipsCm: hipsCm ?? this.hipsCm,
        neckCm: neckCm ?? this.neckCm,
        shouldersCm: shouldersCm ?? this.shouldersCm,
        bicepLeftCm: bicepLeftCm ?? this.bicepLeftCm,
        bicepRightCm: bicepRightCm ?? this.bicepRightCm,
        tricepLeftCm: tricepLeftCm ?? this.tricepLeftCm,
        tricepRightCm: tricepRightCm ?? this.tricepRightCm,
        forearmLeftCm: forearmLeftCm ?? this.forearmLeftCm,
        forearmRightCm: forearmRightCm ?? this.forearmRightCm,
        thighLeftCm: thighLeftCm ?? this.thighLeftCm,
        thighRightCm: thighRightCm ?? this.thighRightCm,
        calfLeftCm: calfLeftCm ?? this.calfLeftCm,
        calfRightCm: calfRightCm ?? this.calfRightCm,
        notes: notes ?? this.notes,
        photoPath: photoPath ?? this.photoPath,
        createdAt: createdAt,
        updatedAt: updatedAt ?? DateTime.now().toUtc(),
      );

  Map<String, dynamic> toUpsertMap() => {
        'id': id,
        'user_id': userId,
        'checkin_date':
            checkinDate.toIso8601String().split('T').first,
        'weight_kg': weightKg,
        'body_fat_pct': bodyFatPct,
        'chest_cm': chestCm,
        'waist_cm': waistCm,
        'hips_cm': hipsCm,
        'neck_cm': neckCm,
        'shoulders_cm': shouldersCm,
        'bicep_left_cm': bicepLeftCm,
        'bicep_right_cm': bicepRightCm,
        'tricep_left_cm': tricepLeftCm,
        'tricep_right_cm': tricepRightCm,
        'forearm_left_cm': forearmLeftCm,
        'forearm_right_cm': forearmRightCm,
        'thigh_left_cm': thighLeftCm,
        'thigh_right_cm': thighRightCm,
        'calf_left_cm': calfLeftCm,
        'calf_right_cm': calfRightCm,
        'notes': notes,
        'photo_path': photoPath,
        'updated_at': updatedAt.toIso8601String(),
      };

  factory BodyCheckin.fromMap(Map<String, dynamic> map) => BodyCheckin(
        id: map['id'] as String,
        userId: map['user_id'] as String,
        checkinDate: DateTime.parse(map['checkin_date'] as String),
        weightKg: _num(map['weight_kg']),
        bodyFatPct: _num(map['body_fat_pct']),
        chestCm: _num(map['chest_cm']),
        waistCm: _num(map['waist_cm']),
        hipsCm: _num(map['hips_cm']),
        neckCm: _num(map['neck_cm']),
        shouldersCm: _num(map['shoulders_cm']),
        bicepLeftCm: _num(map['bicep_left_cm']),
        bicepRightCm: _num(map['bicep_right_cm']),
        tricepLeftCm: _num(map['tricep_left_cm']),
        tricepRightCm: _num(map['tricep_right_cm']),
        forearmLeftCm: _num(map['forearm_left_cm']),
        forearmRightCm: _num(map['forearm_right_cm']),
        thighLeftCm: _num(map['thigh_left_cm']),
        thighRightCm: _num(map['thigh_right_cm']),
        calfLeftCm: _num(map['calf_left_cm']),
        calfRightCm: _num(map['calf_right_cm']),
        notes: map['notes'] as String?,
        photoPath: map['photo_path'] as String?,
        createdAt: DateTime.tryParse('${map['created_at']}'),
        updatedAt: DateTime.tryParse('${map['updated_at']}'),
      );

  static double? _num(Object? v) =>
      v == null ? null : (v is num ? v.toDouble() : double.tryParse('$v'));
}
