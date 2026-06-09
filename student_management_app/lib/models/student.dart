class Student {
  final int? id;
  final String name;
  final String email;
  final String studentId;
  final String course;

  Student({
    this.id,
    required this.name,
    required this.email,
    required this.studentId,
    required this.course,
  });

  factory Student.fromMap(Map<String, dynamic> map) => Student(
        id: map['id'] as int?,
        name: map['name'] as String,
        email: map['email'] as String,
        studentId: map['student_id'] as String,
        course: map['course'] as String,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'email': email,
        'student_id': studentId,
        'course': course,
      };
}
