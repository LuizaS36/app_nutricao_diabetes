import 'package:flutter/material.dart';
import '../app_state.dart';
import '../data.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/confetti.dart';
import '../widgets/glucose_chart.dart';
import '../widgets/sheets.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key, required this.state});
  final AppState state;

  static const _goalKcal = 1880;

  @override
  Widget build(BuildContext context) => Stack(children: [
        _content(context),
        if (state.confetti) Positioned.fill(child: IgnorePointer(child: ConfettiLayer(onDone: state.endConfetti))),
      ]);

  Widget _content(BuildContext context) {
    final today = dateKey(DateTime.now());
    final todayLogs = state.foodLogs.where((f) => f.date == today).toList();
    final eaten = todayLogs.fold<int>(0, (s, f) => s + f.kcal);
    final latest = state.glucoseLogs.isEmpty ? null : state.glucoseLogs.first;

    return ListView(padding: const EdgeInsets.all(16), children: [
      PageHeading(eyebrow: 'Hoje', title: 'Olá, ${state.firstName}!', subtitle: 'Acompanhe seu dia por aqui.'),
      FilledButton.icon(
        onPressed: () => showAddGlucoseSheet(context, state),
        icon: const Icon(Icons.add),
        label: const Text('Registrar glicose'),
      ),
      const SizedBox(height: 16),
      // Calorias (somadas dos registros de hoje)
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
                SizedBox.expand(
                  child: CircularProgressIndicator(value: (eaten / _goalKcal).clamp(0, 1).toDouble(), strokeWidth: 10, backgroundColor: AppColors.mint, color: AppColors.teal),
                ),
                Column(mainAxisSize: MainAxisSize.min, children: [
                  Text('$eaten', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
                  const Text('de 1.880 kcal', style: TextStyle(fontSize: 10, color: AppColors.muted)),
                ]),
              ]),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Text(
                todayLogs.isEmpty
                    ? 'Nenhuma refeição registrada hoje. Toque no + de uma refeição abaixo para começar.'
                    : (eaten >= _goalKcal ? 'Meta diária atingida.' : 'Restam ${_goalKcal - eaten} kcal para a meta de hoje.'),
                style: const TextStyle(color: AppColors.muted, height: 1.5),
              ),
            ),
          ]),
        ]),
      ),
      // Glicemia (último registro)
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
            Text(latest == null ? '—' : '${latest.value}', style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w800)),
            const SizedBox(width: 6),
            const Padding(padding: EdgeInsets.only(bottom: 6), child: Text('mg/dL', style: TextStyle(color: AppColors.muted))),
            const Spacer(),
            if (latest != null)
              Chip(
                label: Text(latest.value > 140 ? 'Acima da meta' : 'Na meta'),
                backgroundColor: AppColors.mint,
                side: BorderSide.none,
                labelStyle: TextStyle(color: latest.value > 140 ? AppColors.warn : AppColors.teal, fontWeight: FontWeight.w700),
              ),
          ]),
          if (latest == null)
            const Text('Nenhuma medição ainda. Toque em "Registrar glicose".', style: TextStyle(fontSize: 12, color: AppColors.muted))
          else ...[
            const SizedBox(height: 10),
            const MiniGlucoseChart(),
          ],
        ]),
      ),
      // Refeições do dia
      const Padding(padding: EdgeInsets.only(top: 8, bottom: 8), child: Eyebrow('Plano de hoje')),
      for (final m in meals)
        AppCard(
          child: Row(children: [
            Stack(clipBehavior: Clip.none, children: [
              IconBubble(Icons.restaurant, color: mealColor(m.color)),
              if (todayLogs.any((f) => f.meal == m.key))
                const Positioned(right: -4, top: -4, child: CircleAvatar(radius: 8, backgroundColor: AppColors.teal, child: Icon(Icons.check, size: 11, color: Colors.white))),
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
      AppCard(onTap: () => state.setTab(2), child: _NextReminder(state.medications)),
    ]);
  }
}

class _NextReminder extends StatelessWidget {
  const _NextReminder(this.meds);
  final List<Medication> meds;

  @override
  Widget build(BuildContext context) {
    final pending = meds.where((m) => !m.done).toList()..sort((a, b) => a.time.compareTo(b.time));
    final next = pending.isEmpty ? null : pending.first;
    return Row(children: [
      const IconBubble(Icons.medication_outlined, color: AppColors.purple),
      const SizedBox(width: 12),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('PRÓXIMO LEMBRETE', style: TextStyle(fontSize: 10, color: AppColors.muted, fontWeight: FontWeight.w700)),
          Text(next?.name ?? 'Nenhum lembrete', style: const TextStyle(fontWeight: FontWeight.w700)),
          Text(next == null ? 'Cadastre medicamentos na aba Glicose' : '${next.dose} · ${next.type}', style: const TextStyle(fontSize: 12, color: AppColors.muted)),
        ]),
      ),
      if (next != null) Text(next.time, style: const TextStyle(fontWeight: FontWeight.w800)),
    ]);
  }
}
