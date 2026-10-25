import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../tracker.dart';
import '../tracker_models.dart';
import 'formatters.dart';
import 'tracker_widgets.dart';

class TodayView extends StatelessWidget {
  const TodayView({
    required this.tracker,
    required this.now,
    required this.onStamp,
    required this.onEditPause,
    required this.onChangeTray,
    required this.onCorrectTray,
    super.key,
  });

  final Tracker tracker;
  final DateTime now;
  final VoidCallback? onStamp;
  final VoidCallback? onEditPause;
  final VoidCallback? onChangeTray;
  final VoidCallback? onCorrectTray;

  @override
  Widget build(BuildContext context) {
    final worn = tracker.wornOn(now, now);
    final paused = tracker.pausedOn(now, now);
    final active = tracker.activePause;
    final remaining = dailyWearGoal - worn;
    final change = tracker.plannedChange(now)!;
    final deficit = tracker.currentTrayWearDeficit(now);
    final suggestedChange = tracker.suggestedChange(now);
    final due = !dayOf(now).isBefore(change);
    final tray = tracker.current!;
    final reached = remaining <= Duration.zero;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Eyebrow(longDateText(now)),
        const SizedBox(height: 8),
        Text(
          'Dein Tag im Blick.',
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        const SizedBox(height: 24),
        SectionCard(
          children: [
            SizedBox(
              width: double.infinity,
              child: Semantics(
                liveRegion: true,
                label: active == null
                    ? 'Schiene eingesetzt. Schiene herausnehmen'
                    : 'Schiene draußen. Schiene wieder einsetzen',
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: active == null
                        ? AppTheme.green
                        : AppTheme.amber,
                  ),
                  onPressed: onStamp,
                  icon: Icon(
                    active == null ? Icons.pause_rounded : Icons.check_rounded,
                  ),
                  label: Column(
                    children: [
                      Text(
                        active == null ? 'Schiene raus' : 'Schiene rein',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        active == null ? 'Pause starten' : 'Pause beenden',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                active == null
                    ? '${hoursText(paused)} ohne Schiene heute'
                    : 'Pause seit ${dateTimeText(active.start)}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: AppTheme.muted),
              ),
            ),
            if (active != null)
              Center(
                child: TextButton(
                  onPressed: onEditPause,
                  child: const Text('Entnahmezeit korrigieren'),
                ),
              ),
          ],
        ),
        SectionCard(
          children: [
            const Eyebrow('Heute'),
            const SizedBox(height: 22),
            WearProgress(worn: worn),
            const SizedBox(height: 18),
            Center(
              child: Text(
                reached
                    ? 'Tagesziel erreicht. Gut gemacht!'
                    : 'Noch ${hoursText(remaining)} bis zum Tagesziel',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppTheme.green,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (!reached && remaining > nextDay(now).difference(now))
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'Das Tagesziel ist heute nicht mehr erreichbar.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.muted, fontSize: 12),
                ),
              ),
          ],
        ),
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.ink,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Eyebrow(
                          'Deine aktuelle Schiene',
                          color: AppTheme.lime,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Schiene ${tray.number.toString().padLeft(2, '0')}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.8,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Seit ${dateText(tray.start)}',
                          style: const TextStyle(
                            color: Color(0xFFBCCBBF),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.calendar_month_outlined,
                      color: AppTheme.lime,
                      size: 28,
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 18),
                child: Divider(height: 1, color: Color(0xFF496053)),
              ),
              Text(
                due ? 'Bereit für die nächste Schiene' : 'Nächster Wechsel',
                style: const TextStyle(color: Color(0xFFBCCBBF), fontSize: 13),
              ),
              const SizedBox(height: 4),
              Text(
                due ? 'Dein Wechsel ist fällig.' : longDateText(change),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (suggestedChange != null) ...[
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${hoursText(deficit)} im Verzug',
                        style: const TextStyle(
                          color: AppTheme.lime,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Vorgeschlagen: ${longDateText(suggestedChange)}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ],
              if (due) ...[
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.lime,
                      foregroundColor: AppTheme.ink,
                    ),
                    onPressed: onChangeTray,
                    icon: const Icon(Icons.arrow_forward_rounded),
                    label: const Text(
                      'Nächste Schiene starten',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  style: TextButton.styleFrom(foregroundColor: AppTheme.lime),
                  onPressed: onCorrectTray,
                  child: const Text('Wechsel korrigieren'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class WearProgress extends StatelessWidget {
  const WearProgress({required this.worn, super.key});

  final Duration worn;

  @override
  Widget build(BuildContext context) => Semantics(
    label:
        'Heute ${hoursText(worn)} getragen. Tagesziel ${dailyWearGoal.inHours} Stunden.',
    child: ExcludeSemantics(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final diameter = math.min(constraints.maxWidth, 260.0);
          // Keep the center text readable at large accessibility text sizes.
          final scaled = MediaQuery.textScalerOf(context).scale(1);
          return Center(
            child: SizedBox(
              width: diameter,
              height: diameter,
              child: CustomPaint(
                painter: _WearRingPainter(
                  progress: (worn.inSeconds / dailyWearGoal.inSeconds).clamp(
                    0.0,
                    1.0,
                  ),
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (scaled < 1.5) const Eyebrow('Heute getragen'),
                        const SizedBox(height: 6),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            '${worn.inHours} h ${worn.inMinutes.remainder(60).toString().padLeft(2, '0')}',
                            style: const TextStyle(
                              fontSize: 43,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -2,
                              color: AppTheme.ink,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        FittedBox(
                          child: Text(
                            'von ${dailyWearGoal.inHours} Stunden',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.muted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    ),
  );
}

class _WearRingPainter extends CustomPainter {
  const _WearRingPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - 13;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 13
      ..strokeCap = StrokeCap.round;
    const start = math.pi * 0.75;
    const sweep = math.pi * 1.5;
    canvas.drawArc(
      rect,
      start,
      sweep,
      false,
      paint..color = AppTheme.softGreen,
    );
    if (progress > 0) {
      canvas.drawArc(
        rect,
        start,
        sweep * progress,
        false,
        paint..color = AppTheme.green,
      );
      final angle = start + sweep * progress;
      final end = center + Offset(math.cos(angle), math.sin(angle)) * radius;
      canvas.drawCircle(end, 3.5, Paint()..color = AppTheme.lime);
    }
    // Small inset ticks give the ring a quiet, clock-like rhythm.
    for (var i = 0; i <= 20; i++) {
      final angle = start + sweep * i / 20;
      final direction = Offset(math.cos(angle), math.sin(angle));
      canvas.drawLine(
        center + direction * (radius - 15),
        center + direction * (radius - 19),
        Paint()
          ..color = AppTheme.line
          ..strokeWidth = 1.5,
      );
    }
  }

  @override
  bool shouldRepaint(_WearRingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
