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
void showAppointmentsSheet(BuildContext context) {
  final today = DateTime.now();
  final items = [
    (1, '09:00', 'Marina Costa', 'Retorno'),
    (1, '14:30', 'Rafael Mendes', 'Primeira consulta'),
    (2, '10:00', 'Clara Oliveira', 'Acompanhamento'),
    (3, '08:30', 'Paulo Nunes', 'Retorno'),
    (3, '16:00', 'Marina Costa', 'Ajuste de plano'),
    (4, '11:00', 'Rafael Mendes', 'Acompanhamento'),
  ];
  _sheet(
    context,
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const _Title('Agenda', 'Calendário de consultas'),
      for (var i = 0; i < items.length; i++) ...[
        if (i == 0 || items[i - 1].$1 != items[i].$1)
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 4),
            child: Text(ptDate(today.add(Duration(days: items[i].$1))), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.teal)),
          ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Text(items[i].$2, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          title: Text(items[i].$3, style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: Text(items[i].$4),
        ),
      ],
    ]),
  );
}

// ---------- Pacientes que precisam de atenção ----------
void showAttentionSheet(BuildContext context) {
  const rows = [
    ('CO', 'Clara Oliveira', 'Glicemia de 164 mg/dL, acima da meta definida.'),
    ('RM', 'Rafael Mendes', 'Não registra refeições há 3 dias.'),
    ('PN', 'Paulo Nunes', 'Adesão ao plano caiu para 58% nesta semana.'),
  ];
  _sheet(
    context,
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const _Title('Atenção', 'Pacientes que precisam de atenção'),
      for (final r in rows)
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: InitialsAvatar(r.$1),
          title: Text(r.$2, style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: Text(r.$3),
        ),
    ]),
  );
}

// ---------- Sino: alertas clínicos ----------
const clinicalAlertCount = 3;

void showClinicalAlertsSheet(BuildContext context, AppState state) {
  const alerts = [
    ('CO', 'Clara Oliveira', 'Pico de Glicemia', '164 mg/dL após o almoço'),
    ('RM', 'Rafael Mendes', 'Baixo Consumo de Água', 'Apenas 500 ml registrados hoje'),
    ('PN', 'Paulo Nunes', 'Pouca Ingestão de Alimentos', 'Nenhuma refeição registrada desde ontem'),
  ];
  _sheet(
    context,
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const _Title('Central clínica', 'Alertas de pacientes'),
      for (final a in alerts)
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: InitialsAvatar(a.$1),
          title: Text(a.$2, style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(a.$3, style: const TextStyle(color: AppColors.warn, fontWeight: FontWeight.w700)),
            Text(a.$4),
          ]),
          trailing: TextButton(
            onPressed: () {
              Navigator.pop(context);
              state.openChat(a.$2);
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
