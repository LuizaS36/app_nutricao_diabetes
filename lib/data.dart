import 'models.dart';

const meals = <Meal>[
  Meal(key: 'Café da manhã', time: '07:30', title: 'Iogurte com frutas e granola', kcal: 380, done: true, color: 'peach',
    items: ['Iogurte natural, 170g', 'Banana, 1 unidade', 'Granola sem açúcar, 30g'],
    itemAlternatives: [['Leite desnatado, 200ml', 'Iogurte vegetal, 170g'], ['Mamão, ½ unidade', 'Maçã, 1 unidade'], ['Aveia em flocos, 30g', 'Chia, 20g']],
    alternatives: ['Omelete com pão integral', 'Mingau de aveia com morangos']),
  Meal(key: 'Almoço', time: '12:30', title: 'Frango grelhado com legumes', kcal: 540, done: true, color: 'green',
    items: ['Peito de frango, 120g', 'Arroz integral, 100g', 'Brócolis e cenoura, 150g'],
    itemAlternatives: [['Peixe assado, 120g', 'Carne magra, 100g'], ['Quinoa cozida, 100g', 'Batata-doce, 130g'], ['Abobrinha e couve-flor, 150g', 'Salada verde, 150g']],
    alternatives: ['Peixe assado com batata-doce', 'Carne magra com quinoa']),
  Meal(key: 'Lanche', time: '16:00', title: 'Frutas com oleaginosas', kcal: 230, done: false, color: 'yellow',
    items: ['Maçã, 1 unidade', 'Castanhas, 20g'],
    itemAlternatives: [['Pera, 1 unidade', 'Banana, 1 unidade'], ['Amêndoas, 20g', 'Pasta de amendoim, 1 colher']],
    alternatives: ['Iogurte com chia', 'Torrada integral com ricota']),
  Meal(key: 'Jantar', time: '19:30', title: 'Sopa de legumes com carne', kcal: 420, done: false, color: 'purple',
    items: ['Sopa de legumes, 300ml', 'Carne desfiada, 80g', 'Torrada integral, 2 unidades'],
    itemAlternatives: [['Creme de abóbora, 300ml', 'Caldo de legumes, 300ml'], ['Frango desfiado, 80g', 'Tofu grelhado, 100g'], ['Pão integral, 1 fatia', 'Biscoito de arroz, 3 unidades']],
    alternatives: ['Salada completa com atum', 'Omelete de legumes']),
];

List<GlucoseLog> initialGlucose() => [
      GlucoseLog(id: 1, value: 112, context: 'Em jejum', time: '07:42'),
      GlucoseLog(id: 2, value: 124, context: 'Após o almoço', time: '13:50'),
      GlucoseLog(id: 3, value: 98, context: 'Antes do jantar', time: '19:12'),
      GlucoseLog(id: 4, value: 132, context: 'Após o jantar', time: '21:08'),
      GlucoseLog(id: 5, value: 106, context: 'Em jejum', time: '07:36'),
      GlucoseLog(id: 6, value: 145, context: 'Após o almoço', time: '14:02'),
    ];

List<Medication> initialMedications() => [
      Medication(id: 1, name: 'Metformina', dose: '500mg', time: '08:00', type: 'Medicamento', done: true),
      Medication(id: 2, name: 'Vitamina D', dose: '1 cápsula', time: '12:30', type: 'Vitamina', done: true),
      Medication(id: 3, name: 'Metformina', dose: '500mg', time: '20:00', type: 'Medicamento'),
    ];

const initialPatients = <Patient>[
  Patient(id: 1, name: 'Marina Costa', initials: 'MC', condition: 'Diabetes tipo 2', last: 'Hoje, 08:42', glucose: 112, status: 'Estável'),
  Patient(id: 2, name: 'Rafael Mendes', initials: 'RM', condition: 'Pré-diabetes', last: 'Ontem, 19:20', glucose: 98, status: 'Estável'),
  Patient(id: 3, name: 'Clara Oliveira', initials: 'CO', condition: 'Diabetes tipo 1', last: 'Hoje, 07:10', glucose: 164, status: 'Atenção'),
  Patient(id: 4, name: 'Paulo Nunes', initials: 'PN', condition: 'Diabetes tipo 2', last: '2 dias atrás', glucose: 126, status: 'Estável'),
];
