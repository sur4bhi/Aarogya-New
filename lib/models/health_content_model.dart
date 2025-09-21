import 'package:cloud_firestore/cloud_firestore.dart';

class HealthContentModel {
  final String id;
  final String title;
  final String description;
  final String content;
  final HealthContentType type;
  final String category;
  final List<String> tags;
  final String language;
  final Map<String, String> localizedTitles; // language_code: title
  final Map<String, String> localizedDescriptions; // language_code: description
  final Map<String, String> localizedContent; // language_code: content
  final String? imageUrl;
  final String? videoUrl;
  final String? audioUrl;
  final int readTimeMinutes;
  final HealthContentDifficulty difficulty;
  final List<String> targetConditions; // diabetes, hypertension, etc.
  final int likes;
  final int views;
  final double rating;
  final String author;
  final String? authorImageUrl;
  final bool isVerified;
  final bool isActive;
  final DateTime publishedAt;
  final DateTime updatedAt;
  final DateTime createdAt;

  HealthContentModel({
    required this.id,
    required this.title,
    required this.description,
    required this.content,
    required this.type,
    required this.category,
    this.tags = const [],
    required this.language,
    this.localizedTitles = const {},
    this.localizedDescriptions = const {},
    this.localizedContent = const {},
    this.imageUrl,
    this.videoUrl,
    this.audioUrl,
    this.readTimeMinutes = 5,
    this.difficulty = HealthContentDifficulty.beginner,
    this.targetConditions = const [],
    this.likes = 0,
    this.views = 0,
    this.rating = 0.0,
    required this.author,
    this.authorImageUrl,
    this.isVerified = false,
    this.isActive = true,
    required this.publishedAt,
    required this.updatedAt,
    required this.createdAt,
  });

  // Getters for localized content
  String getLocalizedTitle(String languageCode) {
    return localizedTitles[languageCode] ?? title;
  }

  String getLocalizedDescription(String languageCode) {
    return localizedDescriptions[languageCode] ?? description;
  }

  String getLocalizedContent(String languageCode) {
    return localizedContent[languageCode] ?? content;
  }

  // Computed properties
  bool get hasMedia => imageUrl != null || videoUrl != null || audioUrl != null;
  bool get hasVideo => videoUrl != null;
  bool get hasAudio => audioUrl != null;
  bool get isPopular => views > 100 || likes > 20;
  bool get isHighlyRated => rating >= 4.0;

  String get readTime {
    if (readTimeMinutes < 1) return 'Quick read';
    if (readTimeMinutes == 1) return '1 min read';
    return '$readTimeMinutes min read';
  }

  String get categoryDisplayName {
    switch (category.toLowerCase()) {
      case 'diabetes':
        return 'Diabetes Management';
      case 'hypertension':
        return 'Blood Pressure';
      case 'heart_health':
        return 'Heart Health';
      case 'nutrition':
        return 'Nutrition & Diet';
      case 'exercise':
        return 'Exercise & Fitness';
      case 'mental_health':
        return 'Mental Wellness';
      case 'medication':
        return 'Medication Guide';
      case 'prevention':
        return 'Disease Prevention';
      default:
        return category;
    }
  }

  // Factory constructor from Firestore
  factory HealthContentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return HealthContentModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      content: data['content'] ?? '',
      type: HealthContentType.values.firstWhere(
        (type) => type.toString() == data['type'],
        orElse: () => HealthContentType.article,
      ),
      category: data['category'] ?? '',
      tags: List<String>.from(data['tags'] ?? []),
      language: data['language'] ?? 'en',
      localizedTitles: Map<String, String>.from(data['localizedTitles'] ?? {}),
      localizedDescriptions: Map<String, String>.from(data['localizedDescriptions'] ?? {}),
      localizedContent: Map<String, String>.from(data['localizedContent'] ?? {}),
      imageUrl: data['imageUrl'],
      videoUrl: data['videoUrl'],
      audioUrl: data['audioUrl'],
      readTimeMinutes: data['readTimeMinutes'] ?? 5,
      difficulty: HealthContentDifficulty.values.firstWhere(
        (diff) => diff.toString() == data['difficulty'],
        orElse: () => HealthContentDifficulty.beginner,
      ),
      targetConditions: List<String>.from(data['targetConditions'] ?? []),
      likes: data['likes'] ?? 0,
      views: data['views'] ?? 0,
      rating: data['rating']?.toDouble() ?? 0.0,
      author: data['author'] ?? '',
      authorImageUrl: data['authorImageUrl'],
      isVerified: data['isVerified'] ?? false,
      isActive: data['isActive'] ?? true,
      publishedAt: (data['publishedAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  // Convert to Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'content': content,
      'type': type.toString(),
      'category': category,
      'tags': tags,
      'language': language,
      'localizedTitles': localizedTitles,
      'localizedDescriptions': localizedDescriptions,
      'localizedContent': localizedContent,
      'imageUrl': imageUrl,
      'videoUrl': videoUrl,
      'audioUrl': audioUrl,
      'readTimeMinutes': readTimeMinutes,
      'difficulty': difficulty.toString(),
      'targetConditions': targetConditions,
      'likes': likes,
      'views': views,
      'rating': rating,
      'author': author,
      'authorImageUrl': authorImageUrl,
      'isVerified': isVerified,
      'isActive': isActive,
      'publishedAt': Timestamp.fromDate(publishedAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'content': content,
      'type': type.toString(),
      'category': category,
      'tags': tags,
      'language': language,
      'localizedTitles': localizedTitles,
      'localizedDescriptions': localizedDescriptions,
      'localizedContent': localizedContent,
      'imageUrl': imageUrl,
      'videoUrl': videoUrl,
      'audioUrl': audioUrl,
      'readTimeMinutes': readTimeMinutes,
      'difficulty': difficulty.toString(),
      'targetConditions': targetConditions,
      'likes': likes,
      'views': views,
      'rating': rating,
      'author': author,
      'authorImageUrl': authorImageUrl,
      'isVerified': isVerified,
      'isActive': isActive,
      'publishedAt': publishedAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Factory constructor from JSON
  factory HealthContentModel.fromJson(Map<String, dynamic> json) {
    return HealthContentModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      content: json['content'] ?? '',
      type: HealthContentType.values.firstWhere(
        (type) => type.toString() == json['type'],
        orElse: () => HealthContentType.article,
      ),
      category: json['category'] ?? '',
      tags: List<String>.from(json['tags'] ?? []),
      language: json['language'] ?? 'en',
      localizedTitles: Map<String, String>.from(json['localizedTitles'] ?? {}),
      localizedDescriptions: Map<String, String>.from(json['localizedDescriptions'] ?? {}),
      localizedContent: Map<String, String>.from(json['localizedContent'] ?? {}),
      imageUrl: json['imageUrl'],
      videoUrl: json['videoUrl'],
      audioUrl: json['audioUrl'],
      readTimeMinutes: json['readTimeMinutes'] ?? 5,
      difficulty: HealthContentDifficulty.values.firstWhere(
        (diff) => diff.toString() == json['difficulty'],
        orElse: () => HealthContentDifficulty.beginner,
      ),
      targetConditions: List<String>.from(json['targetConditions'] ?? []),
      likes: json['likes'] ?? 0,
      views: json['views'] ?? 0,
      rating: json['rating']?.toDouble() ?? 0.0,
      author: json['author'] ?? '',
      authorImageUrl: json['authorImageUrl'],
      isVerified: json['isVerified'] ?? false,
      isActive: json['isActive'] ?? true,
      publishedAt: DateTime.parse(json['publishedAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  // Copy with method
  HealthContentModel copyWith({
    String? title,
    String? description,
    String? content,
    HealthContentType? type,
    String? category,
    List<String>? tags,
    String? language,
    Map<String, String>? localizedTitles,
    Map<String, String>? localizedDescriptions,
    Map<String, String>? localizedContent,
    String? imageUrl,
    String? videoUrl,
    String? audioUrl,
    int? readTimeMinutes,
    HealthContentDifficulty? difficulty,
    List<String>? targetConditions,
    int? likes,
    int? views,
    double? rating,
    String? author,
    String? authorImageUrl,
    bool? isVerified,
    bool? isActive,
    DateTime? publishedAt,
    DateTime? updatedAt,
  }) {
    return HealthContentModel(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      content: content ?? this.content,
      type: type ?? this.type,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      language: language ?? this.language,
      localizedTitles: localizedTitles ?? this.localizedTitles,
      localizedDescriptions: localizedDescriptions ?? this.localizedDescriptions,
      localizedContent: localizedContent ?? this.localizedContent,
      imageUrl: imageUrl ?? this.imageUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      audioUrl: audioUrl ?? this.audioUrl,
      readTimeMinutes: readTimeMinutes ?? this.readTimeMinutes,
      difficulty: difficulty ?? this.difficulty,
      targetConditions: targetConditions ?? this.targetConditions,
      likes: likes ?? this.likes,
      views: views ?? this.views,
      rating: rating ?? this.rating,
      author: author ?? this.author,
      authorImageUrl: authorImageUrl ?? this.authorImageUrl,
      isVerified: isVerified ?? this.isVerified,
      isActive: isActive ?? this.isActive,
      publishedAt: publishedAt ?? this.publishedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdAt: createdAt,
    );
  }
}

// Enums
enum HealthContentType {
  article,
  video,
  audio,
  infographic,
  quiz,
  checklist,
  guide,
  tip,
  recipe,
  exercise,
}

enum HealthContentDifficulty {
  beginner,
  intermediate,
  advanced,
}

// Extension for display names
extension HealthContentTypeExtension on HealthContentType {
  String get displayName {
    switch (this) {
      case HealthContentType.article:
        return 'Article';
      case HealthContentType.video:
        return 'Video';
      case HealthContentType.audio:
        return 'Audio';
      case HealthContentType.infographic:
        return 'Infographic';
      case HealthContentType.quiz:
        return 'Quiz';
      case HealthContentType.checklist:
        return 'Checklist';
      case HealthContentType.guide:
        return 'Guide';
      case HealthContentType.tip:
        return 'Quick Tip';
      case HealthContentType.recipe:
        return 'Recipe';
      case HealthContentType.exercise:
        return 'Exercise';
    }
  }

  String get icon {
    switch (this) {
      case HealthContentType.article:
        return '📄';
      case HealthContentType.video:
        return '🎥';
      case HealthContentType.audio:
        return '🎧';
      case HealthContentType.infographic:
        return '📊';
      case HealthContentType.quiz:
        return '❓';
      case HealthContentType.checklist:
        return '✅';
      case HealthContentType.guide:
        return '📖';
      case HealthContentType.tip:
        return '💡';
      case HealthContentType.recipe:
        return '🥗';
      case HealthContentType.exercise:
        return '🏃';
    }
  }
}

extension HealthContentDifficultyExtension on HealthContentDifficulty {
  String get displayName {
    switch (this) {
      case HealthContentDifficulty.beginner:
        return 'Beginner';
      case HealthContentDifficulty.intermediate:
        return 'Intermediate';
      case HealthContentDifficulty.advanced:
        return 'Advanced';
    }
  }

  String get icon {
    switch (this) {
      case HealthContentDifficulty.beginner:
        return '🟢';
      case HealthContentDifficulty.intermediate:
        return '🟡';
      case HealthContentDifficulty.advanced:
        return '🔴';
    }
  }
}