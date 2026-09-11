import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_theme.dart';
import '../tracker.dart';
import '../tracker_models.dart';
import 'formatters.dart';
import 'history_view.dart';
import 'pause_dialog.dart';
import 'setup_dialog.dart';
import 'today_view.dart';
import 'tracker_widgets.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  static const routePath = '/';

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final AppLifecycleListener _lifecycle;
  final _scrollController = ScrollController();
  Tracker? _tracker;
  String? _error;
  bool _busy = false;
  bool _loading = false;
  int _tab = 0;
  DateTime _now = DateTime.now();
  DateTime _selected = dayOf(DateTime.now());

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onResume: _refresh);
    unawaited(_load());
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _scrollController.dispose();
    unawaited(_tracker?.close());
    super.dispose();
  }

  Future<void> _load() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final tracker = await Tracker.open();
      if (!mounted) {
        await tracker.close();
        return;
      }
      setState(() => _tracker = tracker);
      _refresh();
    } catch (error, stack) {
      debugPrint('Could not open tracker: $error\n$stack');
      if (mounted) {
        setState(() => _error = 'Datenbank konnte nicht geöffnet werden.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // Recalculate on interaction and resume. No periodic timer or background work.
  void _refresh() {
    if (!mounted) return;
    setState(() {
      final today = dayOf(DateTime.now());
      if (_selected == dayOf(_now) || _selected.isAfter(today)) {
        _selected = today;
      }
      _now = DateTime.now();
      final firstDay = _tracker?.firstDay;
      if (firstDay != null && _selected.isBefore(firstDay)) {
        _selected = firstDay;
      }
    });
  }

  Future<void> _perform(Future<void> Function() action) async {
    if (_busy || !mounted) return;
    setState(() => _busy = true);
    try {
      await action();
    } catch (error, stack) {
      if (error is! FormatException) {
        debugPrint('Tracker write failed: $error\n$stack');
      }
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(saveError(error))));
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
        _refresh();
      }
    }
  }

  Future<void> _setup() async {
    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => SetupDialog(tracker: _tracker!),
    );
    _refresh();
  }

  Future<void> _editPause(PauseInterval? pause) async {
    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          PauseDialog(tracker: _tracker!, day: _selected, pause: pause),
    );
    _refresh();
  }

  Future<void> _changeTray() async {
    final tracker = _tracker!;
    final number = tracker.current!.number + 1;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Schiene wechseln?'),
        content: Text(
          'Schiene $number startet heute mit $daysPerTray neuen Tragetagen. Eine offene Pause bleibt bestehen, bis du das Einsetzen stempelst.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Wechsel bestätigen'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await _perform(() => tracker.startTray(number, DateTime.now()));
    }
  }

  void _select(DateTime date) {
    _refresh();
    setState(() => _selected = date);
  }

  @override
  Widget build(BuildContext context) {
    final tracker = _tracker;
    return Scaffold(
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppTheme.line)),
        ),
        child: NavigationBar(
          selectedIndex: _tab,
          onDestinationSelected: (value) {
            _refresh();
            setState(() => _tab = value);
            if (_scrollController.hasClients) _scrollController.jumpTo(0);
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Heute',
            ),
            NavigationDestination(
              icon: Icon(Icons.bar_chart_outlined),
              selectedIcon: Icon(Icons.bar_chart_rounded),
              label: 'Verlauf',
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: tracker == null
            ? Center(
                child: _error == null
                    ? const CircularProgressIndicator()
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_error!),
                          TextButton(
                            onPressed: _loading ? null : _load,
                            child: const Text('Erneut versuchen'),
                          ),
                        ],
                      ),
              )
            : Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 680),
                  child: ListView(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(
                      MediaQuery.sizeOf(context).width < 380 ? 16 : 24,
                      16,
                      MediaQuery.sizeOf(context).width < 380 ? 16 : 24,
                      20,
                    ),
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppTheme.ink,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.sentiment_satisfied_alt_rounded,
                              color: AppTheme.lime,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'invisaligner',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.8,
                              color: AppTheme.ink,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      if (tracker.current == null)
                        SectionCard(
                          children: [
                            const Eyebrow('Ein kleiner Schritt. Jeden Tag.'),
                            const SizedBox(height: 20),
                            Text(
                              'Deine Schiene.\nDein Rhythmus.',
                              style: Theme.of(context).textTheme.headlineLarge,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Pausen mit einem Tippen erfassen. Tragezeit und nächsten Wechsel im Blick behalten.',
                              style: TextStyle(
                                fontSize: 16,
                                height: 1.6,
                                color: AppTheme.muted,
                              ),
                            ),
                            const SizedBox(height: 28),
                            const _SetupStep(
                              icon: Icons.tune_rounded,
                              title: 'Einmal einrichten',
                              text:
                                  'Schienennummer und ersten Tragetag wählen.',
                            ),
                            const SizedBox(height: 20),
                            const _SetupStep(
                              icon: Icons.touch_app_outlined,
                              title: 'Ein Tippen genügt',
                              text: 'Beim Herausnehmen und Einsetzen stempeln.',
                            ),
                            const SizedBox(height: 28),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed: _setup,
                                icon: const Icon(Icons.arrow_forward_rounded),
                                label: const Text('Schiene einrichten'),
                              ),
                            ),
                          ],
                        )
                      else if (_tab == 0)
                        TodayView(
                          tracker: tracker,
                          now: _now,
                          onStamp: _busy
                              ? null
                              : () => _perform(() async {
                                  await tracker.stamp();
                                  unawaited(HapticFeedback.lightImpact());
                                }),
                          onEditPause: _busy
                              ? null
                              : () => _editPause(tracker.activePause),
                          onChangeTray: _busy ? null : _changeTray,
                        )
                      else
                        HistoryView(
                          tracker: tracker,
                          now: _now,
                          selected: _selected,
                          busy: _busy,
                          onSelect: _select,
                          onEdit: _editPause,
                        ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

class _SetupStep extends StatelessWidget {
  const _SetupStep({
    required this.icon,
    required this.title,
    required this.text,
  });

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.softGreen,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: AppTheme.green),
      ),
      const SizedBox(width: 14),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(
              text,
              style: const TextStyle(color: AppTheme.muted, fontSize: 13),
            ),
          ],
        ),
      ),
    ],
  );
}
