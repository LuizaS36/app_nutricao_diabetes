import 'package:flutter/material.dart';

import '../app_state.dart';
import '../data.dart';
import '../models.dart';
import '../nutrition.dart';
import '../taco_db.dart';
import '../theme.dart';

Future<void> _openSheet(BuildContext context, Widget child) =>
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          20 + MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: SingleChildScrollView(child: child),
      ),
    );

/// Registrar alimento. `food` pré-preenche a busca; `alimento` + `gramas`
/// já abrem com o alimento escolhido. `replaces` = item da dieta que foi trocado.
void showAddFoodSheet(
  BuildContext context,
  AppState state, {
  String meal = 'Café da manhã',
  String food = '',
  Alimento? alimento,
  double? gramas,
  String? replaces,
  required String date,
}) => _openSheet(
  context,
  _FoodForm(
    state: state,
    meal: meal,
    food: food,
    alimento: alimento,
    gramas: gramas,
    replaces: replaces,
    date: date,
  ),
);

/// Sugere trocas com as mesmas calorias (usa taco.substituir).
void showSubstituteSheet(
  BuildContext context,
  AppState state, {
  required String meal,
  required Alimento original,
  required double grams,
  required String date,
}) => _openSheet(
  context,
  _SubstituteList(
    host: context,
    state: state,
    meal: meal,
    original: original,
    grams: grams,
    date: date,
  ),
);

void showAddGlucoseSheet(BuildContext context, AppState state) =>
    _openSheet(context, _GlucoseForm(state: state));

void showAddMedicationSheet(BuildContext context, AppState state) =>
    _openSheet(context, _MedicationForm(state: state));

void showAddWaterSheet(BuildContext context, AppState state) =>
    _openSheet(context, _WaterForm(state: state));

class _SheetTitle extends StatelessWidget {
  const _SheetTitle(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Text(
      text,
      style: Theme.of(context).textTheme.titleLarge
          ?.copyWith(fontWeight: FontWeight.w800),
    ),
  );
}

class _FoodForm extends StatefulWidget {
  const _FoodForm({
    required this.state,
    required this.meal,
    required this.food,
    required this.date,
    this.alimento,
    this.gramas,
    this.replaces,
  });
  final AppState state;
  final String meal, food, date;
  final Alimento? alimento;
  final double? gramas;
  final String? replaces;
  @override
  State<_FoodForm> createState() => _FoodFormState();
}

class _FoodFormState extends State<_FoodForm> {
  final _key = GlobalKey<FormState>();
  late String meal = widget.meal;
  late final search = TextEditingController(text: widget.food);
  late final grams = TextEditingController(
    text: widget.gramas == null ? '' : fmtGramas(widget.gramas!),
  );
  Alimento? selected;
  List<Alimento> results = [];
  bool noResult = false;
  int _req = 0;

  @override
  void initState() {
    super.initState();
    selected = widget.alimento;
    if (selected == null && widget.food.trim().length >= 2) {
      _search(widget.food);
    }
  }

  @override
  void dispose() {
    search.dispose();
    grams.dispose();
    super.dispose();
  }

  /// Gramas digitadas (aceita vírgula). null se vazio ou inválido.
  double? get _g {
    final v = double.tryParse(grams.text.trim().replaceAll(',', '.'));
    return (v == null || v <= 0) ? null : v;
  }

  Future<void> _search(String q) async {
    final id = ++_req;
    if (q.trim().length < 2) {
      setState(() {
        results = [];
        noResult = false;
      });
      return;
    }
    final r = await Nutrition.instance.taco.buscar(q.trim(), limite: 6);
    if (!mounted || id != _req) return; // ignora resposta antiga
    setState(() {
      results = r;
      noResult = r.isEmpty;
    });
  }

  @override
  Widget build(BuildContext context) {
    final a = selected;
    final g = _g;
    final Macros? m = (a != null && g != null) ? Porcao(a, g).macros : null;
    return Form(
      key: _key,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SheetTitle(
            widget.replaces == null
                ? 'Registrar refeição'
                : 'Registrar substituição',
          ),
          if (widget.replaces != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'No lugar de: ${widget.replaces}',
                style: const TextStyle(fontSize: 12, color: AppColors.muted),
              ),
            ),
          DropdownButtonFormField<String>(
            initialValue: meal,
            decoration: const InputDecoration(labelText: 'Refeição'),
            items: [
              for (final x in meals)
                DropdownMenuItem(value: x.key, child: Text(x.key)),
            ],
            onChanged: (v) => setState(() => meal = v ?? meal),
          ),
          const SizedBox(height: 12),
          if (a == null) ...[
            TextField(
              controller: search,
              onChanged: _search,
              decoration: const InputDecoration(
                labelText: 'Alimento',
                hintText: 'Ex.: banana, arroz integral...',
                prefixIcon: Icon(Icons.search, size: 18),
              ),
            ),
            for (final r in results)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(r.nome),
                subtitle: Text('${fmtNum(r.por100g.kcal, 0)} kcal por 100 g'),
                onTap: () => setState(() {
                  selected = r;
                  results = [];
                  noResult = false;
                }),
              ),
            if (noResult)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'Nenhum alimento encontrado na TACO.',
                  style: TextStyle(fontSize: 12, color: AppColors.muted),
                ),
              ),
          ] else
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                a.nome,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text('${fmtNum(a.por100g.kcal, 0)} kcal por 100 g'),
              trailing: TextButton(
                onPressed: () => setState(() => selected = null),
                child: const Text('Trocar'),
              ),
            ),
          const SizedBox(height: 12),
          TextFormField(
            controller: grams,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'Quantidade',
              suffixText: 'g',
              hintText: 'Ex.: 100',
            ),
            validator: (_) => _g == null ? 'Informe as gramas' : null,
          ),
          if (m != null) ...[
            const SizedBox(height: 12),
            Text(
              '${fmtNum(m.kcal, 0)} kcal',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
            Text(
              'Proteína ${fmtNum(m.proteina)} g · Carboidrato ${fmtNum(m.carbo)} g · Gordura ${fmtNum(m.gordura)} g',
              style: const TextStyle(fontSize: 12, color: AppColors.muted),
            ),
            if (a != null && a.incompleto)
              const Text(
                'Alguns valores não foram medidos na TACO.',
                style: TextStyle(fontSize: 11, color: AppColors.muted),
              ),
          ],
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: a == null
                    ? null
                    : () {
                        if (!_key.currentState!.validate()) return;
                        final gg = _g!;
                        final mm = Porcao(a, gg).macros;
                        widget.state.addFood(
                          FoodLog(
                            id: DateTime.now().millisecondsSinceEpoch,
                            meal: meal,
                            name: a.nome,
                            amount: '${fmtGramas(gg)} g',
                            kcal: mm.kcal.round(),
                            date: widget.date,
                            protein: mm.proteina,
                            carbs: mm.carbo,
                            fat: mm.gordura,
                            tacoId: a.id,
                            grams: gg,
                            replaces: widget.replaces,
                          ),
                        );
                        Navigator.pop(context);
                      },
                child: const Text('Registrar'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Lista de substituições com as mesmas calorias do alimento original.
class _SubstituteList extends StatefulWidget {
  const _SubstituteList({
    required this.host,
    required this.state,
    required this.meal,
    required this.original,
    required this.grams,
    required this.date,
  });
  final BuildContext host; // contexto da tela, para abrir o próximo sheet
  final AppState state;
  final String meal, date;
  final Alimento original;
  final double grams;
  @override
  State<_SubstituteList> createState() => _SubstituteListState();
}

class _SubstituteListState extends State<_SubstituteList> {
  late final Future<List<Substituicao>> _future = Nutrition.instance.taco
      .substituir(widget.original, widget.grams);
  final search = TextEditingController();
  List<Alimento> results = [];
  bool noResult = false;
  int _req = 0;

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  Future<void> _search(String q) async {
    final id = ++_req;
    if (q.trim().length < 2) {
      setState(() {
        results = [];
        noResult = false;
      });
      return;
    }
    final r = await Nutrition.instance.taco.buscar(q.trim(), limite: 6);
    if (!mounted || id != _req) return; // ignora resposta antiga
    setState(() {
      results = r;
      noResult = r.isEmpty;
    });
  }

  /// Fecha esta folha e abre o registro já com o alimento escolhido.
  void _escolher(Alimento a, {double? gramas}) {
    Navigator.pop(context);
    showAddFoodSheet(
      widget.host,
      widget.state,
      meal: widget.meal,
      date: widget.date,
      alimento: a,
      gramas: gramas,
      replaces: widget.original.nome,
    );
  }

  Widget _tile(BuildContext context, Substituicao s) {
    final a = s.porcao.alimento;
    final m = s.porcao.macros;
    final u = s.porcao.micros;
    String mic(String label, double v, String campo, String unit) =>
        a.semDado.contains(campo) ? '$label —' : '$label ${fmtNum(v)} $unit';
    return ListTile(
      contentPadding: EdgeInsets.zero,
      isThreeLine: true,
      title: Text(
        '${a.nome} · ${fmtGramas(s.porcao.gramas)} g',
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        '${fmtNum(m.kcal, 0)} kcal · P ${fmtNum(m.proteina)} g · C ${fmtNum(m.carbo)} g · G ${fmtNum(m.gordura)} g\n'
        '${mic('Cálcio', u.calcio, 'calcio_mg', 'mg')} · ${mic('Ferro', u.ferro, 'ferro_mg', 'mg')} · ${mic('Fibra', u.fibra, 'fibra_g', 'g')}',
        style: const TextStyle(fontSize: 12),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _escolher(a, gramas: s.porcao.gramas),
    );
  }

  @override
  Widget build(BuildContext context) {
    final base = Porcao(widget.original, widget.grams);
    final bm = base.macros;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SheetTitle('Substituir ${widget.original.nome}'),
        Text(
          'Dieta: ${fmtGramas(widget.grams)} g · ${fmtNum(bm.kcal, 0)} kcal · P ${fmtNum(bm.proteina)} g · C ${fmtNum(bm.carbo)} g · G ${fmtNum(bm.gordura)} g',
          style: const TextStyle(fontSize: 12, color: AppColors.muted),
        ),
        const SizedBox(height: 4),
        const Text(
          'Sugestões com as mesmas calorias:',
          style: TextStyle(fontSize: 12, color: AppColors.muted),
        ),
        const SizedBox(height: 8),
        FutureBuilder<List<Substituicao>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (snap.hasError) {
              return const Padding(
                padding: EdgeInsets.all(12),
                child: Text('Não foi possível buscar substituições.'),
              );
            }
            final list = snap.data ?? const <Substituicao>[];
            if (list.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(12),
                child: Text('Nenhuma sugestão encontrada para este alimento.'),
              );
            }
            return Column(children: [for (final s in list) _tile(context, s)]);
          },
        ),
        const Divider(height: 28),
        const Text(
          'Comeu outra coisa?',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 2),
        const Text(
          'Busque o alimento que você realmente comeu e informe a quantidade.',
          style: TextStyle(fontSize: 12, color: AppColors.muted),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: search,
          onChanged: _search,
          decoration: const InputDecoration(
            labelText: 'Buscar alimento',
            hintText: 'Ex.: arroz branco',
            prefixIcon: Icon(Icons.search, size: 18),
          ),
        ),
        for (final r in results)
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: Text(r.nome),
            subtitle: Text('${fmtNum(r.por100g.kcal, 0)} kcal por 100 g'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _escolher(r),
          ),
        if (noResult)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'Nenhum alimento encontrado na TACO.',
              style: TextStyle(fontSize: 12, color: AppColors.muted),
            ),
          ),
      ],
    );
  }
}

class _GlucoseForm extends StatefulWidget {
  const _GlucoseForm({required this.state});
  final AppState state;
  @override
  State<_GlucoseForm> createState() => _GlucoseFormState();
}

class _GlucoseFormState extends State<_GlucoseForm> {
  static const contexts = [
    'Em jejum',
    'Antes do almoço',
    'Após o almoço',
    'Antes do jantar',
    'Após o jantar',
    'Antes de dormir',
  ];
  final _key = GlobalKey<FormState>();
  final value = TextEditingController();
  String ctx = contexts.first;

  @override
  void dispose() {
    value.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Form(
    key: _key,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Align(
          alignment: Alignment.centerLeft,
          child: _SheetTitle('Registrar glicemia'),
        ),
        TextFormField(
          controller: value,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Valor da glicemia',
            suffixText: 'mg/dL',
            hintText: '110',
          ),
          validator: (v) {
            final n = int.tryParse(v ?? '');
            return (n == null || n < 20 || n > 600)
                ? 'Informe um valor entre 20 e 600'
                : null;
          },
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: ctx,
          decoration: const InputDecoration(labelText: 'Momento da medição'),
          items: [
            for (final c in contexts)
              DropdownMenuItem(value: c, child: Text(c)),
          ],
          onChanged: (v) => setState(() => ctx = v ?? ctx),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: () {
                if (!_key.currentState!.validate()) return;
                final now = TimeOfDay.now();
                widget.state.addGlucose(
                  GlucoseLog(
                    id: DateTime.now().millisecondsSinceEpoch,
                    value: int.parse(value.text),
                    context: ctx,
                    time:
                        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
                  ),
                );
                Navigator.pop(context);
              },
              child: const Text('Salvar medição'),
            ),
          ],
        ),
      ],
    ),
  );
}

class _MedicationForm extends StatefulWidget {
  const _MedicationForm({required this.state});
  final AppState state;
  @override
  State<_MedicationForm> createState() => _MedicationFormState();
}

class _MedicationFormState extends State<_MedicationForm> {
  final _key = GlobalKey<FormState>();
  final name = TextEditingController();
  final dose = TextEditingController();
  final time = TextEditingController();
  String type = 'Medicamento';

  @override
  void dispose() {
    name.dispose();
    dose.dispose();
    time.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (t != null) {
      time.text =
          '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    }
  }

  @override
  Widget build(BuildContext context) => Form(
    key: _key,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Align(
          alignment: Alignment.centerLeft,
          child: _SheetTitle('Adicionar medicamento'),
        ),
        DropdownButtonFormField<String>(
          initialValue: type,
          decoration: const InputDecoration(labelText: 'Tipo'),
          items: [
            for (final t in ['Medicamento', 'Vitamina', 'Suplemento'])
              DropdownMenuItem(value: t, child: Text(t)),
          ],
          onChanged: (v) => setState(() => type = v ?? type),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: name,
          decoration: const InputDecoration(labelText: 'Nome'),
          validator: (v) => (v ?? '').trim().isEmpty ? 'Obrigatório' : null,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: dose,
                decoration: const InputDecoration(
                  labelText: 'Dose',
                  hintText: 'Ex.: 500mg',
                ),
                validator: (v) =>
                    (v ?? '').trim().isEmpty ? 'Obrigatório' : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: time,
                readOnly: true,
                onTap: _pickTime,
                decoration: const InputDecoration(labelText: 'Horário'),
                validator: (v) => (v ?? '').isEmpty ? 'Obrigatório' : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: () {
                if (!_key.currentState!.validate()) return;
                widget.state.addMedication(
                  Medication(
                    id: DateTime.now().millisecondsSinceEpoch,
                    name: name.text.trim(),
                    dose: dose.text.trim(),
                    time: time.text,
                    type: type,
                  ),
                );
                Navigator.pop(context);
              },
              child: const Text('Adicionar à rotina'),
            ),
          ],
        ),
      ],
    ),
  );
}

class _WaterForm extends StatefulWidget {
  const _WaterForm({required this.state});
  final AppState state;
  @override
  State<_WaterForm> createState() => _WaterFormState();
}

class _WaterFormState extends State<_WaterForm> {
  final _key = GlobalKey<FormState>();
  final ml = TextEditingController();

  @override
  void dispose() {
    ml.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Form(
    key: _key,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SheetTitle('Registrar água'),
        TextFormField(
          controller: ml,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Quantidade',
            suffixText: 'mL',
            hintText: 'Ex.: 250',
          ),
          validator: (v) {
            final n = int.tryParse((v ?? '').trim());
            return (n == null || n < 10 || n > 3000)
                ? 'Informe um valor entre 10 e 3000 mL'
                : null;
          },
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: [
            for (final v in const [150, 200, 250, 300, 500])
              ActionChip(
                label: Text('$v mL'),
                onPressed: () => setState(() => ml.text = '$v'),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: () {
                if (!_key.currentState!.validate()) return;
                widget.state.addWaterMl(int.parse(ml.text.trim()));
                Navigator.pop(context);
              },
              child: const Text('Adicionar'),
            ),
          ],
        ),
      ],
    ),
  );
}
