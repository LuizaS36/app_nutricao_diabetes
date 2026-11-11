import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, required this.state});
  final AppState state;
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _key = GlobalKey<FormState>();
  bool creating = false;
  final name = TextEditingController();
  final email = TextEditingController();
  final phone = TextEditingController();
  final birth = TextEditingController();
  final city = TextEditingController();
  final password = TextEditingController();
  String role = 'patient';
  bool terms = false;

  @override
  void dispose() {
    for (final c in [name, email, phone, birth, city, password]) { c.dispose(); }
    super.dispose();
  }

  String? _required(String? v) => (v ?? '').trim().isEmpty ? 'Obrigatório' : null;

  Future<void> _pickBirth() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 30),
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (d != null) {
      birth.text = '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    }
  }

  void _submit() {
    if (!_key.currentState!.validate()) return;
    if (creating && !terms) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Aceite os termos de uso para continuar.')));
      return;
    }
    widget.state.authenticate(
      role == 'nutritionist' ? Role.nutritionist : Role.patient,
      creating: creating,
      name: name.text.trim(),
      email: email.text.trim(),
      phone: phone.text,
      birthDate: birth.text,
      city: city.text.trim(),
    );
  }

  void _forgot() {
    final ctl = TextEditingController();
    var sent = false;
    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: Text(sent ? 'Verifique seu e-mail' : 'Recuperar senha'),
          content: sent
              ? const Text('Se o endereço estiver cadastrado, você receberá em instantes o link para criar uma nova senha.')
              : Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Informe o seu e-mail cadastrado para receber o link de recuperação de senha.'),
                  const SizedBox(height: 12),
                  TextField(controller: ctl, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'E-mail', hintText: 'voce@email.com')),
                ]),
          actions: [
            if (sent)
              FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('Entendi'))
            else ...[
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
              FilledButton(
                onPressed: () { if (ctl.text.contains('@')) setD(() => sent = true); },
                child: const Text('Enviar'),
              ),
            ],
          ],
        ),
      ),
    ).whenComplete(ctl.dispose);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(children: [
              _hero(),
              Padding(padding: const EdgeInsets.fromLTRB(22, 26, 22, 36), child: _form()),
            ]),
          ),
        ),
      );

  Widget _hero() => Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
        decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFF3F7D7), Color(0xFFDCE8A7), AppColors.leaf]),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(color: AppColors.teal, borderRadius: BorderRadius.circular(13)),
              child: const Icon(Icons.water_drop, color: Colors.white),
            ),
            const SizedBox(width: 12),
            const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('equilibra', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.deep)),
              Text('SAÚDE & NUTRIÇÃO', style: TextStyle(fontSize: 8, letterSpacing: 1.4, color: Color(0xFF71814D))),
            ]),
          ]),
          const SizedBox(height: 36),
          const Eyebrow('Cuidado conectado'),
          const SizedBox(height: 8),
          const Text('Equilíbrio para cuidar da sua saúde todos os dias.', style: TextStyle(fontSize: 30, height: 1.1, fontWeight: FontWeight.w800, color: AppColors.deep, letterSpacing: -1)),
          const SizedBox(height: 12),
          const Text('Acompanhe sua alimentação, glicemia e orientações profissionais em um só lugar.', style: TextStyle(fontSize: 14, height: 1.6, color: Color(0xFF657343))),
        ]),
      );

  Widget _gap() => const SizedBox(height: 14);

  Widget _form() => Form(
        key: _key,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Eyebrow(creating ? 'Comece agora' : 'Bem-vindo de volta'),
          const SizedBox(height: 6),
          Text(creating ? 'Crie sua conta' : 'Entre na sua conta', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.deep)),
          const SizedBox(height: 6),
          Text(creating ? 'Preencha seus dados para acessar o Equilibra.' : 'Use seus dados para continuar seu acompanhamento.', style: const TextStyle(color: AppColors.muted)),
          const SizedBox(height: 22),
          if (creating) ...[
            TextFormField(controller: name, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'Nome completo'), validator: _required),
            _gap(),
          ],
          TextFormField(
            controller: email,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'E-mail', hintText: 'voce@email.com'),
            validator: (v) => (v ?? '').contains('@') ? null : 'Informe um e-mail válido',
          ),
          _gap(),
          if (creating) ...[
            TextFormField(
              controller: phone,
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, PhoneFormatter()],
              decoration: const InputDecoration(labelText: 'Telefone', hintText: '(11) 99999-9999'),
              validator: _required,
            ),
            _gap(),
            TextFormField(controller: birth, readOnly: true, onTap: _pickBirth, decoration: const InputDecoration(labelText: 'Data de nascimento', suffixIcon: Icon(Icons.calendar_today_outlined, size: 18)), validator: _required),
            _gap(),
            TextFormField(controller: city, decoration: const InputDecoration(labelText: 'Cidade', hintText: 'Cidade, estado'), validator: _required),
            _gap(),
          ],
          TextFormField(
            controller: password,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Senha', hintText: 'Mínimo de 6 caracteres'),
            validator: (v) => (v ?? '').length >= 6 ? null : 'Mínimo de 6 caracteres',
          ),
          if (!creating) Align(alignment: Alignment.centerRight, child: TextButton(onPressed: _forgot, child: const Text('Esqueci minha senha'))),
          _gap(),
          DropdownButtonFormField<String>(
            initialValue: role,
            decoration: const InputDecoration(labelText: 'Tipo de acesso'),
            items: const [
              DropdownMenuItem(value: 'patient', child: Text('Paciente')),
              DropdownMenuItem(value: 'nutritionist', child: Text('Nutricionista')),
            ],
            onChanged: (v) => setState(() => role = v ?? role),
          ),
          if (creating)
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: terms,
              onChanged: (v) => setState(() => terms = v ?? false),
              title: const Text('Li e aceito os termos de uso e a política de privacidade.', style: TextStyle(fontSize: 12)),
            ),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, child: FilledButton(onPressed: _submit, child: Text(creating ? 'Criar conta' : 'Entrar'))),
          const SizedBox(height: 14),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(creating ? 'Já possui uma conta?' : 'Ainda não possui uma conta?', style: const TextStyle(color: AppColors.muted, fontSize: 12)),
            TextButton(onPressed: () => setState(() { creating = !creating; _key.currentState?.reset(); }), child: Text(creating ? 'Entrar' : 'Criar conta')),
          ]),
        ]),
      );
}
