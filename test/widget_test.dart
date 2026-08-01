import 'package:flutter_test/flutter_test.dart';

import 'package:checkin_quinzenal/hevy_parser.dart';
import 'package:checkin_quinzenal/models.dart';
import 'package:checkin_quinzenal/report.dart';

void main() {
  group('parseHevyText', () {
    test('parseia formato padrão do Hevy', () {
      const text = '''
Workout 1: Leg Day
Date: 2026-07-27
Duration: 60 minutes

Barbell Squat
Set 1: 100 kg × 8
Set 2: 100 kg × 8
Set 3: 100 kg × 8

Romanian Deadlift
Set 1: 80 kg × 10
Set 2: 80 kg × 10
''';
      final parsed = parseHevyText(text);
      expect(parsed.dateIso, '2026-07-27');
      expect(parsed.title, 'Leg Day');
      expect(parsed.exercises.length, 2);
      expect(parsed.exercises[0].name, 'Barbell Squat');
      expect(parsed.exercises[0].sets.length, 3);
      expect(parsed.exercises[0].sets.first.weight, 100);
      expect(parsed.exercises[0].sets.first.reps, 8);
      expect(parsed.exercises[1].name, 'Romanian Deadlift');
      expect(parsed.exercises[1].sets.length, 2);
    });

    test('aceita x minúsculo e sem prefixo de série', () {
      const text = '''
Bench Press
60 kg x 10
60 kg x 10
70 kg x 8
''';
      final parsed = parseHevyText(text);
      expect(parsed.exercises.single.name, 'Bench Press');
      expect(parsed.exercises.single.sets.length, 3);
      expect(parsed.exercises.single.sets.last.weight, 70);
      expect(parsed.exercises.single.sets.last.reps, 8);
    });

    test('aceita séries sem peso e sem reps', () {
      const text = '''
Push-ups
Set 1: 20 reps
Set 2: 15 reps
Plank
Set 1: 90 sec
''';
      final parsed = parseHevyText(text);
      expect(parsed.exercises[0].sets.first.weight, isNull);
      expect(parsed.exercises[0].sets.first.reps, 20);
      expect(parsed.exercises[1].name, 'Plank');
      expect(parsed.exercises[1].sets.single.note, '90 sec');
    });

    test('retorna aviso quando não reconhece nada', () {
      final parsed = parseHevyText('qualquer coisa sem sentido');
      expect(parsed.exercises, isEmpty);
      expect(parsed.warnings, isNotEmpty);
    });

    test('data com barra', () {
      final parsed = parseHevyText('Date: 2026/07/27\n\nSquat\nSet 1: 50 kg × 5');
      expect(parsed.dateIso, '2026-07-27');
    });

    test('parseia exemplo real do Hevy', () {
      const text = '''
Posterior A
Tuesday, Jul 21, 2026 at 6:06pm

Straight Leg Deadlift
"fiz livre 2 serie foi mais difícil do que no smith"
Set 1: 160 kg x 9
Set 2: 160 kg x 6

Bent Over Row (Barbell)
Set 1: 100 kg x 5
Set 2: 80 kg x 7
Set 3: 80 kg x 7

Lat Pulldown (Cable)
Set 1: 105.5 kg x 9
Set 2: 105.5 kg x 7

Single Arm Cable Row
Set 1: 75 kg x 9
Set 2: 75 kg x 9

Kettlebell Curl
"pos 3 banco
2 serie alternando dps da 6"
Set 1: 14 kg x 9
Set 2: 14 kg x 8
Set 3: 14 kg x 8

Seated Leg Curl (Machine)
Set 1: 130 kg x 9
Set 2: 102.5 kg x 9

Hip Adduction (Machine)
Set 1: 152.5 kg x 8

@hevyapp
https://hevy.com/workout/FceFu1MS6Zh
''';
      final parsed = parseHevyText(text);
      expect(parsed.title, 'Posterior A');
      expect(parsed.dateIso, '2026-07-21');
      expect(parsed.exercises.length, 7);
      expect(parsed.exercises[0].name, 'Straight Leg Deadlift');
      expect(parsed.exercises[0].note, contains('fiz livre'));
      expect(parsed.exercises[0].sets.length, 2);
      expect(parsed.exercises[0].sets.first.weight, 160);
      expect(parsed.exercises[2].sets.first.weight, 105.5);
      expect(parsed.exercises[4].name, 'Kettlebell Curl');
      expect(parsed.exercises[4].note, contains('pos 3 banco'));
      expect(parsed.exercises[4].note, contains('alternando'));
      expect(parsed.exercises[6].sets.single.weight, 152.5);
      expect(parsed.warnings, isEmpty);
    });

    test('data em português', () {
      final parsed = parseHevyText(
          'Terça-feira, 21 de julho de 2026 às 18:06\n\nSquat\nSet 1: 50 kg x 5');
      expect(parsed.dateIso, '2026-07-21');
    });
  });

  group('generateReport', () {
    final start = DateTime(2026, 7, 27);

    test('gera relatório com treino e check-in', () {
      final checkIn = CheckIn(date: '2026-07-27')
        ..weight = 82.5
        ..sleepHours = 7.5
        ..sleepQualityPercent = 80
        ..sleepSatisfaction = 4
        ..joy = 4
        ..energy = 3
        ..mentalClarity = 4
        ..stress = 2
        ..muscleSoreness = 3
        ..immunity = 4
        ..brokeDiet = false
        ..hunger = 3
        ..hadCaffeine = true
        ..digestion = 4
        ..trained = true
        ..workoutTime = '20:00'
        ..motivation = 4
        ..strength = 3
        ..steps = 8500
        ..didOtherSport = true
        ..otherSportDesc = 'jiujitsu'
        ..didCardio = true
        ..cardioMinutes = 30
        ..cardioAvgBpm = 145;

      final workout = Workout(
        dateIso: '2026-07-27',
        title: 'Leg Day',
        exercises: [
          WorkoutExercise(name: 'Barbell Squat', sets: [
            WorkoutSet(weight: 100, reps: 8),
            WorkoutSet(weight: 100, reps: 8),
          ]),
        ],
      );

      final report = generateReport(
        cycleStart: start,
        cycleLength: 14,
        checkIns: {'2026-07-27': checkIn},
        workouts: [workout],
      );

      expect(report, contains('RELATÓRIO DE FEEDBACK QUINZENAL'));
      expect(report, contains('27/07/2026 a 09/08/2026'));
      expect(report, contains('Leg Day'));
      expect(report, contains('Barbell Squat: 100 kg x 8, 100 kg x 8'));
      expect(report, contains('Peso em jejum: 82,5 kg'));
      expect(report, contains('Sono: 7,5h'));
      expect(report, contains('Qualidade do sono: 80%'));
      expect(report, contains('Alegria: 4/5'));
      expect(report, contains('Furou a dieta: não'));
      expect(report, contains('Café/estimulantes: sim'));
      expect(report, contains('Treinou: sim'));
      expect(report, contains('Horário: 20h00'));
      expect(report, contains('Passos: 8500'));
      expect(report, contains('Outro esporte: jiujitsu'));
      expect(report, contains('Cardio: sim (30 min, média 145 bpm)'));
    });

    test('marca dias sem dados', () {
      final report = generateReport(
        cycleStart: start,
        cycleLength: 14,
        checkIns: {},
        workouts: [],
      );
      expect(report, contains('(sem dados)'));
      expect(report, contains('(nenhum treino registrado no período)'));
    });

    test('ignora treinos fora do período', () {
      final workout = Workout(
        dateIso: '2026-07-01',
        exercises: [WorkoutExercise(name: 'X', sets: [WorkoutSet(weight: 10, reps: 5)])],
      );
      final report = generateReport(
        cycleStart: start,
        cycleLength: 14,
        checkIns: {},
        workouts: [workout],
      );
      expect(report, contains('(nenhum treino registrado no período)'));
      expect(report, isNot(contains('2026-07-01')));
    });

    test('respeita tamanho personalizado do ciclo', () {
      final checkIn = CheckIn(date: '2026-07-27')..steps = 8500;
      final report = generateReport(
        cycleStart: start,
        cycleLength: 7,
        checkIns: {'2026-07-27': checkIn},
        workouts: [],
      );
      expect(report, contains('27/07/2026 a 02/08/2026'));
      expect(report, contains('Passos: 8500'));
    });

    test('checkbox não marcada vira "não" no relatório', () {
      final checkIn = CheckIn(date: '2026-07-28')..steps = 8500;
      final report = generateReport(
        cycleStart: start,
        cycleLength: 14,
        checkIns: {'2026-07-28': checkIn},
        workouts: [],
      );
      expect(report, contains('Furou a dieta: não'));
      expect(report, contains('Café/estimulantes: não'));
      expect(report, contains('Treinou: não'));
      expect(report, contains('Outro esporte: não'));
      expect(report, contains('Cardio: não'));
      expect(report, contains('Passos: 8500'));
    });
  });
}
