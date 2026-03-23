import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:math';
import '../../themes/app_themes.dart';

/// Midnight Aurora theme UI - Aurora borealis gradients, frosted glass, flowing particles
class MidnightAuroraThemeUI extends StatelessWidget {
  final List<dynamic> messages;
  final bool isProcessing;
  final bool isListening;
  final TextEditingController textController;
  final VoidCallback onSend;
  final VoidCallback onMicPressed;
  final VoidCallback onMenuPressed;
  final VoidCallback onSettingsPressed;
  final AppThemeConfig theme;

  const MidnightAuroraThemeUI({
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
          // Aurora background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF0D1117),
                  Color(0xFF0B1A2B),
                  Color(0xFF0D1117),
                ],
              ),
            ),
          ),

          // Aurora streak - top left green
          Positioned(
            top: -100,
            left: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF00FFA3).withValues(alpha: 0.15),
                    const Color(0xFF00FFA3).withValues(alpha: 0.05),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Aurora streak - top right purple
          Positioned(
            top: -60,
            right: -80,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF8B5CF6).withValues(alpha: 0.2),
                    const Color(0xFF8B5CF6).withValues(alpha: 0.05),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Aurora streak - center blue
          Positioned(
            top: 150,
            left: 50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF3B82F6).withValues(alpha: 0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Bottom aurora glow
          Positioned(
            bottom: -50,
            left: 0,
            right: 0,
            child: Container(
              height: 200,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    const Color(0xFF00FFA3).withValues(alpha: 0.05),
                    const Color(0xFF8B5CF6).withValues(alpha: 0.08),
                  ],
                ),
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (messages.isNotEmpty)
                        ListView.builder(
                          padding: const EdgeInsets.only(
                            left: 16, right: 16, top: 16, bottom: 100,
                          ),
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            return _AuroraMessage(
                              text: messages[index].text,
                              isUser: messages[index].isUser,
                            );
                          },
                        ),
                      if (messages.isEmpty)
                        _AuroraOrb(
                          isProcessing: isProcessing,
                          isListening: isListening,
                        ),
                    ],
                  ),
                ),
                _buildInput(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF0D1117).withValues(alpha: 0.7),
            border: Border(
              bottom: BorderSide(
                color: const Color(0xFF00FFA3).withValues(alpha: 0.15),
              ),
            ),
          ),
          child: Row(
            children: [
              IconButton(
                icon: Icon(Icons.menu, color: theme.accentColor),
                onPressed: onMenuPressed,
              ),
              const SizedBox(width: 4),
              // Small aurora orb indicator
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00FFA3), Color(0xFF8B5CF6)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00FFA3).withValues(alpha: 0.4),
                      blurRadius: 10,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'J.A.R.V.I.S.',
                  style: TextStyle(
                    color: Color(0xFF00FFA3),
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 3,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.settings_outlined, color: Color(0xFF8B949E)),
                onPressed: onSettingsPressed,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInput() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF161B22).withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                width: 1.5,
                color: const Color(0xFF00FFA3).withValues(alpha: 0.2),
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00FFA3).withValues(alpha: 0.08),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.05),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {},
                  child: const Icon(Icons.add_circle_outline,
                      color: Color(0xFF8B949E), size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: textController,
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Ask JARVIS anything...',
                      hintStyle: TextStyle(color: Color(0xFF8B949E)),
                    ),
                    onSubmitted: (_) => onSend(),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onSend,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00FFA3), Color(0xFF3B82F6)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.send_rounded,
                        color: Colors.white, size: 18),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onMicPressed,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isListening
                            ? [const Color(0xFFFF6B6B), const Color(0xFFFF8B8B)]
                            : [const Color(0xFF8B5CF6), const Color(0xFF6D28D9)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: isListening
                          ? [
                              BoxShadow(
                                color: const Color(0xFFFF6B6B).withValues(alpha: 0.5),
                                blurRadius: 12,
                              ),
                            ]
                          : [],
                    ),
                    child: Icon(
                      isListening ? Icons.stop : Icons.mic,
                      color: Colors.white,
                      size: 18,
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

/// Frosted glass message bubble with aurora tint
class _AuroraMessage extends StatelessWidget {
  final String text;
  final bool isUser;

  const _AuroraMessage({required this.text, required this.isUser});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser
                    ? const Color(0xFF00FFA3).withValues(alpha: 0.12)
                    : const Color(0xFF161B22).withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isUser
                      ? const Color(0xFF00FFA3).withValues(alpha: 0.3)
                      : const Color(0xFF8B5CF6).withValues(alpha: 0.2),
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isUser
                            ? const Color(0xFF00FFA3)
                            : const Color(0xFF8B5CF6))
                        .withValues(alpha: 0.08),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: Text(
                text,
                style: TextStyle(
                  color: isUser
                      ? const Color(0xFF00FFA3)
                      : const Color(0xFFE6EDF3),
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Aurora orb with flowing green-purple gradient and glow
class _AuroraOrb extends StatefulWidget {
  final bool isProcessing;
  final bool isListening;

  const _AuroraOrb({required this.isProcessing, required this.isListening});

  @override
  State<_AuroraOrb> createState() => _AuroraOrbState();
}

class _AuroraOrbState extends State<_AuroraOrb>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotateController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_pulseController, _rotateController]),
      builder: (context, child) {
        final pulse = _pulseController.value;
        final rotate = _rotateController.value * 2 * pi;

        return Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00FFA3)
                    .withValues(alpha: 0.2 + pulse * 0.15),
                blurRadius: 40 + pulse * 25,
                spreadRadius: 8,
              ),
              BoxShadow(
                color: const Color(0xFF8B5CF6)
                    .withValues(alpha: 0.15 + pulse * 0.1),
                blurRadius: 50 + pulse * 15,
                spreadRadius: 12,
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer ring rotating
              Transform.rotate(
                angle: rotate,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF00FFA3).withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              // Inner orb
              ClipOval(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: SweepGradient(
                        startAngle: rotate,
                        endAngle: rotate + 2 * pi,
                        colors: [
                          const Color(0xFF00FFA3).withValues(alpha: 0.4),
                          const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                          const Color(0xFF3B82F6).withValues(alpha: 0.35),
                          const Color(0xFF00FFA3).withValues(alpha: 0.4),
                        ],
                      ),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.15),
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'J.A.R.V.I.S',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 3,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            widget.isListening
                                ? 'LISTENING'
                                : widget.isProcessing
                                    ? 'PROCESSING'
                                    : 'READY',
                            style: TextStyle(
                              color: const Color(0xFF00FFA3)
                                  .withValues(alpha: 0.7),
                              fontSize: 10,
                              letterSpacing: 2,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
