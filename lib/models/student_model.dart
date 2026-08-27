/// نموذج مبسّط يُستخدم فقط في شاشة "قائمة الطلاب" العامة (students.php).
/// منفصل عمداً عن [Student] الذي يمثل الملف الكامل للطالب المسجّل دخوله.
class StudentModel {
  final int id;
  final String name;
  final String className;
  final String phone;
  final String email;

  StudentModel({
    required this.id,
    required this.name,
    required this.className,
    required this.phone,
    required this.email,
  });

  factory StudentModel.fromJson(Map<String, dynamic> json) {
    return StudentModel(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      name: json['name']?.toString() ?? '',
      className: json['class']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
    );
  }
}
