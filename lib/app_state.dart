import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'data.dart';
import 'models.dart';

enum Role { patient, nutritionist }

String dateKey(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Equivale aos useState/localStorage do App() no React.
/// Qualquer mudança chama notifyListeners() e é salva no aparelho (shared_preferences).
class AppState extends ChangeNotifier {
  static const _storageKey = 'equilibra_state_v1';
  SharedPreferences? _prefs;

  static Future<AppState> load() async {
    final s = AppState();
    s._prefs = await SharedPreferences.getInstance();
    s._restore();
    return s;
  }

  // ---- Sessão e navegação ----
  bool authenticated = false;
  Role role = Role.patient;
  int tab = 0;
  String messageTarget = ''; // contato a abrir na aba Mensagens

  // ---- Paciente ----
  double water = 1.5;
  bool confetti = false;
  final List<FoodLog> foodLogs = [];
  final List<GlucoseLog> glucoseLogs = initialGlucose();
  final List<Medication> medications = initialMedications();
  NotificationPrefs notif = NotificationPrefs();

  // ---- Nutricionista ----
  final List<Patient> patients = [...initialPatients];
  final Map<int, Map<String, DietEntry>> _diets = {};

  // ---- Perfis e configurações ----
  final Map<Role, ProfileInfo> profiles = {
    Role.patient: const ProfileInfo(
      name: 'Marina Costa', email: 'marina.costa@email.com', phone: '(11) 98765-4321',
      birthDate: '14 de setembro de 1988', city: 'São Paulo, SP',
      detail1: '1,67 m', detail2: '72,4 kg', detail3: '68 kg', diabetes: 'Diabetes Tipo 2',
    ),
    Role.nutritionist: const ProfileInfo(
      name: 'Dra. Ana Lima', email: 'ana.lima@equilibra.com', phone: '(11) 98765-4321',
      birthDate: '08 de abril de 1985', city: 'São Paulo, SP',
      detail1: '12345', detail2: 'Nutrição clínica', detail3: 'Seg a Sex, 08h às 18h',
    ),
  };
  final Map<String, Map<String, bool>> settings = {
    'patient': {'reminders': true, 'messages': true, 'weekly': false},
    'nutritionist': {'reminders': true, 'messages': true, 'weekly': false},
  };

  ProfileInfo get profile => profiles[role]!;

  // ---- Ações: sessão ----
  void authenticate(Role r, {bool creating = false, String name = '', String email = '', String phone = '', String birthDate = '', String city = ''}) {
    if (creating) {
      profiles[r] = profiles[r]!.copyWith(name: name, email: email, phone: phone, birthDate: birthDate, city: city);
    }
    role = r;
    tab = 0;
    authenticated = true;
    notifyListeners();
  }

  void logout() {
    authenticated = false;
    role = Role.patient;
    tab = 0;
    messageTarget = '';
    notifyListeners();
  }

  void setRole(Role r) { role = r; tab = 0; messageTarget = ''; notifyListeners(); }
  void setTab(int i) { tab = i; messageTarget = ''; notifyListeners(); }

  /// Abre a aba Mensagens já na conversa com [name].
  void openChat(String name) {
    messageTarget = name;
    tab = role == Role.patient ? 3 : 1;
    notifyListeners();
  }

  // ---- Ações: paciente ----
  void addWater() {
    final before = water;
    water = double.parse((water + 0.25).toStringAsFixed(2));
    if (before < 2.5 && water >= 2.5) confetti = true;
    notifyListeners();
  }

  void endConfetti() { confetti = false; notifyListeners(); }

  void addFood(FoodLog f) { foodLogs.add(f); notifyListeners(); }
  void addGlucose(GlucoseLog g) { glucoseLogs.insert(0, g); notifyListeners(); }
  void addMedication(Medication m) { medications.add(m); notifyListeners(); }
  void removeMedication(int id) { medications.removeWhere((m) => m.id == id); notifyListeners(); }
  void saveNotif(NotificationPrefs p) { notif = p.copy(); notifyListeners(); }

  // ---- Ações: nutricionista ----
  void addPatient(Patient p) { patients.add(p); notifyListeners(); }

  /// Dieta do paciente (se ainda não foi editada, usa o plano padrão).
  Map<String, DietEntry> dietFor(int patientId) =>
      _diets[patientId] ??
      {for (final m in meals) m.key: DietEntry(time: m.time, title: m.title, items: m.items.join('\n'))};

  void saveDiet(int patientId, Map<String, DietEntry> plan) {
    _diets[patientId] = {for (final e in plan.entries) e.key: e.value.copy()};
    notifyListeners();
  }

  // ---- Ações: perfil ----
  void saveProfile(Role r, ProfileInfo p) { profiles[r] = p; notifyListeners(); }

  bool setting(Role r, String key) => settings[r.name]![key] ?? false;
  void toggleSetting(Role r, String key) {
    settings[r.name]![key] = !setting(r, key);
    notifyListeners();
  }

  // ---- Persistência ----
  @override
  void notifyListeners() {
    super.notifyListeners();
    _persist();
  }

  void _persist() {
    final p = _prefs;
    if (p == null) return;
    p.setString(_storageKey, jsonEncode(_toJson()));
  }

  Map<String, dynamic> _toJson() => {
        'authenticated': authenticated,
        'role': role.name,
        'water': water,
        'foodLogs': foodLogs.map((e) => e.toJson()).toList(),
        'glucoseLogs': glucoseLogs.map((e) => e.toJson()).toList(),
        'medications': medications.map((e) => e.toJson()).toList(),
        'patients': patients.map((e) => e.toJson()).toList(),
        'diets': _diets.map((k, v) => MapEntry('$k', v.map((mk, e) => MapEntry(mk, e.toJson())))),
        'profiles': {for (final e in profiles.entries) e.key.name: e.value.toJson()},
        'settings': settings,
        'notif': notif.toJson(),
      };

  void _restore() {
    final raw = _prefs?.getString(_storageKey);
    if (raw == null) return;
    try {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      authenticated = j['authenticated'] == true;
      role = j['role'] == 'nutritionist' ? Role.nutritionist : Role.patient;
      water = (j['water'] as num?)?.toDouble() ?? water;

      List<T> list<T>(String k, T Function(Map<String, dynamic>) f) =>
          (j[k] as List).map((e) => f(Map<String, dynamic>.from(e as Map))).toList();

      if (j['foodLogs'] != null) { foodLogs..clear()..addAll(list('foodLogs', FoodLog.fromJson)); }
      if (j['glucoseLogs'] != null) { glucoseLogs..clear()..addAll(list('glucoseLogs', GlucoseLog.fromJson)); }
      if (j['medications'] != null) { medications..clear()..addAll(list('medications', Medication.fromJson)); }
      if (j['patients'] != null) { patients..clear()..addAll(list('patients', Patient.fromJson)); }

      (j['diets'] as Map?)?.forEach((k, v) {
        _diets[int.parse(k as String)] = {
          for (final e in (v as Map).entries) e.key as String: DietEntry.fromJson(Map<String, dynamic>.from(e.value as Map)),
        };
      });
      final pr = j['profiles'] as Map?;
      if (pr != null) {
        for (final r in Role.values) {
          final v = pr[r.name];
          if (v != null) profiles[r] = ProfileInfo.fromJson(Map<String, dynamic>.from(v as Map));
        }
      }
      final st = j['settings'] as Map?;
      if (st != null) {
        for (final e in st.entries) {
          settings[e.key as String] = {for (final x in (e.value as Map).entries) x.key as String: x.value == true};
        }
      }
      if (j['notif'] != null) notif = NotificationPrefs.fromJson(Map<String, dynamic>.from(j['notif'] as Map));
    } catch (_) {
      // dado salvo inválido: ignora e usa os valores padrão
    }
  }
}
