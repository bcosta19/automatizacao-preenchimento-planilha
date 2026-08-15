import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

class AppState extends ChangeNotifier {
  static const _prefsKey = 'checkin_quinzenal_data_v1';

  String _cycleStartIso = '';
  final Map<String, CheckIn> _checkIns = {};
  final List<Workout> _workouts = [];
  final List<CardioEntry> _cardios = [];
  final Map<String, List<Workout>> _workoutsByDate = {};
  final Map<String, List<CardioEntry>> _cardiosByDate = {};
  List<DateTime>? _cachedCycles;
  Settings _settings = Settings();

  String get cycleStartIso => _cycleStartIso;
  Settings get settings => _settings;
  Map<String, CheckIn> get checkIns => _checkIns;
  List<Workout> get workouts => List.unmodifiable(_workouts);
  List<CardioEntry> get cardios => List.unmodifiable(_cardios);

  DateTime get cycleStart =>
      _cycleStartIso.isEmpty ? DateTime.now() : dateFromIso(_cycleStartIso);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw != null) {
      try {
        final data = jsonDecode(raw) as Map<String, dynamic>;
        _cycleStartIso = data['cycleStart'] as String? ?? '';
        _checkIns.clear();
        (data['checkIns'] as Map<String, dynamic>? ?? {}).forEach((k, v) {
          _checkIns[k] = CheckIn.fromJson(v as Map<String, dynamic>);
        });
        _workouts
          ..clear()
          ..addAll((data['workouts'] as List? ?? [])
              .map((e) => Workout.fromJson(e as Map<String, dynamic>)));
        _cardios
          ..clear()
          ..addAll((data['cardios'] as List? ?? [])
              .map((e) => CardioEntry.fromJson(e as Map<String, dynamic>)));
        _settings = Settings.fromJson(
            data['settings'] as Map<String, dynamic>? ?? {});
      } catch (_) {}
    }
    _reindex();
    _ensureCycle();
    notifyListeners();
  }

  void _reindex() {
    _workoutsByDate.clear();
    for (final w in _workouts) {
      (_workoutsByDate[w.dateIso] ??= []).add(w);
    }
    _cardiosByDate.clear();
    for (final c in _cardios) {
      (_cardiosByDate[c.dateIso] ??= []).add(c);
    }
    for (final list in _cardiosByDate.values) {
      list.sort((a, b) => (a.time ?? '').compareTo(b.time ?? ''));
    }
    _cachedCycles = null;
  }

  void _ensureCycle() {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final length = _settings.cycleLength;
    if (_cycleStartIso.isEmpty) {
      _cycleStartIso = isoOf(todayDate);
      return;
    }
    var start = dateFromIso(_cycleStartIso);
    final diff = todayDate.difference(start).inDays;
    if (diff >= length) {
      final blocks = diff ~/ length;
      start = start.add(Duration(days: length * blocks));
      _cycleStartIso = isoOf(start);
      _cachedCycles = null;
    }
  }

  List<DateTime> cycleDays() {
    final start = cycleStart;
    return List.generate(_settings.cycleLength, (i) => start.add(Duration(days: i)));
  }

  List<DateTime> cyclesAvailable() {
    if (_cachedCycles != null) return _cachedCycles!;
    final currentStart = cycleStart;
    final length = _settings.cycleLength;
    final all = [
      ..._checkIns.keys.map(dateFromIso),
      ..._workouts.map((w) => dateFromIso(w.dateIso)),
      ..._cardios.map((c) => dateFromIso(c.dateIso)),
    ];
    if (all.isEmpty) {
      return _cachedCycles = [currentStart];
    }
    final earliest = all.reduce((a, b) => a.isBefore(b) ? a : b);
    final diff = currentStart.difference(earliest).inDays;
    final blocks = (diff + length - 1) ~/ length;
    return _cachedCycles = [
      currentStart,
      for (var b = 1; b <= blocks; b++)
        currentStart.subtract(Duration(days: length * b)),
    ];
  }

  void setCycleStart(DateTime d) {
    _cycleStartIso = isoOf(DateTime(d.year, d.month, d.day));
    _cachedCycles = null;
    save();
  }

  CheckIn? checkInFor(DateTime d) => _checkIns[isoOf(d)];

  CheckIn ensureCheckIn(DateTime d) =>
      _checkIns.putIfAbsent(isoOf(d), () => CheckIn(date: isoOf(d)));

  void setCheckIn(CheckIn c) {
    _checkIns[c.date] = c;
    _cachedCycles = null;
    save();
  }

  List<Workout> workoutsForRange(DateTime start, DateTime end) {
    final startIso = isoOf(start);
    final endIso = isoOf(end);
    return _workouts
        .where((w) => w.dateIso.compareTo(startIso) >= 0 && w.dateIso.compareTo(endIso) <= 0)
        .toList()
      ..sort((a, b) => a.dateIso.compareTo(b.dateIso));
  }

  List<Workout> workoutsForDate(DateTime d) =>
      _workoutsByDate[isoOf(d)] ?? const [];

  void addWorkout(Workout w) {
    _workouts.add(w);
    _syncCheckInWorkout(w);
    _reindex();
    save();
  }

  void updateWorkout(Workout w) {
    final i = _workouts.indexWhere((x) => identical(x, w));
    if (i >= 0) {
      _workouts[i] = w;
      _syncCheckInWorkout(w);
      _reindex();
      save();
    }
  }

  void removeWorkout(Workout w) {
    _workouts.remove(w);
    _reindex();
    final remaining = _workoutsByDate[w.dateIso];
    final c = checkInFor(dateFromIso(w.dateIso));
    if (c != null) {
      if (remaining == null || remaining.isEmpty) {
        c.trained = false;
        c.workoutTime = null;
      } else {
        c.trained = true;
        c.workoutTime = remaining.first.time ?? c.workoutTime;
      }
    }
    save();
  }

  void _syncCheckInWorkout(Workout w) {
    final d = dateFromIso(w.dateIso);
    final c = ensureCheckIn(d);
    c.trained = true;
    if (w.time != null && w.time!.isNotEmpty) {
      c.workoutTime = w.time;
    }
  }

  // --- Cardio Management ---

  List<CardioEntry> cardiosForDate(DateTime d) =>
      _cardiosByDate[isoOf(d)] ?? const [];

  List<CardioEntry> cardiosForRange(DateTime start, DateTime end) {
    final startIso = isoOf(start);
    final endIso = isoOf(end);
    return _cardios
        .where((c) => c.dateIso.compareTo(startIso) >= 0 && c.dateIso.compareTo(endIso) <= 0)
        .toList()
      ..sort((a, b) => a.dateIso.compareTo(b.dateIso));
  }

  void addCardio(CardioEntry c) {
    _cardios.add(c);
    _reindex();
    _syncCheckInCardio(c.dateIso);
    save();
  }

  void updateCardio(CardioEntry c) {
    final i = _cardios.indexWhere((x) => x.id == c.id);
    if (i >= 0) {
      _cardios[i] = c;
      _reindex();
      _syncCheckInCardio(c.dateIso);
      save();
    }
  }

  void removeCardio(CardioEntry c) {
    _cardios.removeWhere((x) => x.id == c.id);
    _reindex();
    _syncCheckInCardio(c.dateIso);
    save();
  }

  int totalCardioMinutesForDate(DateTime d) {
    final list = _cardiosByDate[isoOf(d)];
    if (list != null && list.isNotEmpty) {
      var sum = 0;
      for (final item in list) {
        sum += item.minutes;
      }
      return sum;
    }
    return checkInFor(d)?.cardioMinutes ?? 0;
  }

  int? avgBpmForDate(DateTime d) {
    final list = _cardiosByDate[isoOf(d)];
    if (list != null && list.isNotEmpty) {
      var totalBpmMin = 0;
      var totalMin = 0;
      for (final item in list) {
        if (item.avgBpm != null && item.avgBpm! > 0) {
          totalBpmMin += item.avgBpm! * item.minutes;
          totalMin += item.minutes;
        }
      }
      return totalMin > 0 ? (totalBpmMin / totalMin).round() : null;
    }
    return checkInFor(d)?.cardioAvgBpm;
  }

  int totalCardioMinutesForRange(DateTime start, DateTime end) {
    final startIso = isoOf(start);
    final endIso = isoOf(end);
    var sum = 0;
    var hasEntries = false;
    for (final c in _cardios) {
      if (c.dateIso.compareTo(startIso) >= 0 && c.dateIso.compareTo(endIso) <= 0) {
        sum += c.minutes;
        hasEntries = true;
      }
    }
    if (hasEntries) return sum;

    // Fallback to checkins in range if no cardio entries
    var cur = DateTime(start.year, start.month, start.day);
    final last = DateTime(end.year, end.month, end.day);
    while (!cur.isAfter(last)) {
      final c = checkInFor(cur);
      if (c?.didCardio == true && c?.cardioMinutes != null) {
        sum += c!.cardioMinutes!;
      }
      cur = cur.add(const Duration(days: 1));
    }
    return sum;
  }

  int? avgBpmForRange(DateTime start, DateTime end) {
    final startIso = isoOf(start);
    final endIso = isoOf(end);
    var totalBpmMin = 0;
    var totalMin = 0;
    for (final c in _cardios) {
      if (c.dateIso.compareTo(startIso) >= 0 && c.dateIso.compareTo(endIso) <= 0) {
        if (c.avgBpm != null && c.avgBpm! > 0) {
          totalBpmMin += c.avgBpm! * c.minutes;
          totalMin += c.minutes;
        }
      }
    }
    if (totalMin > 0) {
      return (totalBpmMin / totalMin).round();
    }

    var cur = DateTime(start.year, start.month, start.day);
    final last = DateTime(end.year, end.month, end.day);
    while (!cur.isAfter(last)) {
      final c = checkInFor(cur);
      if (c?.didCardio == true && c?.cardioMinutes != null && c?.cardioAvgBpm != null) {
        totalBpmMin += c!.cardioAvgBpm! * c.cardioMinutes!;
        totalMin += c.cardioMinutes!;
      }
      cur = cur.add(const Duration(days: 1));
    }
    return totalMin > 0 ? (totalBpmMin / totalMin).round() : null;
  }

  int totalCardioMinutesForWeek(DateTime cycleStart, int weekIndex) {
    final start = cycleStart.add(Duration(days: weekIndex * 7));
    final end = start.add(const Duration(days: 6));
    return totalCardioMinutesForRange(start, end);
  }

  void _syncCheckInCardio(String dateIso) {
    final list = _cardiosByDate[dateIso];
    final d = dateFromIso(dateIso);
    final c = ensureCheckIn(d);
    if (list == null || list.isEmpty) {
      c.didCardio = false;
      c.cardioMinutes = null;
      c.cardioAvgBpm = null;
    } else {
      c.didCardio = true;
      var totalMin = 0;
      var totalBpmMin = 0;
      var totalBpmsMin = 0;
      for (final item in list) {
        totalMin += item.minutes;
        if (item.avgBpm != null && item.avgBpm! > 0) {
          totalBpmMin += item.avgBpm! * item.minutes;
          totalBpmsMin += item.minutes;
        }
      }
      c.cardioMinutes = totalMin;
      c.cardioAvgBpm = totalBpmsMin > 0 ? (totalBpmMin / totalBpmsMin).round() : null;
    }
  }

  void updateSettings(Settings s) {
    _settings = s;
    _cachedCycles = null;
    save();
  }

  Future<void> save() async {
    _ensureCycle();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode({
      'cycleStart': _cycleStartIso,
      'checkIns': _checkIns.map((k, v) => MapEntry(k, v.toJson())),
      'workouts': _workouts.map((w) => w.toJson()).toList(),
      'cardios': _cardios.map((c) => c.toJson()).toList(),
      'settings': _settings.toJson(),
    }));
    notifyListeners();
  }
}
