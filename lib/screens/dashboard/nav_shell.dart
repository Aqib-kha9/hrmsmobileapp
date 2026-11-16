import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import 'dashboard_screen.dart';
import '../attendance/attendance_screen.dart';
import '../leave/leave_screen.dart';
import '../payroll/payroll_screen.dart';
import '../loans/loans_screen.dart';
import '../profile/profile_screen.dart';
import '../notifications/notifications_screen.dart';

enum AppNavTab { home, attendance, leave, payroll, loans }

class NavShell extends StatefulWidget {
  const NavShell({super.key});

  @override
  State<NavShell> createState() => _NavShellState();
}

class _NavShellState extends State<NavShell> {
  int _currentIndex = 0;

  // Keep screen references for state preservation, but only render the active one.
  final Map<AppNavTab, GlobalKey> _screenKeys = {
    AppNavTab.home: GlobalKey(),
    AppNavTab.attendance: GlobalKey(),
    AppNavTab.leave: GlobalKey(),
    AppNavTab.payroll: GlobalKey(),
    AppNavTab.loans: GlobalKey(),
  };

  @override
  void initState() {
    super.initState();
    // Load dashboard data on app start
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<DashboardProvider>().loadDashboard();
    });
  }

  List<AppNavTab> _getAvailableTabs(bool showLeave) {
    if (showLeave) {
      return const [
        AppNavTab.home,
        AppNavTab.attendance,
        AppNavTab.leave,
        AppNavTab.payroll,
        AppNavTab.loans,
      ];
    }
    return const [
      AppNavTab.home,
      AppNavTab.attendance,
      AppNavTab.payroll,
      AppNavTab.loans,
    ];
  }

  void _navigateToLogicalTab(int logicalIndex, List<AppNavTab> availableTabs) {
    AppNavTab targetTab;
    switch (logicalIndex) {
      case 0:
        targetTab = AppNavTab.home;
        break;
      case 1:
        targetTab = AppNavTab.attendance;
        break;
      case 2:
        targetTab = AppNavTab.leave;
        break;
      case 3:
        targetTab = AppNavTab.payroll;
        break;
      case 4:
        targetTab = AppNavTab.loans;
        break;
      default:
        targetTab = AppNavTab.home;
    }

    final targetIndex = availableTabs.indexOf(targetTab);
    if (targetIndex != -1 && targetIndex != _currentIndex) {
      setState(() => _currentIndex = targetIndex);
    }
  }

  Widget _buildScreenForTab(AppNavTab tab, List<AppNavTab> availableTabs) {
    switch (tab) {
      case AppNavTab.home:
        return DashboardScreen(
          key: _screenKeys[AppNavTab.home],
          onNavigate: (logicalIndex) => _navigateToLogicalTab(logicalIndex, availableTabs),
        );
      case AppNavTab.attendance:
        return AttendanceScreen(key: _screenKeys[AppNavTab.attendance]);
      case AppNavTab.leave:
        return LeaveScreen(key: _screenKeys[AppNavTab.leave]);
      case AppNavTab.payroll:
        return PayrollScreen(key: _screenKeys[AppNavTab.payroll]);
      case AppNavTab.loans:
        return LoansScreen(key: _screenKeys[AppNavTab.loans]);
    }
  }

  BottomNavigationBarItem _buildBarItem(AppNavTab tab) {
    switch (tab) {
      case AppNavTab.home:
        return const BottomNavigationBarItem(
          icon: Icon(Icons.dashboard_rounded),
          activeIcon: Icon(Icons.dashboard_rounded),
          label: 'Home',
        );
      case AppNavTab.attendance:
        return const BottomNavigationBarItem(
          icon: Icon(Icons.fingerprint_outlined),
          activeIcon: Icon(Icons.fingerprint),
          label: 'Attendance',
        );
      case AppNavTab.leave:
        return const BottomNavigationBarItem(
          icon: Icon(Icons.beach_access_outlined),
          activeIcon: Icon(Icons.beach_access),
          label: 'Leave',
        );
      case AppNavTab.payroll:
        return const BottomNavigationBarItem(
          icon: Icon(Icons.account_balance_wallet_outlined),
          activeIcon: Icon(Icons.account_balance_wallet),
          label: 'Payroll',
        );
      case AppNavTab.loans:
        return const BottomNavigationBarItem(
          icon: Icon(Icons.credit_card_outlined),
          activeIcon: Icon(Icons.credit_card),
          label: 'Loans',
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthProvider>();
    final employee = auth.currentEmployee;
    final bool showLeave = employee?.isLeaveAllowed ?? true;
    final availableTabs = _getAvailableTabs(showLeave);

    // Safeguard current index bounds when tabs change dynamically
    if (_currentIndex >= availableTabs.length) {
      _currentIndex = 0;
    }

    final activeTab = availableTabs[_currentIndex];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Company logo
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.all(3),
                child: Image.asset(
                  'assets/images/company_logo.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.workspaces_outline,
                    color: AppColors.primary,
                    size: 18,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'HRMS',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 17,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, size: 22),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              );
            },
            tooltip: 'Notifications',
          ),
          IconButton(
            icon: const Icon(Icons.person_outline, size: 22),
            onPressed: _navigateToProfile,
            tooltip: 'Profile',
          ),
        ],
      ),
      body: _buildScreenForTab(activeTab, availableTabs),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: AppColors.surface,
        elevation: 8,
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
          if (availableTabs[index] == AppNavTab.home) {
            context.read<DashboardProvider>().loadDashboard();
          }
        },
        items: availableTabs.map(_buildBarItem).toList(),
      ),
    );
  }

  void _navigateToProfile() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ProfileScreen()),
    );
  }
}
