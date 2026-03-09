import 'package:flutter/material.dart';

/// Reusable quick action chip widget for assistant responses
class QuickActionChips extends StatelessWidget {
  final List<String> actions;
  final Function(String) onActionSelected;
  final Color chipColor;
  final Color textColor;
  final Color borderColor;

  const QuickActionChips({
    super.key,
    required this.actions,
    required this.onActionSelected,
    required this.chipColor,
    required this.textColor,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    if (actions.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: actions.map((action) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => onActionSelected(action),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: chipColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: borderColor,
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: chipColor.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getIconForAction(action),
                        size: 16,
                        color: textColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        action,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  IconData _getIconForAction(String action) {
    final lowerAction = action.toLowerCase();
    
    if (lowerAction.contains('remind') || lowerAction.contains('timer')) {
      return Icons.timer_outlined;
    } else if (lowerAction.contains('call') || lowerAction.contains('phone')) {
      return Icons.phone_outlined;
    } else if (lowerAction.contains('message') || lowerAction.contains('text')) {
      return Icons.message_outlined;
    } else if (lowerAction.contains('email') || lowerAction.contains('mail')) {
      return Icons.email_outlined;
    } else if (lowerAction.contains('search') || lowerAction.contains('find')) {
      return Icons.search_outlined;
    } else if (lowerAction.contains('calendar') || lowerAction.contains('schedule')) {
      return Icons.calendar_today_outlined;
    } else if (lowerAction.contains('navigate') || lowerAction.contains('direction')) {
      return Icons.navigation_outlined;
    } else if (lowerAction.contains('play') || lowerAction.contains('music')) {
      return Icons.play_arrow_outlined;
    } else if (lowerAction.contains('more') || lowerAction.contains('details')) {
      return Icons.read_more_outlined;
    } else if (lowerAction.contains('yes') || lowerAction.contains('confirm')) {
      return Icons.check_circle_outline;
    } else if (lowerAction.contains('no') || lowerAction.contains('cancel')) {
      return Icons.cancel_outlined;
    } else if (lowerAction.contains('save') || lowerAction.contains('bookmark')) {
      return Icons.bookmark_outline;
    } else if (lowerAction.contains('share')) {
      return Icons.share_outlined;
    } else if (lowerAction.contains('copy')) {
      return Icons.copy_outlined;
    }
    
    return Icons.touch_app_outlined;
  }
}

/// Generator for common quick action suggestions
class QuickActionGenerator {
  /// Generate actions based on message content
  static List<String> generateActions(String message) {
    final lowerMessage = message.toLowerCase();
    final actions = <String>[];

    // Weather-related actions
    if (lowerMessage.contains('weather') || lowerMessage.contains('forecast')) {
      actions.addAll(['Hourly forecast', '5-day forecast', 'Set weather alert']);
    }

    // Time-related actions
    if (lowerMessage.contains('time') || lowerMessage.contains('schedule')) {
      actions.addAll(['Set reminder', 'Add to calendar', 'Set timer']);
    }

    // Task-related actions
    if (lowerMessage.contains('task') || lowerMessage.contains('todo') || 
        lowerMessage.contains('remind')) {
      actions.addAll(['Create task', 'Set reminder', 'View all tasks']);
    }

    // Search-related actions
    if (lowerMessage.contains('search') || lowerMessage.contains('find') ||
        lowerMessage.contains('look up')) {
      actions.addAll(['Search web', 'Deep search', 'Save result']);
    }

    // Navigation-related actions
    if (lowerMessage.contains('navigate') || lowerMessage.contains('direction') ||
        lowerMessage.contains('route')) {
      actions.addAll(['Start navigation', 'View map', 'Share location']);
    }

    // Communication-related actions
    if (lowerMessage.contains('call') || lowerMessage.contains('phone') ||
        lowerMessage.contains('contact')) {
      actions.addAll(['Call now', 'Send message', 'Add contact']);
    }

    // Music/Media-related actions
    if (lowerMessage.contains('music') || lowerMessage.contains('song') ||
        lowerMessage.contains('play')) {
      actions.addAll(['Play now', 'Add to queue', 'Save playlist']);
    }

    // News/Information-related actions
    if (lowerMessage.contains('news') || lowerMessage.contains('article') ||
        lowerMessage.contains('story')) {
      actions.addAll(['Read more', 'Related stories', 'Save for later']);
    }

    // Translation-related actions
    if (lowerMessage.contains('translate') || lowerMessage.contains('language')) {
      actions.addAll(['Speak translation', 'Copy text', 'Reverse translate']);
    }

    // Default actions if no specific context
    if (actions.isEmpty) {
      actions.addAll(['Tell me more', 'Save this', 'Share']);
    }

    // Limit to 3 actions maximum
    return actions.take(3).toList();
  }

  /// Generate contextual follow-up suggestions
  static List<String> generateFollowUps(String lastUserMessage, String lastAssistantMessage) {
    final userLower = lastUserMessage.toLowerCase();
    final assistantLower = lastAssistantMessage.toLowerCase();
    final followUps = <String>[];

    // If user asked about something, offer to do it
    if (userLower.contains('what') || userLower.contains('how')) {
      followUps.add('Can you do that for me?');
    }

    // If assistant mentioned a task, offer to schedule it
    if (assistantLower.contains('task') || assistantLower.contains('remind')) {
      followUps.add('Remind me later');
    }

    // If talking about time, offer to set alarm
    if (assistantLower.contains('time') || assistantLower.contains('o\'clock')) {
      followUps.add('Set an alarm');
    }

    // If location mentioned, offer navigation
    if (assistantLower.contains('located') || assistantLower.contains('address')) {
      followUps.add('Navigate there');
    }

    // If asking about someone, offer to call
    if (assistantLower.contains('contact') || assistantLower.contains('reach')) {
      followUps.add('Call them');
    }

    // Generic helpful follow-ups
    if (followUps.isEmpty) {
      followUps.addAll([
        'Thanks!',
        'Anything else?',
        'Save this info',
      ]);
    }

    return followUps.take(2).toList();
  }
}
