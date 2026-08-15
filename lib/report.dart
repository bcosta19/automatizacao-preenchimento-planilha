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
  List<CardioEntry>? cardios,
  int? weeklyCardioGoal,
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

  final rangeCardios = (cardios ?? []).where((c) {
    final d = dateFromIso(c.dateIso);
    return !d.isBefore(cycleStart) && !d.isAfter(end);
  }).toList()..sort((a, b) => a.dateIso.compareTo(b.dateIso));

  // --- Resumo de Cardio e Meta ---
  if (weeklyCardioGoal != null && weeklyCardioGoal > 0) {
    final cycleGoal = (weeklyCardioGoal * (cycleLength / 7)).round();
    var totalMin = rangeCardios.fold<int>(0, (sum, c) => sum + c.minutes);
    if (rangeCardios.isEmpty) {
      for (var i = 0; i < cycleLength; i++) {
        final d = cycleStart.add(Duration(days: i));
        final c = checkIns[isoOf(d)];
        if (c?.didCardio == true && c?.cardioMinutes != null) {
          totalMin += c!.cardioMinutes!;
        }
      }
    }
    final remaining = (cycleGoal - totalMin).clamp(0, 9999);
    final percent = cycleGoal > 0 ? ((totalMin / cycleGoal) * 100).toStringAsFixed(0) : '0';

    buffer.writeln('========================================');
    buffer.writeln('META DE CARDIO');
    buffer.writeln('========================================');
    buffer.writeln('Meta do ciclo: ${cycleGoal} min (Meta semanal: ${weeklyCardioGoal} min)');
    buffer.writeln('Realizado: ${totalMin} min (${percent}%) | ${remaining == 0 ? 'Meta batida! 🎉' : 'Faltam: ${remaining} min'}');

    if (cycleLength >= 14) {
      final w1End = cycleStart.add(const Duration(days: 6));
      final w2Start = cycleStart.add(const Duration(days: 7));
      int w1Min = rangeCardios.where((c) {
        final d = dateFromIso(c.dateIso);
        return !d.isBefore(cycleStart) && !d.isAfter(w1End);
      }).fold(0, (sum, c) => sum + c.minutes);

      int w2Min = rangeCardios.where((c) {
        final d = dateFromIso(c.dateIso);
        return !d.isBefore(w2Start) && !d.isAfter(end);
      }).fold(0, (sum, c) => sum + c.minutes);

      buffer.writeln('• Semana 1 (${dmy(cycleStart)} a ${dmy(w1End)}): ${w1Min} min');
      buffer.writeln('• Semana 2 (${dmy(w2Start)} a ${dmy(end)}): ${w2Min} min');
    }
    buffer.writeln();
  }

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
        '${weekdayFull[d.weekday - 1]} ${dmy(d)}${w.time != null ? ' às ${_time(w.time!)}' : ''}${w.title != null && w.title!.isNotEmpty ? ' — ${w.title}' : ''}');
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
    final dIso = isoOf(d);
    final c = checkIns[dIso];
    final dayCardios = rangeCardios.where((item) => item.dateIso == dIso).toList();
    final hasData = (c != null && c.filledCount > 0) || dayCardios.isNotEmpty;

    if (!hasData) {
      buffer.writeln();
      buffer.writeln('${weekdayFull[d.weekday - 1]} ${dmy(d)}: (sem dados)');
      continue;
    }
    final t = c?.trained ?? false;
    buffer.writeln();
    buffer.writeln('Dia ${i + 1} — ${weekdayFull[d.weekday - 1]} ${dmy(d)}');

    final morning = <String>[];
    if (c?.weight != null) morning.add('Peso em jejum: ${_n(c!.weight!)} kg');
    if (c?.sleepHours != null) morning.add('Sono: ${_n(c!.sleepHours!)}h');
    if (c?.sleepQualityPercent != null) morning.add('Qualidade do sono: ${c!.sleepQualityPercent}%');
    if (c?.sleepSatisfaction != null) morning.add('Satisfação com o sono: ${c!.sleepSatisfaction}/5');
    if (morning.isNotEmpty) buffer.writeln('  ${morning.join(' | ')}');

    final feelings = <String>[];
    if (c?.joy != null) feelings.add('Alegria: ${c!.joy}/5');
    if (c?.energy != null) feelings.add('Energia: ${c!.energy}/5');
    if (c?.mentalClarity != null) feelings.add('Claridade mental: ${c!.mentalClarity}/5');
    if (c?.stress != null) feelings.add('Estresse: ${c!.stress}/5');
    if (c?.muscleSoreness != null) feelings.add('Dor muscular: ${c!.muscleSoreness}/5');
    if (c?.immunity != null) feelings.add('Imunidade: ${c!.immunity}/5');
    if (feelings.isNotEmpty) buffer.writeln('  ${feelings.join(' | ')}');

    final habits = <String>[];
    habits.add('Furou a dieta: ${c?.brokeDiet == true ? 'sim' : 'não'}');
    if (c?.brokeDiet == true &&
        c?.brokeDietNote?.trim().isNotEmpty == true) {
      habits[habits.length - 1] += ': ${c!.brokeDietNote}';
    }
    if (c?.hunger != null) habits.add('Fome/apetite: ${c!.hunger}/5');
    habits.add('Café/estimulantes: ${c?.hadCaffeine == true ? 'sim' : 'não'}');
    if (c?.hadCaffeine == true &&
        c?.caffeineNote?.trim().isNotEmpty == true) {
      habits[habits.length - 1] += ': ${c!.caffeineNote}';
    }
    if (c?.digestion != null) habits.add('Digestão: ${c!.digestion}/5');
    buffer.writeln('  ${habits.join(' | ')}');

    if (t) {
      final training = <String>['Treinou: sim'];
      if (c?.workoutTime != null) training.add('Horário: ${_time(c!.workoutTime!)}');
      if (c?.motivation != null) training.add('Motivação: ${c!.motivation}/5');
      if (c?.strength != null) training.add('Força: ${c!.strength}/5');
      buffer.writeln('  ${training.join(' | ')}');
    } else {
      buffer.writeln('  Treinou: não');
    }

    final activity = <String>[];
    if (c?.steps != null) activity.add('Passos: ${c!.steps}');
    if (c?.didOtherSport == true) {
      final sport = StringBuffer(
          'Outro esporte: ${c?.otherSportDesc?.trim().isNotEmpty == true ? c!.otherSportDesc : 'sim'}');
      final details = <String>[];
      if (c?.sportTime != null) details.add(_time(c!.sportTime!));
      if (c?.sportMinutes != null) details.add('${c!.sportMinutes} min');
      if (details.isNotEmpty) sport.write(' (${details.join(', ')})');
      activity.add(sport.toString());
    } else {
      activity.add('Outro esporte: não');
    }

    if (dayCardios.isNotEmpty) {
      final totalMin = dayCardios.fold<int>(0, (sum, item) => sum + item.minutes);
      final bpms = dayCardios.where((item) => item.avgBpm != null && item.avgBpm! > 0).toList();
      final avgBpm = bpms.isNotEmpty
          ? (bpms.fold<int>(0, (sum, item) => sum + (item.avgBpm! * item.minutes)) /
                  bpms.fold<int>(0, (sum, item) => sum + item.minutes))
              .round()
          : null;

      final cardio = StringBuffer('Cardio: sim (${totalMin} min');
      if (avgBpm != null) cardio.write(', média ${avgBpm} bpm');
      cardio.write(')');

      if (dayCardios.length > 1) {
        final sessions = dayCardios.map((s) {
          final parts = <String>['${s.minutes} min'];
          if (s.avgBpm != null) parts.add('${s.avgBpm} bpm');
          if (s.note?.isNotEmpty == true) parts.add(s.note!);
          return parts.join(', ');
        }).join(' | ');
        cardio.write(' [Sessões: $sessions]');
      }
      activity.add(cardio.toString());
    } else if (c?.didCardio == true) {
      final cardio = StringBuffer('Cardio: sim');
      if (c?.cardioMinutes != null) cardio.write(' (${c!.cardioMinutes} min');
      if (c?.cardioAvgBpm != null) {
        cardio.write('${c?.cardioMinutes != null ? ', ' : ' ('}média ${c!.cardioAvgBpm} bpm');
      }
      if (c?.cardioMinutes != null || c?.cardioAvgBpm != null) cardio.write(')');
      activity.add(cardio.toString());
    } else {
      activity.add('Cardio: não');
    }
    if (activity.isNotEmpty) buffer.writeln('  ${activity.join(' | ')}');
    if (c?.daySummary?.trim().isNotEmpty == true) {
      buffer.writeln('  Resumo do dia: "${c!.daySummary!.trim()}"');
    }
  }

  // --- Compilação do Resumo Semanal (Comentários) ---
  final hasAnySummary = List.generate(cycleLength, (i) => checkIns[isoOf(cycleStart.add(Duration(days: i)))])
      .any((c) => c?.daySummary?.trim().isNotEmpty == true);

  if (hasAnySummary) {
    buffer.writeln();
    buffer.writeln('========================================');
    buffer.writeln('RESUMO SEMANAL (COMENTÁRIOS DOS DIAS)');
    buffer.writeln('========================================');

    final numWeeks = (cycleLength + 6) ~/ 7;
    for (var w = 0; w < numWeeks; w++) {
      final wStart = cycleStart.add(Duration(days: w * 7));
      final daysInThisWeek = (cycleLength - (w * 7)).clamp(1, 7);
      final wEnd = wStart.add(Duration(days: daysInThisWeek - 1));

      buffer.writeln();
      buffer.writeln('--- SEMANA ${w + 1} (${dmy(wStart)} a ${dmy(wEnd)}) ---');

      var foundInWeek = false;
      for (var d = 0; d < daysInThisWeek; d++) {
        final dayDate = wStart.add(Duration(days: d));
        final c = checkIns[isoOf(dayDate)];
        if (c?.daySummary?.trim().isNotEmpty == true) {
          foundInWeek = true;
          buffer.writeln(
              '• ${weekdayShort[dayDate.weekday - 1]} ${dmy(dayDate)}: ${c!.daySummary!.trim()}');
        }
      }
      if (!foundInWeek) {
        buffer.writeln('(nenhum comentário registrado nesta semana)');
      }
    }
  }

  buffer.writeln();
  buffer.writeln('Fim do relatório.');
  return buffer.toString();
}
