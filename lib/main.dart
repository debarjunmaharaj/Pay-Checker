import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/payments_provider.dart';
import 'providers/logs_provider.dart';
import 'providers/settings_provider.dart';
import 'services/background_service.dart';
import 'services/notification_service.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/main_layout.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await NotificationService().init();
    await BackgroundService.initialize();
    await BackgroundService.registerPeriodicTask();
  } catch (e) {
    debugPrint('Background service init warning: $e');
  }

  runApp(const PayCheckerApp());
}

class PayCheckerApp extends StatelessWidget {
  const PayCheckerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..loadSavedState()),
        ChangeNotifierProvider(create: (_) => PaymentsProvider()),
        ChangeNotifierProvider(create: (_) => LogsProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()..initSettings()),
      ],
      child: MaterialApp(
        title: 'Pay Checker',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const AnimatedSplashScreen(),
      ),
    );
  }
}

class AppInitializer extends StatelessWidget {
  const AppInitializer({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    if (auth.isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(strokeWidth: 3, color: AppTheme.primaryBlue),
              ),
              SizedBox(height: 16),
              Text(
                'Pay Checker',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (auth.isConnected) {
      return const MainLayout();
    }

    return const OnboardingScreen();
  }
}
