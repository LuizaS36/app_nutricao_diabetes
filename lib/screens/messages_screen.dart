import 'package:flutter/material.dart';
import '../app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';

typedef _Contact = ({String name, String initials, String preview, String time, int unread});

class _Msg {
  _Msg(this.fromMe, this.text, this.time);
  final bool fromMe;
  final String text, time;
}

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key, required this.state});
  final AppState state;
  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  String selected = '';
  String _lastTarget = '';
  String search = '';
  final input = TextEditingController();
  final scroll = ScrollController();
  late final List<_Msg> messages = widget.state.role == Role.patient
      ? [_Msg(false, 'Olá, Marina! Como você se sentiu com o novo plano alimentar?', '09:34'), _Msg(true, 'Olá! Estou me adaptando bem. Gostei muito das opções de lanche.', '09:41')]
      : [_Msg(false, 'Olá, doutora! Estou me adaptando bem ao novo plano.', '09:34'), _Msg(true, 'Que bom! Vi que seus registros de glicose também estão ótimos.', '09:41')];

  List<_Contact> get contacts => widget.state.role == Role.patient
      ? [
          (name: 'Dra. Ana Lima', initials: 'AL', preview: 'Que bom! Até amanhã.', time: '09:41', unread: 1),
          (name: 'Equipe Equilibra', initials: 'EQ', preview: 'Seu relatório está disponível.', time: 'Ontem', unread: 0),
        ]
      : [
          (name: 'Marina Costa', initials: 'MC', preview: 'Estou me adaptando bem ao novo plano.', time: '09:41', unread: 2),
          (name: 'Clara Oliveira', initials: 'CO', preview: 'Enviei meus registros da semana.', time: '08:20', unread: 1),
          (name: 'Rafael Mendes', initials: 'RM', preview: 'Obrigado pelas novas orientações.', time: 'Ontem', unread: 0),
          (name: 'Paulo Nunes', initials: 'PN', preview: 'Podemos ajustar o jantar?', time: 'Seg', unread: 0),
        ];

  @override
  void initState() {
    super.initState();
    if (widget.state.role == Role.patient) selected = contacts.first.name;
  }

  @override
  void dispose() { input.dispose(); scroll.dispose(); super.dispose(); }

  void _send() {
    final t = input.text.trim();
    if (t.isEmpty) return;
    setState(() => messages.add(_Msg(true, t, 'Agora')));
    input.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scroll.hasClients) scroll.animateTo(scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
    });
  }

  @override
  Widget build(BuildContext context) {
    final target = widget.state.messageTarget;
    if (target.isNotEmpty && target != _lastTarget) {
      _lastTarget = target;
      selected = target;
    } else if (target.isEmpty) {
      _lastTarget = '';
    }
    return selected.isEmpty ? _inbox() : _conversation();
  }

  Widget _inbox() {
    final list = contacts.where((c) => c.name.toLowerCase().contains(search.toLowerCase())).toList();
    final unread = contacts.where((c) => c.unread > 0).length;
    return ListView(padding: const EdgeInsets.all(16), children: [
      PageHeading(
        eyebrow: 'Atendimento',
        title: 'Mensagens',
        subtitle: widget.state.role == Role.patient ? 'Converse com sua equipe de cuidado.' : 'Selecione uma conversa para falar com o paciente.',
      ),
      Card(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Todas as mensagens', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              Text('$unread conversas não lidas', style: const TextStyle(fontSize: 11, color: AppColors.muted)),
              const SizedBox(height: 12),
              TextField(
                onChanged: (v) => setState(() => search = v),
                decoration: const InputDecoration(prefixIcon: Icon(Icons.search, size: 18), hintText: 'Buscar conversa', isDense: true),
              ),
            ]),
          ),
          const Divider(height: 1),
          for (final c in list)
            ListTile(
              leading: InitialsAvatar(c.initials),
              title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              subtitle: Text(c.preview, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
              trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(c.time, style: const TextStyle(fontSize: 10, color: AppColors.muted)),
                if (c.unread > 0)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    width: 18,
                    height: 18,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(color: AppColors.teal, shape: BoxShape.circle),
                    child: Text('${c.unread}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
                  ),
              ]),
              onTap: () => setState(() => selected = c.name),
            ),
        ]),
      ),
    ]);
  }

  Widget _conversation() {
    final list = contacts;
    final c = list.firstWhere((x) => x.name == selected, orElse: () => (name: selected, initials: selected.isEmpty ? '?' : selected[0], preview: '', time: '', unread: 0));
    final maxW = MediaQuery.of(context).size.width * .75;
    return Column(children: [
      Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(8, 4, 16, 8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          TextButton(onPressed: () { widget.state.messageTarget = ''; setState(() { selected = ''; }); }, child: const Text('‹ Voltar para todas as mensagens')),
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Row(children: [
              InitialsAvatar(c.initials),
              const SizedBox(width: 10),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(c.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                const Row(children: [
                  CircleAvatar(radius: 3, backgroundColor: AppColors.teal),
                  SizedBox(width: 5),
                  Text('Online agora', style: TextStyle(fontSize: 11, color: AppColors.teal)),
                ]),
              ]),
            ]),
          ),
        ]),
      ),
      const Divider(height: 1),
      Expanded(
        child: ListView(controller: scroll, padding: const EdgeInsets.all(16), children: [
          const Center(child: Padding(padding: EdgeInsets.only(bottom: 14), child: Text('Hoje', style: TextStyle(fontSize: 11, color: AppColors.muted)))),
          for (final m in messages)
            Align(
              alignment: m.fromMe ? Alignment.centerRight : Alignment.centerLeft,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxW),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(crossAxisAlignment: m.fromMe ? CrossAxisAlignment.end : CrossAxisAlignment.start, children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: m.fromMe ? AppColors.teal : Colors.white,
                        border: Border.all(color: m.fromMe ? AppColors.teal : AppColors.line),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(m.fromMe ? 14 : 4),
                          topRight: Radius.circular(m.fromMe ? 4 : 14),
                          bottomLeft: const Radius.circular(14),
                          bottomRight: const Radius.circular(14),
                        ),
                      ),
                      child: Text(m.text, style: TextStyle(fontSize: 13, height: 1.5, color: m.fromMe ? Colors.white : AppColors.text)),
                    ),
                    Padding(padding: const EdgeInsets.only(top: 3), child: Text(m.time, style: const TextStyle(fontSize: 10, color: AppColors.muted))),
                  ]),
                ),
              ),
            ),
        ]),
      ),
      Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
        child: Row(children: [
          Expanded(
            child: TextField(
              controller: input,
              onSubmitted: (_) => _send(),
              decoration: const InputDecoration(hintText: 'Escreva uma mensagem...', isDense: true),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            style: IconButton.styleFrom(backgroundColor: AppColors.teal, foregroundColor: Colors.white),
            onPressed: _send,
            icon: const Icon(Icons.send_rounded, size: 18),
            tooltip: 'Enviar',
          ),
        ]),
      ),
    ]);
  }
}
