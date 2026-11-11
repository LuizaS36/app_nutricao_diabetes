import 'package:flutter/material.dart';
import '../app_state.dart';
import '../models.dart';
import '../theme.dart';
import 'common.dart';

Future<void> _sheet(BuildContext context, Widget child) => showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.of(ctx).viewInsets.bottom),
        child: SingleChildScrollView(child: child),
      ),
    );

// ---------- Menu do usuário (avatar no topo) ----------
void showUserSheet(BuildContext context, AppState state) {
  final p = state.profile;
  final patient = state.role == Role.patient;
  _sheet(
    context,
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        InitialsAvatar(patient ? 'MC' : 'AL', radius: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(p.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            Text(patient ? 'Paciente' : 'Nutricionista', style: const TextStyle(fontSize: 12, color: AppColors.muted)),
          ]),
        ),
      ]),
      const Divider(height: 28),
      const Text('Data de nascimento', style: TextStyle(fontSize: 11, color: AppColors.muted)),
      Text(p.birthDate, style: const TextStyle(fontWeight: FontWeight.w700)),
      const SizedBox(height: 10),
      const Text('E-mail', style: TextStyle(fontSize: 11, color: AppColors.muted)),
      Text(p.email, style: const TextStyle(fontWeight: FontWeight.w700)),
      const SizedBox(height: 18),
      SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: () {
            Navigator.pop(context);
            state.setRole(patient ? Role.nutritionist : Role.patient);
          },
          child: Text('Visualizar como ${patient ? 'Nutricionista' : 'Paciente'}'),
        ),
      ),
      const SizedBox(height: 8),
      SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger, side: const BorderSide(color: Color(0xFFF0D8D2))),
          onPressed: () {
            Navigator.pop(context);
            state.logout();
          },
          child: const Text('Sair da conta'),
        ),
      ),
    ]),
  );
}

// ---------- Configurações de notificação (sino do paciente) ----------
void showNotificationSettingsSheet(BuildContext context, AppState state) =>
    _sheet(context, _NotificationForm(state: state));

class _NotificationForm extends StatefulWidget {
  const _NotificationForm({required this.state});
  final AppState state;
  @override
  State<_NotificationForm> createState() => _NotificationFormState();
}

class _NotificationFormState extends State<_NotificationForm> {
  late final NotificationPrefs draft = widget.state.notif.copy();

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Eyebrow('Preferências de alertas'),
        const SizedBox(height: 4),
        Text('Configurações de notificação', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Notificações de Refeições', style: TextStyle(fontWeight: FontWeight.w700)),
          subtitle: const Text('Receba lembretes nos horários definidos no seu plano.'),
          value: draft.meals,
          onChanged: (v) => setState(() => draft.meals = v),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Notificações de Medicação', style: TextStyle(fontWeight: FontWeight.w700)),
          subtitle: const Text('Alertas para medicamentos, vitaminas e suplementos.'),
          value: draft.medication,
          onChanged: (v) => setState(() => draft.medication = v),
        ),
        const SizedBox(height: 8),
        const Text('Lembrete de Ingestão de Água', style: TextStyle(fontWeight: FontWeight.w700)),
        const Text('Alertar caso nenhum consumo seja registrado durante o período.', style: TextStyle(fontSize: 12, color: AppColors.muted)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: draft.waterInterval,
          items: const [
            DropdownMenuItem(value: '1', child: Text('A cada 1 hora')),
            DropdownMenuItem(value: '2', child: Text('A cada 2 horas')),
            DropdownMenuItem(value: '3', child: Text('A cada 3 horas')),
            DropdownMenuItem(value: '4', child: Text('A cada 4 horas')),
            DropdownMenuItem(value: '0', child: Text('Desativado')),
          ],
          onChanged: (v) => setState(() => draft.waterInterval = v ?? draft.waterInterval),
        ),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          OutlinedButton(
            style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: () {
              widget.state.saveNotif(draft);
              Navigator.pop(context);
            },
            child: const Text('Salvar'),
          ),
        ]),
      ]);
}
