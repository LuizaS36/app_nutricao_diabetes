import 'package:flutter/material.dart';

import 'app_state.dart';
import 'auth_service.dart';
import 'nutrition.dart';
import 'screens/auth_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/glucose_screen.dart';
import 'screens/meals_screen.dart';
import 'screens/messages_screen.dart';
import 'screens/nutritionist_patients_screen.dart';
import 'screens/profile_screen.dart';
import 'theme.dart';
import 'widgets/account_sheets.dart';
import 'widgets/common.dart';
import 'widgets/nutri_sheets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Nutrition.instance.init(); // banco da TACO
  await AuthService.init(); // Supabase (se configurado)
  final state = await AppState.load();
  await state.syncSession(); // confere se ainda ha login valido
  runApp(EquilibraApp(state: state));
}

class EquilibraApp extends StatelessWidget {
  const EquilibraApp({super.key, required this.state});
  final AppState state;
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Equilibra',
    debugShowCheckedModeBanner: false,
    theme: buildTheme(),
    home: RootScreen(state: state),
    scrollBehavior: const NoStretchScrollBehavior(),
  );
}

class _Nav {
  const _Nav(this.label, this.icon);
  final String label;
  final IconData icon;
}

const _patientNav = [
  _Nav('Visão geral', Icons.home_outlined),
  _Nav('Refeições', Icons.restaurant_outlined),
  _Nav('Glicose', Icons.water_drop_outlined),
  _Nav('Mensagens', Icons.chat_bubble_outline),
  _Nav('Perfil', Icons.person_outline),
];

const _nutriNav = [
  _Nav('Pacientes', Icons.groups_outlined),
  _Nav('Mensagens', Icons.chat_bubble_outline),
  _Nav('Perfil', Icons.person_outline),
];

class RootScreen extends StatelessWidget {
  const RootScreen({super.key, required this.state});
  final AppState state;

  Widget _body() {
    if (state.role == Role.patient) {
      return switch (state.tab) {
        0 => DashboardScreen(state: state),
        1 => MealsScreen(state: state),
        2 => GlucoseScreen(state: state),
        3 => MessagesScreen(state: state),
        _ => ProfileScreen(state: state),
      };
    }
    return switch (state.tab) {
      0 => NutritionistPatientsScreen(state: state),
      1 => MessagesScreen(state: state),
      _ => ProfileScreen(state: state),
    };
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: state,
    builder: (context, _) {
      if (!state.authenticated) return AuthScreen(state: state);
      final patient = state.role == Role.patient;
      final nav = patient ? _patientNav : _nutriNav;
      return Scaffold(
        appBar: AppBar(
          title: const Row(
            children: [
              Icon(Icons.water_drop, color: AppColors.teal),
              SizedBox(width: 8),
              Text('equilibra', style: TextStyle(fontWeight: FontWeight.w800)),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'Notificações',
              onPressed: () => patient
                  ? showNotificationSettingsSheet(context, state)
                  : showClinicalAlertsSheet(context, state),
              icon: patient
                  ? const Icon(Icons.notifications_none)
                  : Badge(
                      label: const Text('$clinicalAlertCount'),
                      backgroundColor: AppColors.danger,
                      child: const Icon(Icons.notifications_none),
                    ),
            ),
            InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => showUserSheet(context, state),
              child: Padding(
                padding: const EdgeInsets.only(right: 12, left: 4),
                child: InitialsAvatar(
                  _initials(state.profile.name),
                  radius: 16,
                ),
              ),
            ),
          ],
        ),
        body: SafeArea(child: _body()),
        bottomNavigationBar: NavigationBar(
          selectedIndex: state.tab,
          onDestinationSelected: state.setTab,
          destinations: [
            for (final n in nav)
              NavigationDestination(
                icon: n.label == 'Mensagens'
                    ? Badge(
                        label: const Text('2'),
                        backgroundColor: AppColors.danger,
                        child: Icon(n.icon),
                      )
                    : Icon(n.icon),
                label: n.label,
              ),
          ],
        ),
      );
    },
  );
}
class NoStretchScrollBehavior extends MaterialScrollBehavior {
  const NoStretchScrollBehavior();

  @override
  Widget buildOverscrollIndicator(BuildContext context, Widget child, ScrollableDetails details) => child;

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) => const ClampingScrollPhysics();
}

/// "Marina Costa" -> "MC"
String _initials(String name) {
  final p = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((s) => s.isNotEmpty)
      .toList();
  if (p.isEmpty) return '?';
  return (p.length == 1 ? p.first[0] : p.first[0] + p.last[0]).toUpperCase();
}
