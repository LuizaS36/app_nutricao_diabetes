import 'package:flutter/material.dart';
import '../app_state.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/glucose_chart.dart';
import 'diet_screen.dart';

class PatientDetailScreen extends StatelessWidget {
  const PatientDetailScreen({super.key, required this.state, required this.patient});
  final AppState state;
  final Patient patient;

  List<FoodLog> _history() {
    if (patient.name == 'Marina Costa' && state.foodLogs.isNotEmpty) return state.foodLogs;
    final today = dateKey(DateTime.now());
    final yesterday = dateKey(DateTime.now().subtract(const Duration(days: 1)));
    return [
      FoodLog(id: 901, meal: 'Café da manhã', name: 'Iogurte com banana e granola', amount: '1 porção', kcal: 365, date: today),
      FoodLog(id: 902, meal: 'Almoço', name: 'Frango, arroz integral e legumes', amount: '1 prato', kcal: 525, date: today),
      FoodLog(id: 903, meal: 'Jantar', name: 'Sopa de legumes com carne', amount: '300ml', kcal: 410, date: yesterday),
    ];
  }

  void _openDiet(BuildContext context, {required bool editing}) => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => DietScreen(state: state, patient: patient, startEditing: editing)),
      );

  @override
  Widget build(BuildContext context) {
    final history = _history();
    return Scaffold(
      appBar: AppBar(title: Text(patient.name)),
      body: SafeArea(
        child: ListView(padding: const EdgeInsets.all(16), children: [
          Row(children: [
            InitialsAvatar(patient.initials, radius: 32),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Eyebrow('Paciente'),
                Text(patient.name, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                Text('${patient.condition} · Acompanhamento desde fev. 2024', style: const TextStyle(fontSize: 11, color: AppColors.muted)),
              ]),
            ),
          ]),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  state.openChat(patient.name);
                },
                child: const Text('Enviar mensagem'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(child: FilledButton(onPressed: () => _openDiet(context, editing: true), child: const Text('Editar dieta'))),
          ]),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _Stat('Glicemia média', patient.glucose > 0 ? '${patient.glucose}' : '—', 'mg/dL', 'Dentro da meta')),
            const SizedBox(width: 8),
            const Expanded(child: _Stat('Adesão ao plano', '84', '%', '↑ 6% no mês')),
            const SizedBox(width: 8),
            const Expanded(child: _Stat('Peso atual', '72,4', 'kg', 'Meta: 68 kg')),
          ]),
          const SizedBox(height: 4),
          AppCard(
            padding: const EdgeInsets.all(18),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Eyebrow('Últimos 7 dias'),
                    SizedBox(height: 2),
                    Text('Evolução da glicemia', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  ]),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(color: AppColors.mint, borderRadius: BorderRadius.circular(10)),
                  child: const Text('Meta: 70–140', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.olive)),
                ),
              ]),
              const SizedBox(height: 16),
              const GlucoseChart(),
            ]),
          ),
          AppCard(
            padding: const EdgeInsets.all(18),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Eyebrow('Plano alimentar atual'),
              const SizedBox(height: 4),
              const Text('1.880 kcal / dia', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
              const SizedBox(height: 14),
              const _Bar('Proteínas', '105g', .70, AppColors.teal),
              const _Bar('Carboidratos', '210g', .72, AppColors.lime),
              const _Bar('Gorduras', '62g', .65, AppColors.leaf),
              const SizedBox(height: 4),
              SizedBox(width: double.infinity, child: OutlinedButton(onPressed: () => _openDiet(context, editing: false), child: const Text('Visualizar dieta completa'))),
            ]),
          ),
          AppCard(
            padding: const EdgeInsets.all(18),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Eyebrow('Adesão alimentar'),
              const SizedBox(height: 2),
              const Text('Histórico de refeições realizadas', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              const SizedBox(height: 6),
              for (final log in history)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(log.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  subtitle: Text('${log.meal} · ${log.date.split('-').reversed.join('/')} · ${log.amount}', style: const TextStyle(fontSize: 11)),
                  trailing: Text('${log.kcal} kcal', style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.teal, fontSize: 12)),
                ),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value, this.unit, this.note);
  final String label, value, unit, note;
  @override
  Widget build(BuildContext context) => AppCard(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontSize: 10, color: AppColors.muted)),
          const SizedBox(height: 4),
          Text.rich(TextSpan(text: value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800), children: [
            TextSpan(text: ' $unit', style: const TextStyle(fontSize: 9, color: AppColors.muted, fontWeight: FontWeight.w400)),
          ])),
          const SizedBox(height: 2),
          Text(note, style: const TextStyle(fontSize: 10, color: AppColors.teal, fontWeight: FontWeight.w600)),
        ]),
      );
}

class _Bar extends StatelessWidget {
  const _Bar(this.label, this.value, this.progress, this.color);
  final String label, value;
  final double progress;
  final Color color;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(children: [
          Row(children: [
            Expanded(child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.muted))),
            Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
          ]),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(value: progress, minHeight: 6, color: color, backgroundColor: color.withValues(.2)),
          ),
        ]),
      );
}
