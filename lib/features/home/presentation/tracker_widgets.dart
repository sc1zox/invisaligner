import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class SectionCard extends StatelessWidget {
  const SectionCard({
    required this.children,
    this.color = Colors.white,
    super.key,
  });

  final List<Widget> children;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: AppTheme.line.withValues(alpha: 0.7)),
      boxShadow: [
        BoxShadow(
          color: AppTheme.ink.withValues(alpha: 0.025),
          blurRadius: 20,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    child: Material(
      type: MaterialType.transparency,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    ),
  );
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.5,
      color: AppTheme.ink,
    ),
  );
}

class Eyebrow extends StatelessWidget {
  const Eyebrow(this.text, {this.color = AppTheme.muted, super.key});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    style: TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.7,
      color: color,
    ),
  );
}
