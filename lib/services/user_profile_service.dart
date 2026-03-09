import 'package:hive_flutter/hive_flutter.dart';
import '../models/user_profile.dart';

/// Service for managing user profile and personalization
class UserProfileService {
  static final UserProfileService _instance = UserProfileService._internal();
  factory UserProfileService() => _instance;
  UserProfileService._internal();

  static const String _profileBoxName = 'user_profile';
  static const String _profileKey = 'current_profile';
  
  Box<UserProfile>? _profileBox;
  UserProfile? _currentProfile;

  /// Initialize the profile service
  Future<void> initialize() async {
    // Register adapter if not already registered
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(UserProfileAdapter());
    }
    
    _profileBox = await Hive.openBox<UserProfile>(_profileBoxName);
    
    // Load or create default profile
    await _loadProfile();
  }

  /// Load existing profile or create default
  Future<void> _loadProfile() async {
    _currentProfile = _profileBox?.get(_profileKey);
    
    if (_currentProfile == null) {
      // Create default profile
      _currentProfile = UserProfile(
        name: 'User',
        preferredGreeting: 'sir',
        createdAt: DateTime.now(),
        lastActive: DateTime.now(),
      );
      await _saveProfile();
    }
  }

  /// Save current profile to Hive
  Future<void> _saveProfile() async {
    if (_currentProfile != null) {
      await _profileBox?.put(_profileKey, _currentProfile!);
    }
  }

  /// Get current user profile
  UserProfile? get profile => _currentProfile;

  /// Check if profile exists
  bool get hasProfile => _currentProfile != null;

  /// Update user name
  Future<void> updateName(String name) async {
    if (_currentProfile != null) {
      _currentProfile!.name = name;
      await _saveProfile();
    }
  }

  /// Update preferred greeting (sir, madam, boss, etc.)
  Future<void> updatePreferredGreeting(String greeting) async {
    if (_currentProfile != null) {
      _currentProfile!.preferredGreeting = greeting;
      await _saveProfile();
    }
  }

  /// Add user interest
  Future<void> addInterest(String interest) async {
    if (_currentProfile != null) {
      if (!_currentProfile!.interests.contains(interest)) {
        _currentProfile!.interests.add(interest);
        await _saveProfile();
      }
    }
  }

  /// Remove user interest
  Future<void> removeInterest(String interest) async {
    if (_currentProfile != null) {
      _currentProfile!.interests.remove(interest);
      await _saveProfile();
    }
  }

  /// Update preferences
  Future<void> updatePreference(String key, dynamic value) async {
    if (_currentProfile != null) {
      _currentProfile!.preferences[key] = value;
      await _saveProfile();
    }
  }

  /// Get preference value
  dynamic getPreference(String key, {dynamic defaultValue}) {
    return _currentProfile?.preferences[key] ?? defaultValue;
  }

  /// Update last active timestamp
  Future<void> updateLastActive() async {
    if (_currentProfile != null) {
      _currentProfile!.updateLastActive();
      await _saveProfile();
    }
  }

  /// Increment conversation count
  Future<void> incrementConversations() async {
    if (_currentProfile != null) {
      _currentProfile!.incrementConversations();
      await _saveProfile();
    }
  }

  /// Update voice preference
  Future<void> updateVoicePreference(String voice) async {
    if (_currentProfile != null) {
      _currentProfile!.voicePreference = voice;
      await _saveProfile();
    }
  }

  /// Update speech rate
  Future<void> updateSpeechRate(double rate) async {
    if (_currentProfile != null) {
      _currentProfile!.speechRate = rate.clamp(0.1, 1.0);
      await _saveProfile();
    }
  }

  /// Get personalized greeting
  String getGreeting() {
    if (_currentProfile == null) return 'Hello!';
    return _currentProfile!.getTimeBasedGreeting();
  }

  /// Get welcome back message
  String getWelcomeBackMessage() {
    if (_currentProfile == null) return 'Welcome back!';
    return _currentProfile!.getWelcomeBackMessage();
  }

  /// Get user name
  String get userName => _currentProfile?.name ?? 'User';

  /// Get preferred greeting term
  String get preferredGreeting => _currentProfile?.preferredGreeting ?? 'sir';

  /// Get interests list
  List<String> get interests => _currentProfile?.interests ?? [];

  /// Get total conversations
  int get totalConversations => _currentProfile?.totalConversations ?? 0;

  /// Check if this is first time user
  bool get isFirstTimeUser => (_currentProfile?.totalConversations ?? 0) < 3;

  /// Reset profile to defaults
  Future<void> resetProfile() async {
    _currentProfile = UserProfile(
      name: 'User',
      preferredGreeting: 'sir',
      createdAt: DateTime.now(),
      lastActive: DateTime.now(),
    );
    await _saveProfile();
  }

  /// Close the box
  Future<void> dispose() async {
    await _profileBox?.close();
  }
}
