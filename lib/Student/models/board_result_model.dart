class BoardResultResponse {
  final int id;
  final int testId;
  final String studentId;
  final int batchId;
  final Map<String, String> marks;
  final String totalMarksObtained;
  final String totalMaxMarks;
  final String percentage;
  final int? rank;
  final BoardTest test;
  final Batch batch;

  BoardResultResponse({
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

  factory BoardResultResponse.fromJson(Map<String, dynamic> json) {
    return BoardResultResponse(
      id: json['id'],
      testId: json['testId'],
      studentId: json['studentId'],
      batchId: json['batchId'],
      marks: Map<String, String>.from(json['marks']),
      totalMarksObtained: json['totalMarksObtained'],
      totalMaxMarks: json['totalMaxMarks'],
      percentage: json['percentage'],
      rank: json['rank'],
      test: BoardTest.fromJson(json['test']),
      batch: Batch.fromJson(json['batch']),
    );
  }
}

class BoardTest {
  final String name;
  final String date;
  final List<TestStructure> testStructure;

  BoardTest({
    required this.name,
    required this.date,
    required this.testStructure,
  });

  factory BoardTest.fromJson(Map<String, dynamic> json) {
    return BoardTest(
      name: json['name'],
      date: json['date'],
      testStructure: (json['testStructure'] as List)
          .map((e) => TestStructure.fromJson(e))
          .toList(),
    );
  }
}

class TestStructure {
  final String id;
  final String? topicId;        // ✅ Made nullable
  final int maxMarks;
  final String? subjectId;      // ✅ Made nullable
  final String? topicName;      // ✅ Made nullable
  final String? subjectName;    // ✅ Made nullable
  final String? name;           // ✅ Added for alternative structure

  TestStructure({
    required this.id,
    this.topicId,
    required this.maxMarks,
    this.subjectId,
    this.topicName,
    this.subjectName,
    this.name,
  });

  factory TestStructure.fromJson(Map<String, dynamic> json) {
    return TestStructure(
      id: json['id'],
      topicId: json['topicId']?.toString(),          // ✅ Safe conversion
      maxMarks: json['maxMarks'],
      subjectId: json['subjectId']?.toString(),      // ✅ Safe conversion
      topicName: json['topicName'],                  // ✅ Nullable
      subjectName: json['subjectName'],              // ✅ Nullable
      name: json['name'],                            // ✅ Alternative field
    );
  }

  // ✅ Helper getter to get display name
  String get displayName => subjectName ?? name ?? 'Unknown Subject';

  // ✅ Helper getter to get display topic
  String get displayTopic => topicName ?? name ?? 'General';
}

class Batch {
  final String name;

  Batch({required this.name});

  factory Batch.fromJson(Map<String, dynamic> json) {
    return Batch(name: json['name']);
  }
}

class TestDetailResponse {
  final int id;
  final String name;
  final String date;
  final int testTemplateId;
  final List<TestStructure> testStructure;
  final TestTemplate testTemplate;

  TestDetailResponse({
    required this.id,
    required this.name,
    required this.date,
    required this.testTemplateId,
    required this.testStructure,
    required this.testTemplate,
  });

  factory TestDetailResponse.fromJson(Map<String, dynamic> json) {
    return TestDetailResponse(
      id: json['id'],
      name: json['name'],
      date: json['date'],
      testTemplateId: json['testTemplateId'],
      testStructure: (json['testStructure'] as List)
          .map((e) => TestStructure.fromJson(e))
          .toList(),
      testTemplate: TestTemplate.fromJson(json['testTemplate']),
    );
  }
}

class TestTemplate {
  final String name;
  final String examType;

  TestTemplate({
    required this.name,
    required this.examType,
  });

  factory TestTemplate.fromJson(Map<String, dynamic> json) {
    return TestTemplate(
      name: json['name'],
      examType: json['examType'],
    );
  }
}

class PerformanceResponse {
  final StudentPerformance? myPerformance;
  final BatchAnalysis batchAnalysis;
  final List<LeaderboardEntry> leaderboard;

  PerformanceResponse({
    this.myPerformance,
    required this.batchAnalysis,
    required this.leaderboard,
  });

  factory PerformanceResponse.fromJson(Map<String, dynamic> json) {
    return PerformanceResponse(
      myPerformance: json['myPerformance'] != null
          ? StudentPerformance.fromJson(json['myPerformance'])
          : null,
      batchAnalysis: BatchAnalysis.fromJson(json['batchAnalysis']),
      leaderboard: (json['leaderboard'] as List)
          .map((e) => LeaderboardEntry.fromJson(e))
          .toList(),
    );
  }
}

class StudentPerformance {
  final String studentId;
  final String studentName;
  final double averageScore;
  final int testsCompleted;
  final int? rank;

  StudentPerformance({
    required this.studentId,
    required this.studentName,
    required this.averageScore,
    required this.testsCompleted,
    this.rank,
  });

  factory StudentPerformance.fromJson(Map<String, dynamic> json) {
    return StudentPerformance(
      studentId: json['studentId'],
      studentName: json['studentName'],
      averageScore: json['averageScore'].toDouble(),
      testsCompleted: json['testsCompleted'],
      rank: json['rank'],
    );
  }
}

class BatchAnalysis {
  final double average;
  final double topScore;
  final int totalStudents;

  BatchAnalysis({
    required this.average,
    required this.topScore,
    required this.totalStudents,
  });

  factory BatchAnalysis.fromJson(Map<String, dynamic> json) {
    return BatchAnalysis(
      average: (json['average'] ?? 0).toDouble(),
      topScore: (json['topScore'] ?? 0).toDouble(),
      totalStudents: json['totalStudents'] ?? 0,
    );
  }
}

class LeaderboardEntry {
  final String studentId;
  final String studentName;
  final double score;
  final int rank;

  LeaderboardEntry({
    required this.studentId,
    required this.studentName,
    required this.score,
    required this.rank,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      studentId: json['studentId'],
      studentName: json['studentName'],
      score: json['score'].toDouble(),
      rank: json['rank'],
    );
  }
}