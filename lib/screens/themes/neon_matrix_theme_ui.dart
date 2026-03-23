import 'package:flutter/material.dart';
import 'dart:math';
import '../../themes/app_themes.dart';

/// Neon Matrix theme UI - Matrix digital rain, terminal-style, green/gold accents
class NeonMatrixThemeUI extends StatelessWidget {
  final List<dynamic> messages;
  final bool isProcessing;
  final bool isListening;
  final TextEditingController textController;
  final VoidCallback onSend;
  final VoidCallback onMicPressed;
  final VoidCallback onMenuPressed;
  final VoidCallback onSettingsPressed;
  final AppThemeConfig theme;

  const NeonMatrixThemeUI({
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
      body: Stack(
        children: [
          // Digital rain background
          const Positioned.fill(
            child: _MatrixRain(),
          ),

          // Scanline overlay
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: List.generate(
                      50,
                      (i) => i.isEven
                          ? Colors.transparent
                          : Colors.black.withValues(alpha: 0.03),
                    ),
                  ),
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
                            return _MatrixMessage(
                              text: messages[index].text,
                              isUser: messages[index].isUser,
                            );
                          },
                        ),
                      if (messages.isEmpty)
                        _MatrixOrb(
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFF00FF41).withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.menu, color: Color(0xFF00FF41)),
            onPressed: onMenuPressed,
          ),
          // Matrix-style status indicator
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: const Color(0xFF00FF41),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00FF41).withValues(alpha: 0.8),
                  blurRadius: 6,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'J.A.R.V.I.S.',
              style: TextStyle(
                color: const Color(0xFF00FF41),
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 4,
                fontFamily: theme.fontFamily,
                shadows: [
                  Shadow(
                    color: const Color(0xFF00FF41).withValues(alpha: 0.5),
                    blurRadius: 8,
                  ),
                ],
              ),
            ),
          ),
          // Status text
          Text(
            'ONLINE',
            style: TextStyle(
              color: const Color(0xFF00FF41).withValues(alpha: 0.6),
              fontSize: 10,
              letterSpacing: 2,
              fontFamily: theme.fontFamily,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Color(0xFF00FF41)),
            onPressed: onSettingsPressed,
          ),
        ],
      ),
    );
  }

  Widget _buildInput() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border(
          top: BorderSide(
            color: const Color(0xFF00FF41).withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF0A0A0A),
          border: Border.all(
            color: const Color(0xFF00FF41).withValues(alpha: 0.4),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Text(
              '>',
              style: TextStyle(
                color: const Color(0xFF00FF41),
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: theme.fontFamily,
                shadows: [
                  Shadow(
                    color: const Color(0xFF00FF41).withValues(alpha: 0.6),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: textController,
                style: TextStyle(
                  color: const Color(0xFF00FF41),
                  fontSize: 14,
                  fontFamily: theme.fontFamily,
                ),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: 'ENTER COMMAND...',
                  hintStyle: TextStyle(
                    color: const Color(0xFF006B1D),
                    fontFamily: theme.fontFamily,
                    fontSize: 14,
                  ),
                ),
                onSubmitted: (_) => onSend(),
              ),
            ),
            GestureDetector(
              onTap: onSend,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: const Color(0xFFFFD700).withValues(alpha: 0.5),
                  ),
                ),
                child: Icon(
                  Icons.play_arrow,
                  color: const Color(0xFFFFD700),
                  size: 18,
                  shadows: [
                    Shadow(
                      color: const Color(0xFFFFD700).withValues(alpha: 0.5),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onMicPressed,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isListening
                      ? const Color(0xFF00FF41).withValues(alpha: 0.2)
                      : Colors.transparent,
                  border: Border.all(
                    color: isListening
                        ? const Color(0xFF00FF41)
                        : const Color(0xFF00FF41).withValues(alpha: 0.5),
                  ),
                  boxShadow: isListening
                      ? [
                          BoxShadow(
                            color: const Color(0xFF00FF41).withValues(alpha: 0.5),
                            blurRadius: 8,
                          ),
                        ]
                      : [],
                ),
                child: Icon(
                  isListening ? Icons.stop : Icons.mic,
                  color: const Color(0xFF00FF41),
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Terminal-style message with > and JARVIS: prefixes
class _MatrixMessage extends StatelessWidget {
  final String text;
  final bool isUser;

  const _MatrixMessage({required this.text, required this.isUser});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.8),
        border: Border(
          left: BorderSide(
            color: isUser
                ? const Color(0xFF00FF41).withValues(alpha: 0.6)
                : const Color(0xFFFFD700).withValues(alpha: 0.6),
            width: 2,
          ),
        ),
      ),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 13,
            height: 1.6,
          ),
          children: [
            TextSpan(
              text: isUser ? '> ' : 'JARVIS: ',
              style: TextStyle(
                color: isUser
                    ? const Color(0xFF00FF41)
                    : const Color(0xFFFFD700),
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    color: (isUser
                            ? const Color(0xFF00FF41)
                            : const Color(0xFFFFD700))
                        .withValues(alpha: 0.4),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
            TextSpan(
              text: text,
              style: TextStyle(
                color: isUser
                    ? const Color(0xFF00FF41).withValues(alpha: 0.9)
                    : const Color(0xFFFFD700).withValues(alpha: 0.85),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Matrix orb with green and gold glowing effects
class _MatrixOrb extends StatefulWidget {
  final bool isProcessing;
  final bool isListening;

  const _MatrixOrb({required this.isProcessing, required this.isListening});

  @override
  State<_MatrixOrb> createState() => _MatrixOrbState();
}

class _MatrixOrbState extends State<_MatrixOrb>
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
        final value = _controller.value;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF00FF41).withValues(alpha: 0.5 + value * 0.3),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00FF41)
                        .withValues(alpha: 0.2 + value * 0.2),
                    blurRadius: 30 + value * 20,
                    spreadRadius: 5,
                  ),
                  BoxShadow(
                    color: const Color(0xFFFFD700)
                        .withValues(alpha: 0.1 + value * 0.1),
                    blurRadius: 40 + value * 15,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF00FF41).withValues(alpha: 0.3),
                      const Color(0xFFFFD700).withValues(alpha: 0.15),
                      Colors.black.withValues(alpha: 0.8),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'J.A.R.V.I.S',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          color: const Color(0xFF00FF41),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 3,
                          shadows: [
                            Shadow(
                              color: const Color(0xFF00FF41)
                                  .withValues(alpha: 0.8),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.isListening
                            ? '[ REC ]'
                            : widget.isProcessing
                                ? '[ ... ]'
                                : '[ OK ]',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          color: const Color(0xFFFFD700)
                              .withValues(alpha: 0.8),
                          fontSize: 10,
                          letterSpacing: 2,
                          shadows: [
                            Shadow(
                              color: const Color(0xFFFFD700)
                                  .withValues(alpha: 0.5),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Blinking cursor
            AnimatedOpacity(
              opacity: value > 0.5 ? 1.0 : 0.3,
              duration: const Duration(milliseconds: 100),
              child: Text(
                '█',
                style: TextStyle(
                  fontFamily: 'monospace',
                  color: const Color(0xFF00FF41),
                  fontSize: 16,
                  shadows: [
                    Shadow(
                      color: const Color(0xFF00FF41).withValues(alpha: 0.5),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Matrix digital rain background animation
class _MatrixRain extends StatefulWidget {
  const _MatrixRain();

  @override
  State<_MatrixRain> createState() => _MatrixRainState();
}

class _MatrixRainState extends State<_MatrixRain>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_RainColumn> _columns = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    )..addListener(_updateRain);
    _controller.repeat();
  }

  void _updateRain() {
    if (mounted) {
      setState(() {
        for (final col in _columns) {
          col.offset += col.speed;
          if (col.offset > col.maxHeight) {
            col.offset = -_random.nextDouble() * 200;
            col.chars = _generateChars();
          }
        }
      });
    }
  }

  String _generateChars() {
    const chars = 'ｦｱｳｴｵｶｷｸｹｺｻｼｽｾｿﾀﾁﾂﾃﾅﾆﾇﾈﾊﾋﾎﾏﾐﾑﾒﾓﾔﾕﾗﾘﾜ0123456789';
    return String.fromCharCodes(
      List.generate(
        8 + _random.nextInt(12),
        (_) => chars.codeUnitAt(_random.nextInt(chars.length)),
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_columns.isEmpty) {
      final width = MediaQuery.of(context).size.width;
      final height = MediaQuery.of(context).size.height;
      final colCount = (width / 20).floor();

      for (int i = 0; i < colCount; i++) {
        _columns.add(_RainColumn(
          x: i * 20.0,
          offset: -_random.nextDouble() * height,
          speed: 1.0 + _random.nextDouble() * 3.0,
          chars: _generateChars(),
          maxHeight: height,
        ));
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _MatrixRainPainter(_columns),
      size: Size.infinite,
    );
  }
}

class _RainColumn {
  final double x;
  double offset;
  final double speed;
  String chars;
  final double maxHeight;

  _RainColumn({
    required this.x,
    required this.offset,
    required this.speed,
    required this.chars,
    required this.maxHeight,
  });
}

class _MatrixRainPainter extends CustomPainter {
  final List<_RainColumn> columns;

  _MatrixRainPainter(this.columns);

  @override
  void paint(Canvas canvas, Size size) {
    for (final col in columns) {
      for (int i = 0; i < col.chars.length; i++) {
        final y = col.offset + i * 18;
        if (y < -20 || y > size.height + 20) continue;

        final opacity = (1.0 - i / col.chars.length).clamp(0.0, 1.0);
        final isHead = i == 0;

        final textPainter = TextPainter(
          text: TextSpan(
            text: String.fromCharCode(col.chars.codeUnitAt(i % col.chars.length)),
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 14,
              color: isHead
                  ? Colors.white.withValues(alpha: 0.9)
                  : Color.fromRGBO(0, 255, 65, opacity * 0.25),
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(canvas, Offset(col.x, y));
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
