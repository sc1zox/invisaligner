import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../tracker.dart';
import '../tracker_models.dart';
import 'formatters.dart';

class SetupDialog extends StatefulWidget {
  const SetupDialog({required this.tracker, super.key});

  final Tracker tracker;

  @override
  State<SetupDialog> createState() => _SetupDialogState();
}

class _SetupDialogState extends State<SetupDialog> {
  final _number = TextEditingController(text: '1');
  final _form = GlobalKey<FormState>();
  DateTime _start = dayOf(DateTime.now());
  bool _saving = false;
  String? _error;

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
      await widget.tracker.startTray(int.parse(_number.text), _start);
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
      title: const Text('Deine aktuelle Schiene'),
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
              title: const Text('Erster Tragetag'),
              subtitle: Text(dateText(_start)),
              trailing: const Icon(Icons.calendar_today_outlined),
              onTap: _saving
                  ? null
                  : () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _start,
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                      );
                      if (date != null && mounted) {
                        setState(() => _start = date);
                      }
                    },
            ),
            const Text(
              'Ab diesem Tag gilt die Schiene als eingesetzt. Stemple nur deine Pausen. Vergessene Pausen oder ganze Tage ohne Schiene kannst du im Verlauf nachtragen.',
            ),
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
          child: Text(_saving ? 'Speichert …' : 'Starten'),
        ),
      ],
    ),
  );
}
