import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/student.dart';

class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();
  static Database? _db;

  Future<Database> get database async {
    _db ??= await _init();
    return _db!;
  }

  Future<Database> _init() async {
    final path = join(await getDatabasesPath(), 'students.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE students (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            email TEXT NOT NULL,
            student_id TEXT NOT NULL UNIQUE,
            course TEXT NOT NULL
          )
        ''');
      },
    );
  }

  // Student login
  Future<Student?> loginStudent(String studentId, String email) async {
    final db = await database;
    final rows = await db.query(
      'students',
      where: 'student_id = ? AND email = ?',
      whereArgs: [studentId, email],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Student.fromMap(rows.first);
  }

  // Fetch student by ID
  Future<Student?> getStudentById(int id) async {
    final db = await database;
    final rows = await db.query(
      'students',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Student.fromMap(rows.first);
  }

  // CRUD
  Future<int> insertStudent(Student s) async {
    final db = await database;
    return db.insert('students', s.toMap()..remove('id'));
  }

  Future<int> updateStudent(Student s) async {
    final db = await database;
    return db.update('students', s.toMap(), where: 'id = ?', whereArgs: [s.id]);
  }

  Future<int> deleteStudent(int id) async {
    final db = await database;
    return db.delete('students', where: 'id = ?', whereArgs: [id]);
  }
}
