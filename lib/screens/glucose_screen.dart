import 'package:flutter/material.dart';
import '../app_state.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/glucose_chart.dart';
import '../widgets/sheets.dart';

class GlucoseScreen extends StatefulWidget {
  const GlucoseScreen({super.key, required this.state});
  final AppState state;
  @override
  State<GlucoseScreen> createState() => _GlucoseScreenState();
}

class _GlucoseScreenState extends State<GlucoseScreen> {
  bool editing = false;

  Future<void> _confirmDelete(Medication med) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir medicamento'),
        content: Text('Tem certeza que deseja apagar este registro? ${med.name} será removido da sua rotina.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Confirmar')),
        ],
      ),
    );
    if (ok == true) widget.state.removeMedication(med.id);
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final last = state.glucoseLogs.take(7).toList();
    final avg = last.isEmpty ? '—' : (last.fold<int>(0, (s, l) => s + l.value) / last.length).round().toString();
    final inRange = last.isEmpty ? '—' : (last.where((l) => l.value >= 70 && l.value <= 140).length * 100 / last.length).round().toString();
    return ListView(padding: const EdgeInsets.all(16), children: [
      const PageHeading(eyebrow: 'Acompanhamento', title: 'Glicose e saúde', subtitle: 'Acompanhe sua glicemia, medicamentos e vitaminas.'),
      FilledButton.icon(onPressed: () => showAddGlucoseSheet(context, state), icon: const Icon(Icons.add), label: const Text('Nova medição')),
      const SizedBox(height: 16),
      Row(children: [
        Expanded(child: _Stat('Média dos registros', avg, 'mg/dL', last.isEmpty ? 'Sem registros' : 'Últimos ${last.length} registros')),
        const SizedBox(width: 12),
        Expanded(child: _Stat('Tempo na meta', inRange, '%', last.isEmpty ? 'Sem registros' : 'Meta: 70–140 mg/dL')),
      ]),
      const SizedBox(height: 12),
      AppCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Expanded(child: Text('Histórico de glicemia', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16))),
            TextButton(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => GlucoseHistoryScreen(logs: state.glucoseLogs))),
              child: const Text('Ver todos'),
            ),
          ]),
          if (state.glucoseLogs.isEmpty) const Text('Nenhuma medição ainda.', style: TextStyle(color: AppColors.muted)),
          for (final e in state.glucoseLogs.take(3).toList().asMap().entries) _LogRow(e.value, e.key),
        ]),
      ),
      AppCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Expanded(child: Text('Medicamentos e vitaminas', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16))),
            TextButton(onPressed: () => setState(() => editing = !editing), child: Text(editing ? 'Concluir' : 'Editar')),
          ]),
          for (final med in state.medications)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: editing ? IconButton(icon: const Icon(Icons.delete_outline, color: AppColors.danger), onPressed: () => _confirmDelete(med)) : null,
              title: Text(med.name, style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text('${med.type} · ${med.dose}'),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.schedule, size: 14), const SizedBox(width: 4), Text(med.time)]),
            ),
          OutlinedButton.icon(onPressed: () => showAddMedicationSheet(context, state), icon: const Icon(Icons.add), label: const Text('Adicionar medicamento')),
        ]),
      ),
    ]);
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value, this.unit, this.note);
  final String label, value, unit, note;
  @override
  Widget build(BuildContext context) => AppCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
          const SizedBox(height: 4),
          Text.rich(TextSpan(text: value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800), children: [
            TextSpan(text: ' $unit', style: const TextStyle(fontSize: 12, color: AppColors.muted, fontWeight: FontWeight.w400)),
          ])),
          Text(note, style: const TextStyle(fontSize: 12, color: AppColors.teal, fontWeight: FontWeight.w600)),
        ]),
      );
}

class _LogRow extends StatelessWidget {
  const _LogRow(this.log, this.index);
  final GlucoseLog log;
  final int index;
  @override
  Widget build(BuildContext context) {
    final high = log.value > 140;
    final color = high ? AppColors.warn : AppColors.teal;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(radius: 5, backgroundColor: color),
      title: Text(log.context, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(log.time),
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        GlucoseSparkline(value: log.value, index: index),
        const SizedBox(width: 10),
        Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('${log.value} mg/dL', style: const TextStyle(fontWeight: FontWeight.w800)),
          Text(high ? 'Acima da meta' : 'Na meta', style: TextStyle(fontSize: 11, color: color)),
        ]),
      ]),
    );
  }
}

class GlucoseHistoryScreen extends StatelessWidget {
  const GlucoseHistoryScreen({super.key, required this.logs});
  final List<GlucoseLog> logs;
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Todos os registros')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const PageHeading(eyebrow: 'Acompanhamento completo', title: 'Todos os registros', subtitle: 'Consulte seu histórico e a evolução da glicemia.'),
            const AppCard(
              padding: EdgeInsets.all(18),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Eyebrow('Últimos 7 dias'),
                SizedBox(height: 2),
                Text('Evolução da glicemia', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                Text('Meta: 70–140 mg/dL', style: TextStyle(fontSize: 11, color: AppColors.muted)),
                SizedBox(height: 14),
                GlucoseChart(height: 200),
              ]),
            ),
            AppCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Registros de glicemia', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                for (final e in logs.asMap().entries) _LogRow(e.value, e.key),
              ]),
            ),
          ],
        ),
      );
}
