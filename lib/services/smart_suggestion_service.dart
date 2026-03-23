import 'package:flutter/material.dart';
import '../services/calendar_service.dart';
import '../services/user_profile_service.dart';
import '../services/chat_history_service.dart';

/// Service for generating smart, contextual suggestions
class SmartSuggestionService {
  static final SmartSuggestionService _instance = SmartSuggestionService._internal();
  factory SmartSuggestionService() => _instance;
  SmartSuggestionService._internal();

  final CalendarService _calendarService = CalendarService();
  final UserProfileService _userProfile = UserProfileService();
  final ChatHistoryService _chatHistory = ChatHistoryService();

  /// Get contextual greeting based on time, calendar, and history
  Future<String> getContextualGreeting() async {
    final hour = DateTime.now().hour;
    final greeting = _userProfile.getGreeting();
    
    // Check calendar for context
    final todayEvents = await _calendarService.getTodayEvents();
    
    if (todayEvents.isNotEmpty) {
      final nextEvent = todayEvents.first;
      final eventTitle = nextEvent.title ?? 'event';
      final startTime = nextEvent.start;
      
      if (startTime != null) {
        final now = DateTime.now();
        final difference = startTime.difference(now);
        
        if (difference.inMinutes > 0 && difference.inMinutes <= 60) {
          return '$greeting You have "$eventTitle" in ${difference.inMinutes} minutes.';
        } else if (difference.inHours > 0 && difference.inHours <= 3) {
          return '$greeting You have "$eventTitle" in ${difference.inHours} hours.';
        }
      }
    }

    // Check if user has been active today
    final recentMessages = _chatHistory.getRecentMessages(days: 1);
    if (recentMessages.isEmpty) {
      // First interaction of the day
      if (hour < 12) {
        return '$greeting I hope you have a productive day ahead!';
      } else if (hour < 17) {
        return '$greeting How is your day going so far?';
      } else {
        return '$greeting How was your day?';
      }
    }

    return greeting;
  }

  /// Get proactive suggestions based on context
  Future<List<SmartSuggestion>> getProactiveSuggestions() async {
    final suggestions = <SmartSuggestion>[];
    final hour = DateTime.now().hour;
    final now = DateTime.now();

    // Morning routine suggestions (6 AM - 10 AM)
    if (hour >= 6 && hour < 10) {
      final todayEvents = await _calendarService.getTodayEvents();
      if (todayEvents.isNotEmpty) {
        suggestions.add(SmartSuggestion(
          title: 'Today\'s Schedule',
          description: 'You have ${todayEvents.length} events today',
          icon: Icons.calendar_today,
          action: 'show_calendar',
          priority: SuggestionPriority.high,
        ));
      }

      suggestions.add(SmartSuggestion(
        title: 'Weather Check',
        description: 'Get today\'s weather forecast',
        icon: Icons.wb_sunny,
        action: 'weather',
        priority: SuggestionPriority.medium,
      ));
    }

    // Lunch time suggestions (11 AM - 2 PM)
    if (hour >= 11 && hour < 14) {
      suggestions.add(SmartSuggestion(
        title: 'Lunch Break',
        description: 'Find nearby restaurants',
        icon: Icons.restaurant,
        action: 'find_restaurants',
        priority: SuggestionPriority.low,
      ));
    }

    // Evening suggestions (5 PM - 8 PM)
    if (hour >= 17 && hour < 20) {
      final tomorrowEvents = await _calendarService.getTomorrowEvents();
      if (tomorrowEvents.isNotEmpty) {
        suggestions.add(SmartSuggestion(
          title: 'Tomorrow\'s Preview',
          description: '${tomorrowEvents.length} events tomorrow',
          icon: Icons.event_note,
          action: 'show_tomorrow',
          priority: SuggestionPriority.medium,
        ));
      }
    }

    // Night suggestions (9 PM - 11 PM)
    if (hour >= 21 && hour < 23) {
      suggestions.add(SmartSuggestion(
        title: 'Set Alarm',
        description: 'Wake up on time tomorrow',
        icon: Icons.alarm,
        action: 'set_alarm',
        priority: SuggestionPriority.low,
      ));
    }

    // Context-based suggestions from recent activity
    final recentMessages = _chatHistory.getRecentMessages(days: 1);
    if (recentMessages.isNotEmpty) {
      final lastMessage = recentMessages.last.text.toLowerCase();
      
      // Follow up on incomplete tasks
      if (lastMessage.contains('remind') || lastMessage.contains('later')) {
        suggestions.add(SmartSuggestion(
          title: 'Set Reminder',
          description: 'Create a reminder for your task',
          icon: Icons.notifications_active,
          action: 'create_reminder',
          priority: SuggestionPriority.high,
        ));
      }

      // Follow up on questions
      if (lastMessage.contains('?') && recentMessages.length > 1) {
        final prevMessage = recentMessages[recentMessages.length - 2].text.toLowerCase();
        if (prevMessage.contains('search') || prevMessage.contains('find')) {
          suggestions.add(SmartSuggestion(
            title: 'Search More',
            description: 'Continue your research',
            icon: Icons.search,
            action: 'search_continue',
            priority: SuggestionPriority.medium,
          ));
        }
      }
    }

    // Time-based productivity suggestions
    if (hour >= 9 && hour < 17) {
      suggestions.add(SmartSuggestion(
        title: 'Focus Mode',
        description: 'Minimize distractions for 25 minutes',
        icon: Icons.timer,
        action: 'focus_mode',
        priority: SuggestionPriority.low,
      ));
    }

    // Sort by priority
    suggestions.sort((a, b) => b.priority.index.compareTo(a.priority.index));

    // Return top 3 suggestions
    return suggestions.take(3).toList();
  }

  /// Get quick commands based on user interests
  List<String> getSuggestedCommands() {
    final interests = _userProfile.interests;
    final commands = <String>[];

    // Base commands everyone might want
    commands.addAll([
      'What\'s on my calendar?',
      'Set a reminder',
      'Check the weather',
    ]);

    // Interest-based suggestions
    for (final interest in interests) {
      final lowerInterest = interest.toLowerCase();
      
      if (lowerInterest.contains('tech') || lowerInterest.contains('technology')) {
        commands.add('Latest tech news');
      } else if (lowerInterest.contains('sports')) {
        commands.add('Sports updates');
      } else if (lowerInterest.contains('music')) {
        commands.add('Play my music');
      } else if (lowerInterest.contains('news')) {
        commands.add('Today\'s headlines');
      } else if (lowerInterest.contains('travel')) {
        commands.add('Weather at my destination');
      } else if (lowerInterest.contains('food') || lowerInterest.contains('cooking')) {
        commands.add('Find restaurants nearby');
      }
    }

    return commands.take(5).toList();
  }

  /// Check if user might need a break
  bool shouldSuggestBreak() {
    final recentMessages = _chatHistory.getRecentMessages(days: 1);
    
    if (recentMessages.length >= 10) {
      // User has been very active
      final lastMessage = recentMessages.last.timestamp;
      final now = DateTime.now();
      
      // If active for more than 30 minutes continuously
      if (now.difference(lastMessage).inMinutes < 5) {
        return true;
      }
    }
    
    return false;
  }

  /// Get daily briefing content
  Future<DailyBriefing> getDailyBriefing() async {
    final todayEvents = await _calendarService.getTodayEvents();
    final tomorrowEvents = await _calendarService.getTomorrowEvents();
    
    final eventSummary = StringBuffer();
    
    if (todayEvents.isEmpty) {
      eventSummary.write('You have no events scheduled for today. ');
    } else {
      eventSummary.write('You have ${todayEvents.length} event${todayEvents.length > 1 ? 's' : ''} today. ');
      
      // Mention next event
      final nextEvent = todayEvents.firstWhere(
        (e) => e.start?.isAfter(DateTime.now()) ?? false,
        orElse: () => todayEvents.first,
      );
      
      final nextEventStart = nextEvent.start;
      if (nextEventStart != null) {
        final timeStr = _formatTime(nextEventStart);
        eventSummary.write('Your next event "${nextEvent.title}" is at $timeStr. ');
      }
    }

    return DailyBriefing(
      greeting: await getContextualGreeting(),
      calendarSummary: eventSummary.toString(),
      eventCount: todayEvents.length,
      suggestionCount: 3,
    );
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour;
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }
}

/// Model for smart suggestions
class SmartSuggestion {
  final String title;
  final String description;
  final IconData icon;
  final String action;
  final SuggestionPriority priority;

  SmartSuggestion({
    required this.title,
    required this.description,
    required this.icon,
    required this.action,
    required this.priority,
  });
}

enum SuggestionPriority {
  low,
  medium,
  high,
}

/// Daily briefing model
class DailyBriefing {
  final String greeting;
  final String calendarSummary;
  final int eventCount;
  final int suggestionCount;

  DailyBriefing({
    required this.greeting,
    required this.calendarSummary,
    required this.eventCount,
    required this.suggestionCount,
  });

  String get fullBriefing => '$greeting $calendarSummary';
}
