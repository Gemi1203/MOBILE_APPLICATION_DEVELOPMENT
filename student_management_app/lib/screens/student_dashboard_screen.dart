import 'package:flutter/material.dart';
import '../models/student.dart';
import '../utils/app_theme.dart';

class StudentDashboardScreen extends StatelessWidget {
  final Student student;
  const StudentDashboardScreen({super.key, required this.student});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Welcome, ${student.name}')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppTheme.primary,
                  child: Text(
                    student.name.isNotEmpty
                        ? student.name[0].toUpperCase()
                        : '?',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                title: Text(student.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 18)),
                subtitle: Text(
                  'ID: ${student.studentId}\nCourse: ${student.course}\nEmail: ${student.email}',
                  style: const TextStyle(fontSize: 14),
                ),
                isThreeLine: true,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.edit),
              label: const Text('Edit My Details'),
              onPressed: () {
                // Navigate to RegistrationScreen for editing
                Navigator.pushNamed(context, '/editStudent',
                    arguments: student);
              },
            ),
          ],
        ),
      ),
    );
  }
}
