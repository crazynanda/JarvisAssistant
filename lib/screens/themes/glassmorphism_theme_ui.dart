import 'package:flutter/material.dart';
import 'dart:ui';
import '../../themes/app_themes.dart';

/// Glassmorphism theme UI - Frosted glass, blur effects, depth layers
class GlassmorphismThemeUI extends StatelessWidget {
  final List<dynamic> messages;
  final bool isProcessing;
  final bool isListening;
  final TextEditingController textController;
  final VoidCallback onSend;
  final VoidCallback onMicPressed;
  final VoidCallback onMenuPressed;
  final VoidCallback onSettingsPressed;
  final AppThemeConfig theme;

  const GlassmorphismThemeUI({
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
      body: Stack(
        children: [
          // Gradient background with blur shapes
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0F1C3F),
                  Color(0xFF050A18),
                  Color(0xFF0D1B3C),
                ],
              ),
            ),
          ),

          // Floating blur circles
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF00F0FF).withValues(alpha: 0.3),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            left: -80,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF4D9FFF).withValues(alpha: 0.2),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: Column(
              children: [
                // Glass header
                _buildGlassHeader(),

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
                            return _GlassMessage(
                              text: messages[index].text,
                              isUser: messages[index].isUser,
                            );
                          },
                        ),

                      // Glass Orb
                      if (messages.isEmpty)
                        _GlassOrb(
                          isProcessing: isProcessing,
                          isListening: isListening,
                        ),
                    ],
                  ),
                ),

                // Glass input
                _buildGlassInput(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassHeader() {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            border: Border(
              bottom: BorderSide(
                color: Colors.white.withValues(alpha: 0.2),
              ),
            ),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.menu, color: Color(0xFF00F0FF)),
                onPressed: onMenuPressed,
              ),
              const Expanded(
                child: Text(
                  'J.A.R.V.I.S.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF00F0FF),
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 4,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.settings_outlined,
                    color: Color(0xFF00F0FF)),
                onPressed: onSettingsPressed,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlassInput() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: textController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Ask me anything...',
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
                            ? [const Color(0xFFFF6B6B), const Color(0xFFFF8B8B)]
                            : [
                                const Color(0xFF00F0FF),
                                const Color(0xFF4D9FFF)
                              ],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (isListening
                                  ? const Color(0xFFFF6B6B)
                                  : const Color(0xFF00F0FF))
                              .withValues(alpha: 0.4),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: Icon(
                      isListening ? Icons.stop : Icons.mic,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassMessage extends StatelessWidget {
  final String text;
  final bool isUser;

  const _GlassMessage({required this.text, required this.isUser});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            padding: const EdgeInsets.all(16),
            constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75),
            decoration: BoxDecoration(
              color: isUser
                  ? const Color(0xFF4D9FFF).withValues(alpha: 0.2)
                  : Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
              ),
            ),
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassOrb extends StatefulWidget {
  final bool isProcessing;
  final bool isListening;

  const _GlassOrb({required this.isProcessing, required this.isListening});

  @override
  State<_GlassOrb> createState() => _GlassOrbState();
}

class _GlassOrbState extends State<_GlassOrb>
    with SingleTickerProviderStateMixin {
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
        return Container(
          width: 180,
          height: 180,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                const Color(0xFF00F0FF).withValues(alpha: 0.6),
                const Color(0xFF4D9FFF).withValues(alpha: 0.3),
                Colors.transparent,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00F0FF)
                    .withValues(alpha: 0.3 + _controller.value * 0.2),
                blurRadius: 40 + _controller.value * 20,
                spreadRadius: 10,
              ),
            ],
          ),
          child: ClipOval(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: const Center(
                  child: Text(
                    'J.A.R.V.I.S',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 3,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
