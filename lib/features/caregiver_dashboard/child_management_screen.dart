import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/localization/app_localizations.dart';
import '../../models/barrel.dart';
import '../../providers/session_provider.dart';
import '../../repositories/lumora_repository.dart';
import '../../widgets/sign_out_button.dart';

/// Child management (parent-facing): edits the active child's profile and
/// preferences - name, age, avatar, language, communication methods,
/// favourite activities, sensory/comfort preferences, learning level,
/// enabled context modes and notification triggers.
class ChildManagementScreen extends StatefulWidget {
  const ChildManagementScreen({super.key});

  @override
  State<ChildManagementScreen> createState() => _ChildManagementScreenState();
}

class _ChildManagementScreenState extends State<ChildManagementScreen> {
  late TextEditingController _name;
  late int _age;
  late String _language;
  late String _level;
  late bool _tracking;
  late List<String> _notifiedEmotions;
  late List<String> _enabledModes;
  ChildProfile? _child;

  static const List<String> _modes = <String>[
    'home',
    'school',
    'hospital',
    'travel',
    'public',
    'playground',
    'mealtime',
    'classroom',
    'therapy',
    'bedtime',
  ];

  @override
  void initState() {
    super.initState();
    _child = context.read<SessionProvider>().child;
    _name = TextEditingController(text: _child?.name ?? '');
    _age = _child?.age ?? 6;
    _language = _child?.languageCode ?? 'en';
    _level = _child?.learningLevel ?? 'beginner';
    _tracking = _child?.trackingEnabled ?? true;
    _notifiedEmotions =
        List<String>.from(_child?.notifiedEmotionIds ?? const <String>[]);
    _enabledModes = List<String>.from(
        _child?.enabledModes ?? const <String>['home', 'school']);
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final ChildProfile base = _child ??
        ChildProfile(id: 'unknown', name: _name.text.trim());
    final ChildProfile updated = base.copyWith(
      name: _name.text.trim(),
      age: _age,
      languageCode: _language,
      learningLevel: _level,
      trackingEnabled: _tracking,
      notifiedEmotionIds: _notifiedEmotions,
      enabledModes: _enabledModes,
    );
    await LumoraRepository.instance.saveChild(updated);
    if (!mounted) return;
    await context.read<SessionProvider>().setChild(updated);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.t('common.saved'))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppL10n l = context.l10n;
    final bool editing = _child != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(editing ? l.t('parent.editChild') : l.t('parent.addChild')),
        actions: <Widget>[
          SignOutButton(),
          IconButton(
            tooltip: l.t('common.save'),
            icon: const Icon(Icons.check),
            onPressed: _save,
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            const SizedBox(height: 8),
            TextFormField(
              controller: _name,
              decoration: InputDecoration(labelText: l.t('parent.childName')),
            ),
            const SizedBox(height: 12),
            Text('${l.t('parent.age')}: $_age'),
            Slider(
              value: _age.toDouble(),
              min: 2,
              max: 18,
              divisions: 16,
              label: '$_age',
              onChanged: (double v) => setState(() => _age = v.round()),
            ),
            DropdownButtonFormField<String>(
              initialValue: _language,
              decoration:
                  InputDecoration(labelText: l.t('parent.language')),
              items: const <DropdownMenuItem<String>>[
                DropdownMenuItem<String>(value: 'en', child: Text('English')),
                DropdownMenuItem<String>(value: 'ta', child: Text('தமிழ்')),
              ],
              onChanged: (String? v) =>
                  setState(() => _language = v ?? 'en'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _level,
              decoration: InputDecoration(
                  labelText: l.t('parent.learningLevel')),
              items: <DropdownMenuItem<String>>[
                DropdownMenuItem<String>(
                    value: 'beginner',
                    child: Text(l.t('learn.beginner'))),
                DropdownMenuItem<String>(
                    value: 'intermediate',
                    child: Text(l.t('learn.intermediate'))),
                DropdownMenuItem<String>(
                    value: 'advanced',
                    child: Text(l.t('learn.advanced'))),
              ],
              onChanged: (String? v) =>
                  setState(() => _level = v ?? 'beginner'),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: Text(l.t('track.disableTracking')),
              subtitle: Text(l.t('track.compareNote')),
              value: _tracking,
              onChanged: (bool v) => setState(() => _tracking = v),
            ),
            const Divider(height: 24),
            Text(l.t('parent.modes'),
                style: Theme.of(context).textTheme.titleSmall),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _modes
                  .map((String m) => FilterChip(
                        label: Text(l.t('mode.$m')),
                        selected: _enabledModes.contains(m),
                        onSelected: (bool sel) => setState(() {
                          if (sel) {
                            _enabledModes.add(m);
                          } else {
                            _enabledModes.remove(m);
                          }
                        }),
                      ))
                  .toList(),
            ),
            const Divider(height: 24),
            Text(l.t('parent.notifications'),
                style: Theme.of(context).textTheme.titleSmall),
            Text(l.t('feel.notifyNote'),
                style: Theme.of(context).textTheme.labelSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: EmotionCatalog.ids
                  .map((String e) => FilterChip(
                        label: Text(l.t('emo.$e')),
                        selected: _notifiedEmotions.contains(e),
                        onSelected: (bool sel) => setState(() {
                          if (sel) {
                            _notifiedEmotions.add(e);
                          } else {
                            _notifiedEmotions.remove(e);
                          }
                        }),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _save,
              child: Text(l.t('common.save')),
            ),
          ],
        ),
      ),
    );
  }
}
