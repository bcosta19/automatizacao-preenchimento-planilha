import 'package:flutter/material.dart';

import '../main.dart';
import '../models.dart';
import '../widgets/form_widgets.dart';

class DayFormScreen extends StatefulWidget {
  final DateTime date;

  const DayFormScreen({super.key, required this.date});

  @override
  State<DayFormScreen> createState() => _DayFormScreenState();
}

class _DayFormScreenState extends State<DayFormScreen> {
  late CheckIn _draft;
  late final TextEditingController _weightCtrl;
  late final TextEditingController _sleepCtrl;
  late final TextEditingController _sportCtrl;
  late final TextEditingController _sportMinCtrl;
  late final TextEditingController _dietNoteCtrl;
  late final TextEditingController _caffeineCtrl;
  late final TextEditingController _cardioMinCtrl;
  late final TextEditingController _bpmCtrl;
  late final TextEditingController _stepsCtrl;
  late final TextEditingController _daySummaryCtrl;

  @override
  void initState() {
    super.initState();
    final state = AppScope.read(context);
    _draft = CheckIn.fromJson(
        state.checkInFor(widget.date)?.toJson() ?? {'date': isoOf(widget.date)});
    final dayWorkouts = state.workoutsForDate(widget.date);
    if (dayWorkouts.isNotEmpty) {
      _draft.trained = true;
      if (_draft.workoutTime == null && dayWorkouts.first.time != null) {
        _draft.workoutTime = dayWorkouts.first.time;
      }
    }
    _weightCtrl = _txt(_draft.weight, dec: true);
    _sleepCtrl = _txt(_draft.sleepHours, dec: true);
    _sportCtrl = TextEditingController(text: _draft.otherSportDesc ?? '');
    _sportMinCtrl = _txt(_draft.sportMinutes);
    _dietNoteCtrl = TextEditingController(text: _draft.brokeDietNote ?? '');
    _caffeineCtrl = TextEditingController(text: _draft.caffeineNote ?? '');
    _cardioMinCtrl = _txt(_draft.cardioMinutes);
    _bpmCtrl = _txt(_draft.cardioAvgBpm);
    _stepsCtrl = _txt(_draft.steps);
    _daySummaryCtrl = TextEditingController(text: _draft.daySummary ?? '');
  }

  TextEditingController _txt(num? v, {bool dec = false}) {
    if (v == null) return TextEditingController();
    final d = v.toDouble();
    final s = dec
        ? d.toStringAsFixed(d == d.roundToDouble() ? 0 : 1).replaceAll('.', ',')
        : v.toInt().toString();
    return TextEditingController(text: s);
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    _sleepCtrl.dispose();
    _sportCtrl.dispose();
    _sportMinCtrl.dispose();
    _dietNoteCtrl.dispose();
    _caffeineCtrl.dispose();
    _cardioMinCtrl.dispose();
    _bpmCtrl.dispose();
    _stepsCtrl.dispose();
    _daySummaryCtrl.dispose();
    super.dispose();
  }

  void _save() {
    AppScope.of(context).setCheckIn(_draft);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(const SnackBar(content: Text('Check-in salvo!'), duration: Duration(seconds: 1)));
  }

  double? _parseDec(String s) {
    final t = s.trim().replaceAll(',', '.');
    if (t.isEmpty) return null;
    final v = double.tryParse(t);
    return v;
  }

  int? _parseInt(String s) {
    final t = s.trim();
    if (t.isEmpty) return null;
    return int.tryParse(t);
  }

  @override
  Widget build(BuildContext context) {
    final dayWorkouts = AppScope.of(context).workoutsForDate(widget.date);

    return Scaffold(
      appBar: AppBar(
        title: Text('${weekdayFull[widget.date.weekday - 1]}, ${dmy(widget.date)}'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (dayWorkouts.isNotEmpty)
            Card(
              color: Theme.of(context).colorScheme.secondaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Treino registrado neste dia:',
                        style: Theme.of(context).textTheme.labelLarge),
                    for (final w in dayWorkouts)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '${w.title?.isNotEmpty == true ? w.title : 'Treino'} — ${w.exercises.length} exercícios',
                        ),
                      ),
                  ],
                ),
              ),
            ),
          SectionHeader(
            title: 'Manhã',
            icon: Icons.wb_sunny_outlined,
            subtitle: 'ao acordar',
          ),
          NumberField(
            label: 'Peso em jejum',
            suffix: 'kg',
            hint: 'ex.: 82,5',
            allowDecimal: true,
            controller: _weightCtrl,
            onChanged: (v) => _draft.weight = _parseDec(v),
          ),
          const SizedBox(height: 12),
          NumberField(
            label: 'Duração do sono',
            suffix: 'h',
            hint: 'ex.: 7,5',
            allowDecimal: true,
            controller: _sleepCtrl,
            onChanged: (v) => _draft.sleepHours = _parseDec(v),
          ),
          const SizedBox(height: 12),
          Text('Qualidade do sono: ${_draft.sleepQualityPercent ?? 0}%',
              style: Theme.of(context).textTheme.bodyMedium),
          Slider(
            value: (_draft.sleepQualityPercent ?? 0).toDouble().clamp(0, 100),
            max: 100,
            divisions: 20,
            label: '${_draft.sleepQualityPercent ?? 0}%',
            onChanged: (v) => setState(() => _draft.sleepQualityPercent = v.round()),
          ),
          const SizedBox(height: 12),
          Text('Satisfação com o sono', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 8),
          ScaleSelector(
            value: _draft.sleepSatisfaction,
            onChanged: (v) => setState(() => _draft.sleepSatisfaction = v),
          ),
          SectionHeader(
            title: 'Fim do dia',
            icon: Icons.nights_stay_outlined,
            subtitle: 'lembrete do fim do dia',
          ),
          _scaleRow('Nível de alegria', _draft.joy, (v) => _draft.joy = v),
          _scaleRow('Nível de energia', _draft.energy, (v) => _draft.energy = v),
          _scaleRow('Claridade mental', _draft.mentalClarity, (v) => _draft.mentalClarity = v),
          _scaleRow('Estresse mental e emocional', _draft.stress, (v) => _draft.stress = v),
          _scaleRow('Dor muscular', _draft.muscleSoreness, (v) => _draft.muscleSoreness = v),
          _scaleRow('Imunidade', _draft.immunity, (v) => _draft.immunity = v),
          _scaleRow('Fome e apetite', _draft.hunger, (v) => _draft.hunger = v),
          _scaleRow('Digestão', _draft.digestion, (v) => _draft.digestion = v),
          const SizedBox(height: 4),
          YesNoSwitch(
            label: 'Furou a dieta?',
            value: _draft.brokeDiet,
            onChanged: (v) => setState(() => _draft.brokeDiet = v),
          ),
          if (_draft.brokeDiet == true)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TextField(
                controller: _dietNoteCtrl,
                decoration: const InputDecoration(
                  labelText: 'O quê? Quantidade e horário',
                  hintText: 'ex.: pizza à noite, 2 pedaços, 22h',
                ),
                onChanged: (v) => _draft.brokeDietNote = v.trim().isEmpty ? null : v,
              ),
            ),
          YesNoSwitch(
            label: 'Tomou café/estimulantes?',
            value: _draft.hadCaffeine,
            onChanged: (v) => setState(() => _draft.hadCaffeine = v),
          ),
          if (_draft.hadCaffeine == true)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TextField(
                controller: _caffeineCtrl,
                decoration: const InputDecoration(
                  labelText: 'O quê? Quantidade e horário',
                  hintText: 'ex.: 2 xícaras de café, 15h',
                ),
                onChanged: (v) => _draft.caffeineNote = v.trim().isEmpty ? null : v,
              ),
            ),
          SectionHeader(
            title: 'Treino',
            icon: Icons.fitness_center,
            subtitle: 'se treinou hoje',
          ),
          Builder(
            builder: (ctx) {
              final workouts = AppScope.of(ctx).workoutsForDate(widget.date);
              if (workouts.isEmpty) return const SizedBox.shrink();
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(ctx).colorScheme.primaryContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Theme.of(ctx).colorScheme.primary.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.check_circle, size: 18, color: Theme.of(ctx).colorScheme.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Treino registrado automaticamente',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Theme.of(ctx).colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    for (final w in workouts)
                      Text(
                        '• ${w.title ?? 'Treino'}${w.time != null ? ' às ${w.time}' : ''} (${w.exercises.length} exercícios)',
                        style: TextStyle(fontSize: 12, color: Theme.of(ctx).colorScheme.onPrimaryContainer),
                      ),
                  ],
                ),
              );
            },
          ),
          YesNoSwitch(
            label: 'Treinou hoje?',
            value: _draft.trained,
            onChanged: (v) => setState(() => _draft.trained = v),
          ),
          if (_draft.trained == true) ...[
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.schedule),
              title: const Text('Horário do treino'),
              subtitle: Text(_draft.workoutTime == null ? 'Definir horário' : _draft.workoutTime!),
              trailing: const Icon(Icons.edit_outlined),
              onTap: () async {
                final now = TimeOfDay.now();
                final picked = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay(
                    hour: _draft.workoutTime != null ? _timeOfDayFromString(_draft.workoutTime!) : now.hour,
                    minute: _draft.workoutTime != null ? _minuteFromString(_draft.workoutTime!) : now.minute,
                  ),
                );
                if (picked != null) {
                  setState(() {
                    _draft.workoutTime = picked.format(context);
                  });
                }
              },
            ),
            _scaleRow('Nível de motivação', _draft.motivation, (v) => _draft.motivation = v),
            _scaleRow('Nível de força', _draft.strength, (v) => _draft.strength = v),
          ],
          SectionHeader(
            title: 'Atividade',
            icon: Icons.directions_walk,
            subtitle: 'fim do dia',
          ),
          NumberField(
            label: 'Número de passos',
            hint: 'ex.: 8500',
            controller: _stepsCtrl,
            onChanged: (v) => _draft.steps = _parseInt(v),
          ),
          const SizedBox(height: 12),
          YesNoSwitch(
            label: 'Fez outro esporte? (jiujitsu, etc.)',
            value: _draft.didOtherSport,
            onChanged: (v) => setState(() {
              _draft.didOtherSport = v;
              if (v == true && _draft.otherSportDesc?.trim().isEmpty != false) {
                _draft.otherSportDesc = AppScope.read(context).settings.defaultSport;
                _sportCtrl.text = _draft.otherSportDesc!;
              }
            }),
          ),
          if (_draft.didOtherSport == true) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TextField(
                controller: _sportCtrl,
                decoration: const InputDecoration(
                  labelText: 'Qual esporte?',
                  hintText: 'ex.: jiujitsu',
                ),
                onChanged: (v) => _draft.otherSportDesc = v.isEmpty ? null : v,
              ),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.schedule),
              title: const Text('Horário do esporte'),
              subtitle: Text(_draft.sportTime ?? 'Definir horário'),
              trailing: const Icon(Icons.edit_outlined),
              onTap: () async {
                final now = TimeOfDay.now();
                final picked = await showTimePicker(
                  context: context,
                  initialTime: _draft.sportTime != null
                      ? TimeOfDay(
                          hour: _timeOfDayFromString(_draft.sportTime!),
                          minute: _minuteFromString(_draft.sportTime!),
                        )
                      : TimeOfDay(hour: now.hour, minute: now.minute),
                );
                if (picked != null) {
                  setState(() => _draft.sportTime = picked.format(context));
                }
              },
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: NumberField(
                label: 'Duração do esporte',
                suffix: 'min',
                controller: _sportMinCtrl,
                onChanged: (v) => _draft.sportMinutes = _parseInt(v),
              ),
            ),
          ],
          SectionHeader(
            title: 'Cardio',
            icon: Icons.directions_run,
            subtitle: 'ao longo do dia',
          ),
          Builder(
            builder: (context) {
              final state = AppScope.of(context);
              final dayCardios = state.cardiosForDate(widget.date);
              final totalMin = state.totalCardioMinutesForDate(widget.date);
              final avgBpm = state.avgBpmForDate(widget.date);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (dayCardios.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total: $totalMin min',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          if (avgBpm != null)
                            Text(
                              'BPM médio: $avgBpm bpm',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                        ],
                      ),
                    ),
                    for (final c in dayCardios)
                      Card(
                        margin: const EdgeInsets.only(bottom: 6),
                        child: ListTile(
                          dense: true,
                          leading: const CircleAvatar(
                            radius: 16,
                            child: Icon(Icons.directions_run, size: 16),
                          ),
                          title: Text(
                            '${c.minutes} min${c.note?.isNotEmpty == true ? ' — ${c.note}' : ''}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            [
                              if (c.avgBpm != null) '${c.avgBpm} bpm',
                              if (c.time != null) 'às ${c.time}',
                            ].join(' • '),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 18),
                                onPressed: () => showCardioModal(context, existing: c),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                onPressed: () => state.removeCardio(c),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 6),
                  ],
                  OutlinedButton.icon(
                    icon: const Icon(Icons.add),
                    label: Text(dayCardios.isEmpty ? 'Adicionar cardio neste dia' : 'Adicionar outra sessão de cardio'),
                    onPressed: () => showCardioModal(context, initialDate: widget.date),
                  ),
                ],
              );
            },
          ),
          SectionHeader(
            title: 'Resumo do Dia',
            icon: Icons.comment_outlined,
            subtitle: 'comentários para a semana',
          ),
          TextField(
            controller: _daySummaryCtrl,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Comentários / Observações do dia',
              hintText: 'Como foi o dia, recuperação, rendimento no treino, dieta ou imprevistos...',
              border: OutlineInputBorder(),
            ),
            onChanged: (v) => _draft.daySummary = v.trim().isEmpty ? null : v.trim(),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            icon: const Icon(Icons.save_outlined),
            label: const Text('Salvar check-in'),
            onPressed: _save,
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _scaleRow(String label, int? value, ValueChanged<int?> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 8),
          ScaleSelector(value: value, onChanged: (v) => setState(() => onChanged(v))),
        ],
      ),
    );
  }

  int _timeOfDayFromString(String s) {
    final m = RegExp(r'(\d{1,2}):(\d{2})').firstMatch(s);
    if (m != null) return int.parse(m.group(1)!);
    final hm = RegExp(r'(\d{1,2})h(\d{2})').firstMatch(s);
    if (hm != null) return int.parse(hm.group(1)!);
    return 19;
  }

  int _minuteFromString(String s) {
    final m = RegExp(r'(\d{1,2}):(\d{2})').firstMatch(s);
    if (m != null) return int.parse(m.group(2)!);
    final hm = RegExp(r'(\d{1,2})h(\d{2})').firstMatch(s);
    if (hm != null) return int.parse(hm.group(2)!);
    return 0;
  }
}
