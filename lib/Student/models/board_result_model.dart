// --- RENAMED to BoardResultResponse to match your screen ---
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
  final Test test;
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
}

class TestStructure {
  final String id;
  final int maxMarks;

  // --- FIX: Made fields nullable to handle different API responses ---
  final String? topicId;
  final String? subjectId;
  final String? topicName;
  final String? subjectName;
  final String? name; // For the second API format

  TestStructure({
    required this.id,
    required this.maxMarks,
    this.topicId,
    this.subjectId,
    this.topicName,
    this.subjectName,
    this.name,
  });

  // --- ADDED: Helper getters for consistent display ---
  String get displayName => subjectName ?? name ?? 'Unnamed Subject';
  String get displayTopic => topicName ?? 'Topic';
  // --- END ADDED ---

  factory TestStructure.fromJson(Map<String, dynamic> json) {
    return TestStructure(
      id: json['id'] as String,
      maxMarks: json['maxMarks'] as int,
      topicId: json['topicId'] as String?,
      subjectId: json['subjectId'] as String?,
      topicName: json['topicName'] as String?,
      subjectName: json['subjectName'] as String?,
      name: json['name'] as String?,
    );
  }
}

class Batch {
  final String name;
  Batch({required this.name});
  factory Batch.fromJson(Map<String, dynamic> json) {
    return Batch(name: json['name'] as String);
  }
}

// --- NEW MODELS for new API calls ---

class TestDetailResponse {
  final TestTemplate testTemplate;
  // Add other fields from this API if needed
  TestDetailResponse({required this.testTemplate});

  factory TestDetailResponse.fromJson(Map<String, dynamic> json) {
    return TestDetailResponse(
      testTemplate:
          TestTemplate.fromJson(json['testTemplate'] as Map<String, dynamic>),
    );
  }
}

class TestTemplate {
  final String name;
  final String examType;
  TestTemplate({required this.name, required this.examType});

  factory TestTemplate.fromJson(Map<String, dynamic> json) {
    return TestTemplate(
      name: json['name'] as String,
      examType: json['examType'] as String,
    );
  }
}

class PerformanceResponse {
  final MyPerformance myPerformance;
  final BatchAnalysis batchAnalysis;
  final List<LeaderboardEntry> leaderboard;

  PerformanceResponse({
    required this.myPerformance,
    required this.batchAnalysis,
    required this.leaderboard,
  });

  factory PerformanceResponse.fromJson(Map<String, dynamic> json) {
    return PerformanceResponse(
      myPerformance:
          MyPerformance.fromJson(json['myPerformance'] as Map<String, dynamic>),
      batchAnalysis:
          BatchAnalysis.fromJson(json['batchAnalysis'] as Map<String, dynamic>),
      leaderboard: (json['leaderboard'] as List)
          .map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class SubjectPerformanceResponse {
  final MyPerformance myPerformance;
  final BatchAnalysis batchAnalysis;
  final List<LeaderboardEntry> leaderboard;
  final List<MyScoresListEntry> myScoresList;

  SubjectPerformanceResponse({
    required this.myPerformance,
    required this.batchAnalysis,
    required this.leaderboard,
    required this.myScoresList,
  });

  factory SubjectPerformanceResponse.fromJson(Map<String, dynamic> json) {
    return SubjectPerformanceResponse(
      myPerformance:
          MyPerformance.fromJson(json['myPerformance'] as Map<String, dynamic>),
      batchAnalysis:
          BatchAnalysis.fromJson(json['batchAnalysis'] as Map<String, dynamic>),
      leaderboard: (json['leaderboard'] as List)
          .map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      myScoresList: (json['myScoresList'] as List)
          .map((e) => MyScoresListEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class MyPerformance {
  final num score;
  final num total;
  final num percentage;
  final int? rank;

  MyPerformance(
      {required this.score,
      required this.total,
      required this.percentage,
      this.rank});

  factory MyPerformance.fromJson(Map<String, dynamic> json) {
    return MyPerformance(
      score: json['score'] as num,
      total: json['total'] as num,
      // Handle percentage being string or num
      percentage: json['percentage'] is String
          ? (num.tryParse(json['percentage']) ?? 0.0)
          : json['percentage'] as num,
      rank: json['rank'] as int?,
    );
  }
}

class BatchAnalysis {
  final int totalStudents;
  final num average;
  final num topScore;

  BatchAnalysis(
      {required this.totalStudents,
      required this.average,
      required this.topScore});

  factory BatchAnalysis.fromJson(Map<String, dynamic> json) {
    return BatchAnalysis(
      totalStudents: json['totalStudents'] as int,
      // Handle average/topScore being string or num
      average: json['average'] is String
          ? (num.tryParse(json['average']) ?? 0.0)
          : json['average'] as num,
      topScore: json['topScore'] is String
          ? (num.tryParse(json['topScore']) ?? 0.0)
          : json['topScore'] as num,
    );
  }
}

class LeaderboardEntry {
  final int rank;
  final String studentName;
  final num score;

  LeaderboardEntry(
      {required this.rank, required this.studentName, required this.score});

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      rank: json['rank'] as int,
      studentName: json['name'] as String,
      score: json['score'] as num,
    );
  }
}

class MyScoresListEntry {
  final int testId;
  final String testName;
  final String testDate;
  final num score;
  final int maxMarks;
  final String percentage;

  MyScoresListEntry({
    required this.testId,
    required this.testName,
    required this.testDate,
    required this.score,
    required this.maxMarks,
    required this.percentage,
  });

  factory MyScoresListEntry.fromJson(Map<String, dynamic> json) {
    return MyScoresListEntry(
      testId: json['testId'] as int,
      testName: json['testName'] as String,
      testDate: json['testDate'] as String,
      score: json['score'] as num,
      maxMarks: json['maxMarks'] as int,
      percentage: json['percentage'] as String,
    );
  }
}

// This is a local calculation helper, not from API
class SubjectPerformance {
  final String subjectName;
  int totalMarksObtained = 0;
  int totalMaxMarks = 0;
  int totalTests = 0;

  SubjectPerformance({required this.subjectName});

  void addTest(int marks, int max) {
    totalMarksObtained += marks;
    totalMaxMarks += max;
    totalTests++;
  }

  double get averagePercentage =>
      totalMaxMarks > 0 ? (totalMarksObtained / totalMaxMarks) * 100 : 0.0;

  String get grade {
    final p = averagePercentage;
    if (p >= 90) return 'A+';
    if (p >= 80) return 'A';
    if (p >= 70) return 'B+';
    if (p >= 60) return 'B';
    if (p >= 50) return 'C';
    return 'D';
  }
}
