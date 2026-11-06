import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/localization/app_localizations.dart';
import '../../models/child_profile.dart';
import '../../providers/session_provider.dart';
import '../../repositories/lumora_repository.dart';
import '../../widgets/barrel.dart';

/// Parent control of the Child Home layout: which buttons are visible,
/// their order (move up/down) and size (large buttons toggle).
class HomeLayoutScreen extends StatefulWidget {
  const HomeLayoutScreen({super.key});

  @override
  State<HomeLayoutScreen> createState() => _HomeLayoutScreenState();
}

class _HomeLayoutScreenState extends State<HomeLayoutScreen> {
  static const Map<String, String> _labelKeys = <String, String>{
    'talk': 'home.talk',
    'pictures': 'home.pictures',
    'needs': 'home.myNeeds',
    'feelings': 'home.myFeelings',
    'learn': 'home.learnPlay',
    'routine': 'home.myRoutine',
    'calm': 'home.calmSpace',
    'safety': 'home.safety',
    'progress': 'home.myProgress',
    'profile': 'common.profile',
  };

  late List<String> _layout;
  late bool _largeButtons;
  ChildProfile? _child;

  @override
  void initState() {
    super.initState();
    _child = context.read<SessionProvider>().child;
    _layout = List<String>.from(
        _child?.homeLayout ?? _labelKeys.keys.toList());
    _largeButtons = _child?.largeButtons ?? false;
  }

  Future<void> _save() async {
    if (_child == null) return;
    final ChildProfile updated =
        _child!.copyWith(homeLayout: _layout, largeButtons: _largeButtons);
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

    return Scaffold(
      appBar: AppBar(
        title: Text(l.t('parent.homeLayout')),        actions: <Widget>[
          SignOutButton(),
          IconButton(
            tooltip: l.t('common.save'),
            icon: const Icon(Icons.check),
            onPressed: _save,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            SwitchListTile(
              title: Text(l.t('parent.buttonSize')),
              subtitle: Text(l.t('a11y.largeButtons')),
              value: _largeButtons,
              onChanged: (bool v) => setState(() => _largeButtons = v),
            ),
            const Divider(),
            Expanded(
              child: ReorderableListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: _layout.length,
                onReorderItem: (int oldIndex, int newIndex) {
                  setState(() {
                    final String item = _layout.removeAt(oldIndex);
                    _layout.insert(newIndex, item);
                  });
                },
                itemBuilder: (BuildContext context, int i) {
                  final String key = _layout[i];
                  return Card(
                    key: ValueKey<String>(key),
                    child: ListTile(
                      leading: const Icon(Icons.drag_indicator),
                      title: Text(l.t(_labelKeys[key] ?? key)),
                      trailing: IconButton(
                        icon: const Icon(Icons.visibility_off),
                        tooltip: l.t('common.hide'),
                        onPressed: () =>
                            setState(() => _layout.removeAt(i)),
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Wrap(
                spacing: 8,
                children: _labelKeys.keys
                    .where((String k) => !_layout.contains(k))
                    .map((String k) => ActionChip(
                          label: Text('+ ${l.t(_labelKeys[k]!)}'),
                          onPressed: () =>
                              setState(() => _layout.add(k)),
                        ))
                    .toList(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _save,
                  child: Text(l.t('common.save')),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
