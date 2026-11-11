import 'package:flutter/material.dart';
import '../app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final role = state.role;
    final patient = role == Role.patient;
    final p = state.profile;
    final details = patient
        ? [('Altura', p.detail1), ('Peso atual', p.detail2), ('Meta de peso', p.detail3), ('Nutricionista', 'Dra. Ana Lima')]
        : [('CRN', p.detail1), ('Especialidade', p.detail2), ('Pacientes ativos', '24'), ('Atendimentos', p.detail3)];

    return ListView(padding: const EdgeInsets.all(16), children: [
      const PageHeading(eyebrow: 'Conta', title: 'Meu perfil', subtitle: 'Mantenha seus dados e preferências atualizados.'),
      FilledButton(
        onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => EditProfileScreen(state: state))),
        child: const Text('Editar informações'),
      ),
      const SizedBox(height: 16),
      AppCard(
        padding: const EdgeInsets.all(20),
        child: Row(children: [
          InitialsAvatar(patient ? 'MC' : 'AL', radius: 36),
          const SizedBox(width: 16),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(patient ? 'Paciente desde fevereiro de 2024' : 'Nutricionista clínica · CRN ${p.detail1}', style: const TextStyle(fontSize: 12, color: AppColors.muted)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: AppColors.mint, borderRadius: BorderRadius.circular(10)),
                child: Text(patient ? (p.diabetes.isEmpty ? 'Diabetes Tipo 2' : p.diabetes) : 'Especialista em diabetes', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.olive)),
              ),
            ]),
          ),
        ]),
      ),
      _InfoCard('Informações pessoais', [('E-mail', p.email), ('Telefone', p.phone), ('Data de nascimento', p.birthDate), ('Cidade', p.city)]),
      _InfoCard(patient ? 'Dados de saúde' : 'Dados profissionais', details),
      AppCard(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Eyebrow('Preferências'),
          const SizedBox(height: 2),
          const Text('Configurações', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          if (patient)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Lembretes de saúde', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              subtitle: const Text('Receber alertas de refeições, glicemia e medicamentos.'),
              value: state.setting(role, 'reminders'),
              onChanged: (_) => state.toggleSetting(role, 'reminders'),
            ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Novas mensagens', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            subtitle: const Text('Avisar quando houver uma nova mensagem da equipe.'),
            value: state.setting(role, 'messages'),
            onChanged: (_) => state.toggleSetting(role, 'messages'),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Resumo semanal', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            subtitle: const Text('Receber um resumo da evolução toda segunda-feira.'),
            value: state.setting(role, 'weekly'),
            onChanged: (_) => state.toggleSetting(role, 'weekly'),
          ),
        ]),
      ),
      const SizedBox(height: 8),
      OutlinedButton(
        style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger, side: const BorderSide(color: Color(0xFFF0D8D2)), backgroundColor: const Color(0xFFFFF3F0)),
        onPressed: state.logout,
        child: const Text('Sair do perfil'),
      ),
    ]);
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard(this.title, this.rows);
  final String title;
  final List<(String, String)> rows;
  @override
  Widget build(BuildContext context) => AppCard(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Eyebrow(title),
          const SizedBox(height: 6),
          for (final r in rows) ...[
            const Divider(height: 20),
            Text(r.$1, style: const TextStyle(fontSize: 11, color: AppColors.muted)),
            const SizedBox(height: 2),
            Text(r.$2, style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ]),
      );
}
