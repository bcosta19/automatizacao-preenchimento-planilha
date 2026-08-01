import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

  Color _colorFor(int v) {
    const colors = [
      Color(0xFFD32F2F),
      Color(0xFFEF6C00),
      Color(0xFFF9A825),
      Color(0xFF7CB342),
      Color(0xFF2E7D32),
    ];
    return colors[v - 1];
  }

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
          _DecimalFormatter()
        else
          _IntFormatter(),
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
