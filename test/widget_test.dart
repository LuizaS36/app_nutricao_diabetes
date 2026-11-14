import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app_nutricao_diabetes/app_state.dart';

void main() {
  AppState novo() => AppState();

  String? cadastrar(AppState s, Role role, String email, {String senha = '123456'}) =>
      s.signUp(role: role, name: 'Teste Silva', email: email, password: senha);

  test('paciente não consegue entrar como nutricionista (e vice-versa)', () {
    final s = novo();
    expect(cadastrar(s, Role.patient, 'paciente@email.com'), isNull);
    s.logout();

    expect(s.signIn(role: Role.nutritionist, email: 'paciente@email.com', password: '123456'), isNotNull);
    expect(s.authenticated, isFalse);

    expect(s.signIn(role: Role.patient, email: 'paciente@email.com', password: 'errada1'), isNotNull);
    expect(s.authenticated, isFalse);

    expect(s.signIn(role: Role.patient, email: ' Paciente@Email.com ', password: '123456'), isNull);
    expect(s.authenticated, isTrue);
    expect(s.role, Role.patient);
  });

  test('o mesmo e-mail não pode existir nos dois tipos', () {
    final s = novo();
    expect(cadastrar(s, Role.nutritionist, 'x@email.com'), isNull);
    s.logout();
    expect(cadastrar(s, Role.patient, 'x@email.com'), isNotNull);
  });

  test('cada conta enxerga só os próprios dados', () {
    final s = novo();
    cadastrar(s, Role.patient, 'a@email.com');
    s.addWater();
    expect(s.water, 0.25);
    s.logout();
    cadastrar(s, Role.patient, 'b@email.com');
    expect(s.water, 0);
  });
}

