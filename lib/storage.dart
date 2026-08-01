import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

class AppState extends ChangeNotifier {
  static const _prefsKey = 'checkin_quinzenal_data_v1';

  String _cycleStartIso = '';
  final Map<String, CheckIn> _checkIns = {};
  final List<Workout> _workouts = [];
  Settings _settings = Settings();

  String get cycleStartIso => _cycleStartIso;
  Settings get settings => _settings;
  Map<String, CheckIn> get checkIns => _checkIns;
  List<Workout> get workouts => List.unmodifiable(_workouts);

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
        _settings = Settings.fromJson(
            data['settings'] as Map<String, dynamic>? ?? {});
      } catch (_) {}
    }
    _ensureCycle();
    notifyListeners();
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
    }
  }

  List<DateTime> cycleDays() {
    final start = cycleStart;
    return List.generate(_settings.cycleLength, (i) => start.add(Duration(days: i)));
  }

  List<DateTime> cyclesAvailable() {
    final currentStart = cycleStart;
    final length = _settings.cycleLength;
    final all = [..._checkIns.keys.map(dateFromIso), ..._workouts.map((w) => dateFromIso(w.dateIso))];
    if (all.isEmpty) return [currentStart];
    final earliest = all.reduce((a, b) => a.isBefore(b) ? a : b);
    final diff = currentStart.difference(earliest).inDays;
    final blocks = (diff + length - 1) ~/ length;
    return [
      currentStart,
      for (var b = 1; b <= blocks; b++)
        currentStart.subtract(Duration(days: length * b)),
    ];
  }

  void setCycleStart(DateTime d) {
    _cycleStartIso = isoOf(DateTime(d.year, d.month, d.day));
    save();
  }

  CheckIn? checkInFor(DateTime d) => _checkIns[isoOf(d)];

  CheckIn ensureCheckIn(DateTime d) =>
      _checkIns.putIfAbsent(isoOf(d), () => CheckIn(date: isoOf(d)));

  void setCheckIn(CheckIn c) {
    _checkIns[c.date] = c;
    save();
  }

  List<Workout> workoutsForRange(DateTime start, DateTime end) => _workouts
      .where((w) {
        final d = dateFromIso(w.dateIso);
        return !d.isBefore(start) && !d.isAfter(end);
      })
      .toList()
    ..sort((a, b) => a.dateIso.compareTo(b.dateIso));

  List<Workout> workoutsForDate(DateTime d) {
    final iso = isoOf(d);
    return _workouts.where((w) => w.dateIso == iso).toList();
  }

  void addWorkout(Workout w) {
    _workouts.add(w);
    save();
  }

  void updateWorkout(Workout w) {
    final i = _workouts.indexWhere((x) => identical(x, w));
    if (i >= 0) {
      _workouts[i] = w;
      save();
    }
  }

  void removeWorkout(Workout w) {
    _workouts.remove(w);
    save();
  }

  void updateSettings(Settings s) {
    _settings = s;
    save();
  }

  Future<void> save() async {
    _ensureCycle();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode({
      'cycleStart': _cycleStartIso,
      'checkIns': _checkIns.map((k, v) => MapEntry(k, v.toJson())),
      'workouts': _workouts.map((w) => w.toJson()).toList(),
      'settings': _settings.toJson(),
    }));
    notifyListeners();
  }
}
