import 'package:flutter/material.dart';
import '../app_state.dart';
import '../data.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/common.dart';

class DietScreen extends StatefulWidget {
  const DietScreen({super.key, required this.state, required this.patient, this.startEditing = false});
  final AppState state;
  final Patient patient;
  final bool startEditing;
  @override
  State<DietScreen> createState() => _DietScreenState();
}

class _Ctl {
  _Ctl(DietEntry e)
      : time = TextEditingController(text: e.time),
        title = TextEditingController(text: e.title),
        items = TextEditingController(text: e.items);
  final TextEditingController time, title, items;
  void dispose() { time.dispose(); title.dispose(); items.dispose(); }
}

class _DietScreenState extends State<DietScreen> {
  late bool editing = widget.startEditing;
  late final Map<String, _Ctl> ctl = {
    for (final e in widget.state.dietFor(widget.patient.id).entries) e.key: _Ctl(e.value),
  };

  @override
  void dispose() {
    for (final c in ctl.values) { c.dispose(); }
    super.dispose();
  }

  Future<void> _pickTime(TextEditingController c) async {
    final parts = c.text.split(':');
    final initial = parts.length == 2 ? TimeOfDay(hour: int.tryParse(parts[0]) ?? 8, minute: int.tryParse(parts[1]) ?? 0) : TimeOfDay.now();
    final t = await showTimePicker(context: context, initialTime: initial);
    if (t != null) c.text = '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  void _save() {
    widget.state.saveDiet(widget.patient.id, {
      for (final e in ctl.entries) e.key: DietEntry(time: e.value.time.text, title: e.value.title.text, items: e.value.items.text),
    });
    setState(() => editing = false);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Alterações salvas com sucesso.')));
  }

  @override
  Widget build(BuildContext context) {
    final plan = widget.state.dietFor(widget.patient.id);
    return Scaffold(
      appBar: AppBar(
        title: Text(editing ? 'Editar dieta' : 'Dieta completa'),
        actions: [if (!editing) TextButton(onPressed: () => setState(() => editing = true), child: const Text('Editar dieta'))],
      ),
      bottomNavigationBar: editing
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: FilledButton(onPressed: _save, child: const Text('Salvar dieta')),
              ),
            )
          : null,
      body: SafeArea(
        child: ListView(padding: const EdgeInsets.all(16), children: [
          Eyebrow('Plano alimentar de ${widget.patient.name}'),
          const SizedBox(height: 4),
          const Text('Plano diário de 1.880 kcal, atualizado pela equipe de nutrição.', style: TextStyle(color: AppColors.muted, fontSize: 12)),
          const SizedBox(height: 14),
          for (final m in meals) editing ? _editCard(m) : _viewCard(m, plan[m.key]!),
        ]),
      ),
    );
  }

  Widget _viewCard(Meal m, DietEntry e) => AppCard(
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Eyebrow(e.time),
                const SizedBox(height: 2),
                Text(m.key, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
              ]),
            ),
            Text('${m.kcal} kcal', style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.teal)),
          ]),
          const SizedBox(height: 10),
          Text(e.title, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(e.items.split('\n').where((l) => l.trim().isNotEmpty).join(' · '), style: const TextStyle(fontSize: 12, color: AppColors.muted, height: 1.6)),
          const Divider(height: 24),
          const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            _Macro('Proteínas', '25g'),
            _Macro('Carboidratos', '42g'),
            _Macro('Gorduras', '14g'),
          ]),
        ]),
      );

  Widget _editCard(Meal m) {
    final c = ctl[m.key]!;
    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Eyebrow('Refeição'),
        const SizedBox(height: 2),
        Text(m.key, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        const SizedBox(height: 12),
        TextField(controller: c.time, readOnly: true, onTap: () => _pickTime(c.time), decoration: const InputDecoration(labelText: 'Horário')),
        const SizedBox(height: 12),
        TextField(controller: c.title, decoration: const InputDecoration(labelText: 'Nome da refeição')),
        const SizedBox(height: 12),
        TextField(controller: c.items, minLines: 3, maxLines: 8, decoration: const InputDecoration(labelText: 'Alimentos prescritos (um por linha)', alignLabelWithHint: true)),
      ]),
    );
  }
}

class _Macro extends StatelessWidget {
  const _Macro(this.label, this.value);
  final String label, value;
  @override
  Widget build(BuildContext context) => Text.rich(TextSpan(text: '$label ', style: const TextStyle(fontSize: 11, color: AppColors.muted), children: [
        TextSpan(text: value, style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.deep)),
      ]));
}
