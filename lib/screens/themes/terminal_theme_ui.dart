import 'package:flutter/material.dart';
import '../../themes/app_themes.dart';

/// Terminal theme UI - PowerShell/Command line style
class TerminalThemeUI extends StatelessWidget {
  final List<dynamic> messages;
  final bool isProcessing;
  final bool isListening;
  final TextEditingController textController;
  final VoidCallback onSend;
  final VoidCallback onMicPressed;
  final VoidCallback onMenuPressed;
  final VoidCallback onSettingsPressed;
  final AppThemeConfig theme;

  const TerminalThemeUI({
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
      backgroundColor: const Color(0xFF012456), // PowerShell blue
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Terminal Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: const Color(0xFF012456),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.menu, color: Colors.white70),
                    onPressed: onMenuPressed,
                  ),
                  const Expanded(
                    child: Text(
                      'Windows PowerShell',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontFamily: 'Consolas',
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings, color: Colors.white70),
                    onPressed: onSettingsPressed,
                  ),
                ],
              ),
            ),

            // Terminal startup text
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'J.A.R.V.I.S Terminal\nCopyright (C) Nanda Kumar. All rights reserved.\n\nType your command or speak to J.A.R.V.I.S.\n',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontFamily: 'Consolas',
                  height: 1.5,
                ),
              ),
            ),

            // Messages area
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: messages.length + (isProcessing ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == messages.length) {
                    // Processing indicator
                    return const _TerminalTypingIndicator();
                  }
                  final message = messages[index];
                  return _TerminalMessage(
                    text: message.text,
                    isUser: message.isUser,
                  );
                },
              ),
            ),

            // Command input line
            Container(
              padding: const EdgeInsets.all(16),
              color: const Color(0xFF012456),
              child: Row(
                children: [
                  const Text(
                    'PS C:\\JARVIS> ',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontFamily: 'Consolas',
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: textController,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontFamily: 'Consolas',
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: '',
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onSubmitted: (_) => onSend(),
                    ),
                  ),
                  // Blinking cursor indicator
                  if (isListening)
                    Container(
                      width: 8,
                      height: 16,
                      color: Colors.white,
                    ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: onMicPressed,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isListening ? Colors.red : Colors.green,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Icon(
                        isListening ? Icons.stop : Icons.mic,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TerminalMessage extends StatelessWidget {
  final String text;
  final bool isUser;

  const _TerminalMessage({
    required this.text,
    required this.isUser,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isUser)
            Text(
              'PS C:\\JARVIS> $text',
              style: const TextStyle(
                color: Colors.yellow,
                fontSize: 14,
                fontFamily: 'Consolas',
              ),
            )
          else
            Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontFamily: 'Consolas',
                height: 1.5,
              ),
            ),
        ],
      ),
    );
  }
}

class _TerminalTypingIndicator extends StatefulWidget {
  const _TerminalTypingIndicator();

  @override
  State<_TerminalTypingIndicator> createState() =>
      _TerminalTypingIndicatorState();
}

class _TerminalTypingIndicatorState extends State<_TerminalTypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
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
        return Row(
          children: [
            const Text(
              'Processing',
              style: TextStyle(
                color: Colors.green,
                fontSize: 14,
                fontFamily: 'Consolas',
              ),
            ),
            Opacity(
              opacity: _controller.value,
              child: const Text(
                '...',
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 14,
                  fontFamily: 'Consolas',
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
