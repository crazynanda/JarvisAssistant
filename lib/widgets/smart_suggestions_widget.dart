import 'package:flutter/material.dart';
import '../services/smart_suggestion_service.dart';

/// Widget to display smart suggestions and proactive recommendations
class SmartSuggestionsWidget extends StatefulWidget {
  final Color backgroundColor;
  final Color cardColor;
  final Color accentColor;
  final Color textColor;
  final Color secondaryTextColor;
  final Function(String)? onSuggestionTap;

  const SmartSuggestionsWidget({
    super.key,
    required this.backgroundColor,
    required this.cardColor,
    required this.accentColor,
    required this.textColor,
    required this.secondaryTextColor,
    this.onSuggestionTap,
  });

  @override
  State<SmartSuggestionsWidget> createState() => _SmartSuggestionsWidgetState();
}

class _SmartSuggestionsWidgetState extends State<SmartSuggestionsWidget> {
  final SmartSuggestionService _suggestionService = SmartSuggestionService();
  List<SmartSuggestion> _suggestions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSuggestions();
  }

  Future<void> _loadSuggestions() async {
    final suggestions = await _suggestionService.getProactiveSuggestions();
    
    setState(() {
      _suggestions = suggestions;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingWidget();
    }

    if (_suggestions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              'SUGGESTIONS FOR YOU',
              style: TextStyle(
                color: widget.accentColor.withValues(alpha: 0.8),
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ),
          ..._suggestions.map((suggestion) => _buildSuggestionCard(suggestion)),
        ],
      ),
    );
  }

  Widget _buildSuggestionCard(SmartSuggestion suggestion) {
    final isHighPriority = suggestion.priority == SuggestionPriority.high;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            widget.cardColor,
            isHighPriority 
                ? widget.accentColor.withValues(alpha: 0.1)
                : widget.cardColor,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isHighPriority 
              ? widget.accentColor.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => widget.onSuggestionTap?.call(suggestion.action),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isHighPriority
                        ? widget.accentColor.withValues(alpha: 0.2)
                        : widget.backgroundColor.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    suggestion.icon,
                    color: isHighPriority ? widget.accentColor : widget.secondaryTextColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        suggestion.title,
                        style: TextStyle(
                          color: widget.textColor,
                          fontSize: 15,
                          fontWeight: isHighPriority ? FontWeight.bold : FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        suggestion.description,
                        style: TextStyle(
                          color: widget.secondaryTextColor,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: widget.secondaryTextColor.withValues(alpha: 0.5),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(widget.accentColor),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Loading suggestions...',
            style: TextStyle(
              color: widget.secondaryTextColor,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
