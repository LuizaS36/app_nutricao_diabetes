import 'package:flutter/material.dart';
import 'app_state.dart';
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
  final state = await AppState.load();
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
              title: const Row(children: [
                Icon(Icons.water_drop, color: AppColors.teal),
                SizedBox(width: 8),
                Text('equilibra', style: TextStyle(fontWeight: FontWeight.w800)),
              ]),
              actions: [
                IconButton(
                  tooltip: 'Notificações',
                  onPressed: () => patient ? showNotificationSettingsSheet(context, state) : showClinicalAlertsSheet(context, state),
                  icon: (patient || patientsNeedingAttention(state).isEmpty)
                      ? const Icon(Icons.notifications_none)
                      : Badge(label: Text('${patientsNeedingAttention(state).length}'), backgroundColor: AppColors.danger, child: const Icon(Icons.notifications_none)),
                ),
                InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => showUserSheet(context, state),
                  child: Padding(
                    padding: const EdgeInsets.only(right: 12, left: 4),
                    child: InitialsAvatar(state.initials, radius: 16),
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
                    icon: Icon(n.icon),
                    label: n.label,
                  ),
              ],
            ),
          );
        },
      );
}
