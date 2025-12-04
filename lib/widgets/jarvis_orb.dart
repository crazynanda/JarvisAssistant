import 'package:flutter/material.dart';
import 'dart:math';

class JarvisOrb extends StatefulWidget {
  final bool isProcessing;
  final bool isListening;
  final double size;

  const JarvisOrb({
    super.key,
    required this.isProcessing,
    required this.isListening,
    this.size = 200,
  });

  @override
  State<JarvisOrb> createState() => _JarvisOrbState();
}

class _JarvisOrbState extends State<JarvisOrb> with TickerProviderStateMixin {
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
      duration: const Duration(seconds: 2),
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
    // Determine colors based on state
    final Color coreColor;
    final Color glowColor;

    if (widget.isProcessing) {
      coreColor = const Color(0xFF00A8E8); // Cyan
      glowColor = const Color(0xFF0077B6);
    } else if (widget.isListening) {
      coreColor = const Color(0xFFFFA500); // Orange
      glowColor = const Color(0xFFFF8C00);
    } else {
      coreColor = const Color(0xFF00A8E8).withValues(alpha: 0.5);
      glowColor = const Color(0xFF0077B6).withValues(alpha: 0.3);
    }

    return AnimatedBuilder(
      animation: Listenable.merge([_rotationController, _pulseController]),
      builder: (context, child) {
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer Glow
              Container(
                width: widget.size * (0.8 + _pulseController.value * 0.2),
                height: widget.size * (0.8 + _pulseController.value * 0.2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      glowColor.withValues(alpha: 0.6),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),

              // Rotating Rings
              Transform.rotate(
                angle: _rotationController.value * 2 * pi,
                child: Container(
                  width: widget.size * 0.7,
                  height: widget.size * 0.7,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: coreColor.withValues(alpha: 0.5),
                      width: 2,
                    ),
                  ),
                ),
              ),
              Transform.rotate(
                angle: -_rotationController.value * 2 * pi,
                child: Container(
                  width: widget.size * 0.6,
                  height: widget.size * 0.6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: coreColor.withValues(alpha: 0.3),
                      width: 4,
                    ),
                  ),
                ),
              ),

              // Core
              Container(
                width: widget.size * 0.4,
                height: widget.size * 0.4,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: coreColor,
                  boxShadow: [
                    BoxShadow(
                      color: coreColor.withValues(alpha: 0.8),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
