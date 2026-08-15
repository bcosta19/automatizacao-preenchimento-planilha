import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../main.dart';
import '../models.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final String? subtitle;

  const SectionHeader({super.key, required this.title, required this.icon, this.subtitle});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: scheme.primary),
          const SizedBox(width: 8),
          Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          if (subtitle != null) ...[
            const SizedBox(width: 8),
            Expanded(
              child: Text(subtitle!, style: Theme.of(context).textTheme.bodySmall, overflow: TextOverflow.ellipsis),
            ),
          ],
        ],
      ),
    );
  }
}

class ScaleSelector extends StatelessWidget {
  final int? value;
  final ValueChanged<int?> onChanged;
  final String Function(int)? label;

  const ScaleSelector({super.key, required this.value, required this.onChanged, this.label});

  static const _min = 1;
  static const _max = 5;

  static const List<Color> _chipColors = [
    Color(0xFFD32F2F),
    Color(0xFFEF6C00),
    Color(0xFFF9A825),
    Color(0xFF7CB342),
    Color(0xFF2E7D32),
  ];

  Color _colorFor(int v) => _chipColors[(v - 1).clamp(0, 4)];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 8,
      children: [
        for (var v = _min; v <= _max; v++)
          ChoiceChip(
            selected: value == v,
            showCheckmark: false,
            label: Text(label != null ? '${label!(v)}\n$v' : '$v',
                textAlign: TextAlign.center),
            selectedColor: _colorFor(v),
            backgroundColor: scheme.surfaceContainerHighest,
            labelStyle: TextStyle(
              color: value == v ? Colors.white : scheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
            onSelected: (_) => onChanged(value == v ? null : v),
          ),
      ],
    );
  }
}

class YesNoSwitch extends StatelessWidget {
  final bool? value;
  final ValueChanged<bool?> onChanged;
  final String label;

  const YesNoSwitch({super.key, required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      value: value ?? false,
      onChanged: (v) => onChanged(v ? true : (value == true ? null : false)),
    );
  }
}

class NumberField extends StatelessWidget {
  final String label;
  final String? suffix;
  final String? hint;
  final TextEditingController controller;
  final void Function(String) onChanged;
  final bool allowDecimal;

  static final _intFormatter = _IntFormatter();
  static final _decimalFormatter = _DecimalFormatter();

  const NumberField({
    super.key,
    required this.label,
    required this.controller,
    required this.onChanged,
    this.suffix,
    this.hint,
    this.allowDecimal = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType:
          TextInputType.numberWithOptions(decimal: allowDecimal, signed: false),
      inputFormatters: [
        if (allowDecimal)
          _decimalFormatter
        else
          _intFormatter,
      ],
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix,
        hintText: hint,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      onChanged: onChanged,
    );
  }
}

class _IntFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) return newValue;
    final cleaned = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    if (cleaned != newValue.text) {
      return TextEditingValue(
        text: cleaned,
        selection: TextSelection.collapsed(offset: cleaned.length),
      );
    }
    return newValue;
  }
}

class _DecimalFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) return newValue;
    var t = newValue.text.replaceAll(RegExp(r'[^\d.,]'), '');
    t = t.replaceAll(',', '.');
    if (RegExp(r'\.').allMatches(t).length > 1) return oldValue;
    if (t != newValue.text) {
      return TextEditingValue(
        text: t,
        selection: TextSelection.collapsed(offset: t.length),
      );
    }
    return newValue;
  }
}

Future<void> showCardioModal(
  BuildContext context, {
  CardioEntry? existing,
  DateTime? initialDate,
}) async {
  final state = AppScope.read(context);
  final isEdit = existing != null;
  DateTime date = isEdit
      ? dateFromIso(existing.dateIso)
      : (initialDate ?? DateTime.now());
  var minutes = isEdit ? existing.minutes : 30;
  int? avgBpm = isEdit ? existing.avgBpm : null;
  String? time = isEdit ? existing.time : null;
  String? note = isEdit ? existing.note : null;

  final minCtrl = TextEditingController(text: minutes > 0 ? '$minutes' : '');
  final bpmCtrl = TextEditingController(text: avgBpm != null ? '$avgBpm' : '');
  final noteCtrl = TextEditingController(text: note ?? '');

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setStateModal) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.directions_run,
                          color: Theme.of(ctx).colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        isEdit ? 'Editar Cardio' : 'Adicionar Cardio',
                        style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const Spacer(),
                      if (isEdit)
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          tooltip: 'Excluir cardio',
                          onPressed: () {
                            state.removeCardio(existing);
                            Navigator.of(ctx).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Cardio removido.'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.calendar_today),
                    title: const Text('Data do cardio'),
                    subtitle: Text('${weekdayFull[date.weekday - 1]}, ${dmy(date)}'),
                    trailing: const Icon(Icons.edit_outlined),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: date,
                        firstDate: DateTime.now().subtract(const Duration(days: 365)),
                        lastDate: DateTime.now().add(const Duration(days: 7)),
                      );
                      if (picked != null) {
                        setStateModal(() => date = DateTime(picked.year, picked.month, picked.day));
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  Text('Duração (minutos)',
                      style: Theme.of(ctx).textTheme.labelLarge),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [15, 20, 30, 40, 45, 60].map((m) {
                      final sel = minutes == m;
                      return ChoiceChip(
                        label: Text('${m}m'),
                        selected: sel,
                        onSelected: (_) {
                          setStateModal(() {
                            minutes = m;
                            minCtrl.text = '$m';
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: minCtrl,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          decoration: const InputDecoration(
                            labelText: 'Minutos',
                            suffixText: 'min',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          onChanged: (v) {
                            final n = int.tryParse(v.trim());
                            if (n != null) minutes = n;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: bpmCtrl,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          decoration: const InputDecoration(
                            labelText: 'BPM médio (opcional)',
                            suffixText: 'bpm',
                            hintText: 'ex.: 140',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          onChanged: (v) {
                            final n = int.tryParse(v.trim());
                            avgBpm = n;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.schedule),
                          title: const Text('Horário (opcional)'),
                          subtitle: Text(time ?? 'Não definido'),
                          trailing: const Icon(Icons.edit_outlined),
                          onTap: () async {
                            final picked = await showTimePicker(
                              context: ctx,
                              initialTime: TimeOfDay.now(),
                            );
                            if (picked != null) {
                              setStateModal(() => time = picked.format(ctx));
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: noteCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Tipo / Observação (opcional)',
                      hintText: 'ex.: Esteira inclinada, Bike, Caminhada rápida...',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (v) => note = v.trim().isEmpty ? null : v.trim(),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton.icon(
                      icon: const Icon(Icons.check),
                      label: Text(isEdit ? 'Salvar alterações' : 'Registrar cardio'),
                      onPressed: () {
                        final finalMin = int.tryParse(minCtrl.text.trim()) ?? minutes;
                        if (finalMin <= 0) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(content: Text('Informe a duração do cardio.')),
                          );
                          return;
                        }
                        final finalBpm = int.tryParse(bpmCtrl.text.trim());
                        final finalNote = noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim();

                        if (isEdit) {
                          existing.dateIso = isoOf(date);
                          existing.minutes = finalMin;
                          existing.avgBpm = finalBpm;
                          existing.time = time;
                          existing.note = finalNote;
                          state.updateCardio(existing);
                        } else {
                          final newEntry = CardioEntry(
                            id: DateTime.now().microsecondsSinceEpoch.toString(),
                            dateIso: isoOf(date),
                            minutes: finalMin,
                            avgBpm: finalBpm,
                            time: time,
                            note: finalNote,
                          );
                          state.addCardio(newEntry);
                        }
                        Navigator.of(ctx).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isEdit
                                  ? 'Cardio atualizado!'
                                  : 'Cardio de ${finalMin} min registrado!',
                            ),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

Future<void> showDaySummaryModal(
  BuildContext context, {
  DateTime? date,
}) async {
  final state = AppScope.read(context);
  DateTime selectedDate = date ?? DateTime.now();
  final currentSummary = state.checkInFor(selectedDate)?.daySummary ?? '';
  final summaryCtrl = TextEditingController(text: currentSummary);

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setStateModal) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.comment_outlined,
                          color: Theme.of(ctx).colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Resumo do Dia',
                        style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.calendar_today),
                    title: const Text('Data'),
                    subtitle: Text('${weekdayFull[selectedDate.weekday - 1]}, ${dmy(selectedDate)}'),
                    trailing: const Icon(Icons.edit_outlined),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: selectedDate,
                        firstDate: DateTime.now().subtract(const Duration(days: 365)),
                        lastDate: DateTime.now().add(const Duration(days: 7)),
                      );
                      if (picked != null) {
                        setStateModal(() {
                          selectedDate = DateTime(picked.year, picked.month, picked.day);
                          summaryCtrl.text = state.checkInFor(selectedDate)?.daySummary ?? '';
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Escreva como foi o dia, pontos de atenção no treino, rotina ou dieta. Esses comentários serão agrupados no resumo semanal da planilha.',
                    style: Theme.of(ctx).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: summaryCtrl,
                    maxLines: 5,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: 'Comentários do dia',
                      hintText: 'ex.: Treino rendeu muito, dor no ombro diminuiu. Dieta 100%, água 3.5L...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton.icon(
                      icon: const Icon(Icons.check),
                      label: const Text('Salvar resumo'),
                      onPressed: () {
                        final text = summaryCtrl.text.trim();
                        final c = state.ensureCheckIn(selectedDate);
                        c.daySummary = text.isEmpty ? null : text;
                        state.setCheckIn(c);
                        Navigator.of(ctx).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Resumo do dia salvo!'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

Future<void> showSleepModal(
  BuildContext context, {
  DateTime? date,
}) async {
  final state = AppScope.read(context);
  DateTime selectedDate = date ?? DateTime.now();
  final current = state.checkInFor(selectedDate);

  double? hours = current?.sleepHours?.toDouble();
  int? quality = current?.sleepQualityPercent;
  int? satisfaction = current?.sleepSatisfaction;

  final hoursCtrl = TextEditingController(
    text: hours != null
        ? (hours == hours!.roundToDouble()
            ? hours!.toInt().toString()
            : hours!.toStringAsFixed(1).replaceAll('.', ','))
        : '',
  );
  final qualityCtrl = TextEditingController(
    text: quality?.toString() ?? '',
  );

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setStateModal) {
          void updateFieldsForDate(DateTime newDate) {
            selectedDate = newDate;
            final c = state.checkInFor(selectedDate);
            hours = c?.sleepHours?.toDouble();
            quality = c?.sleepQualityPercent;
            satisfaction = c?.sleepSatisfaction;
            hoursCtrl.text = hours != null
                ? (hours == hours!.roundToDouble()
                    ? hours!.toInt().toString()
                    : hours!.toStringAsFixed(1).replaceAll('.', ','))
                : '';
            qualityCtrl.text = quality?.toString() ?? '';
          }

          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.bedtime_outlined, color: Theme.of(ctx).colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Registro de Sono',
                        style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.calendar_today),
                    title: const Text('Data'),
                    subtitle: Text('${weekdayFull[selectedDate.weekday - 1]}, ${dmy(selectedDate)}'),
                    trailing: const Icon(Icons.edit_outlined),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: selectedDate,
                        firstDate: DateTime.now().subtract(const Duration(days: 365)),
                        lastDate: DateTime.now().add(const Duration(days: 7)),
                      );
                      if (picked != null) {
                        setStateModal(() {
                          updateFieldsForDate(DateTime(picked.year, picked.month, picked.day));
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  Text('Horas de sono:', style: Theme.of(ctx).textTheme.bodyMedium),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    children: [6.0, 6.5, 7.0, 7.5, 8.0, 8.5, 9.0].map((h) {
                      final label = h == h.roundToDouble() ? '${h.toInt()}h' : '${h.toStringAsFixed(1).replaceAll('.', ',')}h';
                      final isSelected = hours == h;
                      return ChoiceChip(
                        label: Text(label),
                        selected: isSelected,
                        onSelected: (sel) {
                          setStateModal(() {
                            hours = sel ? h : null;
                            hoursCtrl.text = hours != null
                                ? (hours == hours!.roundToDouble()
                                    ? hours!.toInt().toString()
                                    : hours!.toStringAsFixed(1).replaceAll('.', ','))
                                : '';
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  NumberField(
                    label: 'Horas de sono (personalizado)',
                    suffix: 'h',
                    hint: 'ex.: 7,5',
                    controller: hoursCtrl,
                    allowDecimal: true,
                    onChanged: (v) {
                      final parsed = double.tryParse(v.trim().replaceAll(',', '.'));
                      setStateModal(() => hours = parsed);
                    },
                  ),
                  const SizedBox(height: 12),
                  NumberField(
                    label: 'Qualidade do sono (0 a 100%)',
                    suffix: '%',
                    hint: 'ex.: 85',
                    controller: qualityCtrl,
                    onChanged: (v) {
                      final parsed = int.tryParse(v.trim());
                      setStateModal(() => quality = parsed?.clamp(0, 100));
                    },
                  ),
                  const SizedBox(height: 14),
                  Text('Satisfação com o sono (1 a 5):', style: Theme.of(ctx).textTheme.bodyMedium),
                  const SizedBox(height: 6),
                  ScaleSelector(
                    value: satisfaction,
                    onChanged: (v) => setStateModal(() => satisfaction = v),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton.icon(
                      icon: const Icon(Icons.check),
                      label: const Text('Salvar sono'),
                      onPressed: () {
                        final c = state.ensureCheckIn(selectedDate);
                        c.sleepHours = hours;
                        c.sleepQualityPercent = quality;
                        c.sleepSatisfaction = satisfaction;
                        state.setCheckIn(c);
                        Navigator.of(ctx).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Dados de sono salvos!'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
