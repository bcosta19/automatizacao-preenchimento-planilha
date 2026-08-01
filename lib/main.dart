import 'package:flutter/material.dart';

import 'models.dart';
import 'notifier.dart';
import 'screens/day_form_screen.dart';
import 'screens/report_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/workout_screen.dart';
import 'storage.dart';

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
    final isCurrent = start == state.cycleStart;
    final days = List.generate(length, (i) => start.add(Duration(days: i)));
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

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
  final bool isToday;
  final VoidCallback onTap;

  const _DayCard({
    required this.day,
    required this.index,
    required this.checkIn,
    required this.isToday,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final filled = checkIn?.filledCount ?? 0;
    final complete = filled == CheckIn.totalFields;
    final today = DateTime.now();
    final isFuture = day.isAfter(DateTime(today.year, today.month, today.day));

    Color bg;
    if (complete) {
      bg = scheme.primaryContainer;
    } else if (filled > 0) {
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
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${weekdayShort[day.weekday - 1]}\n${day.day}',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: scheme.onSurface),
              ),
              const SizedBox(height: 4),
              if (complete)
                Icon(Icons.check_circle, size: 18, color: scheme.primary)
              else
                Text(
                  isFuture ? '–' : '$filled/${CheckIn.totalFields}',
                  style: TextStyle(fontSize: 10, color: scheme.onSurfaceVariant),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
