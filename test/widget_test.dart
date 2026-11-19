import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app_nutricao_diabetes/app_state.dart';

void main() {
  test('adicionar copo de água soma 250ml', () {
    final state = AppState();
    final before = state.water;
    state.addWater();
    expect(state.water, before + 0.25);
  });
}
