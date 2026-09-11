import 'package:flutter/material.dart';

import '../tracker.dart';
import '../tracker_models.dart';
import 'formatters.dart';

class PauseDialog extends StatefulWidget {
  const PauseDialog({
    required this.tracker,
    required this.day,
    this.pause,
    super.key,
  });

  final Tracker tracker;
  final DateTime day;
  final PauseInterval? pause;

  @override
  State<PauseDialog> createState() => _PauseDialogState();
}

class _PauseDialogState extends State<PauseDialog> {
  late DateTime _start;
  late DateTime _end;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final today = dayOf(now);
    _end = widget.pause != null
        ? widget.pause!.end ?? now
        : (dayOf(widget.day) == today
              ? now
              : DateTime(
                  widget.day.year,
                  widget.day.month,
                  widget.day.day,
                  13,
                ));
    final suggestedStart = _end.subtract(const Duration(minutes: 30));
    _start =
        widget.pause?.start ??
        (suggestedStart.isBefore(dayOf(widget.day))
            ? dayOf(widget.day)
            : suggestedStart);
  }

  Future<void> _pick({required bool start}) async {
    final old = start ? _start : _end;
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: old.isAfter(now) ? now : old,
      firstDate: widget.tracker.firstDay!,
      lastDate: now,
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(old),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (time == null || !mounted) return;
    setState(() {
      final value = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
      if (start) {
        _start = value;
      } else {
        _end = value;
      }
      _error = null;
    });
  }

  Future<void> _save({bool delete = false}) async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      if (delete) {
        await widget.tracker.deletePause(widget.pause!.id);
      } else {
        await widget.tracker.savePause(
          widget.pause?.id,
          _start,
          widget.pause != null && widget.pause!.end == null ? null : _end,
        );
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
      title: Text(
        widget.pause == null ? 'Pause nachtragen' : 'Pause bearbeiten',
      ),
      scrollable: true,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Herausgenommen'),
            subtitle: Text(dateTimeText(_start)),
            trailing: const Icon(Icons.edit_outlined),
            onTap: _saving ? null : () => _pick(start: true),
          ),
          if (widget.pause == null || widget.pause!.end != null)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Wieder eingesetzt'),
              subtitle: Text(dateTimeText(_end)),
              trailing: const Icon(Icons.edit_outlined),
              onTap: _saving ? null : () => _pick(start: false),
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
      actions: [
        if (widget.pause != null)
          TextButton(
            onPressed: _saving ? null : () => _save(delete: true),
            child: const Text('Pause löschen'),
          ),
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Abbrechen'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(_saving ? 'Speichert …' : 'Speichern'),
        ),
      ],
    ),
  );
}
