import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/units.dart';
import '../../data/models/body_checkin.dart';
import '../../state/providers.dart';

class CheckinFormScreen extends ConsumerStatefulWidget {
  const CheckinFormScreen({super.key, this.existing});
  final BodyCheckin? existing;

  @override
  ConsumerState<CheckinFormScreen> createState() => _CheckinFormScreenState();
}

class _CheckinFormScreenState extends ConsumerState<CheckinFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late DateTime _date;
  final _notes = TextEditingController();

  // All controllers store the value in the user's display unit; convert on save.
  late final Map<String, TextEditingController> _ctrls;

  @override
  void initState() {
    super.initState();
    _date = widget.existing?.checkinDate ?? DateTime.now();
    _notes.text = widget.existing?.notes ?? '';
    _ctrls = {
      for (final f in _fields) f.key: TextEditingController(),
    };
  }

  @override
  void dispose() {
    _notes.dispose();
    for (final c in _ctrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _populateFromExisting(UnitConverter conv) {
    final e = widget.existing;
    if (e == null) return;
    _ctrls['weight']!.text = e.weightKg == null
        ? ''
        : conv.weightFromKg(e.weightKg).toStringAsFixed(1);
    _ctrls['bodyFat']!.text =
        e.bodyFatPct == null ? '' : e.bodyFatPct!.toStringAsFixed(1);
    void setLen(String key, double? cm) {
      _ctrls[key]!.text = cm == null ? '' : conv.lengthFromCm(cm).toStringAsFixed(1);
    }

    setLen('chest', e.chestCm);
    setLen('waist', e.waistCm);
    setLen('hips', e.hipsCm);
    setLen('neck', e.neckCm);
    setLen('shoulders', e.shouldersCm);
    setLen('bicepLeft', e.bicepLeftCm);
    setLen('bicepRight', e.bicepRightCm);
    setLen('tricepLeft', e.tricepLeftCm);
    setLen('tricepRight', e.tricepRightCm);
    setLen('forearmLeft', e.forearmLeftCm);
    setLen('forearmRight', e.forearmRightCm);
    setLen('thighLeft', e.thighLeftCm);
    setLen('thighRight', e.thighRightCm);
    setLen('calfLeft', e.calfLeftCm);
    setLen('calfRight', e.calfRightCm);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDate: _date,
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final user = ref.read(currentUserProvider);
    final units = ref.read(profileProvider).valueOrNull?.unitSystem ??
        UnitSystem.metric;
    final conv = UnitConverter(units);

    double? readW(String key) {
      final s = _ctrls[key]!.text.trim();
      if (s.isEmpty) return null;
      final v = double.tryParse(s);
      return v == null ? null : conv.weightToKg(v);
    }

    double? readL(String key) {
      final s = _ctrls[key]!.text.trim();
      if (s.isEmpty) return null;
      final v = double.tryParse(s);
      return v == null ? null : conv.lengthToCm(v);
    }

    double? readPct(String key) {
      final s = _ctrls[key]!.text.trim();
      if (s.isEmpty) return null;
      return double.tryParse(s);
    }

    final userId = user?.id ?? widget.existing?.userId ?? 'local-user';
    final base = widget.existing ??
        BodyCheckin(
          id: BodyCheckin.newId(),
          userId: userId,
          checkinDate: _date,
        );

    final next = base.copyWith(
      checkinDate: _date,
      weightKg: readW('weight'),
      bodyFatPct: readPct('bodyFat'),
      chestCm: readL('chest'),
      waistCm: readL('waist'),
      hipsCm: readL('hips'),
      neckCm: readL('neck'),
      shouldersCm: readL('shoulders'),
      bicepLeftCm: readL('bicepLeft'),
      bicepRightCm: readL('bicepRight'),
      tricepLeftCm: readL('tricepLeft'),
      tricepRightCm: readL('tricepRight'),
      forearmLeftCm: readL('forearmLeft'),
      forearmRightCm: readL('forearmRight'),
      thighLeftCm: readL('thighLeft'),
      thighRightCm: readL('thighRight'),
      calfLeftCm: readL('calfLeft'),
      calfRightCm: readL('calfRight'),
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      updatedAt: DateTime.now().toUtc(),
    );

    await ref.read(checkinsProvider.notifier).save(next);
    if (mounted) Navigator.of(context).pop();
  }

  static const _fields = <_Field>[
    _Field('weight', 'Weight', isWeight: true),
    _Field('bodyFat', 'Body fat %', isPercent: true),
    _Field('chest', 'Chest'),
    _Field('waist', 'Waist'),
    _Field('hips', 'Hips'),
    _Field('neck', 'Neck'),
    _Field('shoulders', 'Shoulders'),
    _Field('bicepLeft', 'Bicep (L)'),
    _Field('bicepRight', 'Bicep (R)'),
    _Field('tricepLeft', 'Tricep (L)'),
    _Field('tricepRight', 'Tricep (R)'),
    _Field('forearmLeft', 'Forearm (L)'),
    _Field('forearmRight', 'Forearm (R)'),
    _Field('thighLeft', 'Thigh (L)'),
    _Field('thighRight', 'Thigh (R)'),
    _Field('calfLeft', 'Calf (L)'),
    _Field('calfRight', 'Calf (R)'),
  ];

  bool _populated = false;

  @override
  Widget build(BuildContext context) {
    final units = ref.watch(profileProvider).valueOrNull?.unitSystem ??
        UnitSystem.metric;
    final conv = UnitConverter(units);

    if (!_populated) {
      _populateFromExisting(conv);
      _populated = true;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing == null ? 'New check-in' : 'Edit check-in'),
        actions: [
          IconButton(onPressed: _save, icon: const Icon(Icons.check)),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Date'),
              subtitle: Text(DateFormat.yMMMMd().format(_date)),
              trailing: TextButton(
                onPressed: _pickDate,
                child: const Text('Change'),
              ),
            ),
            const Divider(),
            for (final f in _fields)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TextFormField(
                  controller: _ctrls[f.key],
                  decoration: InputDecoration(
                    labelText: f.label,
                    suffixText: f.suffix(units),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _notes,
              decoration: const InputDecoration(labelText: 'Notes'),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save),
              label: const Text('Save check-in'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Field {
  const _Field(
    this.key,
    this.label, {
    this.isWeight = false,
    this.isPercent = false,
  });
  final String key;
  final String label;
  final bool isWeight;
  final bool isPercent;

  String suffix(UnitSystem units) {
    if (isPercent) return '%';
    if (isWeight) return units.weightLabel;
    return units.lengthLabel;
  }
}
