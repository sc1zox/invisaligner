import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../tracker.dart';
import '../tracker_models.dart';
import 'formatters.dart';
import 'tracker_widgets.dart';

class HistoryView extends StatelessWidget {
  const HistoryView({
    required this.tracker,
    required this.now,
    required this.selected,
    required this.busy,
    required this.onSelect,
    required this.onEdit,
    super.key,
  });

  final Tracker tracker;
  final DateTime now;
  final DateTime selected;
  final bool busy;
  final ValueChanged<DateTime> onSelect;
  final ValueChanged<PauseInterval?> onEdit;

  @override
  Widget build(BuildContext context) {
    final entries = tracker.pauses.where(
      (pause) => pause.overlapsDay(selected),
    );
    final belowGoal = tracker.isBelowDailyWearGoal(selected, now);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Eyebrow('Tag für Tag'),
        const SizedBox(height: 8),
        Text('Dein Verlauf', style: Theme.of(context).textTheme.headlineLarge),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppTheme.softGreen,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              IconButton(
                tooltip: 'Vorheriger Tag',
                onPressed: selected.isAfter(tracker.firstDay!)
                    ? () => onSelect(
                        DateTime(
                          selected.year,
                          selected.month,
                          selected.day - 1,
                        ),
                      )
                    : null,
                icon: const Icon(Icons.chevron_left),
              ),
              Expanded(
                child: TextButton(
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selected,
                      firstDate: tracker.firstDay!,
                      lastDate: DateTime.now(),
                    );
                    if (date != null && context.mounted) onSelect(date);
                  },
                  child: Text(
                    '${selected == dayOf(now) ? 'Heute · ' : ''}${dateText(selected)}',
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Nächster Tag',
                onPressed: selected.isBefore(dayOf(now))
                    ? () => onSelect(nextDay(selected))
                    : null,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ),
        if (selected != dayOf(now))
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => onSelect(dayOf(now)),
              icon: const Icon(Icons.today_rounded, size: 16),
              label: const Text('Zurück zu heute'),
            ),
          ),
        const SizedBox(height: 16),
        SectionCard(
          children: [
            const Eyebrow('Tragezeit'),
            const SizedBox(height: 8),
            Text(
              hoursText(tracker.wornOn(selected, now)),
              style: Theme.of(context).textTheme.headlineLarge
                  ?.copyWith(color: belowGoal ? AppTheme.amber : null),
            ),
            Text(
              'Tragezeit${selected == dayOf(now) ? ' bisher' : ''} · Ziel ${dailyWearGoal.inHours} Stunden',
            ),
            const SizedBox(height: 8),
            Text('${hoursText(tracker.pausedOn(selected, now))} ohne Schiene'),
            const SizedBox(height: 24),
            _WeekChart(
              tracker: tracker,
              now: now,
              selected: selected,
              onSelect: onSelect,
            ),
          ],
        ),
        SectionCard(
          children: [
            const SectionTitle('Deine Pausen'),
            const SizedBox(height: 12),
            if (entries.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Column(
                  children: [
                    Icon(
                      Icons.coffee_outlined,
                      color: AppTheme.muted,
                      size: 28,
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Noch keine Pause eingetragen.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Eine Pause vergessen? Trage sie hier nach.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppTheme.muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ...entries.map(
              (pause) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.pause_circle_outline,
                  color: AppTheme.green,
                ),
                title: Text(
                  '${dateTimeText(pause.start)} → ${pause.end == null ? 'noch draußen' : dateTimeText(pause.end!)}',
                ),
                subtitle: Text(
                  '${hoursText(pause.onDay(selected, now))} an diesem Tag',
                ),
                trailing: const Icon(Icons.edit_outlined, size: 19),
                onTap: busy ? null : () => onEdit(pause),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: busy ? null : () => onEdit(null),
                icon: const Icon(Icons.add),
                label: const Text('Pause nachtragen'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _WeekChart extends StatefulWidget {
  const _WeekChart({
    required this.tracker,
    required this.now,
    required this.selected,
    required this.onSelect,
  });

  final Tracker tracker;
  final DateTime now;
  final DateTime selected;
  final ValueChanged<DateTime> onSelect;

  @override
  State<_WeekChart> createState() => _WeekChartState();
}

class _WeekChartState extends State<_WeekChart> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _showNewestDay();
  }

  @override
  void didUpdateWidget(covariant _WeekChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selected != widget.selected) _showNewestDay();
  }

  void _showNewestDay() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final days = List.generate(
      14,
      (index) => DateTime(
        widget.selected.year,
        widget.selected.month,
        widget.selected.day - 13 + index,
      ),
    );
    // A fixed 25-hour scale also accommodates the autumn clock change.
    const scaleHours = 25;
    return Scrollbar(
      controller: _scrollController,
      thumbVisibility: true,
      scrollbarOrientation: ScrollbarOrientation.bottom,
      child: SingleChildScrollView(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: days.map((day) {
            final tracked = widget.tracker.tracksDay(day);
            final belowGoal = widget.tracker.isBelowDailyWearGoal(
              day,
              widget.now,
            );
            final hours =
                widget.tracker.wornOn(day, widget.now).inSeconds /
                Duration.secondsPerHour;
            return SizedBox(
              width: 68,
              child: Semantics(
                label:
                    '${dateText(day)}: ${tracked ? hoursText(widget.tracker.wornOn(day, widget.now)) : 'Vor Erfassungsbeginn'}',
                selected: day == widget.selected,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: tracked ? () => widget.onSelect(day) : null,
                  child: Container(
                    decoration: BoxDecoration(
                      color: day == widget.selected
                          ? belowGoal
                                ? AppTheme.softAmber
                                : AppTheme.softGreen
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          tracked
                              ? '${hours.toStringAsFixed(1).replaceAll('.', ',')} h'
                              : '–',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 10,
                            color: belowGoal ? AppTheme.amber : null,
                            fontWeight: belowGoal
                                ? FontWeight.w700
                                : FontWeight.normal,
                          ),
                        ),
                        const SizedBox(height: 6),
                        SizedBox(
                          height: 96,
                          width: 22,
                          child: Stack(
                            alignment: Alignment.bottomCenter,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: AppTheme.background,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              FractionallySizedBox(
                                heightFactor: (hours / scaleHours).clamp(0, 1),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: belowGoal
                                        ? AppTheme.amber
                                        : day == widget.selected
                                        ? AppTheme.ink
                                        : AppTheme.green,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 96 * dailyWearGoal.inHours / scaleHours,
                                left: 0,
                                right: 0,
                                child: const Divider(
                                  height: 1,
                                  color: AppTheme.ink,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${day.day}.${day.month}.',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: day == widget.selected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
