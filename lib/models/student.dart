/// نموذج بيانات الطالب - مطابق للحقول الموجودة فعلياً بجدول std26 بالسيرفر.
/// هذا هو النموذج الوحيد المعتمد لبيانات الطالب المسجّل دخوله (بدّلنا إليه
/// عن UserModel القديم الذي كان يحتوي حقولاً غير موجودة أصلاً في قاعدة البيانات
/// مثل gender/nationality/religion/rollNumber... إلخ).
class Student {
  final int studentId;
  final String studentName;
  final String? fatherName;
  final String? grandfatherName;
  final String? motherName;
  final String? originalGovernorate;
  final String? civilRegistry;
  final String? studentCode;
  final String? birthDate;
  final String? placeOfBirth;
  final String? addressDetails;
  final String? area;
  final String? street;
  final String? buildingNo;
  final String? floorNo;
  final String? apartmentNo;
  final String? addressNotes;
  final String? fatherPhone;
  final String? motherPhone;
  final String? fatherJob;
  final String? motherJob;
  final String? studentType;
  final String? previousSchool;
  final String? notes;
  final String? registrationDate;
  final String? transportation;
  final String? paymentStatus;
  final bool isVerified;
  final String? gradeName;
  final String? sectionName;
  final int? sectionId;
  final String? supervisorName;
  final int? supervisorId;
  final String? gender; // 'male' أو 'female' — من عمود std26.gender (قد يكون null لو الطالب لسا ما انصنّف)

  Student({
    required this.studentId,
    required this.studentName,
    this.fatherName,
    this.grandfatherName,
    this.motherName,
    this.originalGovernorate,
    this.civilRegistry,
    this.studentCode,
    this.birthDate,
    this.placeOfBirth,
    this.addressDetails,
    this.area,
    this.street,
    this.buildingNo,
    this.floorNo,
    this.apartmentNo,
    this.addressNotes,
    this.fatherPhone,
    this.motherPhone,
    this.fatherJob,
    this.motherJob,
    this.studentType,
    this.previousSchool,
    this.notes,
    this.registrationDate,
    this.transportation,
    this.paymentStatus,
    this.isVerified = false,
    this.gradeName,
    this.sectionName,
    this.supervisorName,
    this.sectionId,
    this.supervisorId,
    this.gender,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      studentId: int.tryParse(json['student_id'].toString()) ?? 0,
      studentName: json['student_name']?.toString() ?? '',
      fatherName: json['father_name']?.toString(),
      grandfatherName: json['grandfather_name']?.toString(),
      motherName: json['mother_name']?.toString(),
      originalGovernorate: json['original_governorate']?.toString(),
      civilRegistry: json['civil_registry']?.toString(),
      studentCode: json['student_code']?.toString(),
      birthDate: json['birth_date']?.toString(),
      placeOfBirth: json['place_of_birth']?.toString(),
      addressDetails: json['address_details']?.toString(),
      area: json['area']?.toString(),
      street: json['street']?.toString(),
      buildingNo: json['building_no']?.toString(),
      floorNo: json['floor_no']?.toString(),
      apartmentNo: json['apartment_no']?.toString(),
      addressNotes: json['address_notes']?.toString(),
      fatherPhone: json['father_phone']?.toString(),
      motherPhone: json['mother_phone']?.toString(),
      fatherJob: json['father_job']?.toString(),
      motherJob: json['mother_job']?.toString(),
      studentType: json['student_type']?.toString(),
      previousSchool: json['previous_school']?.toString(),
      notes: json['notes']?.toString(),
      registrationDate: json['registration_date']?.toString(),
      transportation: json['transportation']?.toString(),
      paymentStatus: json['payment_status']?.toString(),
      isVerified: json['is_verified'] == true ||
          json['is_verified'] == 1 ||
          json['is_verified'] == '1',
      gradeName: json['grade_name']?.toString(),
      sectionName: json['section_name']?.toString(),
      supervisorName: json['supervisor_name']?.toString(),
      sectionId: json['section_id'] != null ? int.tryParse('${json['section_id']}') : null,
      supervisorId: json['supervisor_id'] != null ? int.tryParse('${json['supervisor_id']}') : null,
      gender: json['gender']?.toString(),
    );
  }

  /// اسم مختصر للصف يُستخدم في بطاقة الداشبورد (بديل عن className/section
  /// اللذين كانا يُقرآن من UserModel وغير موجودين هنا).
  String get displayGrade => gradeName ?? '-';
  String get displaySection => sectionName ?? '-';

  /// قائمة الحقول جاهزة للعرض بصفحة "الملف الشخصي" (label -> value)
  Map<String, String?> get profileFields => {
        'معرف الطالب': studentId.toString(),
        'الاسم الكامل': studentName,
        'اسم الأب': fatherName,
        'اسم الجد': grandfatherName,
        'اسم الأم': motherName,
        'محافظة الأصل': originalGovernorate,
        'السجل المدني': civilRegistry,
        'كود الطالب': studentCode,
        'تاريخ الميلاد': birthDate,
        'مكان الميلاد': placeOfBirth,
        'العنوان التفصيلي': addressDetails,
        'المنطقة': area,
        'الشارع': street,
        'رقم المبنى': buildingNo,
        'رقم الطابق': floorNo,
        'رقم الشقة': apartmentNo,
        'ملاحظات العنوان': addressNotes,
        'رقم هاتف الأب': fatherPhone,
        'رقم هاتف الأم': motherPhone,
        'عمل الأب': fatherJob,
        'عمل الأم': motherJob,
        'نوع الطالب': studentType,
        'المدرسة السابقة': previousSchool,
        'ملاحظات': notes,
        'تاريخ التسجيل': registrationDate,
        'النقل': transportation,
        'حالة الدفع': paymentStatus,
        'حالة التدقيق': isVerified ? 'مدقق' : 'غير مدقق',
        'الصف': gradeName,
        'الشعبة': sectionName,
        'الموجه': supervisorName,
      };
}

/// نموذج بيانات الأخ/الأخت (لعرضهم بالداشبورد).
/// يقبل عدّة تسميات محتملة لمفاتيح الـ JSON حتى يبقى متوافقاً مع أي شكل
/// يرجعه فعلياً siblings.php (id/name/class أو student_id/student_name/grade_name).
class Sibling {
  final int studentId;
  final String studentName;
  final String? gradeName;
  final String relation;
  final String? gender; // 'male' أو 'female' — لتلوين شريط تبديل الحسابات (SiblingPalette)

  Sibling({
    required this.studentId,
    required this.studentName,
    this.gradeName,
    this.relation = 'أخ/أخت',
    this.gender,
  });

  factory Sibling.fromJson(Map<String, dynamic> json) {
    return Sibling(
      studentId: int.tryParse(
            (json['student_id'] ?? json['id'])?.toString() ?? '',
          ) ??
          0,
      studentName:
          (json['student_name'] ?? json['name'])?.toString() ?? '',
      gradeName: (json['grade_name'] ?? json['class'])?.toString(),
      relation: json['relation']?.toString() ?? 'أخ/أخت',
      gender: json['gender']?.toString(),
    );
  }
}
