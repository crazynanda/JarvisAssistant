import 'package:flutter/material.dart';
import 'package:device_calendar/device_calendar.dart';
import '../services/calendar_service.dart';
import 'package:intl/intl.dart';

/// Widget to display calendar events in a sleek UI
class CalendarEventsWidget extends StatefulWidget {
  final Color backgroundColor;
  final Color cardColor;
  final Color accentColor;
  final Color textColor;
  final Color secondaryTextColor;

  const CalendarEventsWidget({
    super.key,
    required this.backgroundColor,
    required this.cardColor,
    required this.accentColor,
    required this.textColor,
    required this.secondaryTextColor,
  });

  @override
  State<CalendarEventsWidget> createState() => _CalendarEventsWidgetState();
}

class _CalendarEventsWidgetState extends State<CalendarEventsWidget> {
  final CalendarService _calendarService = CalendarService();
  List<Event> _todayEvents = [];
  List<Event> _upcomingEvents = [];
  bool _isLoading = true;
  bool _hasPermission = false;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() {
      _isLoading = true;
    });

    final initialized = await _calendarService.initialize();
    
    if (initialized) {
      final today = await _calendarService.getTodayEvents();
      final upcoming = await _calendarService.getEvents(
        startDate: DateTime.now().add(const Duration(days: 1)),
        endDate: DateTime.now().add(const Duration(days: 7)),
      );

      setState(() {
        _todayEvents = today;
        _upcomingEvents = upcoming.take(3).toList();
        _hasPermission = true;
        _isLoading = false;
      });
    } else {
      setState(() {
        _hasPermission = false;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingWidget();
    }

    if (!_hasPermission) {
      return _buildPermissionWidget();
    }

    if (_todayEvents.isEmpty && _upcomingEvents.isEmpty) {
      return _buildEmptyWidget();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.accentColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                color: widget.accentColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Calendar',
                style: TextStyle(
                  color: widget.textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (_todayEvents.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: widget.accentColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_todayEvents.length} today',
                    style: TextStyle(
                      color: widget.accentColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Today's Events
          if (_todayEvents.isNotEmpty) ...[
            Text(
              'Today',
              style: TextStyle(
                color: widget.secondaryTextColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            ..._todayEvents.take(2).map((event) => _buildEventItem(event, true)),
            if (_todayEvents.length > 2)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '+${_todayEvents.length - 2} more events',
                  style: TextStyle(
                    color: widget.secondaryTextColor.withValues(alpha: 0.7),
                    fontSize: 11,
                  ),
                ),
              ),
            const SizedBox(height: 12),
          ],

          // Upcoming Events
          if (_upcomingEvents.isNotEmpty) ...[
            Text(
              'Upcoming',
              style: TextStyle(
                color: widget.secondaryTextColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            ..._upcomingEvents.map((event) => _buildEventItem(event, false)),
          ],
        ],
      ),
    );
  }

  Widget _buildEventItem(Event event, bool isToday) {
    final startTime = event.start;
    final title = event.title ?? 'Untitled Event';
    
    String timeText;
    if (event.allDay == true) {
      timeText = 'All day';
    } else if (startTime != null) {
      timeText = DateFormat('h:mm a').format(startTime);
    } else {
      timeText = '';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: widget.backgroundColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isToday 
              ? widget.accentColor.withValues(alpha: 0.3)
              : Colors.transparent,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: isToday ? widget.accentColor : widget.secondaryTextColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: widget.textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (timeText.isNotEmpty)
                  Text(
                    timeText,
                    style: TextStyle(
                      color: widget.secondaryTextColor,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  Widget _buildPermissionWidget() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.accentColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.calendar_today_outlined,
            color: widget.secondaryTextColor,
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            'Calendar Access Required',
            style: TextStyle(
              color: widget.textColor,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Enable calendar access to see your events',
            style: TextStyle(
              color: widget.secondaryTextColor,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _loadEvents,
            child: Text(
              'Grant Access',
              style: TextStyle(color: widget.accentColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.accentColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.event_available,
            color: widget.accentColor,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No Upcoming Events',
                  style: TextStyle(
                    color: widget.textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Your calendar is clear for the next few days',
                  style: TextStyle(
                    color: widget.secondaryTextColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
