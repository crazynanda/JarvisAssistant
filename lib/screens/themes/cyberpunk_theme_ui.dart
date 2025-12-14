import 'package:flutter/material.dart';
import '../../themes/app_themes.dart';

/// Cyberpunk theme UI - Neon glow, glitch effects, dystopian vibes
class CyberpunkThemeUI extends StatelessWidget {
  final List<dynamic> messages;
  final bool isProcessing;
  final bool isListening;
  final TextEditingController textController;
  final VoidCallback onSend;
  final VoidCallback onMicPressed;
  final VoidCallback onMenuPressed;
  final VoidCallback onSettingsPressed;
  final AppThemeConfig theme;

  const CyberpunkThemeUI({
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
      backgroundColor: const Color(0xFF10002B),
      body: Stack(
        children: [
          // Gradient background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF10002B),
                  Color(0xFF240046),
                  Color(0xFF3C096C),
                ],
              ),
            ),
          ),

          // Scanlines overlay
          Positioned.fill(
            child: CustomPaint(
              painter: _ScanlinesPainter(),
            ),
          ),

          // Main content
          SafeArea(
            child: Column(
              children: [
                // Neon header
                _buildNeonHeader(),

                // Content
                Expanded(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Messages
                      if (messages.isNotEmpty)
                        ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            return _NeonMessage(
                              text: messages[index].text,
                              isUser: messages[index].isUser,
                            );
                          },
                        ),

                      // Neon Orb
                      if (messages.isEmpty)
                        _NeonOrb(
                          isProcessing: isProcessing,
                          isListening: isListening,
                        ),
                    ],
                  ),
                ),

                // Neon input
                _buildNeonInput(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNeonHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFFFF006E).withValues(alpha: 0.5),
            width: 2,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF006E).withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.menu, color: Color(0xFFFF006E)),
            onPressed: onMenuPressed,
          ),
          const Expanded(
            child: _GlitchText(
              text: 'JARVIS_SYS',
              style: TextStyle(
                color: Color(0xFFFF006E),
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 4,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF9D4EDD)),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'v2.077',
              style: TextStyle(
                color: Color(0xFF9D4EDD),
                fontSize: 12,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Color(0xFFFF006E)),
            onPressed: onSettingsPressed,
          ),
        ],
      ),
    );
  }

  Widget _buildNeonInput() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF240046).withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(0), // Sharp corners for cyberpunk
        border: Border.all(
          color: const Color(0xFFFF006E),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF006E).withValues(alpha: 0.4),
            blurRadius: 15,
            spreadRadius: 2,
          ),
          BoxShadow(
            color: const Color(0xFF9D4EDD).withValues(alpha: 0.2),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Row(
        children: [
          const Text(
            '>>',
            style: TextStyle(
              color: Color(0xFFFF006E),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: textController,
              style: const TextStyle(
                color: Color(0xFFE0AAFF),
                fontSize: 16,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'INPUT COMMAND...',
                hintStyle: TextStyle(color: Colors.white24),
              ),
              onSubmitted: (_) => onSend(),
            ),
          ),
          GestureDetector(
            onTap: onMicPressed,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color:
                    isListening ? const Color(0xFFFF006E) : Colors.transparent,
                border: Border.all(
                  color: const Color(0xFFFF006E),
                  width: 2,
                ),
              ),
              child: Icon(
                isListening ? Icons.graphic_eq : Icons.mic,
                color: isListening ? Colors.white : const Color(0xFFFF006E),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScanlinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.1)
      ..strokeWidth = 1;

    for (double y = 0; y < size.height; y += 3) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _GlitchText extends StatefulWidget {
  final String text;
  final TextStyle style;

  const _GlitchText({required this.text, required this.style});

  @override
  State<_GlitchText> createState() => _GlitchTextState();
}

class _GlitchTextState extends State<_GlitchText> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Main text
        Text(widget.text, style: widget.style),
        // Cyan offset (glitch effect)
        Positioned(
          left: 1,
          child: Text(
            widget.text,
            style: widget.style.copyWith(
              color: const Color(0xFF00F0FF).withValues(alpha: 0.3),
            ),
          ),
        ),
      ],
    );
  }
}

class _NeonMessage extends StatelessWidget {
  final String text;
  final bool isUser;

  const _NeonMessage({required this.text, required this.isUser});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: const Color(0xFF240046).withValues(alpha: 0.7),
          border: Border.all(
            color: isUser ? const Color(0xFFFF006E) : const Color(0xFF9D4EDD),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color:
                  (isUser ? const Color(0xFFFF006E) : const Color(0xFF9D4EDD))
                      .withValues(alpha: 0.3),
              blurRadius: 10,
            ),
          ],
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isUser ? const Color(0xFFFF006E) : const Color(0xFFE0AAFF),
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class _NeonOrb extends StatefulWidget {
  final bool isProcessing;
  final bool isListening;

  const _NeonOrb({required this.isProcessing, required this.isListening});

  @override
  State<_NeonOrb> createState() => _NeonOrbState();
}

class _NeonOrbState extends State<_NeonOrb>
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
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const RadialGradient(
              colors: [
                Color(0xFFFF006E),
                Color(0xFF9D4EDD),
                Color(0xFF240046),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF006E)
                    .withValues(alpha: 0.5 + _controller.value * 0.3),
                blurRadius: 40 + _controller.value * 20,
                spreadRadius: 10,
              ),
              BoxShadow(
                color: const Color(0xFF9D4EDD).withValues(alpha: 0.3),
                blurRadius: 60,
                spreadRadius: 20,
              ),
            ],
          ),
          child: const Center(
            child: Text(
              'J.A.R.V.I.S',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 4,
              ),
            ),
          ),
        );
      },
    );
  }
}
