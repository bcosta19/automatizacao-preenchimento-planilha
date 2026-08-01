import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../main.dart';
import '../models.dart';
import '../notifier.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late Settings _settings;

  @override
  void initState() {
    super.initState();
    _settings = Settings.fromJson(AppScope.read(context).settings.toJson());
  }

  void _update(void Function(Settings) apply) {
    setState(() => apply(_settings));
    AppScope.of(context).updateSettings(_settings);
    NotificationService.scheduleAll(_settings);
  }

  Future<void> _pickTime(String label, void Function(int h, int m) apply) async {
    final current = label.contains('fim do dia')
        ? TimeOfDay(hour: _settings.endOfDayHour, minute: _settings.endOfDayMinute)
        : TimeOfDay(hour: _settings.sportHour, minute: _settings.sportMinute);
    final picked = await showTimePicker(context: context, initialTime: current);
    if (picked != null) _update((s) => apply(picked.hour, picked.minute));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Notificações ativas'),
            subtitle: const Text('Lembretes nativos do Android'),
            value: _settings.notificationsEnabled,
            onChanged: (v) => _update((s) => s.notificationsEnabled = v),
          ),
          const Divider(),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.nights_stay_outlined),
            title: const Text('Lembrete fim do dia'),
            subtitle: Text(
                'Todos os dias às ${_hm(_settings.endOfDayHour, _settings.endOfDayMinute)} — preencher o check-in'),
            trailing: const Icon(Icons.edit_outlined),
            onTap: () => _pickTime('fim do dia', (h, m) {
              _settings.endOfDayHour = h;
              _settings.endOfDayMinute = m;
            }),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.sports_martial_arts),
            title: const Text('Lembrete outro esporte'),
            subtitle: Text(
                'Às ${_hm(_settings.sportHour, _settings.sportMinute)} nos dias marcados abaixo'),
            trailing: const Icon(Icons.edit_outlined),
            onTap: () => _pickTime('esporte', (h, m) {
              _settings.sportHour = h;
              _settings.sportMinute = m;
            }),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text('Ciclo de check-in',
                style: Theme.of(context).textTheme.titleSmall),
          ),
          Wrap(
            spacing: 8,
            children: [
              for (final mode in [
                (Settings.cycleSemanal, 'Semanal (7 dias)'),
                (Settings.cycleQuinzenal, 'Quinzenal (14 dias)'),
                (Settings.cyclePersonalizado, 'Personalizado'),
              ])
                FilterChip(
                  label: Text(mode.$2),
                  selected: _settings.cycleMode == mode.$1,
                  onSelected: (_) => _update((s) => s.cycleMode = mode.$1),
                ),
            ],
          ),
          if (_settings.cycleMode == Settings.cyclePersonalizado)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: TextField(
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Tamanho do ciclo (dias)',
                  hintText: 'ex.: 10',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (v) {
                  final n = int.tryParse(v.trim());
                  if (n != null) {
                    _update((s) => s.customCycleLength = n.clamp(2, 60));
                  }
                },
              ),
            ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.flag_outlined),
            title: const Text('Início do ciclo atual'),
            subtitle: Text(dmy(AppScope.of(context).cycleStart)),
            trailing: const Icon(Icons.edit_outlined),
            onTap: () async {
              final state = AppScope.of(context);
              final now = DateTime.now();
              final picked = await showDatePicker(
                context: context,
                initialDate: state.cycleStart,
                firstDate: now.subtract(const Duration(days: 366)),
                lastDate: now,
              );
              if (picked != null) {
                state.setCycleStart(picked);
              }
            },
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text('Dias do lembrete de esporte',
                style: Theme.of(context).textTheme.titleSmall),
          ),
          Wrap(
            spacing: 8,
            children: [
              for (var d = DateTime.monday; d <= DateTime.sunday; d++)
                FilterChip(
                  label: Text(weekdayFull[d - 1]),
                  selected: _settings.sportDays.contains(d),
                  onSelected: (sel) => _update((s) {
                    if (sel) {
                      s.sportDays = [...s.sportDays, d]..sort();
                    } else {
                      s.sportDays = [...s.sportDays]..remove(d);
                    }
                  }),
                ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            decoration: const InputDecoration(
              labelText: 'Esporte habitual',
              hintText: 'ex.: jiujitsu',
            ),
            onChanged: (v) => _update((s) => s.defaultSport = v.trim().isEmpty ? 'jiujitsu' : v.trim()),
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            icon: const Icon(Icons.notifications_active_outlined),
            label: const Text('Enviar notificação de teste'),
            onPressed: () => NotificationService.testNotification(),
          ),
          const SizedBox(height: 16),
          Text(
            'Os lembretes agendados são atualizados automaticamente ao mudar qualquer ajuste. Para horários mais precisos, ative a permissão de "alarmes e lembretes" nas configurações do Android.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  String _hm(int h, int m) => '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
}
