import 'package:flutter/material.dart';
import '../app_state.dart';
import '../data.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/confetti.dart';
import '../widgets/glucose_chart.dart';
import '../widgets/sheets.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key, required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) => Stack(children: [
        _content(context),
        if (state.confetti) Positioned.fill(child: IgnorePointer(child: ConfettiLayer(onDone: state.endConfetti))),
      ]);

  Widget _content(BuildContext context) {
    final today = dateKey(DateTime.now());
    return ListView(padding: const EdgeInsets.all(16), children: [
      const PageHeading(eyebrow: 'Hoje', title: 'Olá, Marina!', subtitle: 'Seu dia está indo muito bem. Continue assim.'),
      FilledButton.icon(
        onPressed: () => showAddGlucoseSheet(context, state),
        icon: const Icon(Icons.add),
        label: const Text('Registrar glicose'),
      ),
      const SizedBox(height: 16),
      // Calorias
      AppCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const IconBubble(Icons.bar_chart_rounded),
            const SizedBox(width: 10),
            const Expanded(child: Text('Calorias', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16))),
            TextButton(onPressed: () => state.setTab(1), child: const Text('Ver detalhes')),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            SizedBox(
              width: 110,
              height: 110,
              child: Stack(alignment: Alignment.center, children: [
                const SizedBox.expand(
                  child: CircularProgressIndicator(value: .68, strokeWidth: 10, backgroundColor: AppColors.mint, color: AppColors.teal),
                ),
                const Column(mainAxisSize: MainAxisSize.min, children: [
                  Text('1.280', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
                  Text('de 1.880 kcal', style: TextStyle(fontSize: 10, color: AppColors.muted)),
                ]),
              ]),
            ),
            const SizedBox(width: 20),
            const Expanded(
              child: Column(children: [
                _Macro('Proteínas', 72, 105, AppColors.coral),
                _Macro('Carboidratos', 138, 210, AppColors.amber),
                _Macro('Gorduras', 42, 62, AppColors.purple),
              ]),
            ),
          ]),
        ]),
      ),
      // Glicemia
      AppCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const IconBubble(Icons.water_drop_outlined, color: AppColors.lime),
            const SizedBox(width: 10),
            const Expanded(child: Text('Glicemia', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16))),
            TextButton(onPressed: () => state.setTab(2), child: const Text('Histórico')),
          ]),
          const SizedBox(height: 8),
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            const Text('112', style: TextStyle(fontSize: 36, fontWeight: FontWeight.w800)),
            const SizedBox(width: 6),
            const Padding(padding: EdgeInsets.only(bottom: 6), child: Text('mg/dL', style: TextStyle(color: AppColors.muted))),
            const Spacer(),
            Chip(label: const Text('Na meta'), backgroundColor: AppColors.mint, side: BorderSide.none, labelStyle: const TextStyle(color: AppColors.teal, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 10),
          const MiniGlucoseChart(),
        ]),
      ),
      // Refeições do dia
      const Padding(padding: EdgeInsets.only(top: 8, bottom: 8), child: Eyebrow('Plano de hoje')),
      for (final m in meals)
        AppCard(
          child: Row(children: [
            Stack(clipBehavior: Clip.none, children: [
              IconBubble(Icons.restaurant, color: mealColor(m.color)),
              if (m.done) const Positioned(right: -4, top: -4, child: CircleAvatar(radius: 8, backgroundColor: AppColors.teal, child: Icon(Icons.check, size: 11, color: Colors.white))),
            ]),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${m.key} · ${m.time}', style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                Text(m.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                Text('${m.kcal} kcal · ${m.items.length} itens', style: const TextStyle(fontSize: 12, color: AppColors.muted)),
              ]),
            ),
            IconButton(
              tooltip: 'Registrar refeição',
              icon: const Icon(Icons.add_circle_outline, color: AppColors.teal),
              onPressed: () => showAddFoodSheet(context, state, meal: m.key, date: today),
            ),
          ]),
        ),
      // Hidratação
      AppCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const IconBubble(Icons.local_drink_outlined, color: AppColors.blue),
            const SizedBox(width: 10),
            const Expanded(child: Text('Hidratação', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16))),
            if (state.water >= 2.5) const Icon(Icons.star, color: Color(0xFFD4A928)),
            Text('${state.water.toStringAsFixed(1)}L / 2,5L', style: const TextStyle(fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(value: (state.water / 2.5).clamp(0, 1), minHeight: 10, color: AppColors.blue, backgroundColor: const Color(0xFFE6F0FB)),
          ),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: Text('${(state.water / 0.25).round()} copos de 250ml${state.water >= 2.5 ? ' · Meta alcançada' : ''}', style: const TextStyle(color: AppColors.muted, fontSize: 12))),
            OutlinedButton.icon(onPressed: state.addWater, icon: const Icon(Icons.add, size: 18), label: const Text('Adicionar copo')),
          ]),
        ]),
      ),
      // Próximo lembrete
      AppCard(
        onTap: () => state.setTab(2),
        child: const Row(children: [
          IconBubble(Icons.medication_outlined, color: AppColors.purple),
          SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('PRÓXIMO LEMBRETE', style: TextStyle(fontSize: 10, color: AppColors.muted, fontWeight: FontWeight.w700)),
              Text('Metformina', style: TextStyle(fontWeight: FontWeight.w700)),
              Text('500mg · Após o jantar', style: TextStyle(fontSize: 12, color: AppColors.muted)),
            ]),
          ),
          Text('20:00', style: TextStyle(fontWeight: FontWeight.w800)),
        ]),
      ),
    ]);
  }
}

class _Macro extends StatelessWidget {
  const _Macro(this.label, this.value, this.goal, this.color);
  final String label;
  final int value, goal;
  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.muted))),
            Text('${value}g / ${goal}g', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 3),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(value: value / goal, minHeight: 6, color: color, backgroundColor: color.withValues(alpha: .15)),
          ),
        ]),
      );
}
