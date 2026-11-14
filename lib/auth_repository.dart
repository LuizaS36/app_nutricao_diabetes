import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';

/// Conta de acesso. A senha NUNCA é guardada: só o hash (com salt aleatório).
class Account {
  Account({required this.id, required this.email, required this.role, required this.salt, required this.hash});
  final String id, email, salt, hash;
  final Role role;

  Map<String, dynamic> toJson() => {'id': id, 'email': email, 'salt': salt, 'hash': hash};
  factory Account.fromJson(Map<String, dynamic> j, Role role) => Account(
        id: j['id'] as String,
        email: j['email'] as String,
        role: role,
        salt: j['salt'] as String,
        hash: j['hash'] as String,
      );
}

/// "Banco de dados" de logins. Pacientes e nutricionistas ficam em listas
/// SEPARADAS: o login só procura na lista do tipo escolhido.
///
/// Hoje é guardado no próprio aparelho (shared_preferences). A interface
/// (register/login/byId) foi pensada para trocar depois por um servidor
/// (Firebase Auth, Supabase etc.) sem mexer nas telas.
class AuthRepository {
  AuthRepository([this._prefs]) {
    for (final r in Role.values) {
      _load(r);
    }
  }

  final SharedPreferences? _prefs;
  final Map<Role, List<Account>> _accounts = {for (final r in Role.values) r: <Account>[]};

  static String _storeKey(Role r) => 'accounts_${r.name}_v1';
  static String normalize(String email) => email.trim().toLowerCase();

  void _load(Role r) {
    final raw = _prefs?.getString(_storeKey(r));
    if (raw == null) return;
    try {
      final list = (jsonDecode(raw) as List).map((e) => Account.fromJson(Map<String, dynamic>.from(e as Map), r));
      _accounts[r]!
        ..clear()
        ..addAll(list);
    } catch (_) {
      // dado inválido: ignora
    }
  }

  void _save(Role r) {
    _prefs?.setString(_storeKey(r), jsonEncode(_accounts[r]!.map((a) => a.toJson()).toList()));
  }

  /// O mesmo e-mail não pode existir em nenhum dos dois tipos.
  bool emailTaken(String email) {
    final e = normalize(email);
    return Role.values.any((r) => _accounts[r]!.any((a) => a.email == e));
  }

  /// Cria a conta. Retorna null se o e-mail já estiver cadastrado.
  Account? register(Role role, String email, String password) {
    final e = normalize(email);
    if (emailTaken(e)) return null;
    final salt = _randomString(16);
    final acc = Account(id: _randomString(8), email: e, role: role, salt: salt, hash: _hash(password, salt));
    _accounts[role]!.add(acc);
    _save(role);
    return acc;
  }

  /// Só procura na lista do [role] escolhido. Retorna null se algo não bater.
  Account? login(Role role, String email, String password) {
    final e = normalize(email);
    for (final a in _accounts[role]!) {
      if (a.email == e) return a.hash == _hash(password, a.salt) ? a : null;
    }
    return null;
  }

  Account? byId(Role role, String id) {
    for (final a in _accounts[role]!) {
      if (a.id == id) return a;
    }
    return null;
  }

  static String _randomString(int bytes) {
    final r = Random.secure();
    return base64UrlEncode(List<int>.generate(bytes, (_) => r.nextInt(256)));
  }

  static String _hash(String password, String salt) {
    final saltBytes = utf8.encode(salt);
    List<int> bytes = utf8.encode('$salt:$password');
    for (var i = 0; i < 20000; i++) {
      bytes = sha256.convert([...bytes, ...saltBytes]).bytes;
    }
    return base64Encode(bytes);
  }
}
