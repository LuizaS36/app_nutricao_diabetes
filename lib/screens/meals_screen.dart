import 'package:flutter/material.dart';
import '../app_state.dart';
import '../data.dart';
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
  Widget build(BuildContext context) {
    final state = widget.state;
    final selectedDate = dateKey(_day(selected));
    return ListView(padding: const EdgeInsets.all(16), children: [
      const PageHeading(eyebrow: 'Plano alimentar', title: 'Minhas refeições', subtitle: 'Dieta atualizada pela Dra. Ana Lima.'),
      Row(children: [
        IconButton(onPressed: () => setState(() { center--; selected--; }), icon: const Icon(Icons.chevron_left)),
        for (var i = 0; i < 5; i++) _dayChip(center + i - 2),
        IconButton(onPressed: () => setState(() { center++; selected++; }), icon: const Icon(Icons.chevron_right)),
      ]),
      const SizedBox(height: 12),
      for (final m in meals) _mealCard(context, state, m, selectedDate),
    ]);
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
          child: Column(children: [
            Text(_wd[d.weekday - 1], style: TextStyle(fontSize: 10, color: isSel ? Colors.white70 : AppColors.muted)),
            Text('${d.day}', style: TextStyle(fontWeight: FontWeight.w800, color: isSel ? Colors.white : AppColors.text)),
          ]),
        ),
      ),
    );
  }

  Widget _mealCard(BuildContext context, AppState state, dynamic m, String date) {
    final added = state.foodLogs.where((f) => f.meal == m.key && f.date == date).toList();
    final consumed = added.fold<int>(0, (s, f) => s + f.kcal);
    return Card(
      child: ExpansionTile(
        initiallyExpanded: m.key == 'Café da manhã',
        shape: const Border(),
        collapsedShape: const Border(),
        leading: IconBubble(Icons.restaurant, color: mealColor(m.color)),
        title: Text('${m.key} · ${m.time}', style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text('$consumed de ${m.kcal} kcal consumidas', style: const TextStyle(fontSize: 12)),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Eyebrow('Dieta proposta'),
          const Text('Somente leitura · por Dra. Ana Lima', style: TextStyle(fontSize: 11, color: AppColors.muted)),
          const SizedBox(height: 6),
          Text((m.items as List<String>).join(' · ')),
          const SizedBox(height: 8),
          for (var i = 0; i < m.items.length; i++)
            ExpansionTile(
              dense: true,
              tilePadding: EdgeInsets.zero,
              shape: const Border(),
              collapsedShape: const Border(),
              title: Text("Substituir ${m.items[i].split(',').first.toLowerCase()}", style: const TextStyle(fontSize: 13, color: AppColors.teal)),
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(spacing: 8, children: [
                    for (final alt in m.itemAlternatives[i] as List<String>)
                      ActionChip(label: Text(alt), onPressed: () => showAddFoodSheet(context, state, meal: m.key, food: alt, date: date)),
                  ]),
                ),
              ],
            ),
          const SizedBox(height: 8),
          Text('Progresso da refeição · $consumed de ${m.kcal} kcal', style: const TextStyle(fontSize: 12, color: AppColors.muted)),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(value: (consumed / m.kcal).clamp(0, 1).toDouble(), minHeight: 8, color: AppColors.teal, backgroundColor: AppColors.mint),
          ),
          if (added.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text('Alimentos consumidos neste horário', style: TextStyle(fontWeight: FontWeight.w700)),
            for (final f in added)
              ListTile(dense: true, contentPadding: EdgeInsets.zero, title: Text(f.name), subtitle: Text('${f.amount} · ${f.kcal} kcal')),
          ],
          ExpansionTile(
            dense: true,
            tilePadding: EdgeInsets.zero,
            shape: const Border(),
            collapsedShape: const Border(),
            title: const Text('Substituir a refeição completa', style: TextStyle(fontSize: 13, color: AppColors.teal)),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Wrap(spacing: 8, children: [
                  for (final alt in m.alternatives as List<String>)
                    ActionChip(label: Text(alt), onPressed: () => showAddFoodSheet(context, state, meal: m.key, food: alt, date: date)),
                ]),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FilledButton.tonalIcon(
            onPressed: () => showAddFoodSheet(context, state, meal: m.key, date: date),
            icon: const Icon(Icons.add),
            label: const Text('Registrar refeição'),
          ),
        ],
      ),
    );
  }
}
