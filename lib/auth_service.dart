// auth_service.dart
// Conta de usuário (cadastro, login, sair) usando o Supabase.
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_config.dart';

class AuthResult {
  const AuthResult({
    required this.ok,
    this.message,
    this.needsConfirmation = false,
  });
  final bool ok;
  final String? message; // erro, ou aviso (ex.: confirmar e-mail)
  final bool needsConfirmation; // true: conta criada, falta confirmar o e-mail
}

class AuthService {
  AuthService._();
  static bool _ready = false;

  /// As chaves foram preenchidas em supabase_config.dart?
  static bool get configured =>
      SupabaseConfig.url.isNotEmpty && SupabaseConfig.anonKey.isNotEmpty;

  /// Supabase configurado E iniciado.
  static bool get enabled => configured && _ready;

  /// URL limpa: tira barras no final e sufixos como /rest/v1 ou /auth/v1.
  static String get _url => SupabaseConfig.url
      .trim()
      .replaceAll(RegExp(r'/+$'), '')
      .replaceAll(RegExp(r'/(rest|auth)/v1$'), '');

  static Future<void> init() async {
    if (!configured) {
      debugPrint(
        '[Supabase] NÃO configurado: url tem ${SupabaseConfig.url.length} caracteres e a chave tem ${SupabaseConfig.anonKey.length}. Confira o arquivo lib/supabase_config.dart e salve. O app usa o login local.',
      );
      return;
    }
    if (_ready) return;
    try {
      await Supabase.initialize(
        url: _url,
        anonKey: SupabaseConfig.anonKey.trim(),
      );
      _ready = true;
      debugPrint('[Supabase] iniciado em $_url');
    } catch (e) {
      debugPrint('[Supabase] ERRO ao iniciar: $e');
    }
  }

  static SupabaseClient get _c => Supabase.instance.client;
  static bool get hasSession => enabled && _c.auth.currentSession != null;
  static User? get user => enabled ? _c.auth.currentUser : null;

  /// Cria a conta. O perfil (tabela `perfil`) é criado pelo banco, por um trigger,
  /// usando os dados enviados em `data`.
  static Future<AuthResult> signUp({
    required String email,
    required String password,
    required String name,
    required String role, // 'paciente' | 'nutricionista'
    String phone = '',
    String birthDate = '',
    String city = '',
  }) async {
    if (!enabled)
      return const AuthResult(ok: false, message: 'Supabase não configurado.');
    try {
      final res = await _c.auth.signUp(
        email: email.trim(),
        password: password,
        data: {
          'nome': name.trim(),
          'papel': role,
          'telefone': phone,
          'data_nascimento': birthDate,
          'cidade': city,
        },
      );
      debugPrint(
        '[Supabase] signUp ok: user=${res.user?.id} sessao=${res.session != null}',
      );
      if (res.user == null)
        return const AuthResult(
          ok: false,
          message: 'Não foi possível criar a conta.',
        );
      final precisaConfirmar = res.session == null;
      return AuthResult(
        ok: true,
        needsConfirmation: precisaConfirmar,
        message: precisaConfirmar
            ? 'Conta criada! Enviamos um e-mail para confirmar o cadastro.'
            : null,
      );
    } on AuthException catch (e) {
      debugPrint('[Supabase] signUp ERRO (${e.statusCode}): ${e.message}');
      return AuthResult(ok: false, message: _traduz(e.message));
    } catch (e) {
      debugPrint('[Supabase] signUp FALHOU: $e');
      return AuthResult(ok: false, message: 'Falha ao conectar: $e');
    }
  }

  static Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    if (!enabled)
      return const AuthResult(ok: false, message: 'Supabase não configurado.');
    try {
      await _c.auth.signInWithPassword(email: email.trim(), password: password);
      debugPrint('[Supabase] signIn ok');
      return const AuthResult(ok: true);
    } on AuthException catch (e) {
      debugPrint('[Supabase] signIn ERRO (${e.statusCode}): ${e.message}');
      return AuthResult(ok: false, message: _traduz(e.message));
    } catch (e) {
      debugPrint('[Supabase] signIn FALHOU: $e');
      return AuthResult(ok: false, message: 'Falha ao conectar: $e');
    }
  }

  static Future<void> signOut() async {
    if (!enabled) return;
    try {
      await _c.auth.signOut();
    } catch (_) {}
  }

  /// Linha da tabela `perfil` do usuário logado (ou null).
  static Future<Map<String, dynamic>?> loadPerfil() async {
    final u = user;
    if (u == null) return null;
    try {
      return await _c.from('perfil').select().eq('id', u.id).maybeSingle();
    } catch (_) {
      return null;
    }
  }

  static String _traduz(String msg) {
    final m = msg.toLowerCase();
    if (m.contains('invalid login')) return 'E-mail ou senha incorretos.';
    if (m.contains('already registered') ||
        m.contains('already been registered'))
      return 'Este e-mail já está cadastrado.';
    if (m.contains('at least'))
      return 'A senha precisa ter pelo menos 6 caracteres.';
    if (m.contains('not confirmed'))
      return 'Confirme seu e-mail antes de entrar.';
    if (m.contains('valid email') || m.contains('invalid email'))
      return 'E-mail inválido.';
    if (m.contains('rate limit'))
      return 'Muitas tentativas. Aguarde um pouco e tente de novo.';
    return msg;
  }
}
