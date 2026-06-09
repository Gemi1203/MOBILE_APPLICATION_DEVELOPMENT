import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart'; // ✅ Now available
import 'utils/app_theme.dart';
import 'database/database_helper.dart';
import 'models/student.dart';
import 'screens/student_login_screen.dart';
import 'screens/student_dashboard_screen.dart';
import 'screens/registration_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Initialize sqflite for desktop (Windows, macOS, Linux)
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  runApp(const StudentApp());
}

class StudentApp extends StatelessWidget {
  const StudentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Student Portal',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const _RootGate(),
      routes: {
        '/login': (_) => const StudentLoginScreen(),
        '/register': (_) => const RegistrationScreen(),
      },
    );
  }
}

class _RootGate extends StatefulWidget {
  const _RootGate();

  @override
  State<_RootGate> createState() => _RootGateState();
}

class _RootGateState extends State<_RootGate> {
  bool _loading = true;
  int? _studentId;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _studentId = prefs.getInt('student_id');
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_studentId != null) {
      return FutureBuilder<Student?>(
        future: DatabaseHelper.instance.getStudentById(_studentId!),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          return StudentDashboardScreen(student: snapshot.data!);
        },
      );
    }

    return const StudentLoginScreen();
  }
}
