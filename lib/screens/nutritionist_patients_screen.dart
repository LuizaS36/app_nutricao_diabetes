import 'package:flutter/material.dart';
import '../app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/nutri_sheets.dart';
import 'patient_detail_screen.dart';

class NutritionistPatientsScreen extends StatefulWidget {
  const NutritionistPatientsScreen({super.key, required this.state});
  final AppState state;
  @override
  State<NutritionistPatientsScreen> createState() => _NutritionistPatientsScreenState();
}

class _NutritionistPatientsScreenState extends State<NutritionistPatientsScreen> {
  String search = '';

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final q = search.toLowerCase();
    final filtered = state.patients.where((p) => p.name.toLowerCase().contains(q) || p.condition.toLowerCase().contains(q)).toList();
    final total = state.patients.length;

    return ListView(padding: const EdgeInsets.all(16), children: [
      PageHeading(eyebrow: 'Gestão clínica', title: 'Meus pacientes', subtitle: 'Acompanhe a evolução e os planos de seus $total pacientes ativos.'),
      FilledButton.icon(onPressed: () => showAddPatientSheet(context, state), icon: const Icon(Icons.add), label: const Text('Adicionar paciente')),
      const SizedBox(height: 16),
      Row(children: [
        Expanded(child: _Overview(icon: Icons.calendar_today_outlined, value: '0', label: 'Consultas esta semana', onTap: () => showAppointmentsSheet(context))),
        const SizedBox(width: 12),
        Expanded(child: _Overview(icon: Icons.notifications_none, value: '${patientsNeedingAttention(state).length}', label: 'Precisam de atenção', onTap: () => showAttentionSheet(context, state))),
      ]),
      const SizedBox(height: 4),
      Card(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Todos os pacientes', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              Text('$total pacientes ativos · ${filtered.length} exibidos', style: const TextStyle(fontSize: 11, color: AppColors.muted)),
              const SizedBox(height: 12),
              TextField(
                onChanged: (v) => setState(() => search = v),
                decoration: const InputDecoration(prefixIcon: Icon(Icons.search, size: 18), hintText: 'Buscar paciente', isDense: true),
              ),
            ]),
          ),
          const Divider(height: 1),
          for (final p in filtered)
            ListTile(
              leading: InitialsAvatar(p.initials),
              title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              subtitle: Text('${p.condition} · ${p.last}', style: const TextStyle(fontSize: 11)),
              trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(p.glucose > 0 ? '${p.glucose} mg/dL' : '—', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                Text(p.status, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: statusColor(p.status))),
              ]),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => PatientDetailScreen(state: state, patient: p))),
            ),
          if (filtered.isEmpty) Padding(padding: const EdgeInsets.all(20), child: Text(state.patients.isEmpty ? 'Você ainda não tem pacientes. Toque em "Adicionar paciente".' : 'Nenhum paciente encontrado.', style: const TextStyle(color: AppColors.muted))),
        ]),
      ),
    ]);
  }
}

class _Overview extends StatelessWidget {
  const _Overview({required this.icon, required this.value, required this.label, required this.onTap});
  final IconData icon;
  final String value, label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => AppCard(
        onTap: onTap,
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          IconBubble(icon, color: AppColors.leaf),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              Text(label, style: const TextStyle(fontSize: 11, color: AppColors.muted)),
            ]),
          ),
        ]),
      );
}
