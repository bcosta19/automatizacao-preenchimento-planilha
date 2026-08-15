import 'package:flutter/material.dart';

import '../main.dart';
import '../models.dart';
import '../hevy_parser.dart';

class WorkoutScreen extends StatelessWidget {
  const WorkoutScreen({super.key});

  Future<void> _importHevy(BuildContext context) async {
    final textController = TextEditingController();
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Importar do Hevy',
                style: Theme.of(ctx).textTheme.titleMedium),
            const SizedBox(height: 8),
            const Text(
              'No Hevy, abra o treino, toque em compartilhar e copie o texto. Cole aqui:',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: textController,
              maxLines: 10,
              decoration: const InputDecoration(
                hintText: 'Colar texto do treino aqui...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(textController.text),
              child: const Text('Processar'),
            ),
          ],
        ),
      ),
    );
    if (result == null || result.trim().isEmpty || !context.mounted) return;

    final parsed = parseHevyText(result);
    if (!context.mounted) return;
    if (parsed.exercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(parsed.warnings.first)),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WorkoutEditorScreen(workout: parsed.toWorkout(DateTime.now())),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final workouts = [...state.workouts]
      ..sort((a, b) => b.dateIso.compareTo(a.dateIso));

    return Scaffold(
      appBar: AppBar(title: const Text('Treinos')),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Treino'),
        onPressed: () => showModalBottomSheet<void>(
          context: context,
          builder: (ctx) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.paste),
                  title: const Text('Importar do Hevy'),
                  subtitle: const Text('Colar texto compartilhado do treino'),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _importHevy(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.edit_note),
                  title: const Text('Adicionar manualmente'),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            WorkoutEditorScreen(workout: Workout(dateIso: isoOf(DateTime.now()))),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      body: workouts.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.fitness_center,
                      size: 64, color: Theme.of(context).colorScheme.outline),
                  const SizedBox(height: 12),
                  const Text('Nenhum treino registrado'),
                  const SizedBox(height: 4),
                  Text('Importe o texto do Hevy ou adicione manualmente.',
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.only(bottom: 88),
              itemCount: workouts.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, i) => _WorkoutTile(workout: workouts[i]),
            ),
    );
  }
}

class _WorkoutTile extends StatelessWidget {
  final Workout workout;

  const _WorkoutTile({required this.workout});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final d = dateFromIso(workout.dateIso);
    return ExpansionTile(
      leading: CircleAvatar(
        child: Text(weekdayShort[d.weekday - 1].substring(0, 2).toUpperCase(),
            style: const TextStyle(fontSize: 11)),
      ),
      title: Text(workout.title?.isNotEmpty == true ? workout.title! : 'Treino'),
      subtitle: Text('${dmy(d)} • ${workout.exercises.length} exercícios'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => WorkoutEditorScreen(workout: workout),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 20),
            onPressed: () => showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Excluir treino?'),
                content: Text('${workout.title ?? 'Treino'} de ${dmy(d)} será removido.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: const Text('Cancelar'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.of(ctx).pop(true),
                    child: const Text('Excluir'),
                  ),
                ],
              ),
            ).then((ok) {
              if (ok == true) state.removeWorkout(workout);
            }),
          ),
        ],
      ),
      children: [
        for (final e in workout.exercises)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: Text(e.name, style: const TextStyle(fontWeight: FontWeight.w500))),
                Expanded(
                  flex: 2,
                  child: Text(e.setsDisplay(), textAlign: TextAlign.right),
                ),
              ],
            ),
          ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class WorkoutEditorScreen extends StatefulWidget {
  final Workout workout;

  const WorkoutEditorScreen({super.key, required this.workout});

  @override
  State<WorkoutEditorScreen> createState() => _WorkoutEditorScreenState();
}

class _WorkoutEditorScreenState extends State<WorkoutEditorScreen> {
  late Workout _workout;
  late final TextEditingController _titleCtrl;
  late DateTime _date;

  @override
  void initState() {
    super.initState();
    _workout = widget.workout;
    _titleCtrl = TextEditingController(text: _workout.title ?? '');
    _date = dateFromIso(_workout.dateIso);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Treino'),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.save_outlined),
            label: const Text('Salvar'),
            onPressed: _save,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _titleCtrl,
            decoration: const InputDecoration(labelText: 'Nome do treino'),
            onChanged: (v) => _workout.title = v.isEmpty ? null : v,
          ),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.calendar_today),
            title: const Text('Data do treino'),
            subtitle: Text('${weekdayFull[_date.weekday - 1]}, ${dmy(_date)}'),
            trailing: const Icon(Icons.edit_outlined),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _date,
                firstDate: DateTime.now().subtract(const Duration(days: 60)),
                lastDate: DateTime.now().add(const Duration(days: 2)),
              );
              if (picked != null) {
                setState(() {
                  _date = DateTime(picked.year, picked.month, picked.day);
                  _workout.dateIso = isoOf(_date);
                });
              }
            },
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.access_time),
            title: const Text('Horário do treino'),
            subtitle: Text(_workout.time ?? 'Não informado'),
            trailing: const Icon(Icons.edit_outlined),
            onTap: () async {
              final initial = _workout.time != null
                  ? TimeOfDay(
                      hour: int.tryParse(_workout.time!.split(':')[0]) ?? 18,
                      minute: int.tryParse(_workout.time!.split(':')[1]) ?? 0,
                    )
                  : const TimeOfDay(hour: 18, minute: 0);
              final picked = await showTimePicker(
                context: context,
                initialTime: initial,
              );
              if (picked != null) {
                setState(() {
                  _workout.time =
                      '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                });
              }
            },
          ),
          const Divider(height: 24),
          for (var i = 0; i < _workout.exercises.length; i++)
            _ExerciseCard(
              key: ObjectKey(_workout.exercises[i]),
              exercise: _workout.exercises[i],
              onRemove: () => setState(() => _workout.exercises.removeAt(i)),
              onChanged: () => setState(() {}),
            ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Adicionar exercício'),
            onPressed: () {
              setState(() {
                _workout.exercises.add(WorkoutExercise(name: ''));
              });
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _save() {
    final state = AppScope.of(context);
    _workout.exercises.removeWhere((e) => e.name.trim().isEmpty && e.sets.isEmpty);
    for (final e in _workout.exercises) {
      e.sets.removeWhere((s) => s.weight == null && s.reps == null);
      if (e.name.trim().isNotEmpty) e.name = e.name.trim();
    }
    if (_workout.exercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Adicione pelo menos um exercício.')),
      );
      return;
    }
    final exists = state.workouts.contains(_workout);
    if (exists) {
      state.updateWorkout(_workout);
    } else {
      state.addWorkout(_workout);
    }
    Navigator.of(context).pop();
  }
}

class _ExerciseCard extends StatefulWidget {
  final WorkoutExercise exercise;
  final VoidCallback onRemove;
  final VoidCallback onChanged;

  const _ExerciseCard({
    super.key,
    required this.exercise,
    required this.onRemove,
    required this.onChanged,
  });

  @override
  State<_ExerciseCard> createState() => _ExerciseCardState();
}

class _ExerciseCardState extends State<_ExerciseCard> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _noteCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.exercise.name);
    _noteCtrl = TextEditingController(text: widget.exercise.note ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final exercise = widget.exercise;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(labelText: 'Exercício'),
                    onChanged: (v) => exercise.name = v,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: widget.onRemove,
                ),
              ],
            ),
            TextField(
              controller: _noteCtrl,
              minLines: 1,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Anotação (opcional)',
                hintText: 'ex.: fiz livre, foi mais difícil que no smith',
              ),
              onChanged: (v) {
                exercise.note = v.trim().isEmpty ? null : v;
                widget.onChanged();
              },
            ),
            const SizedBox(height: 8),
            for (var i = 0; i < exercise.sets.length; i++)
              _SetRow(
                set: exercise.sets[i],
                index: i,
                onChanged: widget.onChanged,
              ),
            const SizedBox(height: 8),
            TextButton.icon(
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Adicionar série'),
              onPressed: () {
                exercise.sets.add(WorkoutSet());
                widget.onChanged();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SetRow extends StatefulWidget {
  final WorkoutSet set;
  final int index;
  final VoidCallback onChanged;

  const _SetRow({required this.set, required this.index, required this.onChanged});

  @override
  State<_SetRow> createState() => _SetRowState();
}

class _SetRowState extends State<_SetRow> {
  late final TextEditingController _weightCtrl;
  late final TextEditingController _repsCtrl;

  @override
  void initState() {
    super.initState();
    _weightCtrl = TextEditingController(
      text: widget.set.weight != null
          ? (widget.set.weight! == widget.set.weight!.roundToDouble()
              ? widget.set.weight!.toInt().toString()
              : widget.set.weight!.toStringAsFixed(1).replaceAll('.', ','))
          : '',
    );
    _repsCtrl = TextEditingController(text: widget.set.reps?.toString() ?? '');
  }

  @override
  void didUpdateWidget(covariant _SetRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.set != widget.set) {
      final wText = widget.set.weight != null
          ? (widget.set.weight! == widget.set.weight!.roundToDouble()
              ? widget.set.weight!.toInt().toString()
              : widget.set.weight!.toStringAsFixed(1).replaceAll('.', ','))
          : '';
      if (_weightCtrl.text != wText) _weightCtrl.text = wText;
      final rText = widget.set.reps?.toString() ?? '';
      if (_repsCtrl.text != rText) _repsCtrl.text = rText;
    }
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    _repsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 24, child: Text('${widget.index + 1}.')),
          Expanded(
            child: TextField(
              controller: _weightCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Peso (kg)',
                isDense: true,
                border: OutlineInputBorder(),
              ),
              onChanged: (v) {
                final t = v.trim().replaceAll(',', '.');
                widget.set.weight = t.isEmpty ? null : double.tryParse(t);
                widget.onChanged();
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _repsCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Reps',
                isDense: true,
                border: OutlineInputBorder(),
              ),
              onChanged: (v) {
                widget.set.reps = v.trim().isEmpty ? null : int.tryParse(v.trim());
                widget.onChanged();
              },
            ),
          ),
        ],
      ),
    );
  }
}
