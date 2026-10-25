import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../tracker.dart';
import '../tracker_models.dart';
import 'formatters.dart';

enum TrayDialogMode { setup, change, correct }

class TrayDialog extends StatefulWidget {
  const TrayDialog({required this.tracker, required this.mode, super.key});

  final Tracker tracker;
  final TrayDialogMode mode;

  @override
  State<TrayDialog> createState() => _TrayDialogState();
}

class _TrayDialogState extends State<TrayDialog> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _number;
  late DateTime _start;
  bool _saving = false;
  String? _error;

  /// A tray must start after the one before it, so the picker hides older days.
  DateTime get _firstDate {
    final tracker = widget.tracker;
    final before = switch (widget.mode) {
      TrayDialogMode.setup => null,
      TrayDialogMode.change => tracker.current,
      TrayDialogMode.correct => tracker.previous,
    };
    return before == null ? DateTime(2000) : nextDay(before.start);
  }

  @override
  void initState() {
    super.initState();
    final current = widget.tracker.current;
    _number = TextEditingController(
      text: switch (widget.mode) {
        TrayDialogMode.setup => '1',
        TrayDialogMode.change => '${current!.number + 1}',
        TrayDialogMode.correct => '${current!.number}',
      },
    );
    _start = widget.mode == TrayDialogMode.correct
        ? current!.start
        : dayOf(DateTime.now());
  }

  @override
  void dispose() {
    _number.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final number = int.parse(_number.text);
      if (widget.mode == TrayDialogMode.correct) {
        await widget.tracker.updateCurrentTray(number, _start);
      } else {
        await widget.tracker.startTray(number, _start);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = saveError(error);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving,
    child: AlertDialog(
      title: Text(switch (widget.mode) {
        TrayDialogMode.setup => 'Deine aktuelle Schiene',
        TrayDialogMode.change => 'Schiene wechseln?',
        TrayDialogMode.correct => 'Wechsel korrigieren',
      }),
      scrollable: true,
      content: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _number,
              enabled: !_saving,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(labelText: 'Schienennummer'),
              validator: (value) => (int.tryParse(value ?? '') ?? 0) > 0
                  ? null
                  : 'Bitte eine Nummer größer als 0 eingeben.',
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                widget.mode == TrayDialogMode.setup
                    ? 'Erster Tragetag'
                    : 'Gewechselt am',
              ),
              subtitle: Text(dateText(_start)),
              trailing: const Icon(Icons.calendar_today_outlined),
              onTap: _saving
                  ? null
                  : () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _start,
                        firstDate: _firstDate,
                        lastDate: DateTime.now(),
                      );
                      if (date != null && mounted) {
                        setState(() => _start = date);
                      }
                    },
            ),
            Text(switch (widget.mode) {
              TrayDialogMode.setup => 'Ab diesem Tag gilt die Schiene als eingesetzt. Stemple nur deine Pausen. Vergessene Pausen oder ganze Tage ohne Schiene kannst du im Verlauf nachtragen.',
              TrayDialogMode.change =>
                'Die neue Schiene startet mit $daysPerTray neuen Tragetagen. Hast du vergessen, den Wechsel einzutragen, wähle den tatsächlichen Tag. Eine offene Pause bleibt bestehen, bis du das Einsetzen stempelst.',
              TrayDialogMode.correct => 'Trage den Tag ein, an dem du diese Schiene tatsächlich eingesetzt hast. Der nächste Wechsel wird danach neu berechnet.',
            }),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Abbrechen'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(
            _saving
                ? 'Speichert …'
                : switch (widget.mode) {
                    TrayDialogMode.setup => 'Starten',
                    TrayDialogMode.change => 'Wechsel bestätigen',
                    TrayDialogMode.correct => 'Speichern',
                  },
          ),
        ),
      ],
    ),
  );
}
