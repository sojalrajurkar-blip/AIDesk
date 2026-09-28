import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'screens/login_screen.dart';
import 'screens/requester_dashboard_screen.dart';
import 'screens/operator_dashboard_screen.dart';
import 'screens/manager_dashboard_screen.dart';
import 'screens/admin_users_screen.dart';
import 'screens/admin_audit_logs_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthState()),
        ChangeNotifierProvider(create: (_) => NotificationService()),
      ],
      child: const AiOfficeHelpDeskApp(),
    ),
  );
}

class AiOfficeHelpDeskApp extends StatelessWidget {
  const AiOfficeHelpDeskApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DeskAI Operations — Autonomous IT Help Desk',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const RoleRouter(),
    );
  }
}

class RoleRouter extends StatefulWidget {
  const RoleRouter({super.key});

  @override
  State<RoleRouter> createState() => _RoleRouterState();
}

class _RoleRouterState extends State<RoleRouter> {
  int _adminNavIndex = 0;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();

    if (!auth.isAuthenticated) {
      return const LoginScreen();
    }

    final role = auth.currentRole.toUpperCase();

    switch (role) {
      case 'REQUESTER':
        return const RequesterDashboardScreen();
      case 'OPERATOR':
      case 'TEAM_LEAD':
        return const OperatorDashboardScreen();
      case 'MANAGER':
        return const ManagerDashboardScreen();
      case 'ADMIN':
        // Super Admin Navigation Shell (Governance & Audit)
        return Scaffold(
          body: IndexedStack(
            index: _adminNavIndex,
            children: const [
              AdminAuditLogsScreen(),
              AdminUsersScreen(),
              ManagerDashboardScreen(),
              OperatorDashboardScreen(),
            ],
          ),
          bottomNavigationBar: Container(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppTheme.border, width: 1)),
              color: Colors.white,
            ),
            child: BottomNavigationBar(
              currentIndex: _adminNavIndex,
              onTap: (idx) => setState(() => _adminNavIndex = idx),
              type: BottomNavigationBarType.fixed,
              selectedItemColor: AppTheme.primary,
              unselectedItemColor: AppTheme.textMuted,
              selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.verified_user_outlined),
                  activeIcon: Icon(Icons.verified_user),
                  label: 'WORM Audit Ledger',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.people_outline),
                  activeIcon: Icon(Icons.people),
                  label: 'RBAC Users',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.insights_outlined),
                  activeIcon: Icon(Icons.insights),
                  label: 'Manager KPIs',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.queue_outlined),
                  activeIcon: Icon(Icons.queue),
                  label: 'Operator Workstation',
                ),
              ],
            ),
          ),
        );
      default:
        return const RequesterDashboardScreen();
    }
  }
}
