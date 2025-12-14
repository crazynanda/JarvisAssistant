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
  late AnimationController _ring1Controller; // Outer ring - slow clockwise
  late AnimationController
      _ring2Controller; // Middle ring - fast counter-clockwise
  late AnimationController _ring3Controller; // Inner ring - medium clockwise
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();

    _ring1Controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();

    _ring2Controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _ring3Controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ring1Controller.dispose();
    _ring2Controller.dispose();
    _ring3Controller.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Determine colors and animation speed based on state
    final Color ringColor;
    final Color glowColor;
    final bool shouldAnimate = widget.isProcessing || widget.isListening;

    if (widget.isProcessing) {
      ringColor = const Color(0xFF00F0FF); // Neon Cyan
      glowColor = const Color(0xFF00A8E8);
    } else if (widget.isListening) {
      ringColor = const Color(0xFFFF5E00); // Neon Orange
      glowColor = const Color(0xFFFF8C00);
    } else {
      ringColor = const Color(0xFF00A8E8); // Deep Blue (idle)
      glowColor = const Color(0xFF0055FF);
    }

    return AnimatedBuilder(
      animation: Listenable.merge([
        _ring1Controller,
        _ring2Controller,
        _ring3Controller,
        _pulseController
      ]),
      builder: (context, child) {
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Ambient Background Glow (pulsing)
              if (shouldAnimate)
                Container(
                  width: widget.size * (0.9 + _pulseController.value * 0.1),
                  height: widget.size * (0.9 + _pulseController.value * 0.1),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        glowColor.withValues(alpha: 0.3),
                        Colors.transparent,
                      ],
                      stops: const [0.3, 1.0],
                    ),
                  ),
                ),

              // Outer Ring - Slow Clockwise Rotation
              if (shouldAnimate)
                Transform.rotate(
                  angle: _ring1Controller.value * 2 * pi,
                  child: CustomPaint(
                    size: Size(widget.size, widget.size),
                    painter: DashedRingPainter(
                      color: ringColor.withValues(alpha: 0.4),
                      strokeWidth: 2,
                      dashWidth: 15,
                      dashGap: 10,
                      radius: widget.size * 0.48,
                    ),
                  ),
                ),

              // Middle Ring - Fast Counter-Clockwise Rotation
              if (shouldAnimate)
                Transform.rotate(
                  angle: -_ring2Controller.value * 2 * pi,
                  child: CustomPaint(
                    size: Size(widget.size, widget.size),
                    painter: DashedRingPainter(
                      color: ringColor.withValues(alpha: 0.6),
                      strokeWidth: 2.5,
                      dashWidth: 20,
                      dashGap: 15,
                      radius: widget.size * 0.42,
                    ),
                  ),
                ),

              // Inner Ring - Medium Clockwise Rotation
              if (shouldAnimate)
                Transform.rotate(
                  angle: _ring3Controller.value * 2 * pi,
                  child: CustomPaint(
                    size: Size(widget.size, widget.size),
                    painter: DashedRingPainter(
                      color: ringColor.withValues(alpha: 0.5),
                      strokeWidth: 2,
                      dashWidth: 12,
                      dashGap: 8,
                      radius: widget.size * 0.37,
                    ),
                  ),
                ),

              // Center Image (J.A.R.V.I.S logo)
              Container(
                width: widget.size * 0.65,
                height: widget.size * 0.65,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: shouldAnimate
                      ? [
                          BoxShadow(
                            color: ringColor.withValues(alpha: 0.5),
                            blurRadius: 25,
                            spreadRadius: 5,
                          ),
                        ]
                      : null,
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/jarvis_orb.png',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      // Fallback if image fails to load
                      return Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              ringColor,
                              ringColor.withValues(alpha: 0.5),
                            ],
                          ),
                        ),
                        child: Center(
                          child: Text(
                            'J.A.R.V.I.S',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: widget.size * 0.08,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    },
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

/// Custom painter for dashed rings
class DashedRingPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashWidth;
  final double dashGap;
  final double radius;

  DashedRingPainter({
    required this.color,
    required this.strokeWidth,
    required this.dashWidth,
    required this.dashGap,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Calculate dash parameters
    final circumference = 2 * pi * radius;
    final dashCount = (circumference / (dashWidth + dashGap)).floor();
    final dashAngle = (dashWidth / circumference) * 2 * pi;
    final gapAngle = (dashGap / circumference) * 2 * pi;

    // Draw dashed arc segments
    double startAngle = 0;
    for (int i = 0; i < dashCount; i++) {
      canvas.drawArc(
        rect,
        startAngle,
        dashAngle,
        false,
        paint,
      );
      startAngle += dashAngle + gapAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
