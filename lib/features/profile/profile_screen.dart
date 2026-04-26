import 'dart:convert';
import 'dart:typed_data';

import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/units.dart';
import '../../data/models/profile.dart';
import '../../state/providers.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _displayName = TextEditingController();
  final _heightCtrl = TextEditingController();
  final _targetWeightCtrl = TextEditingController();
  final _targetWaistCtrl = TextEditingController();
  final _targetBfCtrl = TextEditingController();

  UnitSystem _units = UnitSystem.metric;
  GoalType? _goal;
  String? _sex;
  DateTime? _birthDate;
  DateTime? _deadline;
  bool _hydrated = false;

  @override
  void dispose() {
    _displayName.dispose();
    _heightCtrl.dispose();
    _targetWeightCtrl.dispose();
    _targetWaistCtrl.dispose();
    _targetBfCtrl.dispose();
    super.dispose();
  }

  void _hydrate(Profile p) {
    if (_hydrated) return;
    _hydrated = true;
    _displayName.text = p.displayName ?? '';
    _units = p.unitSystem;
    final conv = UnitConverter(_units);
    _heightCtrl.text = p.heightCm == null
        ? ''
        : conv.lengthFromCm(p.heightCm).toStringAsFixed(1);
    _targetWeightCtrl.text = p.goalTargetWeightKg == null
        ? ''
        : conv.weightFromKg(p.goalTargetWeightKg).toStringAsFixed(1);
    _targetWaistCtrl.text = p.goalTargetWaistCm == null
        ? ''
        : conv.lengthFromCm(p.goalTargetWaistCm).toStringAsFixed(1);
    _targetBfCtrl.text = p.goalTargetBodyFat == null
        ? ''
        : p.goalTargetBodyFat!.toStringAsFixed(1);
    _goal = p.goalType;
    _sex = p.sex;
    _birthDate = p.birthDate;
    _deadline = p.goalDeadline;
  }

  Future<void> _save() async {
    final user = ref.read(currentUserProvider);
    final id = user?.id ?? 'local-user';
    final conv = UnitConverter(_units);
    final updated = Profile(
      id: id,
      displayName: _displayName.text.trim().isEmpty
          ? null
          : _displayName.text.trim(),
      sex: _sex,
      birthDate: _birthDate,
      heightCm: _parseLen(_heightCtrl.text, conv),
      unitSystem: _units,
      goalType: _goal,
      goalTargetWeightKg: _parseWeight(_targetWeightCtrl.text, conv),
      goalTargetWaistCm: _parseLen(_targetWaistCtrl.text, conv),
      goalTargetBodyFat: double.tryParse(_targetBfCtrl.text.trim()),
      goalDeadline: _deadline,
    );
    await ref.read(profileProvider.notifier).save(updated);
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Profile saved')));
    }
  }

  double? _parseWeight(String s, UnitConverter conv) {
    final v = double.tryParse(s.trim());
    return v == null ? null : conv.weightToKg(v);
  }

  double? _parseLen(String s, UnitConverter conv) {
    final v = double.tryParse(s.trim());
    return v == null ? null : conv.lengthToCm(v);
  }

  Future<void> _exportData() async {
    final checkins = await ref.read(checkinsProvider.future);
    final profile = await ref.read(profileProvider.future);
    final payload = {
      'exported_at': DateTime.now().toUtc().toIso8601String(),
      'profile': profile == null ? null : profile.toUpsertMap(),
      'checkins': checkins.map((c) => c.toUpsertMap()).toList(),
    };
    final bytes = Uint8List.fromList(
      utf8.encode(const JsonEncoder.withIndent('  ').convert(payload)),
    );
    await FileSaver.instance.saveFile(
      name: 'body-progress-${DateTime.now().toIso8601String().split("T").first}',
      bytes: bytes,
      ext: 'json',
      mimeType: MimeType.json,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Exported')),
      );
    }
  }

  Future<void> _signOut() async {
    await ref.read(authRepositoryProvider).signOut();
    ref.invalidate(profileProvider);
    ref.invalidate(checkinsProvider);
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete account?'),
            content: const Text(
              'This permanently removes your account and all of your data. '
              'This cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed) return;

    final db = ref.read(appDatabaseProvider);
    try {
      await ref.read(authRepositoryProvider).deleteAccount();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Remote delete failed: $e')),
        );
      }
    }
    await db.wipeAll();
    ref.invalidate(profileProvider);
    ref.invalidate(checkinsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(onPressed: _save, icon: const Icon(Icons.check)),
        ],
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (p) {
          if (p != null) _hydrate(p);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextField(
                controller: _displayName,
                decoration: const InputDecoration(labelText: 'Display name'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _sex,
                decoration: const InputDecoration(labelText: 'Sex'),
                items: const [
                  DropdownMenuItem(value: 'male', child: Text('Male')),
                  DropdownMenuItem(value: 'female', child: Text('Female')),
                  DropdownMenuItem(value: 'other', child: Text('Other')),
                  DropdownMenuItem(
                      value: 'prefer_not_to_say',
                      child: Text('Prefer not to say')),
                ],
                onChanged: (v) => setState(() => _sex = v),
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Birth date'),
                subtitle: Text(_birthDate == null
                    ? 'Not set'
                    : DateFormat.yMMMMd().format(_birthDate!)),
                trailing: TextButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      firstDate: DateTime(1900),
                      lastDate: DateTime.now(),
                      initialDate: _birthDate ?? DateTime(2000),
                    );
                    if (picked != null) setState(() => _birthDate = picked);
                  },
                  child: const Text('Pick'),
                ),
              ),
              const Divider(),
              const SizedBox(height: 4),
              Text('Units', style: Theme.of(context).textTheme.titleMedium),
              SegmentedButton<UnitSystem>(
                segments: const [
                  ButtonSegment(value: UnitSystem.metric, label: Text('kg / cm')),
                  ButtonSegment(value: UnitSystem.imperial, label: Text('lb / in')),
                ],
                selected: {_units},
                onSelectionChanged: (s) => setState(() {
                  _units = s.first;
                  _hydrated = false; // reformat fields in new units
                  if (p != null) _hydrate(p);
                }),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _heightCtrl,
                decoration: InputDecoration(
                  labelText: 'Height',
                  suffixText: _units.lengthLabel,
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
              const Divider(),
              const SizedBox(height: 4),
              Text('Goal', style: Theme.of(context).textTheme.titleMedium),
              DropdownButtonFormField<GoalType>(
                value: _goal,
                decoration: const InputDecoration(labelText: 'Goal type'),
                items: GoalType.values
                    .map((g) =>
                        DropdownMenuItem(value: g, child: Text(g.label)))
                    .toList(),
                onChanged: (v) => setState(() => _goal = v),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _targetWeightCtrl,
                decoration: InputDecoration(
                  labelText: 'Target weight',
                  suffixText: _units.weightLabel,
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _targetWaistCtrl,
                decoration: InputDecoration(
                  labelText: 'Target waist',
                  suffixText: _units.lengthLabel,
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _targetBfCtrl,
                decoration: const InputDecoration(
                  labelText: 'Target body fat',
                  suffixText: '%',
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Goal deadline'),
                subtitle: Text(_deadline == null
                    ? 'Not set'
                    : DateFormat.yMMMMd().format(_deadline!)),
                trailing: TextButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                      initialDate: _deadline ?? DateTime.now(),
                    );
                    if (picked != null) setState(() => _deadline = picked);
                  },
                  child: const Text('Pick'),
                ),
              ),
              const Divider(),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save),
                label: const Text('Save profile'),
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: _exportData,
                icon: const Icon(Icons.download),
                label: const Text('Export my data (JSON)'),
              ),
              const SizedBox(height: 12),
              if (ref.read(authRepositoryProvider).isConfigured)
                OutlinedButton.icon(
                  onPressed: _signOut,
                  icon: const Icon(Icons.logout),
                  label: const Text('Sign out'),
                ),
              const SizedBox(height: 12),
              if (ref.read(authRepositoryProvider).isConfigured)
                TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                  ),
                  onPressed: _deleteAccount,
                  icon: const Icon(Icons.delete_forever),
                  label: const Text('Delete account'),
                ),
              const SizedBox(height: 12),
              Text(
                'No medical advice. Body Progress provides observational tracking only.',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          );
        },
      ),
    );
  }
}
