import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../main.dart';
import '../models.dart';
import '../report.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  DateTime? _selectedStart;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final cycles = state.cyclesAvailable();
    final length = state.settings.cycleLength;
    final start = _selectedStart ?? cycles.first;
    final report = generateReport(
      cycleStart: start,
      cycleLength: length,
      checkIns: state.checkIns,
      workouts: state.workouts,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Relatório'),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: 'Copiar',
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: report));
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Relatório copiado!')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Compartilhar',
            onPressed: () => SharePlus.instance.share(
              ShareParams(text: report, subject: 'Feedback quinzenal'),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                const Icon(Icons.calendar_month, size: 20),
                const SizedBox(width: 8),
                const Text('Ciclo:'),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButton<DateTime>(
                    value: start,
                    isExpanded: true,
                    items: [
                      for (final c in cycles)
                        DropdownMenuItem(
                          value: c,
                          child: Text(
                            '${dmy(c)} a ${dmy(c.add(Duration(days: length - 1)))}'
                            '${c == cycles.first ? ' (atual)' : ''}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: (v) => setState(() => _selectedStart = v),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _ReportPreview(
              start: start,
              cycleLength: length,
              checkIns: state.checkIns,
              workouts: state.workouts,
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.copy),
                      label: const Text('Copiar'),
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: report));
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Relatório copiado!')),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      icon: const Icon(Icons.share),
                      label: const Text('Compartilhar'),
                      onPressed: () => SharePlus.instance.share(
                        ShareParams(text: report, subject: 'Feedback quinzenal'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportPreview extends StatelessWidget {
  final DateTime start;
  final int cycleLength;
  final Map<String, CheckIn> checkIns;
  final List<Workout> workouts;

  const _ReportPreview({
    required this.start,
    required this.cycleLength,
    required this.checkIns,
    required this.workouts,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final end = start.add(Duration(days: cycleLength - 1));
    final rangeWorkouts = workouts
        .where((w) {
          final d = dateFromIso(w.dateIso);
          return !d.isBefore(start) && !d.isAfter(end);
        })
        .toList()
      ..sort((a, b) => a.dateIso.compareTo(b.dateIso));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Relatório de Feedback',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        Text('Período: ${dmy(start)} a ${dmy(end)}',
            style: theme.textTheme.bodyMedium),
        const SizedBox(height: 20),
        _SectionTitle(title: 'Treinos', icon: Icons.fitness_center),
        if (rangeWorkouts.isEmpty)
          const _EmptyNote(text: '(nenhum treino registrado no período)')
        else
          for (final w in rangeWorkouts) _WorkoutCard(workout: w),
        const SizedBox(height: 8),
        _SectionTitle(title: 'Check-in diário', icon: Icons.assignment_outlined),
        for (var i = 0; i < cycleLength; i++)
          _DayCard(
            day: start.add(Duration(days: i)),
            index: i,
            checkIn: checkIns[isoOf(start.add(Duration(days: i)))],
          ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionTitle({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: scheme.primary),
          const SizedBox(width: 8),
          Text(title,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _EmptyNote extends StatelessWidget {
  final String text;

  const _EmptyNote({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(text,
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(fontStyle: FontStyle.italic)),
    );
  }
}

class _WorkoutCard extends StatelessWidget {
  final Workout workout;

  const _WorkoutCard({required this.workout});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final d = dateFromIso(workout.dateIso);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(workout.title?.isNotEmpty == true ? workout.title! : 'Treino',
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                ),
                Text('${weekdayShort[d.weekday - 1]} ${dmy(d)}',
                    style: theme.textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 8),
            for (final e in workout.exercises)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(e.name, style: theme.textTheme.bodyMedium),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: Text(e.setsDisplay(),
                          textAlign: TextAlign.right,
                          style: theme.textTheme.bodyMedium),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DayCard extends StatelessWidget {
  final DateTime day;
  final int index;
  final CheckIn? checkIn;

  const _DayCard({required this.day, required this.index, required this.checkIn});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final c = checkIn;
    final hasData = c != null && c.filledCount > 0;

    final groups = <(String, List<String>)>[];
    if (hasData) {
      final morning = <String>[
        if (c.weight != null) 'Peso em jejum: ${_n(c.weight!)} kg',
        if (c.sleepHours != null) 'Sono: ${_n(c.sleepHours!)}h',
        if (c.sleepQualityPercent != null) 'Qualidade: ${c.sleepQualityPercent}%',
        if (c.sleepSatisfaction != null) 'Satisfação: ${c.sleepSatisfaction}/5',
      ];
      if (morning.isNotEmpty) groups.add(('Manhã', morning));

      final feelings = <String>[
        if (c.joy != null) 'Alegria: ${c.joy}/5',
        if (c.energy != null) 'Energia: ${c.energy}/5',
        if (c.mentalClarity != null) 'Claridade mental: ${c.mentalClarity}/5',
        if (c.stress != null) 'Estresse: ${c.stress}/5',
        if (c.muscleSoreness != null) 'Dor muscular: ${c.muscleSoreness}/5',
        if (c.immunity != null) 'Imunidade: ${c.immunity}/5',
      ];
      if (feelings.isNotEmpty) groups.add(('Sensações', feelings));

      final habits = <String>[
        'Furou a dieta: ${c.brokeDiet == true ? 'sim' : 'não'}'
            '${c.brokeDiet == true && c.brokeDietNote?.trim().isNotEmpty == true ? ' — ${c.brokeDietNote}' : ''}',
        if (c.hunger != null) 'Fome/apetite: ${c.hunger}/5',
        'Café/estimulantes: ${c.hadCaffeine == true ? 'sim' : 'não'}'
            '${c.hadCaffeine == true && c.caffeineNote?.trim().isNotEmpty == true ? ' — ${c.caffeineNote}' : ''}',
        if (c.digestion != null) 'Digestão: ${c.digestion}/5',
      ];
      groups.add(('Hábitos', habits));

      final trained = c.trained ?? false;
      groups.add((
        'Treino',
        [
          'Treinou: ${trained ? 'sim' : 'não'}',
          if (trained && c.workoutTime != null) 'Horário: ${_time(c.workoutTime!)}',
          if (trained && c.motivation != null) 'Motivação: ${c.motivation}/5',
          if (trained && c.strength != null) 'Força: ${c.strength}/5',
        ],
      ));

      final activity = <String>[
        if (c.steps != null) 'Passos: ${c.steps}',
        if (c.didOtherSport == true)
          'Outro esporte: ${c.otherSportDesc?.trim().isNotEmpty == true ? c.otherSportDesc : 'sim'}'
              '${c.sportTime != null || c.sportMinutes != null ? ' (${[if (c.sportTime != null) _time(c.sportTime!), if (c.sportMinutes != null) '${c.sportMinutes} min'].join(', ')})' : ''}'
        else
          'Outro esporte: não',
        if (c.didCardio == true)
          'Cardio: sim'
              '${c.cardioMinutes != null || c.cardioAvgBpm != null ? ' (${[if (c.cardioMinutes != null) '${c.cardioMinutes} min', if (c.cardioAvgBpm != null) 'média ${c.cardioAvgBpm} bpm'].join(', ')})' : ''}'
        else
          'Cardio: não',
      ];
      groups.add(('Atividade', activity));
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Dia ${index + 1} — ${weekdayFull[day.weekday - 1]} ${dmy(day)}',
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                if (hasData)
                  Icon(
                    c.filledCount == CheckIn.totalFields
                        ? Icons.check_circle
                        : Icons.pending_outlined,
                    size: 18,
                    color: c.filledCount == CheckIn.totalFields
                        ? scheme.primary
                        : scheme.outline,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (!hasData)
              Text('Sem dados neste dia',
                  style: theme.textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic))
            else
              for (final group in groups) _MetricGroup(label: group.$1, items: group.$2),
          ],
        ),
      ),
    );
  }

  String _n(double v) => v == v.roundToDouble()
      ? v.toInt().toString()
      : v.toStringAsFixed(1).replaceAll('.', ',');

  String _time(String t) => t.replaceAll(':', 'h') + (t.contains(':') ? '' : 'h');
}

class _MetricGroup extends StatelessWidget {
  final String label;
  final List<String> items;

  const _MetricGroup({required this.label, required this.items});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: theme.textTheme.labelLarge?.copyWith(color: scheme.primary)),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final item in items)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(item, style: theme.textTheme.bodySmall),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
