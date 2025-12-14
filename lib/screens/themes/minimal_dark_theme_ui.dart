import 'package:flutter/material.dart';
import '../../themes/app_themes.dart';

/// Minimal Dark theme UI - Ultra-clean, Apple-inspired minimal
class MinimalDarkThemeUI extends StatelessWidget {
  final List<dynamic> messages;
  final bool isProcessing;
  final bool isListening;
  final TextEditingController textController;
  final VoidCallback onSend;
  final VoidCallback onMicPressed;
  final VoidCallback onMenuPressed;
  final VoidCallback onSettingsPressed;
  final AppThemeConfig theme;

  const MinimalDarkThemeUI({
    super.key,
    required this.messages,
    required this.isProcessing,
    required this.isListening,
    required this.textController,
    required this.onSend,
    required this.onMicPressed,
    required this.onMenuPressed,
    required this.onSettingsPressed,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Clean header
            _buildCleanHeader(),

            // Content
            Expanded(
              child: messages.isEmpty
                  ? _buildMinimalCenter()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 16),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        return _MinimalMessage(
                          text: messages[index].text,
                          isUser: messages[index].isUser,
                        );
                      },
                    ),
            ),

            // Clean input
            _buildCleanInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildCleanHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.menu, color: Colors.white54),
            onPressed: onMenuPressed,
          ),
          const Expanded(
            child: Text(
              'JARVIS',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w300,
                letterSpacing: 8,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white54),
            onPressed: onSettingsPressed,
          ),
        ],
      ),
    );
  }

  Widget _buildMinimalCenter() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Subtle pulsing dot
          _MinimalDot(isListening: isListening),
          const SizedBox(height: 40),
          Text(
            isListening ? 'Listening' : 'Ready',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 14,
              fontWeight: FontWeight.w300,
              letterSpacing: 4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCleanInput() {
    return Container(
      margin: const EdgeInsets.all(24),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(25),
              ),
              child: TextField(
                controller: textController,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w300,
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Message',
                  hintStyle: TextStyle(color: Colors.white38),
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                onSubmitted: (_) => onSend(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: onMicPressed,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isListening ? Colors.white : const Color(0xFF1A1A1A),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isListening ? Icons.stop : Icons.mic,
                color: isListening ? Colors.black : Colors.white54,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MinimalMessage extends StatelessWidget {
  final String text;
  final bool isUser;

  const _MinimalMessage({required this.text, required this.isUser});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isUser ? const Color(0xFF333333) : const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isUser ? Colors.white : Colors.white70,
            fontSize: 15,
            fontWeight: FontWeight.w300,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}

class _MinimalDot extends StatefulWidget {
  final bool isListening;

  const _MinimalDot({required this.isListening});

  @override
  State<_MinimalDot> createState() => _MinimalDotState();
}

class _MinimalDotState extends State<_MinimalDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: 12 + (_controller.value * 4),
          height: 12 + (_controller.value * 4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.isListening ? Colors.white : Colors.white54,
          ),
        );
      },
    );
  }
}
