import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/manager_dashboard_screen.dart';
import 'screens/admin_dashboard_screen.dart';
import 'screens/driver_dashboard_screen.dart';
import 'theme/app_theme.dart';
import 'widgets/notification_listener.dart' as notif_widget;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthService>(create: (_) => AuthService()),
      ],
      child: notif_widget.DriverNotificationListener(
        child: MaterialApp(
          title: AppTheme.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.darkTheme,
          initialRoute: '/',
          routes: {
            '/': (context) => const AuthWrapper(),
            '/login': (context) => const LoginScreen(),
            '/register': (context) => const RegisterScreen(),
            '/driver': (context) => const DriverDashboardScreen(),
            '/manager': (context) => const ManagerDashboardScreen(),
            '/admin': (context) => const AdminDashboardScreen(),
          },
        ),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    if (auth.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (auth.user != null) {
      final role = auth.userRole;
      if (role == 'admin') {
        return const AdminDashboardScreen();
      } else if (role == 'manager') {
        return const ManagerDashboardScreen();
      } else {
        return const DriverDashboardScreen();
      }
    }
    return const LoginScreen();
  }
}
