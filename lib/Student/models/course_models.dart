// This file defines the structure for your course data from the API.

// Represents a single LMS content item within a topic (video, PDF, link).
class LMSContentModel {
  final int id;
  final int topicId;
  final String title;
  final String contentType; // e.g., "Video", "PDF", "Link"
  final String? contentUrl;
  final String? thumbnailUrl;
  final int order;

  LMSContentModel({
    required this.id,
    required this.topicId,
    required this.title,
    required this.contentType,
    this.contentUrl,
    this.thumbnailUrl,
    required this.order,
  });

  factory LMSContentModel.fromJson(Map<String, dynamic> json) {
    return LMSContentModel(
      id: json['id'],
      topicId: json['topicId'],
      title: json['title'],
      contentType: json['contentType'],
      contentUrl: json['contentUrl'],
      thumbnailUrl: json['thumbnailUrl'],
      order: json['order'],
    );
  }
}

// Represents a topic or sub-topic.
class TopicModel {
  final int id;
  final String name;
  final int subjectId;
  final int? parentId;
  final int order;
  final List<LMSContentModel> lmsContents;
  final List<TopicModel> subTopics;

  TopicModel({
    required this.id,
    required this.name,
    required this.subjectId,
    this.parentId,
    required this.order,
    required this.lmsContents,
    required this.subTopics,
  });

  factory TopicModel.fromJson(Map<String, dynamic> json) {
    var lmsContentsList = json['lmsContents'] as List;
    List<LMSContentModel> lmsContents =
    lmsContentsList.map((i) => LMSContentModel.fromJson(i)).toList();

    var subTopicsList = json['subTopics'] as List;
    List<TopicModel> subTopics =
    subTopicsList.map((i) => TopicModel.fromJson(i)).toList();

    return TopicModel(
      id: json['id'],
      name: json['name'],
      subjectId: json['subjectId'],
      parentId: json['parentId'],
      order: json['order'],
      lmsContents: lmsContents,
      subTopics: subTopics,
    );
  }

  // Helper to flatten all nested topics and subtopics into a single list
  List<TopicModel> getAllNestedTopics() {
    final List<TopicModel> allTopics = [];
    allTopics.add(this); // Add the current topic
    for (var subTopic in subTopics) {
      allTopics.addAll(subTopic.getAllNestedTopics());
    }
    return allTopics;
  }

  // Helper to get all videos from this topic and its subtopics
  List<LMSContentModel> getAllVideos() {
    final List<LMSContentModel> allVideos = [];
    allVideos
        .addAll(lmsContents.where((content) => content.contentType == "Video"));
    for (var subTopic in subTopics) {
      allVideos.addAll(subTopic.getAllVideos());
    }
    return allVideos;
  }

  // Helper to check if this is a main topic (no parent)
  bool isMainTopic() => parentId == null;

  // Helper to find a subtopic by ID within this topic's children
  TopicModel? findSubTopicById(int topicId) {
    for (var subTopic in subTopics) {
      if (subTopic.id == topicId) return subTopic;

      // Search recursively in nested subtopics
      var found = subTopic.findSubTopicById(topicId);
      if (found != null) return found;
    }
    return null;
  }
}

// Represents a subject (e.g., Physics, Chemistry).
class SubjectModel {
  final int id;
  final String name;
  final String code;
  final String type;
  final List<TopicModel> topics;

  SubjectModel({
    required this.id,
    required this.name,
    required this.code,
    required this.type,
    required this.topics,
  });

  factory SubjectModel.fromJson(Map<String, dynamic> json) {
    var topicsList = json['topics'] as List;
    List<TopicModel> topics =
    topicsList.map((i) => TopicModel.fromJson(i)).toList();

    return SubjectModel(
      id: json['id'],
      name: json['name'],
      code: json['code'],
      type: json['type'],
      topics: topics,
    );
  }

  // Helper to get only main topics (parentId = null)
  List<TopicModel> getMainTopics() {
    return topics.where((topic) => topic.isMainTopic()).toList();
  }

  // Helper to find a topic by id (searches recursively through all levels)
  TopicModel? findTopicById(int topicId) {
    for (var topic in topics) {
      if (topic.id == topicId) return topic;

      // Search in subtopics recursively
      var found = topic.findSubTopicById(topicId);
      if (found != null) return found;
    }
    return null;
  }
}