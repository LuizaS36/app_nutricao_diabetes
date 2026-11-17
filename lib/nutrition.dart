// nutrition.dart
// Liga o plano alimentar do app ao banco da TACO (taco_db.dart).
import 'taco_db.dart';

/// Item do plano: um alimento da TACO (pelo id) + a quantidade em gramas.
class PlanItem {
  const PlanItem(this.tacoId, this.grams);
  final int tacoId;
  final double grams;
}

/// PLANO DE EXEMPLO, já com alimentos da TACO. A chave é o nome da refeição
/// (o mesmo `key` usado em data.dart).
/// A TACO não tem granola nem sopa pronta, então foram usados equivalentes.
/// Quando a nutricionista montar o plano de verdade, é aqui (ou no Supabase)
/// que ficam os ids e as gramas.
const planByMeal = <String, List<PlanItem>>{
  'Café da manhã': [
    PlanItem(448, 170), // Iogurte, natural
    PlanItem(182, 80), //  Banana, prata, crua (~1 unidade)
    PlanItem(7, 30), //    Aveia, flocos, crua (no lugar da granola)
  ],
  'Almoço': [
    PlanItem(410, 120), // Frango, peito, sem pele, grelhado
    PlanItem(1, 100), //   Arroz, integral, cozido
    PlanItem(100, 75), //  Brócolis, cozido
    PlanItem(109, 75), //  Cenoura, cozida
  ],
  'Lanche': [
    PlanItem(222, 130), // Maçã, Fuji, com casca, crua (~1 unidade)
    PlanItem(589, 20), //  Castanha-do-Brasil, crua
  ],
  'Jantar': [
    PlanItem(64, 100), //  Abóbora, cabotian, cozida (sopa)
    PlanItem(70, 100), //  Abobrinha, italiana, cozida (sopa)
    PlanItem(109, 100), // Cenoura, cozida (sopa)
    PlanItem(328, 80), //  Carne, bovina, acém, sem gordura, cozido
    PlanItem(52, 50), //   Pão, trigo, forma, integral
  ],
};

/// Acesso único ao banco. Chame `await Nutrition.instance.init()` no main().
class Nutrition {
  Nutrition._();
  static final Nutrition instance = Nutrition._();

  final TacoDb taco = TacoDb();
  final Map<int, Alimento> _cache = {};

  Future<void>? _initFuture;

  /// Carrega na memória os alimentos do plano (assim as telas leem sem await).
  /// Pode ser chamado várias vezes: só carrega uma vez.
  Future<void> init() => _initFuture ??= _load();

  Future<void> _load() async {
    for (final items in planByMeal.values) {
      for (final i in items) {
        if (_cache.containsKey(i.tacoId)) continue;
        final a = await taco.porId(i.tacoId);
        if (a != null) _cache[a.id] = a;
      }
    }
  }

  /// Porções (alimento + gramas) de uma refeição do plano.
  List<Porcao> portions(String mealKey) => [
    for (final i in planByMeal[mealKey] ?? const <PlanItem>[])
      if (_cache[i.tacoId] != null) Porcao(_cache[i.tacoId]!, i.grams),
  ];

  /// Macros somados de uma refeição do plano.
  Macros mealMacros(String mealKey) =>
      portions(mealKey).fold<Macros>(const Macros(), (s, p) => s + p.macros);

  /// Macros somados do dia inteiro (meta do dia = soma do plano).
  Macros dayMacros() =>
      planByMeal.keys.fold<Macros>(const Macros(), (s, k) => s + mealMacros(k));
}

/// 12.5 -> "12,5"   (d = casas decimais)
String fmtNum(double v, [int d = 1]) =>
    v.toStringAsFixed(d).replaceAll('.', ',');

/// 170.0 -> "170" ; 62.5 -> "62,5"
String fmtGramas(double g) =>
    g == g.roundToDouble() ? g.round().toString() : fmtNum(g);
