import 'package:hive/hive.dart';

part 'user_profile.g.dart';

@HiveType(typeId: 2)
class UserProfile extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  String preferredGreeting;

  @HiveField(2)
  List<String> interests;

  @HiveField(3)
  Map<String, dynamic> preferences;

  @HiveField(4)
  DateTime createdAt;

  @HiveField(5)
  DateTime lastActive;

  @HiveField(6)
  int totalConversations;

  @HiveField(7)
  String? profileImagePath;

  @HiveField(8)
  String voicePreference;

  @HiveField(9)
  double speechRate;

  UserProfile({
    required this.name,
    this.preferredGreeting = 'sir',
    this.interests = const [],
    this.preferences = const {},
    required this.createdAt,
    required this.lastActive,
    this.totalConversations = 0,
    this.profileImagePath,
    this.voicePreference = 'default',
    this.speechRate = 0.5,
  });

  /// Get personalized greeting based on time of day
  String getTimeBasedGreeting() {
    final hour = DateTime.now().hour;
    String timeGreeting;
    
    if (hour >= 5 && hour < 12) {
      timeGreeting = 'Good morning';
    } else if (hour >= 12 && hour < 17) {
      timeGreeting = 'Good afternoon';
    } else if (hour >= 17 && hour < 22) {
      timeGreeting = 'Good evening';
    } else {
      timeGreeting = 'Good night';
    }
    
    return '$timeGreeting, $preferredGreeting.';
  }

  /// Get welcome back message
  String getWelcomeBackMessage() {
    return 'Welcome back, $preferredGreeting. How can I assist you today?';
  }

  /// Update last active timestamp
  void updateLastActive() {
    lastActive = DateTime.now();
  }

  /// Increment conversation count
  void incrementConversations() {
    totalConversations++;
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'preferredGreeting': preferredGreeting,
      'interests': interests,
      'preferences': preferences,
      'createdAt': createdAt.toIso8601String(),
      'lastActive': lastActive.toIso8601String(),
      'totalConversations': totalConversations,
      'profileImagePath': profileImagePath,
      'voicePreference': voicePreference,
      'speechRate': speechRate,
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      name: json['name'] as String,
      preferredGreeting: json['preferredGreeting'] as String? ?? 'sir',
      interests: (json['interests'] as List<dynamic>?)?.cast<String>() ?? [],
      preferences: (json['preferences'] as Map<String, dynamic>?) ?? {},
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastActive: DateTime.parse(json['lastActive'] as String),
      totalConversations: json['totalConversations'] as int? ?? 0,
      profileImagePath: json['profileImagePath'] as String?,
      voicePreference: json['voicePreference'] as String? ?? 'default',
      speechRate: json['speechRate'] as double? ?? 0.5,
    );
  }
}
