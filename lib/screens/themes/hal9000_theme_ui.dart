import 'package:flutter/material.dart';
import '../../themes/app_themes.dart';

/// HAL 9000 theme UI - 2001 Space Odyssey style with single red eye
class Hal9000ThemeUI extends StatelessWidget {
  final List<dynamic> messages;
  final bool isProcessing;
  final bool isListening;
  final TextEditingController textController;
  final VoidCallback onSend;
  final VoidCallback onMicPressed;
  final VoidCallback onMenuPressed;
  final VoidCallback onSettingsPressed;
  final AppThemeConfig theme;

  const Hal9000ThemeUI({
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
            // Minimal header - almost hidden
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.menu,
                        color: Colors.white.withValues(alpha: 0.5)),
                    onPressed: onMenuPressed,
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.settings,
                        color: Colors.white.withValues(alpha: 0.5)),
                    onPressed: onSettingsPressed,
                  ),
                ],
              ),
            ),

            // Main area with HAL eye
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Messages (minimal white text)
                  if (messages.isNotEmpty)
                    Positioned.fill(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(40),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          return _HALMessage(
                            text: messages[index].text,
                            isUser: messages[index].isUser,
                          );
                        },
                      ),
                    ),

                  // HAL 9000 Eye
                  if (messages.isEmpty)
                    _HALEye(
                      isProcessing: isProcessing,
                      isListening: isListening,
                    ),
                ],
              ),
            ),

            // Minimal input
            _buildMinimalInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildMinimalInput() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: textController,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Speak to me...',
                  hintStyle: TextStyle(color: Colors.white30),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white24),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.red),
                  ),
                ),
                onSubmitted: (_) => onSend(),
              ),
            ),
          ),
          const SizedBox(width: 16),
          GestureDetector(
            onTap: onMicPressed,
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isListening ? Colors.red : Colors.transparent,
                border: Border.all(
                  color: isListening ? Colors.red : Colors.white30,
                  width: 1,
                ),
              ),
              child: Icon(
                isListening ? Icons.stop : Icons.mic_none,
                color: isListening ? Colors.white : Colors.white54,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HALMessage extends StatelessWidget {
  final String text;
  final bool isUser;

  const _HALMessage({required this.text, required this.isUser});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(
        isUser ? '> $text' : text,
        textAlign: isUser ? TextAlign.right : TextAlign.left,
        style: TextStyle(
          color: isUser ? Colors.red.shade300 : Colors.white,
          fontSize: 16,
          height: 1.6,
        ),
      ),
    );
  }
}

class _HALEye extends StatefulWidget {
  final bool isProcessing;
  final bool isListening;

  const _HALEye({required this.isProcessing, required this.isListening});

  @override
  State<_HALEye> createState() => _HALEyeState();
}

class _HALEyeState extends State<_HALEye> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
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
        final glowIntensity = 0.5 + (_controller.value * 0.5);

        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // HAL 9000 Eye
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black,
                border: Border.all(color: Colors.grey.shade800, width: 8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withValues(alpha: glowIntensity),
                    blurRadius: 50,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: Container(
                margin: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.red,
                      Colors.red.shade900,
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
            // HAL text
            Text(
              widget.isListening ? "I'm listening, Dave..." : "Hello, Dave.",
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 18,
                letterSpacing: 2,
              ),
            ),
          ],
        );
      },
    );
  }
}
