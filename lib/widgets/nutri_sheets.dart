import 'package:flutter/material.dart';
import '../app_state.dart';
import '../models.dart';
import '../theme.dart';
import 'common.dart';

const _wd = ['Segunda', 'Terça', 'Quarta', 'Quinta', 'Sexta', 'Sábado', 'Domingo'];
const _mo = ['janeiro', 'fevereiro', 'março', 'abril', 'maio', 'junho', 'julho', 'agosto', 'setembro', 'outubro', 'novembro', 'dezembro'];
String ptDate(DateTime d) => '${_wd[d.weekday - 1]}, ${d.day} de ${_mo[d.month - 1]}';

Future<void> _sheet(BuildContext context, Widget child) => showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.of(ctx).viewInsets.bottom),
        child: SingleChildScrollView(child: child),
      ),
    );

class _Title extends StatelessWidget {
  const _Title(this.eyebrow, this.title);
  final String eyebrow, title;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Eyebrow(eyebrow),
          const SizedBox(height: 4),
          Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
        ]),
      );
}

// ---------- Calendário de consultas ----------
void showAppointmentsSheet(BuildContext context) => _sheet(
      context,
      const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _Title('Agenda', 'Calendário de consultas'),
        Text(
          'Nenhuma consulta agendada. O agendamento será liberado quando o app for conectado a um servidor.',
          style: TextStyle(color: AppColors.muted, height: 1.5),
        ),
      ]),
    );

/// Pacientes com status "Atenção" (glicemia acima da meta).
List<Patient> patientsNeedingAttention(AppState state) =>
    state.patients.where((p) => p.status == 'Atenção').toList();

// ---------- Pacientes que precisam de atenção ----------
void showAttentionSheet(BuildContext context, AppState state) {
  final list = patientsNeedingAttention(state);
  _sheet(
    context,
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const _Title('Atenção', 'Pacientes que precisam de atenção'),
      if (list.isEmpty) const Text('Nenhum paciente precisa de atenção agora.', style: TextStyle(color: AppColors.muted)),
      for (final p in list)
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: InitialsAvatar(p.initials),
          title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: Text('Glicemia de ${p.glucose} mg/dL, acima da meta definida.'),
        ),
    ]),
  );
}

// ---------- Sino: alertas clínicos ----------
void showClinicalAlertsSheet(BuildContext context, AppState state) {
  final list = patientsNeedingAttention(state);
  _sheet(
    context,
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const _Title('Central clínica', 'Alertas de pacientes'),
      if (list.isEmpty) const Text('Nenhum alerta no momento.', style: TextStyle(color: AppColors.muted)),
      for (final p in list)
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: InitialsAvatar(p.initials),
          title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Pico de Glicemia', style: TextStyle(color: AppColors.warn, fontWeight: FontWeight.w700)),
            Text('${p.glucose} mg/dL'),
          ]),
          trailing: TextButton(
            onPressed: () {
              Navigator.pop(context);
              state.openChat(p.name);
            },
            child: const Text('Abrir chat'),
          ),
        ),
    ]),
  );
}

// ---------- Adicionar paciente ----------
void showAddPatientSheet(BuildContext context, AppState state) => _sheet(context, _AddPatientForm(state: state));

class _AddPatientForm extends StatefulWidget {
  const _AddPatientForm({required this.state});
  final AppState state;
  @override
  State<_AddPatientForm> createState() => _AddPatientFormState();
}

class _AddPatientFormState extends State<_AddPatientForm> {
  final _key = GlobalKey<FormState>();
  final name = TextEditingController();
  final email = TextEditingController();

  @override
  void dispose() { name.dispose(); email.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Form(
        key: _key,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const _Title('Novo registro', 'Adicionar novo paciente'),
          TextFormField(controller: name, decoration: const InputDecoration(labelText: 'Nome completo', hintText: 'Ex.: João da Silva'), validator: (v) => (v ?? '').trim().isEmpty ? 'Obrigatório' : null),
          const SizedBox(height: 12),
          TextFormField(controller: email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'E-mail', hintText: 'paciente@email.com')),
          const SizedBox(height: 12),
          const Text('O paciente receberá um convite para completar seu cadastro e responder à avaliação inicial.', style: TextStyle(fontSize: 12, color: AppColors.muted)),
          const SizedBox(height: 16),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: () {
                if (!_key.currentState!.validate()) return;
                final n = name.text.trim();
                widget.state.addPatient(Patient(
                  id: DateTime.now().millisecondsSinceEpoch,
                  name: n,
                  initials: n.split(' ').where((p) => p.isNotEmpty).map((p) => p[0]).take(2).join().toUpperCase(),
                  condition: 'Aguardando avaliação',
                  last: 'Novo paciente',
                  glucose: 0,
                  status: 'Pendente',
                ));
                Navigator.pop(context);
              },
              child: const Text('Enviar convite'),
            ),
          ]),
        ]),
      );
}
