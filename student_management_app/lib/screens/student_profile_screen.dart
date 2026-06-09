// screens/student/student_profile_screen.dart
// STUDENT ONLY — a student can only see their own profile, nothing else.

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../database/database_helper.dart';
import '../../models/student.dart';
import '../../theme/app_theme.dart';
import '../login_screen.dart';

class StudentProfileScreen extends StatefulWidget {
  final int studentId;
  const StudentProfileScreen({super.key, required this.studentId});

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
  Student? _student;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    final s = await DatabaseHelper.instance.getStudentById(widget.studentId);
    setState(() {
      _student = s;
      _isLoading = false;
    });
  }

  // ── Logout ────────────────────────────────────────────────────────────────
  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: const Text('Logout', style: TextStyle(color: Colors.white)),
        content: const Text('Are you sure you want to logout?',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child:
                const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child:
                const Text('Logout', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
    if (ok != true) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceDark,
        automaticallyImplyLeading: false,
        title: const Text('My Profile',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryBlue))
          : _student == null
              ? const Center(
                  child: Text('Profile not found.',
                      style: TextStyle(color: Colors.white54)))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 12),

                      // ── Avatar ──────────────────────────────────────────
                      CircleAvatar(
                        radius: 54,
                        backgroundColor: AppTheme.primaryBlue,
                        child: Text(
                          _student!.name[0].toUpperCase(),
                          style: const TextStyle(
                            fontSize: 44,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── Name ─────────────────────────────────────────────
                      Text(_student!.name,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          )),
                      const SizedBox(height: 4),

                      // ── Student badge ─────────────────────────────────────
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: AppTheme.primaryBlue.withOpacity(0.4)),
                        ),
                        child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.school,
                                  color: AppTheme.primaryBlue, size: 15),
                              SizedBox(width: 6),
                              Text('Student',
                                  style: TextStyle(
                                      color: AppTheme.primaryBlue,
                                      fontSize: 13)),
                            ]),
                      ),
                      const SizedBox(height: 32),

                      // ── Info Cards ────────────────────────────────────────
                      _infoCard(
                        icon: Icons.badge_outlined,
                        label: 'Student ID',
                        value: _student!.studentId,
                        color: AppTheme.primaryBlue,
                      ),
                      const SizedBox(height: 12),
                      _infoCard(
                        icon: Icons.email_outlined,
                        label: 'Email Address',
                        value: _student!.email,
                        color: AppTheme.primaryBlue,
                      ),
                      const SizedBox(height: 12),
                      _infoCard(
                        icon: Icons.book_outlined,
                        label: 'Course Enrolled',
                        value: _student!.course,
                        color: AppTheme.success,
                      ),
                      const SizedBox(height: 32),

                      // ── Security note ────────────────────────────────────
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: const Row(children: [
                          Icon(Icons.security,
                              color: AppTheme.warning, size: 20),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Your profile is private. Only you can see this information.',
                              style: TextStyle(
                                  color: Colors.white54, fontSize: 13),
                            ),
                          ),
                        ]),
                      ),
                      const SizedBox(height: 32),

                      // ── Logout Button ─────────────────────────────────────
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: OutlinedButton.icon(
                          onPressed: _logout,
                          icon: const Icon(Icons.logout, color: AppTheme.error),
                          label: const Text('Logout',
                              style: TextStyle(
                                  color: AppTheme.error,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppTheme.error),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
    );
  }

  Widget _infoCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 14),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: const TextStyle(color: Colors.white38, fontSize: 11)),
          const SizedBox(height: 3),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600)),
        ]),
      ]),
    );
  }
}
