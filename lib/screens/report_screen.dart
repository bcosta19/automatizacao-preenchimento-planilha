import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../main.dart';
import '../models.dart';
import '../report.dart';
import '../storage.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> with SingleTickerProviderStateMixin {
  DateTime? _selectedStart;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _getReport(AppState state, DateTime start, int length) {
    return generateReport(
      cycleStart: start,
      cycleLength: length,
      checkIns: state.checkIns,
      workouts: state.workouts,
      cardios: state.cardios,
      weeklyCardioGoal: state.settings.weeklyCardioMinutes,
    );
  }

  String _getWorkoutsText(AppState state, DateTime start, int length) {
    final end = start.add(Duration(days: length - 1));
    final rangeWorkouts = state.workoutsForRange(start, end);
    final buffer = StringBuffer();
    buffer.writeln('TREINOS (${dmy(start)} a ${dmy(end)})');
    if (rangeWorkouts.isEmpty) {
      buffer.writeln('(nenhum treino registrado)');
    }
    for (final w in rangeWorkouts) {
      final d = dateFromIso(w.dateIso);
      buffer.writeln();
      buffer.writeln(
          '${weekdayFull[d.weekday - 1]} ${dmy(d)}${w.time != null ? ' às ${w.time}' : ''}${w.title != null && w.title!.isNotEmpty ? ' — ${w.title}' : ''}');
      for (final e in w.exercises) {
        buffer.writeln('  ${e.name}: ${e.setsDisplay()}');
      }
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final cycles = state.cyclesAvailable();
    final length = state.settings.cycleLength;
    final start = _selectedStart ?? cycles.first;
    final end = start.add(Duration(days: length - 1));
    final rangeWorkouts = state.workoutsForRange(start, end);
    final rangeCardios = state.cardiosForRange(start, end);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Relatório de Feedback'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: const [
            Tab(icon: Icon(Icons.view_agenda_outlined), text: 'Dia a Dia'),
            Tab(icon: Icon(Icons.fitness_center), text: 'Treinos'),
            Tab(icon: Icon(Icons.assignment_outlined), text: 'Check-in'),
            Tab(icon: Icon(Icons.text_snippet_outlined), text: 'Texto Planilha'),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            tooltip: 'Opções de cópia',
            onSelected: (val) async {
              String text = '';
              String msg = '';
              if (val == 'all') {
                text = _getReport(state, start, length);
                msg = 'Relatório completo copiado!';
              } else if (val == 'workouts') {
                text = _getWorkoutsText(state, start, length);
                msg = 'Treinos copiados!';
              }
              if (text.isNotEmpty) {
                await Clipboard.setData(ClipboardData(text: text));
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(msg)),
                );
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'all',
                child: ListTile(
                  leading: Icon(Icons.copy),
                  title: Text('Copiar Relatório Completo'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'workouts',
                child: ListTile(
                  leading: Icon(Icons.fitness_center),
                  title: Text('Copiar Apenas Treinos'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Compartilhar',
            onPressed: () {
              final report = _getReport(state, start, length);
              SharePlus.instance.share(
                ShareParams(text: report, subject: 'Feedback quinzenal'),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Seletor de Ciclo
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
              border: Border(
                bottom: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_month, size: 20),
                const SizedBox(width: 8),
                const Text('Ciclo:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<DateTime>(
                      value: start,
                      isExpanded: true,
                      isDense: true,
                      items: [
                        for (final c in cycles)
                          DropdownMenuItem(
                            value: c,
                            child: Text(
                              '${dmy(c)} a ${dmy(c.add(Duration(days: length - 1)))}'
                              '${c == cycles.first ? ' (atual)' : ''}',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                      ],
                      onChanged: (v) => setState(() => _selectedStart = v),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Aba 1: Visão Dia a Dia Integrada (Treinos + Checkin + Cardio + Resumo)
                _IntegratedDayView(
                  start: start,
                  cycleLength: length,
                  checkIns: state.checkIns,
                  workouts: rangeWorkouts,
                  cardios: rangeCardios,
                  weeklyCardioGoal: state.settings.weeklyCardioMinutes,
                ),
                // Aba 2: Apenas Treinos do Ciclo
                _WorkoutsOnlyView(
                  start: start,
                  end: end,
                  workouts: rangeWorkouts,
                ),
                // Aba 3: Apenas Check-ins do Ciclo
                _CheckInsOnlyView(
                  start: start,
                  cycleLength: length,
                  checkIns: state.checkIns,
                ),
                // Aba 4: Texto Puro da Planilha
                _RawTextView(
                  reportText: _getReport(state, start, length),
                ),
              ],
            ),
          ),
          // Botões de Rodapé Fixos
          SafeArea(
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(
                  top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.copy),
                      label: const Text('Copiar tudo'),
                      onPressed: () async {
                        final report = _getReport(state, start, length);
                        await Clipboard.setData(ClipboardData(text: report));
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Relatório completo copiado!')),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      icon: const Icon(Icons.share),
                      label: const Text('Compartilhar'),
                      onPressed: () {
                        final report = _getReport(state, start, length);
                        SharePlus.instance.share(
                          ShareParams(text: report, subject: 'Feedback quinzenal'),
                        );
                      },
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

// -------------------------------------------------------------
// ABA 1: Visão Integrada Dia a Dia
// -------------------------------------------------------------
class _IntegratedDayView extends StatelessWidget {
  final DateTime start;
  final int cycleLength;
  final Map<String, CheckIn> checkIns;
  final List<Workout> workouts;
  final List<CardioEntry> cardios;
  final int weeklyCardioGoal;

  const _IntegratedDayView({
    required this.start,
    required this.cycleLength,
    required this.checkIns,
    required this.workouts,
    required this.cardios,
    required this.weeklyCardioGoal,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final end = start.add(Duration(days: cycleLength - 1));

    final cycleGoal = (weeklyCardioGoal * (cycleLength / 7)).round();
    final totalCardioMin = cardios.isNotEmpty
        ? cardios.fold<int>(0, (sum, c) => sum + c.minutes)
        : List.generate(cycleLength, (i) => checkIns[isoOf(start.add(Duration(days: i)))])
            .where((c) => c?.didCardio == true && c?.cardioMinutes != null)
            .fold<int>(0, (sum, c) => sum + (c?.cardioMinutes ?? 0));

    final remainingCardio = (cycleGoal - totalCardioMin).clamp(0, 99999);
    final cardioPercent = cycleGoal > 0 ? ((totalCardioMin / cycleGoal) * 100).toStringAsFixed(0) : '0';
    final bpms = cardios.where((c) => c.avgBpm != null && c.avgBpm! > 0).toList();
    final avgBpm = bpms.isNotEmpty
        ? (bpms.fold<int>(0, (sum, c) => sum + (c.avgBpm! * c.minutes)) /
                bpms.fold<int>(0, (sum, c) => sum + c.minutes))
            .round()
        : null;

    final filledCheckIns = List.generate(cycleLength, (i) => checkIns[isoOf(start.add(Duration(days: i)))])
        .where((c) => c != null && c.filledCount > 0)
        .length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Card de KPIs do Ciclo
        Card(
          elevation: 0,
          color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.2)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Resumo do Ciclo',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${dmy(start)} a ${dmy(end)}',
                      style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _KpiTile(
                        icon: Icons.fitness_center,
                        title: 'Treinos',
                        value: '${workouts.length}',
                        subtitle: '${workouts.length} sessões',
                      ),
                    ),
                    Expanded(
                      child: _KpiTile(
                        icon: Icons.directions_run,
                        title: 'Cardio',
                        value: '$totalCardioMin min',
                        subtitle: '$cardioPercent% da meta ($cycleGoal min)',
                      ),
                    ),
                    Expanded(
                      child: _KpiTile(
                        icon: Icons.assignment_turned_in_outlined,
                        title: 'Check-ins',
                        value: '$filledCheckIns/$cycleLength',
                        subtitle: 'dias preenchidos',
                      ),
                    ),
                  ],
                ),
                if (weeklyCardioGoal > 0) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: cycleGoal > 0 ? (totalCardioMin / cycleGoal).clamp(0.0, 1.0) : 0.0,
                      minHeight: 8,
                      color: totalCardioMin >= cycleGoal ? Colors.green : theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Meta semanal: $weeklyCardioGoal min',
                        style: theme.textTheme.bodySmall,
                      ),
                      Text(
                        remainingCardio == 0 ? 'Meta de cardio batida! 🎉' : 'Faltam $remainingCardio min',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: remainingCardio == 0 ? Colors.green : theme.colorScheme.error,
                        ),
                      ),
                    ],
                  ),
                ],
                if (avgBpm != null) ...[
                  const SizedBox(height: 4),
                  Text('❤️ BPM Médio do período: $avgBpm bpm', style: theme.textTheme.bodySmall),
                ],
              ],
            ),
          ),
        ),

        // Resumo Semanal (Comentários)
        const SizedBox(height: 16),
        _WeeklySummaryAccordion(
          start: start,
          cycleLength: cycleLength,
          checkIns: checkIns,
        ),

        const SizedBox(height: 16),
        Text(
          'Dia a Dia — Treinos e Check-in',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),

        // Lista de Cards Integrados por Dia
        for (var i = 0; i < cycleLength; i++) ...[
          Builder(
            builder: (ctx) {
              final dayDate = start.add(Duration(days: i));
              final dayIso = isoOf(dayDate);
              final dayCheckIn = checkIns[dayIso];
              final dayWorkouts = workouts.where((w) => w.dateIso == dayIso).toList();
              final dayCardios = cardios.where((c) => c.dateIso == dayIso).toList();

              return _IntegratedDayCard(
                day: dayDate,
                index: i,
                checkIn: dayCheckIn,
                workouts: dayWorkouts,
                cardios: dayCardios,
              );
            },
          ),
        ],
      ],
    );
  }
}

class _KpiTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String subtitle;

  const _KpiTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        Text(title, style: theme.textTheme.labelSmall),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(fontSize: 10, color: theme.colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

// -------------------------------------------------------------
// Card Integrado do Dia (Treino + Checkin + Cardio + Resumo)
// -------------------------------------------------------------
class _IntegratedDayCard extends StatelessWidget {
  final DateTime day;
  final int index;
  final CheckIn? checkIn;
  final List<Workout> workouts;
  final List<CardioEntry> cardios;

  const _IntegratedDayCard({
    required this.day,
    required this.index,
    required this.checkIn,
    required this.workouts,
    required this.cardios,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final c = checkIn;
    final hasData = (c != null && c.filledCount > 0) || workouts.isNotEmpty || cardios.isNotEmpty;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header do Dia
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Dia ${index + 1}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${weekdayFull[day.weekday - 1]}, ${dmy(day)}',
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                if (workouts.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: scheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.fitness_center, size: 12, color: scheme.onSecondaryContainer),
                          const SizedBox(width: 4),
                          Text(
                            workouts.first.time ?? 'Treinou',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: scheme.onSecondaryContainer,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (cardios.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: scheme.tertiaryContainer,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.directions_run, size: 12, color: scheme.onTertiaryContainer),
                        const SizedBox(width: 2),
                        Text(
                          '${cardios.fold<int>(0, (sum, item) => sum + item.minutes)}m',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: scheme.onTertiaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const Divider(height: 16),

            if (!hasData)
              Text('(sem dados neste dia)',
                  style: theme.textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic, color: scheme.outline))
            else ...[
              // Bloco 1: Treino do Dia
              if (workouts.isNotEmpty) ...[
                for (final w in workouts)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: scheme.outlineVariant),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.fitness_center, size: 15, color: scheme.primary),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '${w.title?.isNotEmpty == true ? w.title! : 'Treino'}${w.time != null ? ' (${w.time})' : ''}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ),
                            Text(
                              '${w.exercises.length} exercícios',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        for (final e in w.exercises)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    '• ${e.name}',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                  ),
                                ),
                                Expanded(
                                  flex: 4,
                                  child: Text(
                                    e.setsDisplay(),
                                    textAlign: TextAlign.right,
                                    style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
              ] else if (c?.trained == true) ...[
                Row(
                  children: [
                    Icon(Icons.check, size: 14, color: scheme.primary),
                    const SizedBox(width: 4),
                    Text(
                      'Treinou: sim${c?.workoutTime != null ? ' às ${c!.workoutTime}' : ''}'
                      '${c?.motivation != null ? ' | Motivação: ${c!.motivation}/5' : ''}'
                      '${c?.strength != null ? ' | Força: ${c!.strength}/5' : ''}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
              ],

              // Bloco 2: Cardio do Dia
              if (cardios.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Icon(Icons.directions_run, size: 14, color: scheme.primary),
                      const SizedBox(width: 4),
                      Text(
                        'Cardio: ${cardios.fold<int>(0, (s, item) => s + item.minutes)} min'
                        '${_cardioBpmString(cardios)}'
                        '${cardios.length > 1 ? ' (${cardios.length} sessões)' : ''}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ] else if (c?.didCardio == true && c?.cardioMinutes != null) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Icon(Icons.directions_run, size: 14, color: scheme.primary),
                      const SizedBox(width: 4),
                      Text(
                        'Cardio: ${c!.cardioMinutes} min${c?.cardioAvgBpm != null ? ' (média ${c!.cardioAvgBpm} bpm)' : ''}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ],

              // Bloco 3: Métricas de Check-in (Chips Limpos)
              if (c != null && c.filledCount > 0) ...[
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if (c.weight != null)
                      _InfoBadge(label: '⚖️ ${_n(c.weight!)} kg'),
                    if (c.sleepHours != null)
                      _InfoBadge(label: '🛏️ ${_n(c.sleepHours!)}h${c.sleepQualityPercent != null ? ' (${c.sleepQualityPercent}%)' : ''}'),
                    if (c.steps != null)
                      _InfoBadge(label: '👟 ${c.steps} passos'),
                    if (c.brokeDiet == true)
                      _InfoBadge(
                        label: '🍔 Furou dieta${c.brokeDietNote?.isNotEmpty == true ? ': ${c.brokeDietNote}' : ''}',
                        isWarning: true,
                      )
                    else if (c.brokeDiet == false)
                      _InfoBadge(label: '🥗 Dieta 100%', isSuccess: true),
                    if (c.energy != null)
                      _InfoBadge(label: '⚡ Energia: ${c.energy}/5'),
                    if (c.joy != null)
                      _InfoBadge(label: '😊 Humor: ${c.joy}/5'),
                    if (c.stress != null)
                      _InfoBadge(label: '🧘 Estresse: ${c.stress}/5'),
                    if (c.hunger != null)
                      _InfoBadge(label: '🍽️ Apetite: ${c.hunger}/5'),
                    if (c.digestion != null)
                      _InfoBadge(label: '🥣 Digestão: ${c.digestion}/5'),
                    if (c.hadCaffeine == true)
                      _InfoBadge(label: '☕ Café${c.caffeineNote?.isNotEmpty == true ? ': ${c.caffeineNote}' : ''}'),
                    if (c.didOtherSport == true)
                      _InfoBadge(label: '🥋 ${c.otherSportDesc ?? 'Esporte'}${c.sportMinutes != null ? ' (${c.sportMinutes}m)' : ''}'),
                  ],
                ),
              ],

              // Bloco 4: Resumo / Comentários do Dia
              if (c?.daySummary?.trim().isNotEmpty == true) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: scheme.outlineVariant),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.comment_outlined, size: 14, color: scheme.primary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          c!.daySummary!.trim(),
                          style: theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  String _cardioBpmString(List<CardioEntry> items) {
    final bpms = items.where((c) => c.avgBpm != null && c.avgBpm! > 0).toList();
    if (bpms.isEmpty) return '';
    final avg = (bpms.fold<int>(0, (sum, c) => sum + (c.avgBpm! * c.minutes)) /
            bpms.fold<int>(0, (sum, c) => sum + c.minutes))
        .round();
    return ', média $avg bpm';
  }

  String _n(double v) => v == v.roundToDouble()
      ? v.toInt().toString()
      : v.toStringAsFixed(1).replaceAll('.', ',');
}

class _InfoBadge extends StatelessWidget {
  final String label;
  final bool isWarning;
  final bool isSuccess;

  const _InfoBadge({
    required this.label,
    this.isWarning = false,
    this.isSuccess = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Color bg = scheme.surfaceContainerHighest;
    Color text = scheme.onSurface;

    if (isWarning) {
      bg = scheme.errorContainer.withValues(alpha: 0.7);
      text = scheme.onErrorContainer;
    } else if (isSuccess) {
      bg = Colors.green.withValues(alpha: 0.15);
      text = Colors.green.shade800;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: text),
      ),
    );
  }
}

// -------------------------------------------------------------
// Resumo Semanal Expansível
// -------------------------------------------------------------
class _WeeklySummaryAccordion extends StatelessWidget {
  final DateTime start;
  final int cycleLength;
  final Map<String, CheckIn> checkIns;

  const _WeeklySummaryAccordion({
    required this.start,
    required this.cycleLength,
    required this.checkIns,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final numWeeks = (cycleLength + 6) ~/ 7;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: ExpansionTile(
        initiallyExpanded: true,
        leading: Icon(Icons.comment_outlined, color: theme.colorScheme.primary),
        title: const Text('Resumo Semanal (Comentários)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: const Text('Agrupado para preenchimento do feedback', style: TextStyle(fontSize: 11)),
        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        children: [
          for (var w = 0; w < numWeeks; w++) ...[
            Builder(
              builder: (ctx) {
                final wStart = start.add(Duration(days: w * 7));
                final daysInThisWeek = (cycleLength - (w * 7)).clamp(1, 7);
                final wEnd = wStart.add(Duration(days: daysInThisWeek - 1));
                final comments = <(DateTime, String)>[];

                for (var d = 0; d < daysInThisWeek; d++) {
                  final dayDate = wStart.add(Duration(days: d));
                  final c = checkIns[isoOf(dayDate)];
                  if (c?.daySummary?.trim().isNotEmpty == true) {
                    comments.add((dayDate, c!.daySummary!.trim()));
                  }
                }

                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Semana ${w + 1} (${dmy(wStart)} a ${dmy(wEnd)})',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 6),
                      if (comments.isEmpty)
                        Text(
                          '(nenhum comentário registrado)',
                          style: theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
                        )
                      else
                        for (final item in comments)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '• ${weekdayShort[item.$1.weekday - 1]} ${dmy(item.$1)}: ',
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                                ),
                                Expanded(
                                  child: Text(item.$2, style: const TextStyle(fontSize: 12)),
                                ),
                              ],
                            ),
                          ),
                    ],
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

// -------------------------------------------------------------
// ABA 2: Apenas Treinos
// -------------------------------------------------------------
class _WorkoutsOnlyView extends StatelessWidget {
  final DateTime start;
  final DateTime end;
  final List<Workout> workouts;

  const _WorkoutsOnlyView({
    required this.start,
    required this.end,
    required this.workouts,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (workouts.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.fitness_center, size: 48, color: theme.colorScheme.outline),
            const SizedBox(height: 12),
            const Text('Nenhum treino registrado no período'),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Treinos do Período (${dmy(start)} a ${dmy(end)})',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        for (final w in workouts) ...[
          Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: theme.colorScheme.outlineVariant),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.fitness_center, size: 18, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${w.title?.isNotEmpty == true ? w.title! : 'Treino'}${w.time != null ? ' às ${w.time}' : ''}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                      Text(
                        '${weekdayShort[dateFromIso(w.dateIso).weekday - 1]} ${dmy(dateFromIso(w.dateIso))}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                  const Divider(height: 16),
                  for (var i = 0; i < w.exercises.length; i++) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text('${i + 1}. ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              Expanded(
                                child: Text(w.exercises[i].name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 16, top: 2),
                            child: Text(
                              w.exercises[i].setsDisplay(),
                              style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                            ),
                          ),
                          if (w.exercises[i].note != null && w.exercises[i].note!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(left: 16, top: 2),
                              child: Text(
                                'Nota: ${w.exercises[i].note}',
                                style: theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic, fontSize: 11),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// -------------------------------------------------------------
// ABA 3: Apenas Check-ins
// -------------------------------------------------------------
class _CheckInsOnlyView extends StatelessWidget {
  final DateTime start;
  final int cycleLength;
  final Map<String, CheckIn> checkIns;

  const _CheckInsOnlyView({
    required this.start,
    required this.cycleLength,
    required this.checkIns,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: cycleLength,
      itemBuilder: (context, i) {
        final day = start.add(Duration(days: i));
        final c = checkIns[isoOf(day)];
        return _IntegratedDayCard(
          day: day,
          index: i,
          checkIn: c,
          workouts: const [],
          cardios: const [],
        );
      },
    );
  }
}

// -------------------------------------------------------------
// ABA 4: Visualização em Texto Puro
// -------------------------------------------------------------
class _RawTextView extends StatelessWidget {
  final String reportText;

  const _RawTextView({required this.reportText});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: SelectableText(
        reportText,
        style: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 12,
          height: 1.4,
        ),
      ),
    );
  }
}
