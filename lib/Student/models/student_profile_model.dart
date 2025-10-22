// File: lib/Student/models/student_profile_model.dart

class DiscountModel {
  final String name;
  final String amount;

  DiscountModel({
    required this.name,
    required this.amount,
  });

  factory DiscountModel.fromJson(Map<String, dynamic> json) {
    return DiscountModel(
      name: json['name'] ?? '',
      amount: json['amount'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'amount': amount,
    };
  }
}

class ParentModel {
  final int id;
  final int admissionId;
  final String fullName;
  final String relation;
  final String phoneNumber;
  final String email;
  final String occupation;

  ParentModel({
    required this.id,
    required this.admissionId,
    required this.fullName,
    required this.relation,
    required this.phoneNumber,
    required this.email,
    required this.occupation,
  });

  factory ParentModel.fromJson(Map<String, dynamic> json) {
    return ParentModel(
      id: json['id'] ?? 0,
      admissionId: json['admissionId'] ?? 0,
      fullName: json['fullName'] ?? '',
      relation: json['relation'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      email: json['email'] ?? '',
      occupation: json['occupation'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'admissionId': admissionId,
      'fullName': fullName,
      'relation': relation,
      'phoneNumber': phoneNumber,
      'email': email,
      'occupation': occupation,
    };
  }
}

class StudentUserModel {
  final String fullName;
  final String email;
  final String phoneNumber;
  final DateTime? dateOfBirth;
  final String gender;
  final String address;
  final String photoUrl;

  StudentUserModel({
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    this.dateOfBirth,
    required this.gender,
    required this.address,
    required this.photoUrl,
  });

  factory StudentUserModel.fromJson(Map<String, dynamic> json) {
    return StudentUserModel(
      fullName: json['fullName'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      dateOfBirth: json['dateOfBirth'] != null
          ? DateTime.parse(json['dateOfBirth'])
          : null,
      gender: json['gender'] ?? '',
      address: json['address'] ?? '',
      photoUrl: json['photoUrl'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'email': email,
      'phoneNumber': phoneNumber,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'gender': gender,
      'address': address,
      'photoUrl': photoUrl,
    };
  }

  // Helper method to get age
  int? getAge() {
    if (dateOfBirth == null) return null;
    final now = DateTime.now();
    int age = now.year - dateOfBirth!.year;
    if (now.month < dateOfBirth!.month ||
        (now.month == dateOfBirth!.month && now.day < dateOfBirth!.day)) {
      age--;
    }
    return age;
  }

  // Helper method to get formatted date of birth
  String getFormattedDOB() {
    if (dateOfBirth == null) return 'N/A';
    return '${dateOfBirth!.day}/${dateOfBirth!.month}/${dateOfBirth!.year}';
  }
}

class BranchModel {
  final String name;

  BranchModel({required this.name});

  factory BranchModel.fromJson(Map<String, dynamic> json) {
    return BranchModel(name: json['name'] ?? '');
  }

  Map<String, dynamic> toJson() {
    return {'name': name};
  }
}

class CourseModel {
  final String name;

  CourseModel({required this.name});

  factory CourseModel.fromJson(Map<String, dynamic> json) {
    return CourseModel(name: json['name'] ?? '');
  }

  Map<String, dynamic> toJson() {
    return {'name': name};
  }
}

class StudentProfileModel {
  final int id;
  final DateTime admissionDate;
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
  final List<DiscountModel> discounts;
  final String discountApprovedBy;
  final String totalPayable;
  final bool withGst;
  final String gstPercentage;
  final int branchId;
  final int courseId;
  final String studentUserId;
  final int? enquiryId;
  final String createdByUserId;
  final StudentUserModel studentUser;
  final List<ParentModel> parents;
  final BranchModel branch;
  final CourseModel course;

  StudentProfileModel({
    required this.id,
    required this.admissionDate,
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
    required this.discountApprovedBy,
    required this.totalPayable,
    required this.withGst,
    required this.gstPercentage,
    required this.branchId,
    required this.courseId,
    required this.studentUserId,
    this.enquiryId,
    required this.createdByUserId,
    required this.studentUser,
    required this.parents,
    required this.branch,
    required this.course,
  });

  factory StudentProfileModel.fromJson(Map<String, dynamic> json) {
    return StudentProfileModel(
      id: json['id'] ?? 0,
      admissionDate: DateTime.parse(json['admissionDate']),
      formNumber: json['formNumber'] ?? '',
      sessionYear: json['sessionYear'] ?? '',
      category: json['category'] ?? '',
      status: json['status'] ?? '',
      currentClass: json['currentClass'] ?? '',
      schoolName: json['schoolName'] ?? '',
      board: json['board'] ?? '',
      marksOrCgpa: json['marksOrCgpa'] ?? '',
      emergencyContactName: json['emergencyContactName'] ?? '',
      emergencyContactNumber: json['emergencyContactNumber'] ?? '',
      emergencyContactRelation: json['emergencyContactRelation'] ?? '',
      courseFee: json['courseFee'] ?? '',
      discounts: (json['discounts'] as List<dynamic>?)
          ?.map((discount) => DiscountModel.fromJson(discount))
          .toList() ?? [],
      discountApprovedBy: json['discountApprovedBy'] ?? '',
      totalPayable: json['totalPayable'] ?? '',
      withGst: json['withGst'] ?? false,
      gstPercentage: json['gstPercentage'] ?? '',
      branchId: json['branchId'] ?? 0,
      courseId: json['courseId'] ?? 0,
      studentUserId: json['studentUserId'] ?? '',
      enquiryId: json['enquiryId'],
      createdByUserId: json['createdByUserId'] ?? '',
      studentUser: StudentUserModel.fromJson(json['studentUser'] ?? {}),
      parents: (json['parents'] as List<dynamic>?)
          ?.map((parent) => ParentModel.fromJson(parent))
          .toList() ?? [],
      branch: BranchModel.fromJson(json['branch'] ?? {}),
      course: CourseModel.fromJson(json['course'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'admissionDate': admissionDate.toIso8601String(),
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
      'enquiryId': enquiryId,
      'createdByUserId': createdByUserId,
      'studentUser': studentUser.toJson(),
      'parents': parents.map((p) => p.toJson()).toList(),
      'branch': branch.toJson(),
      'course': course.toJson(),
    };
  }

  // Helper methods
  ParentModel? getFather() {
    try {
      return parents.firstWhere(
            (parent) => parent.relation.toLowerCase() == 'father',
      );
    } catch (e) {
      return null;
    }
  }

  ParentModel? getMother() {
    try {
      return parents.firstWhere(
            (parent) => parent.relation.toLowerCase() == 'mother',
      );
    } catch (e) {
      return null;
    }
  }

  String getTotalDiscount() {
    int total = 0;
    for (var discount in discounts) {
      total += int.tryParse(discount.amount) ?? 0;
    }
    return total.toString();
  }

  String getFormattedAdmissionDate() {
    return '${admissionDate.day}/${admissionDate.month}/${admissionDate.year}';
  }

  bool isActive() => status.toLowerCase() == 'active';
}