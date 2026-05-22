import 'dart:ui';
import 'package:flutter/material.dart';

/// Design tokens for the Loopify glass design system.
class AppTokens {
  AppTokens._();

  // Backdrop colors
  static const Color bgDeep = Color(0xFF05060F);
  static const Color bgMid = Color(0xFF0B0D24);
  static const Color bgHigh = Color(0xFF14163A);

  // Accents
  static const Color accent = Color(0xFFFF7A2F);
  static const Color accentSoft = Color(0xFFFFB070);
  static const Color accentDeep = Color(0xFFE0521D);
  static const Color accentGlow = Color(0x66FF7A2F);

  // Surfaces
  static Color surfaceFill = Colors.white.withOpacity(0.06);
  static Color surfaceFillStrong = Colors.white.withOpacity(0.10);
  static Color surfaceStroke = Colors.white.withOpacity(0.10);
  static Color surfaceStrokeStrong = Colors.white.withOpacity(0.18);

  // Text
  static Color textPrimary = Colors.white;
  static Color textSecondary = Colors.white.withOpacity(0.68);
  static Color textTertiary = Colors.white.withOpacity(0.42);

  // Radii
  static const double rXs = 10;
  static const double rSm = 14;
  static const double rMd = 20;
  static const double rLg = 28;
  static const double rXl = 34;

  // Blurs
  static const double blurSm = 14;
  static const double blurMd = 22;
  static const double blurLg = 32;
}

/// Ambient gradient background with soft accent orbs.
/// Wrap the inside of a Scaffold body (or stack it behind content).
class GlassBackground extends StatelessWidget {
  final Widget child;
  final bool showOrbs;

  const GlassBackground({
    Key? key,
    required this.child,
    this.showOrbs = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Base gradient
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTokens.bgDeep,
                  AppTokens.bgMid,
                  AppTokens.bgDeep,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
        ),
        if (showOrbs) ...[
          // Warm orb top-right
          Positioned(
            top: -120,
            right: -80,
            child: _Orb(
              size: 320,
              colors: [
                AppTokens.accent.withOpacity(0.35),
                AppTokens.accent.withOpacity(0.0),
              ],
            ),
          ),
          // Cool orb bottom-left
          Positioned(
            bottom: -140,
            left: -100,
            child: _Orb(
              size: 360,
              colors: [
                const Color(0xFF6B46C1).withOpacity(0.28),
                const Color(0xFF6B46C1).withOpacity(0.0),
              ],
            ),
          ),
          // Mid teal orb
          Positioned(
            top: 240,
            left: -60,
            child: _Orb(
              size: 220,
              colors: [
                const Color(0xFF4ECDC4).withOpacity(0.18),
                const Color(0xFF4ECDC4).withOpacity(0.0),
              ],
            ),
          ),
        ],
        child,
      ],
    );
  }
}

class _Orb extends StatelessWidget {
  final double size;
  final List<Color> colors;

  const _Orb({required this.size, required this.colors});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: colors),
        ),
      ),
    );
  }
}

/// A frosted glass card with hairline gradient border and subtle highlight.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double radius;
  final double blur;
  final Color? tint;
  final Color? borderColor;
  final List<BoxShadow>? shadows;
  final VoidCallback? onTap;
  final BorderRadius? customBorderRadius;

  const GlassCard({
    Key? key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.radius = AppTokens.rMd,
    this.blur = AppTokens.blurMd,
    this.tint,
    this.borderColor,
    this.shadows,
    this.onTap,
    this.customBorderRadius,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final borderRadius = customBorderRadius ?? BorderRadius.circular(radius);
    final fill = tint ?? AppTokens.surfaceFill;

    final card = ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                fill.withOpacity((fill.opacity * 1.6).clamp(0.0, 1.0)),
                fill,
              ],
            ),
            borderRadius: borderRadius,
            border: Border.all(
              color: borderColor ?? AppTokens.surfaceStroke,
              width: 1,
            ),
          ),
          child: child,
        ),
      ),
    );

    final withShadow = shadows == null
        ? card
        : DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: borderRadius,
              boxShadow: shadows,
            ),
            child: card,
          );

    final wrapped = onTap == null
        ? withShadow
        : Material(
            color: Colors.transparent,
            borderRadius: borderRadius,
            child: InkWell(
              borderRadius: borderRadius,
              onTap: onTap,
              splashColor: Colors.white.withOpacity(0.05),
              highlightColor: Colors.white.withOpacity(0.03),
              child: withShadow,
            ),
          );

    if (margin == null) return wrapped;
    return Padding(padding: margin!, child: wrapped);
  }
}

/// An accent-tinted glass card — used to highlight CTAs.
class AccentGlassCard extends StatelessWidget {
  final Widget child;
  final Color accent;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double radius;
  final VoidCallback? onTap;
  final bool glow;

  const AccentGlassCard({
    Key? key,
    required this.child,
    this.accent = AppTokens.accent,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.radius = AppTokens.rMd,
    this.onTap,
    this.glow = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: padding,
      margin: margin,
      radius: radius,
      onTap: onTap,
      blur: AppTokens.blurMd,
      tint: accent.withOpacity(0.14),
      borderColor: accent.withOpacity(0.45),
      shadows: glow
          ? [
              BoxShadow(
                color: accent.withOpacity(0.22),
                blurRadius: 24,
                spreadRadius: -4,
              ),
            ]
          : null,
      child: child,
    );
  }
}

/// A blurred horizontal bar that sits above the system status bar.
/// Use as a SliverPersistentHeader or inside a Stack.
class GlassTopBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final Widget? leading;
  final double height;
  final bool centerTitle;

  const GlassTopBar({
    Key? key,
    required this.title,
    this.subtitle,
    this.actions,
    this.leading,
    this.height = 64,
    this.centerTitle = false,
  }) : super(key: key);

  @override
  Size get preferredSize {
    final extra = subtitle != null ? 16.0 : 0.0;
    return Size.fromHeight(height + extra);
  }

  @override
  Widget build(BuildContext context) {
    final mediaTop = MediaQuery.of(context).padding.top;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: AppTokens.blurLg, sigmaY: AppTokens.blurLg),
        child: Container(
          padding: EdgeInsets.only(top: mediaTop),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppTokens.bgDeep.withOpacity(0.72),
                AppTokens.bgDeep.withOpacity(0.42),
              ],
            ),
            border: Border(
              bottom: BorderSide(
                color: Colors.white.withOpacity(0.06),
                width: 0.5,
              ),
            ),
          ),
          child: SizedBox(
            height: preferredSize.height - mediaTop,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  if (leading != null) ...[
                    leading!,
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment:
                          centerTitle ? CrossAxisAlignment.center : CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            color: AppTokens.textPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.4,
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle!,
                            style: TextStyle(
                              color: AppTokens.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              letterSpacing: -0.1,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (actions != null) ...actions!,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A small circular glass button — used in app bar actions.
class GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Color? color;
  final double size;

  const GlassIconButton({
    Key? key,
    required this.icon,
    this.onTap,
    this.color,
    this.size = 40,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: AppTokens.blurSm, sigmaY: AppTokens.blurSm),
        child: Material(
          color: Colors.white.withOpacity(0.06),
          shape: CircleBorder(
            side: BorderSide(color: Colors.white.withOpacity(0.10), width: 1),
          ),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox(
              width: size,
              height: size,
              child: Icon(icon, color: color ?? Colors.white, size: 19),
            ),
          ),
        ),
      ),
    );
  }
}

/// A horizontal segmented control with glass styling.
class GlassSegmented<T> extends StatelessWidget {
  final List<({T value, String label})> items;
  final T selected;
  final ValueChanged<T> onChanged;

  const GlassSegmented({
    Key? key,
    required this.items,
    required this.selected,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(4),
      radius: AppTokens.rSm,
      blur: AppTokens.blurSm,
      child: Row(
        children: items.map((item) {
          final isActive = item.value == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(item.value),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  gradient: isActive
                      ? LinearGradient(
                          colors: [
                            AppTokens.accent,
                            AppTokens.accentDeep,
                          ],
                        )
                      : null,
                  borderRadius: BorderRadius.circular(AppTokens.rXs),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: AppTokens.accent.withOpacity(0.35),
                            blurRadius: 14,
                            spreadRadius: -2,
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    item.label,
                    style: TextStyle(
                      color: isActive ? Colors.white : AppTokens.textSecondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      letterSpacing: -0.1,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Bottom-padding helper that accounts for the floating glass tab bar.
class GlassTabBarSpacer extends StatelessWidget {
  const GlassTabBarSpacer({Key? key}) : super(key: key);

  static const double height = 110; // tab bar + safe area buffer

  @override
  Widget build(BuildContext context) => const SizedBox(height: height);
}
