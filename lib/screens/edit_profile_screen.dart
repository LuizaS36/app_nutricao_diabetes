import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key, required this.state});
  final AppState state;
  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _key = GlobalKey<FormState>();
  late final p = widget.state.profile;
  late final name = TextEditingController(text: p.name);
  late final email = TextEditingController(text: p.email);
  late final phone = TextEditingController(text: p.phone);
  late final birth = TextEditingController(text: p.birthDate);
  late final city = TextEditingController(text: p.city);
  late final d1 = TextEditingController(text: p.detail1);
  late final d2 = TextEditingController(text: p.detail2);
  late final d3 = TextEditingController(text: p.detail3);
  late String diabetes = p.diabetes.isEmpty ? 'Não informado' : p.diabetes;

  bool get patient => widget.state.role == Role.patient;

  @override
  void dispose() {
    for (final c in [name, email, phone, birth, city, d1, d2, d3]) { c.dispose(); }
    super.dispose();
  }

  String? _req(String? v) => (v ?? '').trim().isEmpty ? 'Obrigatório' : null;
  Widget _gap() => const SizedBox(height: 14);

  void _save() {
    if (!_key.currentState!.validate()) return;
    widget.state.saveProfile(
      p.copyWith(
        name: name.text.trim(), email: email.text.trim(), phone: phone.text, birthDate: birth.text.trim(), city: city.text.trim(),
        detail1: d1.text.trim(), detail2: d2.text.trim(), detail3: d3.text.trim(), diabetes: patient && diabetes != 'Não informado' ? diabetes : '',
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Editar informações')),
        body: SafeArea(
          child: Form(
            key: _key,
            child: ListView(padding: const EdgeInsets.all(16), children: [
              PageHeading(eyebrow: 'Conta', title: 'Editar informações', subtitle: 'Atualize seus dados pessoais e ${patient ? 'de saúde' : 'profissionais'}.'),
              const Text('Informações pessoais', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              const SizedBox(height: 12),
              TextFormField(controller: name, decoration: const InputDecoration(labelText: 'Nome completo'), validator: _req),
              _gap(),
              TextFormField(controller: email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'E-mail'), validator: (v) => (v ?? '').contains('@') ? null : 'E-mail inválido'),
              _gap(),
              TextFormField(controller: phone, keyboardType: TextInputType.phone, inputFormatters: [FilteringTextInputFormatter.digitsOnly, PhoneFormatter()], decoration: const InputDecoration(labelText: 'Telefone'), validator: _req),
              _gap(),
              TextFormField(controller: birth, decoration: const InputDecoration(labelText: 'Data de nascimento'), validator: _req),
              _gap(),
              TextFormField(controller: city, decoration: const InputDecoration(labelText: 'Cidade'), validator: _req),
              const SizedBox(height: 24),
              Text(patient ? 'Dados de saúde' : 'Dados profissionais', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              const SizedBox(height: 12),
              if (patient) ...[
                DropdownButtonFormField<String>(
                  value: diabetes,
                  decoration: const InputDecoration(labelText: 'Diabetes'),
                  items: [for (final t in ['Não informado', 'Diabetes Tipo 1', 'Diabetes Tipo 2', 'Pré-diabetes', 'Diabetes Gestacional']) DropdownMenuItem(value: t, child: Text(t))],
                  onChanged: (v) => setState(() => diabetes = v ?? diabetes),
                ),
                _gap(),
              ],
              TextFormField(controller: d1, decoration: InputDecoration(labelText: patient ? 'Altura' : 'CRN')),
              _gap(),
              TextFormField(controller: d2, decoration: InputDecoration(labelText: patient ? 'Peso atual' : 'Especialidade')),
              _gap(),
              TextFormField(controller: d3, decoration: InputDecoration(labelText: patient ? 'Meta de peso' : 'Horário de atendimento')),
              const SizedBox(height: 22),
              Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
                const SizedBox(width: 8),
                FilledButton(onPressed: _save, child: const Text('Salvar alterações')),
              ]),
            ]),
          ),
        ),
      );
}
