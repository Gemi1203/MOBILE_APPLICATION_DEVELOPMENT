import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/student.dart';
import '../utils/app_theme.dart';

class RegistrationScreen extends StatefulWidget {
  final Student? student;
  const RegistrationScreen({super.key, this.student});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _email;
  late final TextEditingController _studentId;
  late final TextEditingController _course;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final s = widget.student;
    _name = TextEditingController(text: s?.name ?? '');
    _email = TextEditingController(text: s?.email ?? '');
    _studentId = TextEditingController(text: s?.studentId ?? '');
    _course = TextEditingController(text: s?.course ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _studentId.dispose();
    _course.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final student = Student(
      id: widget.student?.id,
      name: _name.text.trim(),
      email: _email.text.trim(),
      studentId: _studentId.text.trim(),
      course: _course.text.trim(),
    );

    try {
      if (widget.student == null) {
        await DatabaseHelper.instance.insertStudent(student);
      } else {
        await DatabaseHelper.instance.updateStudent(student);
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save: $e'),
          backgroundColor: AppTheme.danger,
        ),
      );
    }
  }

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Required' : null;

  String? _emailValidator(String? v) {
    if (v == null || v.trim().isEmpty) return 'Required';
    final ok = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$').hasMatch(v.trim());
    return ok ? null : 'Invalid email';
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.student != null;
    return Scaffold(
      appBar:
          AppBar(title: Text(editing ? 'Edit Student' : 'Register Student')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: _required,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                validator: _emailValidator,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _studentId,
                decoration: const InputDecoration(
                  labelText: 'Student ID',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
                validator: _required,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _course,
                decoration: const InputDecoration(
                  labelText: 'Course',
                  prefixIcon: Icon(Icons.book_outlined),
                ),
                validator: _required,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: const Icon(Icons.save),
                  label: Text(editing ? 'Update Student' : 'Register Student'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
