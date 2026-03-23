import 'package:flutter/foundation.dart';
import 'package:device_calendar/device_calendar.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

/// Service for managing calendar events on Android and iOS
class CalendarService {
  static final CalendarService _instance = CalendarService._internal();
  factory CalendarService() => _instance;
  CalendarService._internal();

  final DeviceCalendarPlugin _deviceCalendarPlugin = DeviceCalendarPlugin();
  bool _isInitialized = false;
  List<Calendar> _calendars = [];

  /// Initialize the calendar service
  Future<bool> initialize() async {
    try {
      // Initialize timezone data
      tz_data.initializeTimeZones();

      // Request calendar permission
      final status = await Permission.calendar.request();
      if (!status.isGranted) {
        if (kDebugMode) {
          print('Calendar permission denied');
        }
        return false;
      }

      // Check if calendar plugin has permissions
      final permissionsGranted = await _deviceCalendarPlugin.hasPermissions();
      if (permissionsGranted.data != true) {
        final result = await _deviceCalendarPlugin.requestPermissions();
        if (result.data != true) {
          return false;
        }
      }

      _isInitialized = true;
      await _loadCalendars();
      
      if (kDebugMode) {
        print('Calendar service initialized successfully');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Calendar initialization error: $e');
      }
      return false;
    }
  }

  /// Load available calendars
  Future<void> _loadCalendars() async {
    if (!_isInitialized) return;

    try {
      final calendarsResult = await _deviceCalendarPlugin.retrieveCalendars();
      _calendars = calendarsResult.data ?? [];
      
      if (kDebugMode) {
        print('Loaded ${_calendars.length} calendars');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading calendars: $e');
      }
    }
  }

  /// Get list of available calendars
  List<Calendar> get calendars => _calendars;

  /// Get default calendar (usually the first one)
  Calendar? get defaultCalendar {
    if (_calendars.isEmpty) return null;
    // Try to find a default calendar
    return _calendars.firstWhere(
      (cal) => cal.isDefault ?? false,
      orElse: () => _calendars.first,
    );
  }

  /// Get events for a specific date range
  Future<List<Event>> getEvents({
    DateTime? startDate,
    DateTime? endDate,
    String? calendarId,
  }) async {
    if (!_isInitialized) return [];

    try {
      final start = startDate ?? DateTime.now();
      final end = endDate ?? start.add(const Duration(days: 7));

      // Use specified calendar or default
      final calId = calendarId ?? defaultCalendar?.id;
      if (calId == null) return [];

      final eventsResult = await _deviceCalendarPlugin.retrieveEvents(
        calId,
        RetrieveEventsParams(
          startDate: start,
          endDate: end,
        ),
      );

      return eventsResult.data ?? [];
    } catch (e) {
      if (kDebugMode) {
        print('Error retrieving events: $e');
      }
      return [];
    }
  }

  /// Get today's events
  Future<List<Event>> getTodayEvents() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return getEvents(startDate: startOfDay, endDate: endOfDay);
  }

  /// Get events for tomorrow
  Future<List<Event>> getTomorrowEvents() async {
    final now = DateTime.now();
    final tomorrow = now.add(const Duration(days: 1));
    final startOfDay = DateTime(tomorrow.year, tomorrow.month, tomorrow.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return getEvents(startDate: startOfDay, endDate: endOfDay);
  }

  /// Get events for this week
  Future<List<Event>> getThisWeekEvents() async {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 7));

    return getEvents(startDate: startOfWeek, endDate: endOfWeek);
  }

  /// Create a new calendar event
  Future<Result<String>?> createEvent({
    required String title,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    bool isAllDay = false,
    String? location,
    List<Reminder>? reminders,
    String? calendarId,
  }) async {
    if (!_isInitialized) {
      return null;
    }

    try {
      final calId = calendarId ?? defaultCalendar?.id;
      if (calId == null) {
        return null;
      }

      final now = DateTime.now();
      final start = startDate ?? now.add(const Duration(hours: 1));
      final end = endDate ?? start.add(const Duration(hours: 1));

      final event = Event(
        calId,
        title: title,
        description: description,
        start: tz.TZDateTime.from(start, tz.local),
        end: tz.TZDateTime.from(end, tz.local),
        allDay: isAllDay,
        location: location,
        reminders: reminders ?? [Reminder(minutes: 15)],
      );

      final result = await _deviceCalendarPlugin.createOrUpdateEvent(event);
      
      if (kDebugMode) {
        print('Event created: ${result?.data}');
      }
      
      return result;
    } catch (e) {
      if (kDebugMode) {
        print('Error creating event: $e');
      }
      return null;
    }
  }

  /// Delete an event
  Future<bool> deleteEvent(String eventId, {String? calendarId}) async {
    if (!_isInitialized) return false;

    try {
      final calId = calendarId ?? defaultCalendar?.id;
      if (calId == null) return false;

      final result = await _deviceCalendarPlugin.deleteEvent(calId, eventId);
      return result.data ?? false;
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting event: $e');
      }
      return false;
    }
  }

  /// Format events for voice response
  String formatEventsForVoice(List<Event> events, {String title = "Here's your schedule"}) {
    if (events.isEmpty) {
      return "You have no events scheduled.";
    }

    final buffer = StringBuffer();
    buffer.write('$title: ');

    for (int i = 0; i < events.length && i < 5; i++) {
      final event = events[i];
      final eventTitle = event.title ?? 'Untitled event';
      
      if (event.allDay == true) {
        buffer.write('$eventTitle all day');
      } else {
        final startTime = event.start;
        if (startTime != null) {
          final hour = startTime.hour > 12 ? startTime.hour - 12 : startTime.hour;
          final period = startTime.hour >= 12 ? 'PM' : 'AM';
          final minute = startTime.minute.toString().padLeft(2, '0');
          buffer.write('$eventTitle at $hour:$minute $period');
        } else {
          buffer.write(eventTitle);
        }
      }

      if (i < events.length - 1 && i < 4) {
        buffer.write(', ');
      }
    }

    if (events.length > 5) {
      buffer.write(', and ${events.length - 5} more events');
    }

    return buffer.toString();
  }

  /// Create reminder event
  Future<Result<String>?> createReminder({
    required String title,
    DateTime? reminderTime,
    int minutesBefore = 15,
  }) async {
    final reminder = reminderTime ?? DateTime.now().add(Duration(minutes: minutesBefore));
    
    return createEvent(
      title: title,
      startDate: reminder,
      endDate: reminder.add(const Duration(minutes: 1)),
      reminders: [Reminder(minutes: minutesBefore)],
    );
  }

  /// Check if calendar is available
  bool get isAvailable => _isInitialized && _calendars.isNotEmpty;

  /// Get calendar by ID
  Calendar? getCalendarById(String id) {
    try {
      return _calendars.firstWhere((cal) => cal.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Refresh calendars list
  Future<void> refreshCalendars() async {
    await _loadCalendars();
  }

  /// Dispose resources
  void dispose() {
    _calendars.clear();
    _isInitialized = false;
  }
}
