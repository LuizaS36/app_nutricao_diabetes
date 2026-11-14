import 'package:flutter/material.dart';
import '../app_state.dart';
import '../data.dart';
import '../models.dart';

Future<void> _openSheet(BuildContext context, Widget child) => showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.of(ctx).viewInsets.bottom),
        child: SingleChildScrollView(child: child),
      ),
    );

void showAddFoodSheet(BuildContext context, AppState state, {String meal = 'Café da manhã', String food = '', required String date}) =>
    _openSheet(context, _FoodForm(state: state, meal: meal, food: food, date: date));

void showAddGlucoseSheet(BuildContext context, AppState state) =>
    _openSheet(context, _GlucoseForm(state: state));

void showAddMedicationSheet(BuildContext context, AppState state) =>
    _openSheet(context, _MedicationForm(state: state));

class _SheetTitle extends StatelessWidget {
  const _SheetTitle(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Text(text, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
      );
}

class _FoodForm extends StatefulWidget {
  const _FoodForm({required this.state, required this.meal, required this.food, required this.date});
  final AppState state;
  final String meal, food, date;
  @override
  State<_FoodForm> createState() => _FoodFormState();
}

class _FoodFormState extends State<_FoodForm> {
  final _key = GlobalKey<FormState>();
  late String meal = widget.meal;
  late final food = TextEditingController(text: widget.food);
  final amount = TextEditingController();
  final kcal = TextEditingController();

  @override
  void dispose() { food.dispose(); amount.dispose(); kcal.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Form(
        key: _key,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Align(alignment: Alignment.centerLeft, child: _SheetTitle('Registrar refeição')),
          DropdownButtonFormField<String>(
            value: meal,
            decoration: const InputDecoration(labelText: 'Refeição'),
            items: [for (final m in meals) DropdownMenuItem(value: m.key, child: Text(m.key))],
            onChanged: (v) => setState(() => meal = v ?? meal),
          ),
          const SizedBox(height: 12),
          TextFormField(controller: food, decoration: const InputDecoration(labelText: 'Alimento', hintText: 'Ex.: banana, arroz integral...'), validator: (v) => (v ?? '').trim().isEmpty ? 'Obrigatório' : null),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: TextFormField(controller: amount, decoration: const InputDecoration(labelText: 'Quantidade', hintText: 'Ex.: 100g'), validator: (v) => (v ?? '').trim().isEmpty ? 'Obrigatório' : null)),
            const SizedBox(width: 12),
            Expanded(child: TextFormField(controller: kcal, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Calorias', hintText: '120'))),
          ]),
          const SizedBox(height: 16),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: () {
                if (!_key.currentState!.validate()) return;
                widget.state.addFood(FoodLog(
                  id: DateTime.now().millisecondsSinceEpoch,
                  meal: meal,
                  name: food.text.trim(),
                  amount: amount.text.trim(),
                  kcal: int.tryParse(kcal.text) ?? 120,
                  date: widget.date,
                ));
                Navigator.pop(context);
              },
              child: const Text('Registrar'),
            ),
          ]),
        ]),
      );
}

class _GlucoseForm extends StatefulWidget {
  const _GlucoseForm({required this.state});
  final AppState state;
  @override
  State<_GlucoseForm> createState() => _GlucoseFormState();
}

class _GlucoseFormState extends State<_GlucoseForm> {
  static const contexts = ['Em jejum', 'Antes do almoço', 'Após o almoço', 'Antes do jantar', 'Após o jantar', 'Antes de dormir'];
  final _key = GlobalKey<FormState>();
  final value = TextEditingController();
  String ctx = contexts.first;

  @override
  void dispose() { value.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Form(
        key: _key,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Align(alignment: Alignment.centerLeft, child: _SheetTitle('Registrar glicemia')),
          TextFormField(
            controller: value,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Valor da glicemia', suffixText: 'mg/dL', hintText: '110'),
            validator: (v) {
              final n = int.tryParse(v ?? '');
              return (n == null || n < 20 || n > 600) ? 'Informe um valor entre 20 e 600' : null;
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: ctx,
            decoration: const InputDecoration(labelText: 'Momento da medição'),
            items: [for (final c in contexts) DropdownMenuItem(value: c, child: Text(c))],
            onChanged: (v) => setState(() => ctx = v ?? ctx),
          ),
          const SizedBox(height: 16),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: () {
                if (!_key.currentState!.validate()) return;
                final now = TimeOfDay.now();
                widget.state.addGlucose(GlucoseLog(
                  id: DateTime.now().millisecondsSinceEpoch,
                  value: int.parse(value.text),
                  context: ctx,
                  time: '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
                ));
                Navigator.pop(context);
              },
              child: const Text('Salvar medição'),
            ),
          ]),
        ]),
      );
}

class _MedicationForm extends StatefulWidget {
  const _MedicationForm({required this.state});
  final AppState state;
  @override
  State<_MedicationForm> createState() => _MedicationFormState();
}

class _MedicationFormState extends State<_MedicationForm> {
  final _key = GlobalKey<FormState>();
  final name = TextEditingController();
  final dose = TextEditingController();
  final time = TextEditingController();
  String type = 'Medicamento';

  @override
  void dispose() { name.dispose(); dose.dispose(); time.dispose(); super.dispose(); }

  Future<void> _pickTime() async {
    final t = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (t != null) time.text = '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) => Form(
        key: _key,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Align(alignment: Alignment.centerLeft, child: _SheetTitle('Adicionar medicamento')),
          DropdownButtonFormField<String>(
            value: type,
            decoration: const InputDecoration(labelText: 'Tipo'),
            items: [for (final t in ['Medicamento', 'Vitamina', 'Suplemento']) DropdownMenuItem(value: t, child: Text(t))],
            onChanged: (v) => setState(() => type = v ?? type),
          ),
          const SizedBox(height: 12),
          TextFormField(controller: name, decoration: const InputDecoration(labelText: 'Nome'), validator: (v) => (v ?? '').trim().isEmpty ? 'Obrigatório' : null),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: TextFormField(controller: dose, decoration: const InputDecoration(labelText: 'Dose', hintText: 'Ex.: 500mg'), validator: (v) => (v ?? '').trim().isEmpty ? 'Obrigatório' : null)),
            const SizedBox(width: 12),
            Expanded(child: TextFormField(controller: time, readOnly: true, onTap: _pickTime, decoration: const InputDecoration(labelText: 'Horário'), validator: (v) => (v ?? '').isEmpty ? 'Obrigatório' : null)),
          ]),
          const SizedBox(height: 16),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: () {
                if (!_key.currentState!.validate()) return;
                widget.state.addMedication(Medication(
                  id: DateTime.now().millisecondsSinceEpoch,
                  name: name.text.trim(),
                  dose: dose.text.trim(),
                  time: time.text,
                  type: type,
                ));
                Navigator.pop(context);
              },
              child: const Text('Adicionar à rotina'),
            ),
          ]),
        ]),
      );
}
