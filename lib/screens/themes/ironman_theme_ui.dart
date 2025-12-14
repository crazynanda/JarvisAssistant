import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../themes/app_themes.dart';

/// Iron Man JARVIS theme UI - Holographic HUD style
class IronManThemeUI extends StatelessWidget {
  final List<dynamic> messages;
  final bool isProcessing;
  final bool isListening;
  final TextEditingController textController;
  final VoidCallback onSend;
  final VoidCallback onMicPressed;
  final VoidCallback onMenuPressed;
  final VoidCallback onSettingsPressed;
  final AppThemeConfig theme;

  const IronManThemeUI({
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
      backgroundColor: const Color(0xFF0A0E17),
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.3),
                radius: 1.5,
                colors: [
                  Color(0xFF1A1F2E),
                  Color(0xFF0A0E17),
                ],
              ),
            ),
          ),

          // Holographic grid overlay
          CustomPaint(
            size: Size.infinite,
            painter: _HolographicGridPainter(),
          ),

          // Main content
          SafeArea(
            child: Column(
              children: [
                // HUD Header
                _buildHUDHeader(),

                // Central Arc Reactor / Orb
                Expanded(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Messages
                      if (messages.isNotEmpty)
                        Positioned.fill(
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 80),
                            itemCount: messages.length,
                            itemBuilder: (context, index) {
                              return _HolographicMessage(
                                text: messages[index].text,
                                isUser: messages[index].isUser,
                              );
                            },
                          ),
                        ),

                      // Arc Reactor Orb
                      if (messages.isEmpty)
                        _ArcReactorOrb(
                          isProcessing: isProcessing,
                          isListening: isListening,
                        ),
                    ],
                  ),
                ),

                // HUD Input Bar
                _buildHUDInput(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHUDHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFFFF6B35).withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.menu, color: Color(0xFFFF6B35)),
            onPressed: onMenuPressed,
          ),
          // Arc reactor icon
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF00D4FF), width: 2),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00D4FF).withValues(alpha: 0.5),
                  blurRadius: 10,
                ),
              ],
            ),
            child: const Center(
              child:
                  Icon(Icons.blur_circular, color: Color(0xFF00D4FF), size: 16),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'J.A.R.V.I.S. INTERFACE',
              style: TextStyle(
                color: Color(0xFFFF6B35),
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 3,
              ),
            ),
          ),
          // Status indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF00D4FF)),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'ONLINE',
              style: TextStyle(
                color: Color(0xFF00D4FF),
                fontSize: 10,
                letterSpacing: 2,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Color(0xFFFF6B35)),
            onPressed: onSettingsPressed,
          ),
        ],
      ),
    );
  }

  Widget _buildHUDInput() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F2E).withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFFFF6B35).withValues(alpha: 0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF6B35).withValues(alpha: 0.2),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        children: [
          // Voice waveform indicator
          if (isListening)
            const _VoiceWaveform()
          else
            const Icon(Icons.keyboard_voice_outlined, color: Color(0xFF00D4FF)),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: textController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'Enter command, sir...',
                hintStyle: TextStyle(color: Colors.white38),
              ),
              onSubmitted: (_) => onSend(),
            ),
          ),
          GestureDetector(
            onTap: onMicPressed,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isListening
                      ? [const Color(0xFFFF6B35), const Color(0xFFFF8C5A)]
                      : [const Color(0xFF00D4FF), const Color(0xFF4D9FFF)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (isListening
                            ? const Color(0xFFFF6B35)
                            : const Color(0xFF00D4FF))
                        .withValues(alpha: 0.5),
                    blurRadius: 15,
                  ),
                ],
              ),
              child: Icon(
                isListening ? Icons.stop : Icons.mic,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HolographicGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00D4FF).withValues(alpha: 0.05)
      ..strokeWidth = 0.5;

    // Horizontal lines
    for (double y = 0; y < size.height; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Vertical lines
    for (double x = 0; x < size.width; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _HolographicMessage extends StatelessWidget {
  final String text;
  final bool isUser;

  const _HolographicMessage({required this.text, required this.isUser});

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
          color: isUser
              ? const Color(0xFF00D4FF).withValues(alpha: 0.15)
              : const Color(0xFFFF6B35).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isUser
                ? const Color(0xFF00D4FF).withValues(alpha: 0.5)
                : const Color(0xFFFF6B35).withValues(alpha: 0.5),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isUser ? const Color(0xFF00D4FF) : Colors.white,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class _ArcReactorOrb extends StatefulWidget {
  final bool isProcessing;
  final bool isListening;

  const _ArcReactorOrb({required this.isProcessing, required this.isListening});

  @override
  State<_ArcReactorOrb> createState() => _ArcReactorOrbState();
}

class _ArcReactorOrbState extends State<_ArcReactorOrb>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_rotationController, _pulseController]),
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Outer ring
            Transform.rotate(
              angle: _rotationController.value * 2 * math.pi,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF00D4FF).withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
              ),
            ),
            // Middle ring
            Transform.rotate(
              angle: -_rotationController.value * 2 * math.pi * 0.7,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFFF6B35).withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
              ),
            ),
            // Core
            Container(
              width: 100 + (_pulseController.value * 10),
              height: 100 + (_pulseController.value * 10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  colors: [
                    Color(0xFF00D4FF),
                    Color(0xFF0088AA),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00D4FF).withValues(alpha: 0.6),
                    blurRadius: 30 + (_pulseController.value * 20),
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  'J.A.R.V.I.S',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _VoiceWaveform extends StatefulWidget {
  const _VoiceWaveform();

  @override
  State<_VoiceWaveform> createState() => _VoiceWaveformState();
}

class _VoiceWaveformState extends State<_VoiceWaveform>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
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
          mainAxisSize: MainAxisSize.min,
          children: List.generate(5, (index) {
            final offset = (index - 2).abs() * 0.2;
            final height = 10 + (_controller.value * 15) * (1 - offset);
            return Container(
              width: 3,
              height: height,
              margin: const EdgeInsets.symmetric(horizontal: 1),
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B35),
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }),
        );
      },
    );
  }
}
