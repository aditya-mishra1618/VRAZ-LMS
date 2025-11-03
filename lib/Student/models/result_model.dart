class ResultResponse {
  final int id;
  final int testId;
  final String studentId;
  final int batchId;
  final Map<String, String> marks;
  final String totalMarksObtained;
  final String totalMaxMarks;
  final String percentage;
  final int? rank;
  final Test test;
  final Batch batch;

  ResultResponse({
    required this.id,
    required this.testId,
    required this.studentId,
    required this.batchId,
    required this.marks,
    required this.totalMarksObtained,
    required this.totalMaxMarks,
    required this.percentage,
    this.rank,
    required this.test,
    required this.batch,
  });

  factory ResultResponse.fromJson(Map<String, dynamic> json) {
    return ResultResponse(
      id: json['id'] as int,
      testId: json['testId'] as int,
      studentId: json['studentId'] as String,
      batchId: json['batchId'] as int,
      marks: Map<String, String>.from(json['marks'] as Map),
      totalMarksObtained: json['totalMarksObtained'] as String,
      totalMaxMarks: json['totalMaxMarks'] as String,
      percentage: json['percentage'] as String,
      rank: json['rank'] as int?,
      test: Test.fromJson(json['test'] as Map<String, dynamic>),
      batch: Batch.fromJson(json['batch'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'testId': testId,
      'studentId': studentId,
      'batchId': batchId,
      'marks': marks,
      'totalMarksObtained': totalMarksObtained,
      'totalMaxMarks': totalMaxMarks,
      'percentage': percentage,
      'rank': rank,
      'test': test.toJson(),
      'batch': batch.toJson(),
    };
  }
}

class Test {
  final String name;
  final String date;
  final List<TestStructure> testStructure;

  Test({
    required this.name,
    required this.date,
    required this.testStructure,
  });

  factory Test.fromJson(Map<String, dynamic> json) {
    return Test(
      name: json['name'] as String,
      date: json['date'] as String,
      testStructure: (json['testStructure'] as List)
          .map((e) => TestStructure.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'date': date,
      'testStructure': testStructure.map((e) => e.toJson()).toList(),
    };
  }
}

class TestStructure {
  final String id;
  final String topicId;
  final int maxMarks;
  final String subjectId;
  final String topicName;
  final String subjectName;

  TestStructure({
    required this.id,
    required this.topicId,
    required this.maxMarks,
    required this.subjectId,
    required this.topicName,
    required this.subjectName,
  });

  factory TestStructure.fromJson(Map<String, dynamic> json) {
    return TestStructure(
      id: json['id'] as String,
      topicId: json['topicId'] as String,
      maxMarks: json['maxMarks'] as int,
      subjectId: json['subjectId'] as String,
      topicName: json['topicName'] as String,
      subjectName: json['subjectName'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'topicId': topicId,
      'maxMarks': maxMarks,
      'subjectId': subjectId,
      'topicName': topicName,
      'subjectName': subjectName,
    };
  }
}

class Batch {
  final String name;

  Batch({
    required this.name,
  });

  factory Batch.fromJson(Map<String, dynamic> json) {
    return Batch(
      name: json['name'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
    };
  }
}