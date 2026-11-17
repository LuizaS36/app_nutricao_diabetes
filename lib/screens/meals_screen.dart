import 'package:flutter/material.dart';

import '../app_state.dart';
import '../data.dart';
import '../models.dart';
import '../nutrition.dart';
import '../taco_db.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/sheets.dart';

class MealsScreen extends StatefulWidget {
  const MealsScreen({super.key, required this.state});
  final AppState state;
  @override
  State<MealsScreen> createState() => _MealsScreenState();
}

class _MealsScreenState extends State<MealsScreen> {
  static const _wd = ['SEG', 'TER', 'QUA', 'QUI', 'SEX', 'SÁB', 'DOM'];
  int center = 0; // deslocamento (em dias) do dia central
  int selected = 0; // deslocamento do dia selecionado

  DateTime _day(int off) => DateTime.now().add(Duration(days: off));

  @override
  Widget build(BuildContext context) => FutureBuilder<void>(
    future: Nutrition.instance.init(),
    builder: (context, snap) {
      if (snap.hasError)
        return Center(
          child: Text('Erro ao abrir o banco da TACO:\n${snap.error}'),
        );
      if (snap.connectionState != ConnectionState.done)
        return const Center(child: CircularProgressIndicator());
      return _content(context);
    },
  );

  Widget _content(BuildContext context) {
    final state = widget.state;
    final selectedDate = dateKey(_day(selected));
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const PageHeading(
          eyebrow: 'Plano alimentar',
          title: 'Minhas refeições',
          subtitle: 'Dieta atualizada pela Dra. Ana Lima.',
        ),
        Row(
          children: [
            IconButton(
              onPressed: () => setState(() {
                center--;
                selected--;
              }),
              icon: const Icon(Icons.chevron_left),
            ),
            for (var i = 0; i < 5; i++) _dayChip(center + i - 2),
            IconButton(
              onPressed: () => setState(() {
                center++;
                selected++;
              }),
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
        const SizedBox(height: 12),
        for (final m in meals) _mealCard(context, state, m, selectedDate),
      ],
    );
  }

  Widget _dayChip(int off) {
    final d = _day(off);
    final isSel = off == selected;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selected = off),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSel ? AppColors.teal : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE6ECEA)),
          ),
          child: Column(
            children: [
              Text(
                _wd[d.weekday - 1],
                style: TextStyle(
                  fontSize: 10,
                  color: isSel ? Colors.white70 : AppColors.muted,
                ),
              ),
              Text(
                '${d.day}',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: isSel ? Colors.white : AppColors.text,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Exclui um registro de consumo (com opção de desfazer).
  void _deleteFood(BuildContext context, AppState state, FoodLog f) {
    state.removeFood(f.id);
    final bar = ScaffoldMessenger.of(context);
    bar.hideCurrentSnackBar();
    bar.showSnackBar(
      SnackBar(
        content: Text('${f.name} excluído.'),
        action: SnackBarAction(
          label: 'Desfazer',
          onPressed: () => state.addFood(f),
        ),
      ),
    );
  }

  Widget _mealCard(BuildContext context, AppState state, Meal m, String date) {
    final nutri = Nutrition.instance;
    final List<Porcao> portions = nutri.portions(m.key);
    final planKcal = nutri.mealMacros(m.key).kcal.round();
    final added = state.foodLogs
        .where((f) => f.meal == m.key && f.date == date)
        .toList();
    final consumed = added.fold<int>(0, (s, f) => s + f.kcal);
    final replaced = <String>{
      for (final f in added)
        if (f.replaces != null) f.replaces!,
    };
    return Card(
      child: ExpansionTile(
        initiallyExpanded: m.key == 'Café da manhã',
        shape: const Border(),
        collapsedShape: const Border(),
        leading: IconBubble(Icons.restaurant, color: mealColor(m.color)),
        title: Text(
          '${m.key} · ${m.time}',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          '$consumed de $planKcal kcal consumidas',
          style: const TextStyle(fontSize: 12),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Eyebrow('Dieta proposta'),
          const Text(
            'Somente leitura · por Dra. Ana Lima',
            style: TextStyle(fontSize: 11, color: AppColors.muted),
          ),
          const SizedBox(height: 6),
          for (final p in portions)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Expanded(child: Text(p.alimento.nome)),
                  Text(
                    '${fmtGramas(p.gramas)} g · ${fmtNum(p.macros.kcal, 0)} kcal',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          ExpansionTile(
            dense: true,
            tilePadding: EdgeInsets.zero,
            shape: const Border(),
            collapsedShape: const Border(),
            title: const Text(
              'Substituir um alimento',
              style: TextStyle(fontSize: 13, color: AppColors.teal),
            ),
            children: [
              const Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Text(
                    'Escolha o item da dieta que você trocou:',
                    style: TextStyle(fontSize: 11, color: AppColors.muted),
                  ),
                ),
              ),
              for (final p in portions)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    p.alimento.nome,
                    style: const TextStyle(fontSize: 13),
                  ),
                  subtitle: Text(
                    '${fmtGramas(p.gramas)} g · ${fmtNum(p.macros.kcal, 0)} kcal${replaced.contains(p.alimento.nome) ? ' · já substituído' : ''}',
                    style: const TextStyle(fontSize: 11),
                  ),
                  trailing: const Icon(
                    Icons.swap_horiz,
                    size: 18,
                    color: AppColors.teal,
                  ),
                  onTap: () => showSubstituteSheet(
                    context,
                    state,
                    meal: m.key,
                    original: p.alimento,
                    grams: p.gramas,
                    date: date,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Progresso da refeição · $consumed de $planKcal kcal',
            style: const TextStyle(fontSize: 12, color: AppColors.muted),
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: planKcal == 0
                  ? 0.0
                  : (consumed / planKcal).clamp(0.0, 1.0).toDouble(),
              minHeight: 8,
              color: AppColors.teal,
              backgroundColor: AppColors.mint,
            ),
          ),
          if (added.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'Alimentos consumidos neste horário',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            for (final f in added)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(f.name),
                subtitle: Text(
                  '${f.amount} · ${f.kcal} kcal${f.replaces != null ? ' · no lugar de ${f.replaces}' : ''}',
                ),
                trailing: IconButton(
                  tooltip: 'Excluir registro',
                  icon: const Icon(
                    Icons.delete_outline,
                    size: 20,
                    color: AppColors.muted,
                  ),
                  onPressed: () => _deleteFood(context, state, f),
                ),
              ),
          ],
          ExpansionTile(
            dense: true,
            tilePadding: EdgeInsets.zero,
            shape: const Border(),
            collapsedShape: const Border(),
            title: const Text(
              'Substituir a refeição completa',
              style: TextStyle(fontSize: 13, color: AppColors.teal),
            ),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 8,
                  children: [
                    for (final alt in m.alternatives)
                      ActionChip(
                        label: Text(alt),
                        onPressed: () => showAddFoodSheet(
                          context,
                          state,
                          meal: m.key,
                          food: alt,
                          date: date,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FilledButton.tonalIcon(
            onPressed: () =>
                showAddFoodSheet(context, state, meal: m.key, date: date),
            icon: const Icon(Icons.add),
            label: const Text('Registrar refeição'),
          ),
        ],
      ),
    );
  }
}
