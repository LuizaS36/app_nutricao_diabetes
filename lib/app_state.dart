import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_repository.dart';
import 'data.dart';
import 'models.dart';

export 'models.dart' show Role;

String dateKey(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

String initialsOf(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  return parts.take(2).map((p) => p[0]).join().toUpperCase();
}

const _emptyProfile = ProfileInfo(name: '', email: '', phone: '', birthDate: '', city: '', detail1: '', detail2: '', detail3: '');
Map<String, bool> _defaultSettings() => {'reminders': true, 'messages': true, 'weekly': false};

/// Estado do app. Os dados de cada usuário ficam guardados POR CONTA
/// (userdata_<id>): cada login enxerga só o que é seu.
class AppState extends ChangeNotifier {
  AppState([AuthRepository? auth]) : auth = auth ?? AuthRepository();

  static const _sessionKey = 'session_v1';
  final AuthRepository auth;
  SharedPreferences? _prefs;

  static Future<AppState> load() async {
    final prefs = await SharedPreferences.getInstance();
    final s = AppState(AuthRepository(prefs));
    s._prefs = prefs;
    s._restoreSession();
    return s;
  }

  // ---- Sessão ----
  Account? account;
  bool get authenticated => account != null;
  Role get role => account?.role ?? Role.patient;

  int tab = 0;
  String messageTarget = ''; // contato a abrir na aba Mensagens

  // ---- Dados da conta atual ----
  ProfileInfo profile = _emptyProfile;
  Map<String, bool> settings = _defaultSettings();
  NotificationPrefs notif = NotificationPrefs();

  // Paciente
  double water = 0;
  bool confetti = false;
  final List<FoodLog> foodLogs = [];
  final List<GlucoseLog> glucoseLogs = [];
  final List<Medication> medications = [];

  // Nutricionista
  final List<Patient> patients = [];
  final Map<int, Map<String, DietEntry>> _diets = {};

  String get firstName {
    final n = profile.name.trim();
    return n.isEmpty ? 'Usuário' : n.split(RegExp(r'\s+')).first;
  }

  String get initials => initialsOf(profile.name);

  // ---- Autenticação ----

  /// Cria a conta no banco do [role] escolhido. Retorna a mensagem de erro, ou null se deu certo.
  String? signUp({
    required Role role,
    required String name,
    required String email,
    required String password,
    String phone = '',
    String birthDate = '',
    String city = '',
  }) {
    final acc = auth.register(role, email, password);
    if (acc == null) return 'Este e-mail já está cadastrado.';
    _beginSession(
      acc,
      fresh: ProfileInfo(name: name.trim(), email: acc.email, phone: phone, birthDate: birthDate, city: city.trim(), detail1: '', detail2: '', detail3: ''),
    );
    return null;
  }

  /// Só entra se e-mail, senha E tipo de acesso baterem com uma conta existente.
  String? signIn({required Role role, required String email, required String password}) {
    final acc = auth.login(role, email, password);
    if (acc == null) return 'E-mail, senha ou tipo de acesso incorretos.';
    _beginSession(acc);
    return null;
  }

  void logout() {
    account = null;
    tab = 0;
    messageTarget = '';
    _resetData();
    notifyListeners();
  }

  void _beginSession(Account acc, {ProfileInfo? fresh, bool notify = true}) {
    account = acc;
    tab = 0;
    messageTarget = '';
    _resetData();
    if (fresh != null) {
      profile = fresh;
    } else {
      profile = _emptyProfile.copyWith(email: acc.email);
      _restoreUserData();
    }
    if (notify) notifyListeners();
  }

  void _resetData() {
    water = 0;
    confetti = false;
    foodLogs.clear();
    glucoseLogs.clear();
    medications.clear();
    patients.clear();
    _diets.clear();
    notif = NotificationPrefs();
    settings = _defaultSettings();
    profile = _emptyProfile;
  }

  // ---- Navegação ----
  void setTab(int i) { tab = i; messageTarget = ''; notifyListeners(); }

  /// Abre a aba Mensagens já na conversa com [name].
  void openChat(String name) {
    messageTarget = name;
    tab = role == Role.patient ? 3 : 1;
    notifyListeners();
  }

  // ---- Paciente ----
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

  // ---- Nutricionista ----
  void addPatient(Patient p) { patients.add(p); notifyListeners(); }

  /// Dieta do paciente (se ainda não foi editada, usa o plano padrão).
  Map<String, DietEntry> dietFor(int patientId) =>
      _diets[patientId] ??
      {for (final m in meals) m.key: DietEntry(time: m.time, title: m.title, items: m.items.join('\n'))};

  void saveDiet(int patientId, Map<String, DietEntry> plan) {
    _diets[patientId] = {for (final e in plan.entries) e.key: e.value.copy()};
    notifyListeners();
  }

  // ---- Perfil ----
  void saveProfile(ProfileInfo p) { profile = p; notifyListeners(); }

  bool setting(Role r, String key) => settings[key] ?? false;
  void toggleSetting(Role r, String key) {
    settings[key] = !setting(r, key);
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
    final acc = account;
    if (acc == null) {
      p.remove(_sessionKey);
      return;
    }
    p.setString(_sessionKey, jsonEncode({'id': acc.id, 'role': acc.role.name}));
    p.setString('userdata_${acc.id}', jsonEncode(_userJson()));
  }

  Map<String, dynamic> _userJson() => {
        'water': water,
        'foodLogs': foodLogs.map((e) => e.toJson()).toList(),
        'glucoseLogs': glucoseLogs.map((e) => e.toJson()).toList(),
        'medications': medications.map((e) => e.toJson()).toList(),
        'patients': patients.map((e) => e.toJson()).toList(),
        'diets': _diets.map((k, v) => MapEntry('$k', v.map((mk, e) => MapEntry(mk, e.toJson())))),
        'profile': profile.toJson(),
        'settings': settings,
        'notif': notif.toJson(),
      };

  void _restoreSession() {
    final raw = _prefs?.getString(_sessionKey);
    if (raw == null) return;
    try {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      final role = j['role'] == 'nutritionist' ? Role.nutritionist : Role.patient;
      final acc = auth.byId(role, j['id'] as String);
      if (acc != null) _beginSession(acc, notify: false);
    } catch (_) {}
  }

  void _restoreUserData() {
    final acc = account;
    final raw = acc == null ? null : _prefs?.getString('userdata_${acc.id}');
    if (raw == null) return;
    try {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      water = (j['water'] as num?)?.toDouble() ?? 0;

      List<T> list<T>(String k, T Function(Map<String, dynamic>) f) =>
          ((j[k] as List?) ?? const []).map((e) => f(Map<String, dynamic>.from(e as Map))).toList();

      foodLogs..clear()..addAll(list('foodLogs', FoodLog.fromJson));
      glucoseLogs..clear()..addAll(list('glucoseLogs', GlucoseLog.fromJson));
      medications..clear()..addAll(list('medications', Medication.fromJson));
      patients..clear()..addAll(list('patients', Patient.fromJson));

      (j['diets'] as Map?)?.forEach((k, v) {
        _diets[int.parse(k as String)] = {
          for (final e in (v as Map).entries) e.key as String: DietEntry.fromJson(Map<String, dynamic>.from(e.value as Map)),
        };
      });
      if (j['profile'] != null) profile = ProfileInfo.fromJson(Map<String, dynamic>.from(j['profile'] as Map));
      final st = j['settings'] as Map?;
      if (st != null) settings = {for (final e in st.entries) e.key as String: e.value == true};
      if (j['notif'] != null) notif = NotificationPrefs.fromJson(Map<String, dynamic>.from(j['notif'] as Map));
    } catch (_) {
      // dado salvo inválido: segue com os valores vazios
    }
  }
}
