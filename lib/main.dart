import 'package:flutter/material.dart';

import 'models.dart';
import 'notifier.dart';
import 'screens/day_form_screen.dart';
import 'screens/report_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/workout_screen.dart';
import 'storage.dart';
import 'widgets/form_widgets.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final state = AppState();
  await state.load();
  await NotificationService.init();
  await NotificationService.requestPermission();
  await NotificationService.scheduleAll(state.settings);
  runApp(CheckinApp(state: state));
}

class CheckinApp extends StatelessWidget {
  final AppState state;

  const CheckinApp({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: state,
      child: MaterialApp(
        title: 'Check-in Quinzenal',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2E7D32)),
          useMaterial3: true,
          inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder()),
        ),
        home: const HomeScreen(),
      ),
    );
  }
}

class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child})
      : super(notifier: state);

  static AppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope não encontrado na árvore');
    return scope!.notifier!;
  }

  static AppState read(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope não encontrado na árvore');
    return scope!.notifier!;
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime? _selectedCycleStart;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final length = state.settings.cycleLength;
    final cycles = state.cyclesAvailable();
    final start = _selectedCycleStart ?? cycles.first;
    final end = start.add(Duration(days: length - 1));
    final isCurrent = start == state.cycleStart;
    final days = List.generate(length, (i) => start.add(Duration(days: i)));
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    final cycleGoal = state.settings.cycleCardioMinutesGoal;
    final totalCardioDone = state.totalCardioMinutesForRange(start, end);
    final remainingCardio = (cycleGoal - totalCardioDone).clamp(0, 99999);
    final avgBpm = state.avgBpmForRange(start, end);
    final cardioProgress = cycleGoal > 0 ? (totalCardioDone / cycleGoal).clamp(0.0, 1.0) : 0.0;
    final cardioPercent = cycleGoal > 0 ? ((totalCardioDone / cycleGoal) * 100).toStringAsFixed(0) : '0';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Check-in Quinzenal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Ajustes',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.calendar_month, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButton<DateTime>(
                          value: start,
                          isExpanded: true,
                          isDense: true,
                          underline: const SizedBox.shrink(),
                          items: [
                            for (final c in cycles)
                              DropdownMenuItem(
                                value: c,
                                child: Text(
                                  '${dmy(c)} a ${dmy(c.add(Duration(days: length - 1)))}'
                                  '${c == cycles.first ? ' (atual)' : ''}',
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                              ),
                          ],
                          onChanged: (v) => setState(() => _selectedCycleStart = v),
                        ),
                      ),
                      if (isCurrent)
                        Text(
                          '${todayDate.difference(start).inDays + 1}/$length',
                          style: Theme.of(context).textTheme.titleMedium,
                        )
                      else
                        Icon(Icons.history, size: 20, color: Theme.of(context).colorScheme.outline),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isCurrent
                        ? 'Ciclo de $length dias. Ao terminar, um novo período começa automaticamente. Toque em um dia para preencher ou editar.'
                        : 'Ciclo anterior: toque em um dia para ver ou editar o check-in.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // --- Card de Meta e Progresso de Cardio ---
          Card(
            elevation: 1,
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.directions_run, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Meta de Cardio do Ciclo',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            Text(
                              '${state.settings.weeklyCardioMinutes} min/sem • Meta ciclo: ${cycleGoal} min',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      FilledButton.tonalIcon(
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          visualDensity: VisualDensity.compact,
                        ),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Cardio'),
                        onPressed: () => showCardioModal(
                          context,
                          initialDate: isCurrent ? todayDate : start,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: cardioProgress,
                      minHeight: 8,
                      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                      color: cardioProgress >= 1.0
                          ? Colors.green
                          : Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Realizado: ${totalCardioDone} min ($cardioPercent%)',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      Text(
                        remainingCardio == 0
                            ? 'Meta batida! 🎉'
                            : 'Faltam: ${remainingCardio} min',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: remainingCardio == 0
                              ? Colors.green
                              : Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                  ),
                  if (length >= 14) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Semana 1: ${state.totalCardioMinutesForWeek(start, 0)} min',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'Semana 2: ${state.totalCardioMinutesForWeek(start, 1)} min',
                            textAlign: TextAlign.right,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (avgBpm != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '❤️ BPM Médio do período: $avgBpm bpm',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.secondary,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            children: [
              for (var i = 0; i < days.length; i++)
                _DayCard(
                  day: days[i],
                  index: i,
                  checkIn: state.checkInFor(days[i]),
                  cardioMinutes: state.totalCardioMinutesForDate(days[i]),
                  isToday: isCurrent && days[i] == todayDate,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => DayFormScreen(date: days[i])),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  icon: const Icon(Icons.bedtime_outlined),
                  label: const Text('+ Sono'),
                  onPressed: () => showSleepModal(
                    context,
                    date: isCurrent ? todayDate : start,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.tonalIcon(
                  icon: const Icon(Icons.directions_run),
                  label: const Text('+ Cardio'),
                  onPressed: () => showCardioModal(
                    context,
                    initialDate: isCurrent ? todayDate : start,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.tonalIcon(
                  icon: const Icon(Icons.comment_outlined),
                  label: const Text('+ Resumo'),
                  onPressed: () => showDaySummaryModal(
                    context,
                    date: isCurrent ? todayDate : start,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  icon: const Icon(Icons.fitness_center),
                  label: const Text('Treinos'),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const WorkoutScreen()),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  icon: const Icon(Icons.description_outlined),
                  label: const Text('Relatório'),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ReportScreen()),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DayCard extends StatelessWidget {
  final DateTime day;
  final int index;
  final CheckIn? checkIn;
  final int cardioMinutes;
  final bool isToday;
  final VoidCallback onTap;

  const _DayCard({
    required this.day,
    required this.index,
    required this.checkIn,
    this.cardioMinutes = 0,
    required this.isToday,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final filled = checkIn?.filledCount ?? 0;
    final complete = filled == CheckIn.totalFields;
    final hasSummary = checkIn?.daySummary?.trim().isNotEmpty == true;
    final today = DateTime.now();
    final isFuture = day.isAfter(DateTime(today.year, today.month, today.day));

    Color bg;
    if (complete) {
      bg = scheme.primaryContainer;
    } else if (filled > 0 || cardioMinutes > 0) {
      bg = scheme.secondaryContainer;
    } else {
      bg = scheme.surfaceContainerHighest;
    }

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: isToday
                ? Border.all(color: scheme.primary, width: 2)
                : Border.all(color: scheme.outlineVariant),
          ),
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${weekdayShort[day.weekday - 1]} ${day.day}',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: scheme.onSurface),
                  ),
                  if (hasSummary) ...[
                    const SizedBox(width: 2),
                    Icon(Icons.comment, size: 10, color: scheme.primary),
                  ],
                ],
              ),
              const SizedBox(height: 2),
              if (cardioMinutes > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '🏃${cardioMinutes}m',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: scheme.primary,
                    ),
                  ),
                )
              else if (complete)
                Icon(Icons.check_circle, size: 16, color: scheme.primary)
              else
                Text(
                  isFuture ? '–' : '$filled/${CheckIn.totalFields}',
                  style: TextStyle(fontSize: 9, color: scheme.onSurfaceVariant),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
