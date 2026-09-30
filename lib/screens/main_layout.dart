import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../providers/payments_provider.dart';
import '../providers/logs_provider.dart';
import '../services/sms_listener_service.dart';
import 'home/home_dashboard_screen.dart';
import 'payments/payments_screen.dart';
import 'logs/logs_screen.dart';
import 'settings/settings_screen.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;
  final SmsListenerService _smsListenerService = SmsListenerService();

  final List<Widget> _screens = const [
    HomeDashboardScreen(),
    PaymentsScreen(),
    LogsScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initServicesAndData();
    });
  }

  void _initServicesAndData() {
    final paymentsProv = Provider.of<PaymentsProvider>(context, listen: false);
    final logsProv = Provider.of<LogsProvider>(context, listen: false);

    paymentsProv.loadLocalPayments();
    logsProv.loadLogs();

    _smsListenerService.startListening(
      onTransactionProcessed: (txn) {
        paymentsProv.addOrUpdateTransaction(txn);
      },
      onLogAdded: (log) {
        logsProv.addLog(log);
      },
    );
  }

  @override
  void dispose() {
    _smsListenerService.stopListening();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppTheme.borderLight, width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: AppTheme.primaryBlue,
          unselectedItemColor: AppTheme.textMuted,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontSize: 12),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.payment_outlined),
              activeIcon: Icon(Icons.payment),
              label: 'Payments',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.article_outlined),
              activeIcon: Icon(Icons.article),
              label: 'Logs',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}
