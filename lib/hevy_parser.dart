import 'models.dart';

class ParsedWorkout {
  String? dateIso;
  String? time;
  String? title;
  final List<WorkoutExercise> exercises;
  final List<String> warnings;

  ParsedWorkout({
    this.dateIso,
    this.time,
    this.title,
    required this.exercises,
    this.warnings = const [],
  });

  Workout toWorkout(DateTime fallbackDate) => Workout(
        dateIso: dateIso ?? isoOf(fallbackDate),
        time: time,
        title: title,
        exercises: exercises,
      );
}

final RegExp _dateRe =
    RegExp(r'^.*date\s*[:=]\s*(\d{4})[/-](\d{1,2})[/-](\d{1,2})', caseSensitive: false);
final RegExp _dateEnRe = RegExp(
    r'^\s*[A-Za-z]+,?\s*([A-Za-z]{3,9})\s+(\d{1,2}),?\s+(\d{4})');
final RegExp _datePtRe = RegExp(
    r'^.*?\b(\d{1,2})\s+de\s+([A-Za-zçãé]+)\s+de\s+(\d{4})');
final RegExp _titleRe =
    RegExp(r'^\s*workout\s*\d*\s*[:\-]\s*(.+)\s*$', caseSensitive: false);
final RegExp _headerRe =
    RegExp(r'^\s*(date|duration|time|tempo|data)\b', caseSensitive: false);
final RegExp _setRe = RegExp(
  r'^\s*set\s*(\d+)?\s*[:\-.]?\s*(.+?)\s*$',
  caseSensitive: false,
);
final RegExp _setBodyRe = RegExp(
  r'^([\d.,]+)\s*(kg|kgs?|lb|lbs)?\s*[x×*]\s*([\d.,]+)\s*(reps?)?$',
  caseSensitive: false,
);
final RegExp _weightOnlyRe = RegExp(
  r'^([\d.,]+)\s*(kg|kgs?|lb|lbs)$',
  caseSensitive: false,
);
final RegExp _repsOnlyRe = RegExp(
  r'^([\d.,]+)\s*(reps?)$',
  caseSensitive: false,
);

const _monthMap = {
  'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6,
  'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12,
  'janv': 1, 'fev': 2, 'abr': 4, 'mai': 5, 'ago': 8, 'set': 9,
  'out': 10, 'dez': 12,
};

String? _parseTime(String line) {
  // Regex for 12h format with am/pm (e.g. at 6:06pm, 6:06 pm, 6pm)
  final m12 = RegExp(r'(?:at|às|as|time[:\s]*)?\s*\b(\d{1,2})(?:[:.](\d{2}))?\s*(am|pm)\b', caseSensitive: false).firstMatch(line);
  if (m12 != null) {
    var h = int.parse(m12.group(1)!);
    final min = m12.group(2) != null ? int.parse(m12.group(2)!) : 0;
    final ampm = m12.group(3)!.toLowerCase();
    if (ampm == 'pm' && h < 12) h += 12;
    if (ampm == 'am' && h == 12) h = 0;
    return '${h.toString().padLeft(2, '0')}:${min.toString().padLeft(2, '0')}';
  }

  // Regex for 24h format (e.g. às 18:06, at 18:06, 18h06, 18:06)
  final m24 = RegExp(r'(?:at|às|as|time[:\s]*)?\s*(\d{1,2})[:h](\d{2})\b', caseSensitive: false).firstMatch(line);
  if (m24 != null) {
    final h = int.parse(m24.group(1)!);
    final min = int.parse(m24.group(2)!);
    if (h >= 0 && h < 24 && min >= 0 && min < 60) {
      return '${h.toString().padLeft(2, '0')}:${min.toString().padLeft(2, '0')}';
    }
  }

  return null;
}

bool _looksLikeSetLine(String? line) =>
    line != null &&
    (_setRe.hasMatch(line) ||
        _setBodyRe.hasMatch(line) ||
        _weightOnlyRe.hasMatch(line) ||
        _repsOnlyRe.hasMatch(line));

double _num(String s) => double.parse(s.replaceAll(',', '.'));

WorkoutSet? _parseSetBody(String body) {
  final m = _setBodyRe.firstMatch(body.trim());
  if (m != null) {
    return WorkoutSet(weight: _num(m.group(1)!), reps: _num(m.group(3)!).round());
  }
  final mw = _weightOnlyRe.firstMatch(body.trim());
  if (mw != null) return WorkoutSet(weight: _num(mw.group(1)!));
  final mr = _repsOnlyRe.firstMatch(body.trim());
  if (mr != null) return WorkoutSet(reps: _num(mr.group(1)!).round());
  final mn = RegExp(r'^[\d.,:]+\s*\S.*$').firstMatch(body.trim());
  if (mn != null) return WorkoutSet(note: body.trim());
  return null;
}

ParsedWorkout parseHevyText(String text) {
  final lines = text
      .split('\n')
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty)
      .toList();

  String? dateIso;
  String? time;
  String? title;
  final exercises = <WorkoutExercise>[];
  final warnings = <String>[];
  WorkoutExercise? current;

  void closeCurrent() {
    if (current == null) return;
    if (current!.sets.isEmpty) {
      if (current!.name.isNotEmpty) {
        warnings.add('Linha sem séries reconhecidas: "${current!.name}"');
      }
    } else {
      exercises.add(current!);
    }
    current = null;
  }

  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];

    if (time == null) {
      time = _parseTime(line);
    }

    final dateM = _dateRe.firstMatch(line);
    if (dateM != null) {
      final y = int.parse(dateM.group(1)!);
      final mo = int.parse(dateM.group(2)!);
      final d = int.parse(dateM.group(3)!);
      try {
        dateIso = isoOf(DateTime(y, mo, d));
      } catch (_) {}
      continue;
    }
    final dateEnM = _dateEnRe.firstMatch(line);
    if (dateEnM != null) {
      final mo = _monthMap[dateEnM.group(1)!.toLowerCase().substring(0, 3)];
      if (mo != null) {
        try {
          dateIso = isoOf(DateTime(int.parse(dateEnM.group(3)!), mo, int.parse(dateEnM.group(2)!)));
        } catch (_) {}
      }
      continue;
    }
    final datePtM = _datePtRe.firstMatch(line);
    if (datePtM != null) {
      final mo = _monthMap[datePtM.group(2)!.toLowerCase().substring(0, 3)];
      if (mo != null) {
        try {
          dateIso = isoOf(DateTime(
              int.parse(datePtM.group(3)!), mo, int.parse(datePtM.group(1)!)));
        } catch (_) {}
      }
      continue;
    }
    if (_headerRe.hasMatch(line)) continue;
    if (line.startsWith('@') || line.startsWith('http')) continue;
    if (_isNoteLine(line)) {
      if (current != null) {
        final note = line
            .replaceAll(RegExp('^["\'“”]+'), '')
            .replaceAll(RegExp('["\'“”]+\$'), '');
        current!.note = current!.note == null ? note : '${current!.note}\n$note';
      }
      continue;
    }

    final bare = _setBodyRe.firstMatch(line);
    if (bare != null) {
      current ??= WorkoutExercise(name: '');
      current!.sets.add(_setFromBody(bare));
      continue;
    }
    final weightOnly = _weightOnlyRe.firstMatch(line);
    if (weightOnly != null) {
      current ??= WorkoutExercise(name: '');
      current!.sets.add(WorkoutSet(weight: _num(weightOnly.group(1)!)));
      continue;
    }
    final repsOnly = _repsOnlyRe.firstMatch(line);
    if (repsOnly != null) {
      current ??= WorkoutExercise(name: '');
      current!.sets.add(WorkoutSet(reps: _num(repsOnly.group(1)!).round()));
      continue;
    }

    final setM = _setRe.firstMatch(line);
    if (setM != null && setM.group(2)!.isNotEmpty) {
      final body = setM.group(2)!.trim();
      final s = _parseSetBody(body);
      if (s != null) {
        current ??= WorkoutExercise(name: '');
        current!.sets.add(s);
        continue;
      }
    }

    var name = line;
    if (name.startsWith('*')) name = name.replaceFirst('*', '').trim();
    final titleM = _titleRe.firstMatch(line);
    if (title == null && exercises.isEmpty && current == null &&
        (titleM != null || !_looksLikeSetLine(_nextNonEmpty(lines, i)))) {
      title = (titleM != null ? titleM.group(1)!.trim() : name).trim();
      if (title.isEmpty) title = null;
      continue;
    }
    closeCurrent();
    if (name.isEmpty || name.startsWith('*')) continue;
    current = WorkoutExercise(name: name);
  }
  closeCurrent();

  if (exercises.isEmpty && warnings.isEmpty) {
    warnings.add('Nenhum exercício reconhecido no texto. Confira se colou o compartilhamento do Hevy.');
  }

  return ParsedWorkout(
    dateIso: dateIso,
    time: time,
    title: title,
    exercises: exercises,
    warnings: warnings,
  );
}

bool _isNoteLine(String line) {
  final l = line.trim();
  return l.startsWith('"') ||
      l.startsWith('\'') ||
      l.startsWith('“') ||
      l.endsWith('"') ||
      l.endsWith('”') ||
      l.endsWith('\'');
}

String? _nextNonEmpty(List<String> lines, int i) {
  for (var j = i + 1; j < lines.length; j++) {
    if (lines[j].trim().isNotEmpty) return lines[j].trim();
  }
  return null;
}

WorkoutSet _setFromBody(Match m) =>
    WorkoutSet(weight: _num(m.group(1)!), reps: _num(m.group(3)!).round());
