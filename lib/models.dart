enum Role { patient, nutritionist }

class GlucoseLog {
  GlucoseLog({required this.id, required this.value, required this.context, required this.time});
  final int id;
  final int value;
  final String context;
  final String time;
  Map<String, dynamic> toJson() => {'id': id, 'value': value, 'context': context, 'time': time};
  factory GlucoseLog.fromJson(Map<String, dynamic> j) =>
      GlucoseLog(id: j['id'] as int, value: j['value'] as int, context: j['context'] as String, time: j['time'] as String);
}

class FoodLog {
  FoodLog({required this.id, required this.meal, required this.name, required this.amount, required this.kcal, required this.date});
  final int id;
  final String meal;
  final String name;
  final String amount;
  final int kcal;
  final String date; // yyyy-MM-dd
  Map<String, dynamic> toJson() => {'id': id, 'meal': meal, 'name': name, 'amount': amount, 'kcal': kcal, 'date': date};
  factory FoodLog.fromJson(Map<String, dynamic> j) => FoodLog(
      id: j['id'] as int, meal: j['meal'] as String, name: j['name'] as String, amount: j['amount'] as String, kcal: j['kcal'] as int, date: j['date'] as String);
}

class Medication {
  Medication({required this.id, required this.name, required this.dose, required this.time, required this.type, this.done = false});
  final int id;
  final String name;
  final String dose;
  final String time;
  final String type;
  bool done;
  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'dose': dose, 'time': time, 'type': type, 'done': done};
  factory Medication.fromJson(Map<String, dynamic> j) => Medication(
      id: j['id'] as int, name: j['name'] as String, dose: j['dose'] as String, time: j['time'] as String, type: j['type'] as String, done: j['done'] == true);
}

class Meal {
  const Meal({
    required this.key,
    required this.time,
    required this.title,
    required this.kcal,
    required this.done,
    required this.color,
    required this.items,
    required this.itemAlternatives,
    required this.alternatives,
  });
  final String key;
  final String time;
  final String title;
  final int kcal;
  final bool done;
  final String color;
  final List<String> items;
  final List<List<String>> itemAlternatives;
  final List<String> alternatives;
}

class Patient {
  const Patient({required this.id, required this.name, required this.initials, required this.condition, required this.last, required this.glucose, required this.status});
  final int id;
  final String name;
  final String initials;
  final String condition;
  final String last;
  final int glucose;
  final String status;
  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'initials': initials, 'condition': condition, 'last': last, 'glucose': glucose, 'status': status};
  factory Patient.fromJson(Map<String, dynamic> j) => Patient(
      id: j['id'] as int, name: j['name'] as String, initials: j['initials'] as String, condition: j['condition'] as String,
      last: j['last'] as String, glucose: j['glucose'] as int, status: j['status'] as String);
}

/// Uma refeição do plano alimentar editável pela nutricionista.
class DietEntry {
  DietEntry({required this.time, required this.title, required this.items});
  String time;
  String title;
  String items; // um alimento por linha
  DietEntry copy() => DietEntry(time: time, title: title, items: items);
  Map<String, dynamic> toJson() => {'time': time, 'title': title, 'items': items};
  factory DietEntry.fromJson(Map<String, dynamic> j) => DietEntry(time: j['time'] as String, title: j['title'] as String, items: j['items'] as String);
}

class ProfileInfo {
  const ProfileInfo({
    required this.name,
    required this.email,
    required this.phone,
    required this.birthDate,
    required this.city,
    required this.detail1,
    required this.detail2,
    required this.detail3,
    this.diabetes = '',
  });
  final String name, email, phone, birthDate, city, detail1, detail2, detail3, diabetes;

  ProfileInfo copyWith({String? name, String? email, String? phone, String? birthDate, String? city, String? detail1, String? detail2, String? detail3, String? diabetes}) =>
      ProfileInfo(
        name: name ?? this.name,
        email: email ?? this.email,
        phone: phone ?? this.phone,
        birthDate: birthDate ?? this.birthDate,
        city: city ?? this.city,
        detail1: detail1 ?? this.detail1,
        detail2: detail2 ?? this.detail2,
        detail3: detail3 ?? this.detail3,
        diabetes: diabetes ?? this.diabetes,
      );

  Map<String, dynamic> toJson() => {
        'name': name, 'email': email, 'phone': phone, 'birthDate': birthDate, 'city': city,
        'detail1': detail1, 'detail2': detail2, 'detail3': detail3, 'diabetes': diabetes,
      };
  factory ProfileInfo.fromJson(Map<String, dynamic> j) => ProfileInfo(
        name: j['name'] as String, email: j['email'] as String, phone: j['phone'] as String,
        birthDate: j['birthDate'] as String, city: j['city'] as String, detail1: j['detail1'] as String,
        detail2: j['detail2'] as String, detail3: j['detail3'] as String, diabetes: (j['diabetes'] as String?) ?? '',
      );
}

class NotificationPrefs {
  NotificationPrefs({this.meals = true, this.medication = true, this.waterInterval = '2'});
  bool meals;
  bool medication;
  String waterInterval; // horas; '0' = desativado
  NotificationPrefs copy() => NotificationPrefs(meals: meals, medication: medication, waterInterval: waterInterval);
  Map<String, dynamic> toJson() => {'meals': meals, 'medication': medication, 'waterInterval': waterInterval};
  factory NotificationPrefs.fromJson(Map<String, dynamic> j) =>
      NotificationPrefs(meals: j['meals'] != false, medication: j['medication'] != false, waterInterval: (j['waterInterval'] as String?) ?? '2');
}
