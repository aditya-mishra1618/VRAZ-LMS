class ChildProfile {
  final int id;
  final DateTime? admissionDate;
  final String formNumber;
  final String sessionYear;
  final String category;
  final String status;
  final String currentClass;
  final String schoolName;
  final String board;
  final String marksOrCgpa;
  final String emergencyContactName;
  final String emergencyContactNumber;
  final String emergencyContactRelation;
  final String courseFee;
  final List<Discount> discounts;
  final String? discountApprovedBy;
  final String totalPayable;
  final bool withGst;
  final String gstPercentage;
  final int branchId;
  final int courseId;
  final String studentUserId;
  final StudentUser studentUser;
  final Branch branch;
  final Course course;

  ChildProfile({
    required this.id,
    this.admissionDate,
    required this.formNumber,
    required this.sessionYear,
    required this.category,
    required this.status,
    required this.currentClass,
    required this.schoolName,
    required this.board,
    required this.marksOrCgpa,
    required this.emergencyContactName,
    required this.emergencyContactNumber,
    required this.emergencyContactRelation,
    required this.courseFee,
    required this.discounts,
    this.discountApprovedBy,
    required this.totalPayable,
    required this.withGst,
    required this.gstPercentage,
    required this.branchId,
    required this.courseId,
    required this.studentUserId,
    required this.studentUser,
    required this.branch,
    required this.course,
  });

  factory ChildProfile.fromJson(Map<String, dynamic> json) {
    return ChildProfile(
      id: json['id'] ?? 0,
      admissionDate: json['admissionDate'] != null
          ? DateTime.tryParse(json['admissionDate'].toString())
          : null,
      formNumber: json['formNumber']?.toString() ?? '',
      sessionYear: json['sessionYear']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      status: json['status']?.toString() ?? 'ACTIVE',
      currentClass: json['currentClass']?.toString() ?? '',
      schoolName: json['schoolName']?.toString() ?? '',
      board: json['board']?.toString() ?? '',
      marksOrCgpa: json['marksOrCgpa']?.toString() ?? '',
      emergencyContactName: json['emergencyContactName']?.toString() ?? '',
      emergencyContactNumber: json['emergencyContactNumber']?.toString() ?? '',
      emergencyContactRelation: json['emergencyContactRelation']?.toString() ?? '',
      courseFee: json['courseFee']?.toString() ?? '0',
      discounts: (json['discounts'] as List<dynamic>?)
          ?.map((d) => Discount.fromJson(d as Map<String, dynamic>))
          .toList() ??
          [],
      discountApprovedBy: json['discountApprovedBy']?.toString(),
      totalPayable: json['totalPayable']?.toString() ?? '0',
      withGst: json['withGst'] == true,
      gstPercentage: json['gstPercentage']?.toString() ?? '18',
      branchId: json['branchId'] ?? 0,
      courseId: json['courseId'] ?? 0,
      studentUserId: json['studentUserId']?.toString() ?? '',
      studentUser: StudentUser.fromJson(json['studentUser'] ?? {}),
      branch: Branch.fromJson(json['branch'] ?? {}),
      course: Course.fromJson(json['course'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'admissionDate': admissionDate?.toIso8601String(),
      'formNumber': formNumber,
      'sessionYear': sessionYear,
      'category': category,
      'status': status,
      'currentClass': currentClass,
      'schoolName': schoolName,
      'board': board,
      'marksOrCgpa': marksOrCgpa,
      'emergencyContactName': emergencyContactName,
      'emergencyContactNumber': emergencyContactNumber,
      'emergencyContactRelation': emergencyContactRelation,
      'courseFee': courseFee,
      'discounts': discounts.map((d) => d.toJson()).toList(),
      'discountApprovedBy': discountApprovedBy,
      'totalPayable': totalPayable,
      'withGst': withGst,
      'gstPercentage': gstPercentage,
      'branchId': branchId,
      'courseId': courseId,
      'studentUserId': studentUserId,
      'studentUser': studentUser.toJson(),
      'branch': branch.toJson(),
      'course': course.toJson(),
    };
  }

  String get fullName => studentUser.fullName;
  String? get photoUrl => studentUser.photoUrl;
  String get branchName => branch.name;
  String get courseName => course.name;
  String get email => studentUser.email;
  String get phoneNumber => studentUser.phoneNumber;

  @override
  String toString() {
    return 'ChildProfile(id: $id, name: ${studentUser.fullName}, class: $currentClass)';
  }
}

class StudentUser {
  final String id;
  final String fullName;
  final String email;
  final String phoneNumber;
  final String address;
  final String? photoUrl;
  final DateTime? dateOfBirth;
  final String gender;

  StudentUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.address,
    this.photoUrl,
    this.dateOfBirth,
    required this.gender,
  });

  factory StudentUser.fromJson(Map<String, dynamic> json) {
    return StudentUser(
      id: json['id']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phoneNumber: json['phoneNumber']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      photoUrl: json['photoUrl']?.toString(),
      dateOfBirth: json['dateOfBirth'] != null
          ? DateTime.tryParse(json['dateOfBirth'].toString())
          : null,
      gender: json['gender']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'phoneNumber': phoneNumber,
      'address': address,
      'photoUrl': photoUrl,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'gender': gender,
    };
  }
}

class Branch {
  final int id;
  final String name;
  final String code;
  final String locationAddress;

  Branch({
    required this.id,
    required this.name,
    required this.code,
    required this.locationAddress,
  });

  factory Branch.fromJson(Map<String, dynamic> json) {
    return Branch(
      id: json['id'] ?? 0,
      name: json['name']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      locationAddress: json['locationAddress']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'locationAddress': locationAddress,
    };
  }
}

class Course {
  final int id;
  final String name;
  final String code;
  final String fees;

  Course({
    required this.id,
    required this.name,
    required this.code,
    required this.fees,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['id'] ?? 0,
      name: json['name']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      fees: json['fees']?.toString() ?? '0',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'fees': fees,
    };
  }
}

class Discount {
  final String name;
  final String amount;

  Discount({
    required this.name,
    required this.amount,
  });

  factory Discount.fromJson(Map<String, dynamic> json) {
    return Discount(
      name: json['name']?.toString() ?? '',
      amount: json['amount']?.toString() ?? '0',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'amount': amount,
    };
  }
}