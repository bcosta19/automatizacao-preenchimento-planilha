class CheckIn {
  final String date;

  double? weight;
  double? sleepHours;
  int? sleepQualityPercent;
  int? sleepSatisfaction;
  int? joy;
  int? energy;
  int? mentalClarity;
  int? stress;
  int? muscleSoreness;
  int? immunity;
  bool? brokeDiet;
  String? brokeDietNote;
  int? hunger;
  bool? hadCaffeine;
  String? caffeineNote;
  int? digestion;
  bool? trained;
  String? workoutTime;
  int? motivation;
  int? strength;
  int? steps;
  bool? didOtherSport;
  String? otherSportDesc;
  String? sportTime;
  int? sportMinutes;
  bool? didCardio;
  int? cardioMinutes;
  int? cardioAvgBpm;
  String? daySummary;

  CheckIn({required this.date});

  static const int totalFields = 29;

  int get filledCount => [
        weight,
        sleepHours,
        sleepQualityPercent,
        sleepSatisfaction,
        joy,
        energy,
        mentalClarity,
        stress,
        muscleSoreness,
        immunity,
        brokeDiet,
        brokeDietNote,
        hunger,
        hadCaffeine,
        caffeineNote,
        digestion,
        trained,
        workoutTime,
        motivation,
        strength,
        steps,
        didOtherSport,
        otherSportDesc,
        sportTime,
        sportMinutes,
        didCardio,
        cardioMinutes,
        cardioAvgBpm,
        daySummary,
      ].where((e) => e != null).length;

  bool get isComplete => filledCount == totalFields;

  Map<String, dynamic> toJson() => {
        'date': date,
        'weight': weight,
        'sleepHours': sleepHours,
        'sleepQualityPercent': sleepQualityPercent,
        'sleepSatisfaction': sleepSatisfaction,
        'joy': joy,
        'energy': energy,
        'mentalClarity': mentalClarity,
        'stress': stress,
        'muscleSoreness': muscleSoreness,
        'immunity': immunity,
        'brokeDiet': brokeDiet,
        'brokeDietNote': brokeDietNote,
        'hunger': hunger,
        'hadCaffeine': hadCaffeine,
        'caffeineNote': caffeineNote,
        'digestion': digestion,
        'trained': trained,
        'workoutTime': workoutTime,
        'motivation': motivation,
        'strength': strength,
        'steps': steps,
        'didOtherSport': didOtherSport,
        'otherSportDesc': otherSportDesc,
        'sportTime': sportTime,
        'sportMinutes': sportMinutes,
        'didCardio': didCardio,
        'cardioMinutes': cardioMinutes,
        'cardioAvgBpm': cardioAvgBpm,
        'daySummary': daySummary,
      };

  factory CheckIn.fromJson(Map<String, dynamic> j) => CheckIn(
        date: j['date'] as String? ?? '',
      )
        ..weight = (j['weight'] as num?)?.toDouble()
        ..sleepHours = (j['sleepHours'] as num?)?.toDouble()
        ..sleepQualityPercent = j['sleepQualityPercent'] as int?
        ..sleepSatisfaction = j['sleepSatisfaction'] as int?
        ..joy = j['joy'] as int?
        ..energy = j['energy'] as int?
        ..mentalClarity = j['mentalClarity'] as int?
        ..stress = j['stress'] as int?
        ..muscleSoreness = j['muscleSoreness'] as int?
        ..immunity = j['immunity'] as int?
        ..brokeDiet = j['brokeDiet'] as bool?
        ..brokeDietNote = j['brokeDietNote'] as String?
        ..hunger = j['hunger'] as int?
        ..hadCaffeine = j['hadCaffeine'] as bool?
        ..caffeineNote = j['caffeineNote'] as String?
        ..digestion = j['digestion'] as int?
        ..trained = j['trained'] as bool?
        ..workoutTime = j['workoutTime'] as String?
        ..motivation = j['motivation'] as int?
        ..strength = j['strength'] as int?
        ..steps = j['steps'] as int?
        ..didOtherSport = j['didOtherSport'] as bool?
        ..otherSportDesc = j['otherSportDesc'] as String?
        ..sportTime = j['sportTime'] as String?
        ..sportMinutes = j['sportMinutes'] as int?
        ..didCardio = j['didCardio'] as bool?
        ..cardioMinutes = j['cardioMinutes'] as int?
        ..cardioAvgBpm = j['cardioAvgBpm'] as int?
        ..daySummary = j['daySummary'] as String?;
}

class WorkoutSet {
  double? weight;
  int? reps;
  String? note;

  WorkoutSet({this.weight, this.reps, this.note});

  Map<String, dynamic> toJson() =>
      {'weight': weight, 'reps': reps, 'note': note};

  factory WorkoutSet.fromJson(Map<String, dynamic> j) => WorkoutSet(
        weight: (j['weight'] as num?)?.toDouble(),
        reps: j['reps'] as int?,
        note: j['note'] as String?,
      );

  String display() {
    if (note != null && note!.isNotEmpty) return note!;
    final w = weight != null ? _fmtNum(weight!) : '';
    final r = reps != null ? '$reps' : '';
    if (w.isNotEmpty && r.isNotEmpty) return '$w kg x $r';
    if (w.isNotEmpty) return '$w kg';
    return '$r reps';
  }
}

String _fmtNum(double v) => v == v.roundToDouble()
    ? v.toInt().toString()
    : v.toStringAsFixed(1).replaceAll('.', ',');

class WorkoutExercise {
  String name;
  String? note;
  List<WorkoutSet> sets;

  WorkoutExercise({required this.name, this.note, List<WorkoutSet>? sets})
      : sets = sets ?? [];

  Map<String, dynamic> toJson() =>
      {'name': name, 'note': note, 'sets': sets.map((s) => s.toJson()).toList()};

  factory WorkoutExercise.fromJson(Map<String, dynamic> j) => WorkoutExercise(
        name: j['name'] as String? ?? '',
        note: j['note'] as String?,
        sets: (j['sets'] as List? ?? [])
            .map((e) => WorkoutSet.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  String setsDisplay() => sets.map((s) => s.display()).join(', ');
}

class Workout {
  String dateIso;
  String? time;
  String? title;
  List<WorkoutExercise> exercises;

  Workout({required this.dateIso, this.time, this.title, List<WorkoutExercise>? exercises})
      : exercises = exercises ?? [];

  Map<String, dynamic> toJson() => {
        'dateIso': dateIso,
        'time': time,
        'title': title,
        'exercises': exercises.map((e) => e.toJson()).toList(),
      };

  factory Workout.fromJson(Map<String, dynamic> j) => Workout(
        dateIso: j['dateIso'] as String? ?? '',
        time: j['time'] as String?,
        title: j['title'] as String?,
        exercises: (j['exercises'] as List? ?? [])
            .map((e) => WorkoutExercise.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class CardioEntry {
  final String id;
  String dateIso;
  int minutes;
  int? avgBpm;
  String? time;
  String? note;

  CardioEntry({
    required this.id,
    required this.dateIso,
    required this.minutes,
    this.avgBpm,
    this.time,
    this.note,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'dateIso': dateIso,
        'minutes': minutes,
        'avgBpm': avgBpm,
        'time': time,
        'note': note,
      };

  factory CardioEntry.fromJson(Map<String, dynamic> j) => CardioEntry(
        id: j['id'] as String? ?? DateTime.now().microsecondsSinceEpoch.toString(),
        dateIso: j['dateIso'] as String? ?? '',
        minutes: j['minutes'] as int? ?? 0,
        avgBpm: j['avgBpm'] as int?,
        time: j['time'] as String?,
        note: j['note'] as String?,
      );
}

class Settings {
  bool notificationsEnabled;
  int endOfDayHour;
  int endOfDayMinute;
  int sportHour;
  int sportMinute;
  List<int> sportDays;
  String defaultSport;
  String cycleMode;
  int customCycleLength;
  int weeklyCardioMinutes;

  Settings({
    this.notificationsEnabled = true,
    this.endOfDayHour = 21,
    this.endOfDayMinute = 0,
    this.sportHour = 19,
    this.sportMinute = 0,
    this.sportDays = const [DateTime.monday, DateTime.wednesday, DateTime.friday],
    this.defaultSport = 'jiujitsu',
    this.cycleMode = 'quinzenal',
    this.customCycleLength = 10,
    this.weeklyCardioMinutes = 150,
  });

  static const cycleSemanal = 'semanal';
  static const cycleQuinzenal = 'quinzenal';
  static const cyclePersonalizado = 'personalizado';

  int get cycleLength => switch (cycleMode) {
        cycleSemanal => 7,
        cyclePersonalizado => customCycleLength.clamp(2, 60),
        _ => 14,
      };

  int get cycleCardioMinutesGoal {
    if (cycleMode == cycleSemanal) return weeklyCardioMinutes;
    if (cycleMode == cycleQuinzenal) return weeklyCardioMinutes * 2;
    return (weeklyCardioMinutes * (cycleLength / 7)).round();
  }

  Map<String, dynamic> toJson() => {
        'notificationsEnabled': notificationsEnabled,
        'endOfDayHour': endOfDayHour,
        'endOfDayMinute': endOfDayMinute,
        'sportHour': sportHour,
        'sportMinute': sportMinute,
        'sportDays': sportDays,
        'defaultSport': defaultSport,
        'cycleMode': cycleMode,
        'customCycleLength': customCycleLength,
        'weeklyCardioMinutes': weeklyCardioMinutes,
      };

  factory Settings.fromJson(Map<String, dynamic> j) => Settings(
        notificationsEnabled: j['notificationsEnabled'] as bool? ?? true,
        endOfDayHour: j['endOfDayHour'] as int? ?? 21,
        endOfDayMinute: j['endOfDayMinute'] as int? ?? 0,
        sportHour: j['sportHour'] as int? ?? 19,
        sportMinute: j['sportMinute'] as int? ?? 0,
        sportDays: (j['sportDays'] as List? ?? [1, 3, 5]).map((e) => e as int).toList(),
        defaultSport: j['defaultSport'] as String? ?? 'jiujitsu',
        cycleMode: j['cycleMode'] as String? ?? 'quinzenal',
        customCycleLength: j['customCycleLength'] as int? ?? 10,
        weeklyCardioMinutes: j['weeklyCardioMinutes'] as int? ?? 150,
      );
}

const weekdayShort = ['seg', 'ter', 'qua', 'qui', 'sex', 'sáb', 'dom'];
const weekdayFull = [
  'Segunda',
  'Terça',
  'Quarta',
  'Quinta',
  'Sexta',
  'Sábado',
  'Domingo',
];

String isoOf(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

DateTime dateFromIso(String iso) {
  final parts = iso.split('-').map(int.parse).toList();
  return DateTime(parts[0], parts[1], parts[2]);
}

String dmy(DateTime d) => '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
