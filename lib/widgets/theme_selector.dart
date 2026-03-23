import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../themes/app_themes.dart';
import '../themes/theme_provider.dart';

/// Enhanced theme selector widget with larger preview cards and animations
class ThemeSelector extends StatelessWidget {
  const ThemeSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.palette_outlined,
                    color: themeProvider.theme.accentColor,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Select Theme',
                    style: TextStyle(
                      color: themeProvider.theme.textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${themeProvider.availableThemes.length} themes',
                    style: TextStyle(
                      color: themeProvider.theme.secondaryTextColor,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 190,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: themeProvider.availableThemes.length,
                itemBuilder: (context, index) {
                  final themeType = themeProvider.availableThemes[index];
                  final theme = themeProvider.getThemeConfig(themeType);
                  final isSelected =
                      themeType == themeProvider.currentThemeType;

                  return _ThemeCard(
                    theme: theme,
                    isSelected: isSelected,
                    onTap: () => themeProvider.setTheme(themeType),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ThemeCard extends StatefulWidget {
  final AppThemeConfig theme;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeCard({
    required this.theme,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_ThemeCard> createState() => _ThemeCardState();
}

class _ThemeCardState extends State<_ThemeCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    if (widget.isSelected) {
      _glowController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant _ThemeCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected && !oldWidget.isSelected) {
      _glowController.repeat(reverse: true);
    } else if (!widget.isSelected && oldWidget.isSelected) {
      _glowController.stop();
      _glowController.reset();
    }
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _glowController,
        builder: (context, child) {
          final glowValue =
              widget.isSelected ? _glowController.value : 0.0;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            width: 140,
            margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            transform: Matrix4.identity()
              ..scale(widget.isSelected ? 1.05 : 1.0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: widget.theme.backgroundGradient,
              ),
              borderRadius: BorderRadius.circular(
                  widget.theme.borderRadius > 0 ? 16 : 0),
              border: Border.all(
                color: widget.isSelected
                    ? widget.theme.accentColor
                    : widget.theme.surfaceColor.withValues(alpha: 0.5),
                width: widget.isSelected ? 2.5 : 1,
              ),
              boxShadow: widget.isSelected
                  ? [
                      BoxShadow(
                        color: widget.theme.accentColor
                            .withValues(alpha: 0.3 + glowValue * 0.2),
                        blurRadius: 16 + glowValue * 8,
                        spreadRadius: 2,
                      ),
                      BoxShadow(
                        color: widget.theme.orbGlowColor
                            .withValues(alpha: 0.15 + glowValue * 0.1),
                        blurRadius: 24,
                        spreadRadius: 4,
                      ),
                    ]
                  : [],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Orb preview with glow
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        widget.theme.orbPrimaryColor,
                        widget.theme.orbSecondaryColor,
                      ],
                    ),
                    boxShadow: widget.theme.useGlowEffects
                        ? [
                            BoxShadow(
                              color: widget.theme.orbGlowColor
                                  .withValues(alpha: widget.isSelected
                                      ? 0.5 + glowValue * 0.2
                                      : 0.3),
                              blurRadius: widget.isSelected
                                  ? 18 + glowValue * 8
                                  : 12,
                              spreadRadius: 2,
                            ),
                          ]
                        : [],
                  ),
                  child: widget.isSelected
                      ? Icon(
                          Icons.check,
                          color: widget.theme.orbPrimaryColor
                                      .computeLuminance() >
                                  0.5
                              ? Colors.black87
                              : Colors.white,
                          size: 24,
                        )
                      : const SizedBox.shrink(),
                ),
                const SizedBox(height: 14),
                // Theme name
                Text(
                  widget.theme.name,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: widget.isSelected
                        ? widget.theme.accentColor
                        : widget.theme.textColor,
                    fontSize: 13,
                    fontWeight: widget.isSelected
                        ? FontWeight.bold
                        : FontWeight.w600,
                    fontFamily: widget.theme.fontFamily,
                  ),
                ),
                const SizedBox(height: 4),
                // Description
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    widget.theme.description,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: widget.theme.secondaryTextColor
                          .withValues(alpha: 0.8),
                      fontSize: 10,
                      fontFamily: widget.theme.fontFamily,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                // Theme icon
                Icon(
                  widget.theme.icon,
                  color: widget.isSelected
                      ? widget.theme.accentColor
                      : widget.theme.secondaryTextColor,
                  size: 16,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
