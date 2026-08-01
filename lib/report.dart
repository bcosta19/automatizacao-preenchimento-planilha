import 'models.dart';

String _n(double v) => v == v.roundToDouble()
    ? v.toInt().toString()
    : v.toStringAsFixed(1).replaceAll('.', ',');

String _time(String t) => t.replaceAll(':', 'h') + (t.contains(':') ? '' : 'h');

String generateReport({
  required DateTime cycleStart,
  required int cycleLength,
  required Map<String, CheckIn> checkIns,
  required List<Workout> workouts,
}) {
  final end = cycleStart.add(Duration(days: cycleLength - 1));
  final buffer = StringBuffer();

  buffer.writeln('RELATÓRIO DE FEEDBACK QUINZENAL');
  buffer.writeln('Período: ${dmy(cycleStart)} a ${dmy(end)}');
  buffer.writeln();

  final rangeWorkouts = workouts
      .where((w) {
        final d = dateFromIso(w.dateIso);
        return !d.isBefore(cycleStart) && !d.isAfter(end);
      })
      .toList()
    ..sort((a, b) => a.dateIso.compareTo(b.dateIso));

  buffer.writeln('========================================');
  buffer.writeln('TREINOS');
  buffer.writeln('========================================');
  if (rangeWorkouts.isEmpty) {
    buffer.writeln('(nenhum treino registrado no período)');
  }
  for (final w in rangeWorkouts) {
    final d = dateFromIso(w.dateIso);
    buffer.writeln();
    buffer.writeln(
        '${weekdayFull[d.weekday - 1]} ${dmy(d)}${w.title != null && w.title!.isNotEmpty ? ' — ${w.title}' : ''}');
    for (final e in w.exercises) {
      buffer.writeln('  ${e.name}: ${e.setsDisplay()}');
    }
  }

  buffer.writeln();
  buffer.writeln('========================================');
  buffer.writeln('CHECK-IN DIÁRIO');
  buffer.writeln('========================================');

  for (var i = 0; i < cycleLength; i++) {
    final d = cycleStart.add(Duration(days: i));
    final c = checkIns[isoOf(d)];
    final hasData = c != null && c.filledCount > 0;
    if (!hasData) {
      buffer.writeln();
      buffer.writeln('${weekdayFull[d.weekday - 1]} ${dmy(d)}: (sem dados)');
      continue;
    }
    final t = c.trained ?? false;
    buffer.writeln();
    buffer.writeln('Dia ${i + 1} — ${weekdayFull[d.weekday - 1]} ${dmy(d)}');

    final morning = <String>[];
    if (c.weight != null) morning.add('Peso em jejum: ${_n(c.weight!)} kg');
    if (c.sleepHours != null) morning.add('Sono: ${_n(c.sleepHours!)}h');
    if (c.sleepQualityPercent != null) morning.add('Qualidade do sono: ${c.sleepQualityPercent}%');
    if (c.sleepSatisfaction != null) morning.add('Satisfação com o sono: ${c.sleepSatisfaction}/5');
    if (morning.isNotEmpty) buffer.writeln('  ${morning.join(' | ')}');

    final feelings = <String>[];
    if (c.joy != null) feelings.add('Alegria: ${c.joy}/5');
    if (c.energy != null) feelings.add('Energia: ${c.energy}/5');
    if (c.mentalClarity != null) feelings.add('Claridade mental: ${c.mentalClarity}/5');
    if (c.stress != null) feelings.add('Estresse: ${c.stress}/5');
    if (c.muscleSoreness != null) feelings.add('Dor muscular: ${c.muscleSoreness}/5');
    if (c.immunity != null) feelings.add('Imunidade: ${c.immunity}/5');
    if (feelings.isNotEmpty) buffer.writeln('  ${feelings.join(' | ')}');

    final habits = <String>[];
    habits.add('Furou a dieta: ${c.brokeDiet == true ? 'sim' : 'não'}');
    if (c.brokeDiet == true &&
        c.brokeDietNote?.trim().isNotEmpty == true) {
      habits[habits.length - 1] += ': ${c.brokeDietNote}';
    }
    if (c.hunger != null) habits.add('Fome/apetite: ${c.hunger}/5');
    habits.add('Café/estimulantes: ${c.hadCaffeine == true ? 'sim' : 'não'}');
    if (c.hadCaffeine == true &&
        c.caffeineNote?.trim().isNotEmpty == true) {
      habits[habits.length - 1] += ': ${c.caffeineNote}';
    }
    if (c.digestion != null) habits.add('Digestão: ${c.digestion}/5');
    buffer.writeln('  ${habits.join(' | ')}');

    if (t) {
      final training = <String>['Treinou: sim'];
      if (c.workoutTime != null) training.add('Horário: ${_time(c.workoutTime!)}');
      if (c.motivation != null) training.add('Motivação: ${c.motivation}/5');
      if (c.strength != null) training.add('Força: ${c.strength}/5');
      buffer.writeln('  ${training.join(' | ')}');
    } else {
      buffer.writeln('  Treinou: não');
    }

    final activity = <String>[];
    if (c.steps != null) activity.add('Passos: ${c.steps}');
    if (c.didOtherSport == true) {
      final sport = StringBuffer(
          'Outro esporte: ${c.otherSportDesc?.trim().isNotEmpty == true ? c.otherSportDesc : 'sim'}');
      final details = <String>[];
      if (c.sportTime != null) details.add(_time(c.sportTime!));
      if (c.sportMinutes != null) details.add('${c.sportMinutes} min');
      if (details.isNotEmpty) sport.write(' (${details.join(', ')})');
      activity.add(sport.toString());
    } else {
      activity.add('Outro esporte: não');
    }
    if (c.didCardio == true) {
      final cardio = StringBuffer('Cardio: sim');
      if (c.cardioMinutes != null) cardio.write(' (${c.cardioMinutes} min');
      if (c.cardioAvgBpm != null) {
        cardio.write('${c.cardioMinutes != null ? ', ' : ' ('}média ${c.cardioAvgBpm} bpm');
      }
      if (c.cardioMinutes != null || c.cardioAvgBpm != null) cardio.write(')');
      activity.add(cardio.toString());
    } else {
      activity.add('Cardio: não');
    }
    if (activity.isNotEmpty) buffer.writeln('  ${activity.join(' | ')}');
  }

  buffer.writeln();
  buffer.writeln('Fim do relatório.');
  return buffer.toString();
}
