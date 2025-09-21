import 'package:flutter/foundation.dart';
import '../models/health_content_model.dart';
import '../models/user_model.dart';
import '../core/services/local_storage.dart';

class HealthFeedProvider extends ChangeNotifier {
  List<HealthContentModel> _allContent = [];
  List<HealthContentModel> _filteredContent = [];
  List<HealthContentModel> _bookmarkedContent = [];
  Set<String> _bookmarkedIds = {};
  
  bool _isLoading = false;
  String? _error;
  String _selectedCategory = 'all';
  String _selectedLanguage = 'en';
  HealthContentType? _selectedType;
  String _searchQuery = '';
  ContentSortBy _sortBy = ContentSortBy.latest;
  
  // User preferences
  List<String> _userConditions = [];
  List<String> _preferredCategories = [];
  
  // Getters
  List<HealthContentModel> get allContent => List.unmodifiable(_allContent);
  List<HealthContentModel> get filteredContent => List.unmodifiable(_filteredContent);
  List<HealthContentModel> get bookmarkedContent => List.unmodifiable(_bookmarkedContent);
  List<HealthContentModel> get recommendedContent => _getRecommendedContent();
  List<HealthContentModel> get popularContent => _getPopularContent();
  List<HealthContentModel> get recentContent => _getRecentContent();
  
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get selectedCategory => _selectedCategory;
  String get selectedLanguage => _selectedLanguage;
  HealthContentType? get selectedType => _selectedType;
  String get searchQuery => _searchQuery;
  ContentSortBy get sortBy => _sortBy;
  
  List<String> get availableCategories => [
    'all',
    'diabetes',
    'hypertension',
    'heart_health',
    'nutrition',
    'exercise',
    'mental_health',
    'medication',
    'prevention',
  ];
  
  List<HealthContentType> get availableTypes => HealthContentType.values;
  
  // Initialize with sample content and user preferences
  Future<void> initialize({UserModel? user}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      // Load user preferences
      if (user != null) {
        _userConditions = user.chronicConditions;
        _selectedLanguage = user.preferredLanguage ?? 'en';
        _loadUserPreferences();
      }
      
      // Load bookmarked content IDs
      await _loadBookmarks();
      
      // Load sample content (in production, this would be from Firestore)
      await _loadSampleContent();
      
      // Apply initial filtering
      _applyFilters();
      
    } catch (e) {
      _error = e.toString();
      debugPrint('HealthFeedProvider initialization error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Search and Filter Methods
  void setSearchQuery(String query) {
    _searchQuery = query.toLowerCase().trim();
    _applyFilters();
    notifyListeners();
  }
  
  void setCategory(String category) {
    _selectedCategory = category;
    _applyFilters();
    notifyListeners();
  }
  
  void setLanguage(String language) {
    _selectedLanguage = language;
    _applyFilters();
    notifyListeners();
  }
  
  void setContentType(HealthContentType? type) {
    _selectedType = type;
    _applyFilters();
    notifyListeners();
  }
  
  void setSortBy(ContentSortBy sortBy) {
    _sortBy = sortBy;
    _applyFilters();
    notifyListeners();
  }
  
  void clearFilters() {
    _selectedCategory = 'all';
    _selectedType = null;
    _searchQuery = '';
    _sortBy = ContentSortBy.latest;
    _applyFilters();
    notifyListeners();
  }
  
  // Content interaction methods
  Future<void> toggleBookmark(String contentId) async {
    if (_bookmarkedIds.contains(contentId)) {
      _bookmarkedIds.remove(contentId);
      _bookmarkedContent.removeWhere((content) => content.id == contentId);
    } else {
      _bookmarkedIds.add(contentId);
      final content = _allContent.firstWhere((c) => c.id == contentId);
      _bookmarkedContent.add(content);
    }
    
    await _saveBookmarks();
    notifyListeners();
  }
  
  bool isBookmarked(String contentId) {
    return _bookmarkedIds.contains(contentId);
  }
  
  Future<void> markAsRead(String contentId) async {
    // Update view count (in production, sync with server)
    final index = _allContent.indexWhere((c) => c.id == contentId);
    if (index != -1) {
      _allContent[index] = _allContent[index].copyWith(views: _allContent[index].views + 1);
    }
    notifyListeners();
  }
  
  Future<void> likeContent(String contentId) async {
    // Toggle like (in production, sync with server)
    final index = _allContent.indexWhere((c) => c.id == contentId);
    if (index != -1) {
      _allContent[index] = _allContent[index].copyWith(likes: _allContent[index].likes + 1);
    }
    _applyFilters();
    notifyListeners();
  }
  
  // Private methods
  void _applyFilters() {
    List<HealthContentModel> filtered = List.from(_allContent);
    
    // Language filter
    if (_selectedLanguage != 'all') {
      filtered = filtered.where((content) => 
        content.language == _selectedLanguage || 
        content.localizedContent.containsKey(_selectedLanguage)
      ).toList();
    }
    
    // Category filter
    if (_selectedCategory != 'all') {
      filtered = filtered.where((content) => 
        content.category.toLowerCase() == _selectedCategory.toLowerCase()
      ).toList();
    }
    
    // Type filter
    if (_selectedType != null) {
      filtered = filtered.where((content) => content.type == _selectedType).toList();
    }
    
    // Search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((content) =>
        content.getLocalizedTitle(_selectedLanguage).toLowerCase().contains(_searchQuery) ||
        content.getLocalizedDescription(_selectedLanguage).toLowerCase().contains(_searchQuery) ||
        content.tags.any((tag) => tag.toLowerCase().contains(_searchQuery)) ||
        content.author.toLowerCase().contains(_searchQuery)
      ).toList();
    }
    
    // Sort content
    _sortContent(filtered);
    
    _filteredContent = filtered;
  }
  
  void _sortContent(List<HealthContentModel> content) {
    switch (_sortBy) {
      case ContentSortBy.latest:
        content.sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
        break;
      case ContentSortBy.popular:
        content.sort((a, b) => (b.views + b.likes).compareTo(a.views + a.likes));
        break;
      case ContentSortBy.rating:
        content.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case ContentSortBy.alphabetical:
        content.sort((a, b) => a.getLocalizedTitle(_selectedLanguage)
            .compareTo(b.getLocalizedTitle(_selectedLanguage)));
        break;
      case ContentSortBy.readTime:
        content.sort((a, b) => a.readTimeMinutes.compareTo(b.readTimeMinutes));
        break;
    }
  }
  
  List<HealthContentModel> _getRecommendedContent() {
    List<HealthContentModel> recommended = [];
    
    // Content based on user conditions
    for (String condition in _userConditions) {
      recommended.addAll(_allContent.where((content) =>
        content.targetConditions.contains(condition.toLowerCase()) &&
        !recommended.contains(content)
      ));
    }
    
    // Popular content if no specific recommendations
    if (recommended.isEmpty) {
      recommended = _getPopularContent();
    }
    
    // Limit to 10 items
    return recommended.take(10).toList();
  }
  
  List<HealthContentModel> _getPopularContent() {
    List<HealthContentModel> popular = List.from(_allContent);
    popular.sort((a, b) => (b.views + b.likes).compareTo(a.views + a.likes));
    return popular.take(10).toList();
  }
  
  List<HealthContentModel> _getRecentContent() {
    List<HealthContentModel> recent = List.from(_allContent);
    recent.sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
    return recent.take(10).toList();
  }
  
  Future<void> _loadBookmarks() async {
    final bookmarks = LocalStorageService.getStringList('health_bookmarks') ?? [];
    _bookmarkedIds = Set.from(bookmarks);
    
    _bookmarkedContent = _allContent.where((content) => 
      _bookmarkedIds.contains(content.id)
    ).toList();
  }
  
  Future<void> _saveBookmarks() async {
    await LocalStorageService.saveStringList('health_bookmarks', _bookmarkedIds.toList());
  }
  
  void _loadUserPreferences() {
    final categories = LocalStorageService.getStringList('preferred_health_categories') ?? [];
    _preferredCategories = categories;
  }
  
  Future<void> _loadSampleContent() async {
    // Sample content - in production, this would load from Firestore
    final now = DateTime.now();
    
    _allContent = [
      // Diabetes content
      HealthContentModel(
        id: 'diabetes_diet_1',
        title: 'Managing Diabetes Through Diet',
        description: 'Learn how to control blood sugar levels with proper nutrition and meal planning.',
        content: '''
# Managing Diabetes Through Diet

Proper nutrition is crucial for managing diabetes effectively. Here are key principles:

## 1. Carbohydrate Counting
- Monitor carbohydrate intake
- Choose complex carbs over simple sugars
- Spread carbs throughout the day

## 2. Portion Control
- Use smaller plates
- Measure portions
- Follow the plate method

## 3. Healthy Food Choices
- Whole grains
- Lean proteins
- Non-starchy vegetables
- Healthy fats

## 4. Meal Timing
- Eat regular meals
- Don't skip breakfast
- Plan healthy snacks
        ''',
        type: HealthContentType.article,
        category: 'diabetes',
        tags: ['diabetes', 'diet', 'nutrition', 'blood sugar'],
        language: 'en',
        localizedTitles: {
          'hi': 'आहार के माध्यम से मधुमेह का प्रबंधन',
          'mr': 'आहाराद्वारे मधुमेहाचे व्यवस्थापन',
        },
        localizedDescriptions: {
          'hi': 'उचित पोषण और भोजन योजना के साथ रक्त शर्करा के स्तर को नियंत्रित करना सीखें।',
          'mr': 'योग्य पोषण आणि जेवणाच्या नियोजनासह रक्तशर्करेची पातळी नियंत्रित करण्यास शिका।',
        },
        imageUrl: 'https://example.com/diabetes_diet.jpg',
        readTimeMinutes: 8,
        difficulty: HealthContentDifficulty.beginner,
        targetConditions: ['diabetes', 'prediabetes'],
        likes: 45,
        views: 234,
        rating: 4.5,
        author: 'Dr. Priya Sharma',
        isVerified: true,
        publishedAt: now.subtract(const Duration(days: 2)),
        updatedAt: now.subtract(const Duration(days: 1)),
        createdAt: now.subtract(const Duration(days: 7)),
      ),
      
      // Hypertension content
      HealthContentModel(
        id: 'bp_exercise_1',
        title: 'Exercise for Blood Pressure Control',
        description: 'Discover safe and effective exercises to help lower and maintain healthy blood pressure.',
        content: '''
# Exercise for Blood Pressure Control

Regular physical activity is one of the most effective ways to lower blood pressure naturally.

## Safe Exercises for Hypertension:

### 1. Walking
- Start with 10-15 minutes daily
- Gradually increase to 30 minutes
- Maintain moderate pace

### 2. Swimming
- Low impact on joints
- Full body workout
- 20-30 minutes, 3 times per week

### 3. Cycling
- Stationary or outdoor
- Control intensity easily
- Good for cardiovascular health

### 4. Yoga
- Reduces stress
- Improves flexibility
- Gentle on the body

## Important Tips:
- Always warm up and cool down
- Monitor your heart rate
- Stay hydrated
- Consult your doctor before starting
        ''',
        type: HealthContentType.article,
        category: 'hypertension',
        tags: ['blood pressure', 'exercise', 'hypertension', 'fitness'],
        language: 'en',
        localizedTitles: {
          'hi': 'रक्तचाप नियंत्रण के लिए व्यायाम',
          'mr': 'रक्तदाब नियंत्रणासाठी व्यायाम',
        },
        imageUrl: 'https://example.com/bp_exercise.jpg',
        readTimeMinutes: 6,
        difficulty: HealthContentDifficulty.beginner,
        targetConditions: ['hypertension', 'heart disease'],
        likes: 67,
        views: 189,
        rating: 4.3,
        author: 'Dr. Amit Patel',
        isVerified: true,
        publishedAt: now.subtract(const Duration(days: 1)),
        updatedAt: now.subtract(const Duration(hours: 12)),
        createdAt: now.subtract(const Duration(days: 5)),
      ),
      
      // Heart Health content
      HealthContentModel(
        id: 'heart_healthy_foods',
        title: '10 Heart-Healthy Foods You Should Eat',
        description: 'Discover foods that promote cardiovascular health and reduce heart disease risk.',
        content: '''
# 10 Heart-Healthy Foods You Should Eat

## 1. Salmon
Rich in omega-3 fatty acids that reduce inflammation.

## 2. Oats
High in soluble fiber that helps lower cholesterol.

## 3. Berries
Packed with antioxidants and fiber.

## 4. Avocados
Good source of monounsaturated fats.

## 5. Nuts
Almonds and walnuts support heart health.

## 6. Olive Oil
Extra virgin olive oil reduces inflammation.

## 7. Leafy Greens
High in vitamins, minerals, and antioxidants.

## 8. Tomatoes
Rich in lycopene, a heart-protective antioxidant.

## 9. Beans
High in fiber and protein, low in fat.

## 10. Dark Chocolate
Contains flavonoids that benefit heart health.
        ''',
        type: HealthContentType.infographic,
        category: 'heart_health',
        tags: ['heart health', 'nutrition', 'diet', 'prevention'],
        language: 'en',
        imageUrl: 'https://example.com/heart_foods.jpg',
        readTimeMinutes: 4,
        difficulty: HealthContentDifficulty.beginner,
        targetConditions: ['heart disease', 'hypertension', 'high cholesterol'],
        likes: 89,
        views: 345,
        rating: 4.7,
        author: 'Nutritionist Ravi Kumar',
        isVerified: true,
        publishedAt: now.subtract(const Duration(days: 3)),
        updatedAt: now.subtract(const Duration(days: 2)),
        createdAt: now.subtract(const Duration(days: 10)),
      ),
      
      // Mental Health content
      HealthContentModel(
        id: 'stress_management',
        title: 'Simple Stress Management Techniques',
        description: 'Learn practical methods to manage stress and improve your mental well-being.',
        content: '''
# Simple Stress Management Techniques

## Breathing Exercises
- 4-7-8 breathing technique
- Box breathing
- Deep diaphragmatic breathing

## Mindfulness Practices
- 5-minute meditation
- Body scan relaxation
- Mindful walking

## Physical Activities
- Gentle stretching
- Progressive muscle relaxation
- Short walks in nature

## Lifestyle Changes
- Regular sleep schedule
- Limiting caffeine
- Connecting with others
        ''',
        type: HealthContentType.guide,
        category: 'mental_health',
        tags: ['stress', 'mental health', 'relaxation', 'wellness'],
        language: 'en',
        audioUrl: 'https://example.com/stress_audio.mp3',
        readTimeMinutes: 7,
        difficulty: HealthContentDifficulty.beginner,
        targetConditions: ['stress', 'anxiety', 'hypertension'],
        likes: 52,
        views: 167,
        rating: 4.4,
        author: 'Dr. Sunita Verma',
        isVerified: true,
        publishedAt: now.subtract(const Duration(hours: 18)),
        updatedAt: now.subtract(const Duration(hours: 6)),
        createdAt: now.subtract(const Duration(days: 2)),
      ),
      
      // Exercise content
      HealthContentModel(
        id: 'home_workout_seniors',
        title: '15-Minute Home Workout for Seniors',
        description: 'Safe and effective exercises you can do at home, designed specifically for older adults.',
        content: '''
# 15-Minute Home Workout for Seniors

## Warm-up (3 minutes)
- Arm circles
- Neck rolls
- Ankle rotations

## Strength Exercises (8 minutes)
- Chair stands
- Wall push-ups
- Seated leg extensions
- Arm raises with light weights

## Balance and Flexibility (4 minutes)
- Single-leg stands
- Heel-to-toe walking
- Seated spinal twist
- Shoulder stretches

Remember to listen to your body and stop if you feel pain!
        ''',
        type: HealthContentType.video,
        category: 'exercise',
        tags: ['seniors', 'exercise', 'home workout', 'safety'],
        language: 'en',
        videoUrl: 'https://example.com/senior_workout.mp4',
        imageUrl: 'https://example.com/senior_exercise.jpg',
        readTimeMinutes: 15,
        difficulty: HealthContentDifficulty.beginner,
        targetConditions: ['arthritis', 'osteoporosis', 'general wellness'],
        likes: 34,
        views: 123,
        rating: 4.6,
        author: 'Fitness Trainer Maya Singh',
        isVerified: true,
        publishedAt: now.subtract(const Duration(hours: 6)),
        updatedAt: now.subtract(const Duration(hours: 2)),
        createdAt: now.subtract(const Duration(days: 1)),
      ),
    ];
  }
  
  // Refresh content (for pull-to-refresh)
  Future<void> refreshContent() async {
    await initialize();
  }
}

enum ContentSortBy {
  latest,
  popular,
  rating,
  alphabetical,
  readTime,
}

extension ContentSortByExtension on ContentSortBy {
  String get displayName {
    switch (this) {
      case ContentSortBy.latest:
        return 'Latest';
      case ContentSortBy.popular:
        return 'Most Popular';
      case ContentSortBy.rating:
        return 'Highest Rated';
      case ContentSortBy.alphabetical:
        return 'A-Z';
      case ContentSortBy.readTime:
        return 'Quick Read';
    }
  }
}