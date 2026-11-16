import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

/// Responsive layout metrics shared across Splash, Login, Register, and Forgot Password screens.
class WijiBumiResponsiveMetrics {
  final double width;
  final double height;

  const WijiBumiResponsiveMetrics({required this.width, required this.height});

  bool get isCompactMobile => width < 380 || height < 700;
  bool get isTablet => width >= 600 && width < 1000;
  bool get isDesktop => width >= 1000;

  double get contentMaxWidth {
    if (width >= 1200) return 460;
    if (width >= 600) return 440;
    return width;
  }

  double get horizontalPadding {
    if (width >= 600) return 24;
    if (width < 375) return 16;
    return 22;
  }

  double get splashLogoSize {
    final base = math.min(width * 0.42, height * 0.25);
    return base.clamp(120.0, 200.0);
  }

  double get authLogoSize {
    final base = math.min(width * 0.22, height * 0.125);
    return base.clamp(68.0, 108.0);
  }

  double get brandFontSize {
    if (isDesktop) return 38;
    if (isTablet) return 36;
    if (isCompactMobile) return 30;
    return 34;
  }

  double get authBrandFontSize {
    if (isDesktop || isTablet) return 30;
    if (isCompactMobile) return 24;
    return 27;
  }

  double get authHeadingSize {
    if (isDesktop || isTablet) return 20;
    if (isCompactMobile) return 17;
    return 18.5;
  }

  double get subtitleFontSize {
    if (isCompactMobile) return 13;
    return 14.5;
  }
}

/// Consistent organic ivory-mint gradient background with botanical silhouettes
/// and frosted translucent glass accents strictly clipped to viewport bounds.
class WijiBumiAmbientBackground extends StatelessWidget {
  final Widget child;

  const WijiBumiAmbientBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.of(context).size.width;
        final h = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : MediaQuery.of(context).size.height;
        final shortSide = math.min(w, h);

        return ClipRect(
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. Base ivory-mint diagonal gradient
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? const [
                            Color(0xFF0E1B14),
                            Color(0xFF13261C),
                            Color(0xFF183123),
                          ]
                        : const [
                            AppColors.paleMint,
                            AppColors.warmIvory,
                            Color(0xFFEDF5E6),
                          ],
                    stops: const [0.0, 0.52, 1.0],
                  ),
                ),
              ),

              // 2. Top-right warm sun wash (matching reference splash/login lighting)
              Positioned(
                top: -shortSide * 0.25,
                right: -shortSide * 0.2,
                child: IgnorePointer(
                  child: Container(
                    width: shortSide * 0.9,
                    height: shortSide * 0.9,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          (isDark
                                  ? AppColors.emeraldGreen
                                  : const Color(0xFFF6E3C5))
                              .withValues(alpha: isDark ? 0.14 : 0.36),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // 3. Soft center-bottom ambient sage wash
              Positioned(
                bottom: -shortSide * 0.3,
                left: -shortSide * 0.18,
                child: IgnorePointer(
                  child: Container(
                    width: shortSide * 0.95,
                    height: shortSide * 0.95,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          (isDark
                                  ? AppColors.primary
                                  : AppColors.softSage)
                              .withValues(alpha: isDark ? 0.18 : 0.65),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // 4. Botanical tropical/palm shadows in corners
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _BotanicalLeafPainter(isDark: isDark),
                  ),
                ),
              ),

              // 5. Layered organic translucent glass waves / droplets
              Positioned(
                top: -shortSide * 0.12,
                left: -shortSide * 0.14,
                child: _GlassBubble(
                  size: (shortSide * 0.48).clamp(130, 260),
                  isDark: isDark,
                ),
              ),
              Positioned(
                bottom: -shortSide * 0.14,
                left: -shortSide * 0.12,
                child: _GlassBubble(
                  size: (shortSide * 0.52).clamp(140, 280),
                  isDark: isDark,
                ),
              ),
              Positioned(
                bottom: -shortSide * 0.18,
                right: -shortSide * 0.16,
                child: _GlassBubble(
                  size: (shortSide * 0.64).clamp(160, 340),
                  isDark: isDark,
                ),
              ),

              // 6. Active foreground content
              child,
            ],
          ),
        );
      },
    );
  }
}

class _GlassBubble extends StatelessWidget {
  final double size;
  final bool isDark;

  const _GlassBubble({required this.size, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: isDark ? 0.08 : 0.42),
                  (isDark ? AppColors.primary : AppColors.softSage)
                      .withValues(alpha: isDark ? 0.04 : 0.14),
                ],
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: isDark ? 0.1 : 0.65),
                width: 1.2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BotanicalLeafPainter extends CustomPainter {
  final bool isDark;

  _BotanicalLeafPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final baseColor = isDark
        ? AppColors.emeraldGreen.withValues(alpha: 0.08)
        : const Color(0xFF7D9C76).withValues(alpha: 0.20);
    final softColor = isDark
        ? AppColors.oliveGreen.withValues(alpha: 0.06)
        : const Color(0xFF9AB38D).withValues(alpha: 0.15);

    final leafPaint = Paint()
      ..color = baseColor
      ..style = PaintingStyle.fill;

    final softLeafPaint = Paint()
      ..color = softColor
      ..style = PaintingStyle.fill;

    final scale = math.min(size.width, size.height).clamp(320.0, 900.0);

    // Top-left palm frond cluster
    _drawPalmBranch(
      canvas,
      origin: Offset(-scale * 0.04, -scale * 0.02),
      angle: 0.58,
      length: scale * 0.55,
      paint: leafPaint,
    );

    // Top-right delicate frond
    _drawPalmBranch(
      canvas,
      origin: Offset(size.width + scale * 0.04, scale * 0.06),
      angle: 2.52,
      length: scale * 0.44,
      paint: softLeafPaint,
    );

    // Mid-left lower fern accent
    _drawPalmBranch(
      canvas,
      origin: Offset(-scale * 0.05, size.height * 0.72),
      angle: -0.35,
      length: scale * 0.36,
      paint: leafPaint,
    );

    // Bottom-right palm frond
    _drawPalmBranch(
      canvas,
      origin: Offset(size.width + scale * 0.02, size.height + scale * 0.02),
      angle: -2.2,
      length: scale * 0.50,
      paint: leafPaint,
    );
  }

  void _drawPalmBranch(
    Canvas canvas, {
    required Offset origin,
    required double angle,
    required double length,
    required Paint paint,
  }) {
    canvas.save();
    canvas.translate(origin.dx, origin.dy);
    canvas.rotate(angle);

    final stemPaint = Paint()
      ..color = paint.color
      ..strokeWidth = (length * 0.018).clamp(1.5, 4.0)
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawLine(Offset.zero, Offset(length, 0), stemPaint);

    const leafletCount = 9;
    for (int i = 1; i <= leafletCount; i++) {
      final t = i / (leafletCount + 1);
      final x = length * t;
      final bladeLen = length * 0.34 * math.sin(t * math.pi * 0.92);
      final bladeWidth = bladeLen * 0.22;

      for (final sign in const [-1.0, 1.0]) {
        final path = Path()
          ..moveTo(x, 0)
          ..quadraticBezierTo(
            x + bladeLen * 0.45,
            sign * bladeWidth * 1.4,
            x + bladeLen * 0.85,
            sign * bladeLen * 0.52,
          )
          ..quadraticBezierTo(
            x + bladeLen * 0.42,
            sign * bladeWidth * 0.2,
            x,
            0,
          );
        canvas.drawPath(path, paint);
      }
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _BotanicalLeafPainter oldDelegate) =>
      oldDelegate.isDark != isDark;
}

/// Official Wiji Bumi artwork placed over a soft circular emerald-lime ambient glow.
class WijiBumiLogoWithGlow extends StatelessWidget {
  final double size;

  const WijiBumiLogoWithGlow({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    final glowSize = size * 1.38;

    return SizedBox(
      width: glowSize,
      height: size * 1.15,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: glowSize,
            height: glowSize * 0.82,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.ambientGlowGreen.withValues(alpha: 0.42),
                  AppColors.emeraldGreen.withValues(alpha: 0.16),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.52, 1.0],
              ),
            ),
          ),
          Image.asset(
            'assets/images/wiji_bumi_logo.png',
            height: size,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
            errorBuilder: (_, _, _) => Icon(
              Icons.eco_rounded,
              size: size * 0.72,
              color: AppColors.oliveGreen,
            ),
          ),
        ],
      ),
    );
  }
}

/// Renders the official transparent Wiji Bumi logo cleanly without any box,
/// border, or background decoration for compact headers such as AppBars.
class WijiBumiCompactLogo extends StatelessWidget {
  final double size;

  const WijiBumiCompactLogo({super.key, this.size = 43});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/wiji_bumi_logo.png',
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      errorBuilder: (_, _, _) => Icon(
        Icons.eco_rounded,
        size: size * 0.72,
        color: AppColors.oliveGreen,
      ),
    );
  }
}

/// Frosted glassmorphism container tailored for Wiji Bumi auth forms.
class WijiBumiGlassAuthCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;

  const WijiBumiGlassAuthCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
    this.borderRadius = 28,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: AppColors.forestGreen.withValues(alpha: isDark ? 0.35 : 0.08),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF15271D).withValues(alpha: 0.84)
                  : AppColors.warmIvory.withValues(alpha: 0.78),
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.14)
                    : Colors.white.withValues(alpha: 0.88),
                width: 1.5,
              ),
            ),
            child: Material(
              type: MaterialType.transparency,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// Rounded sage-bordered translucent input matching the Wiji Bumi Login UI reference.
class WijiBumiAuthTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String)? onFieldSubmitted;
  final Iterable<String>? autofillHints;

  const WijiBumiAuthTextField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.validator,
    this.onChanged,
    this.onFieldSubmitted,
    this.autofillHints,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fillColor = isDark
        ? const Color(0xFF102018).withValues(alpha: 0.72)
        : AppColors.warmIvory.withValues(alpha: 0.72);
    final enabledBorderColor = isDark
        ? Colors.white.withValues(alpha: 0.16)
        : AppColors.sageBorder;
    final hintColor = isDark
        ? AppColors.textMutedDark
        : const Color(0xFF7C8879);

    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      validator: validator,
      onChanged: onChanged,
      onFieldSubmitted: onFieldSubmitted,
      autofillHints: autofillHints,
      style: TextStyle(
        fontSize: 14.5,
        fontWeight: FontWeight.w500,
        color: isDark ? AppColors.textPrimaryDark : AppColors.neutralDark,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          color: hintColor,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        filled: true,
        fillColor: fillColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        prefixIcon: Icon(
          prefixIcon,
          size: 20,
          color: isDark ? AppColors.textSecondaryDark : const Color(0xFF8C9F84),
        ),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: enabledBorderColor, width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: enabledBorderColor, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.emeraldGreen, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error, width: 1.6),
        ),
      ),
    );
  }
}

/// Deep forest-green pill CTA button with press scale animation & soft shadow.
class WijiBumiPrimaryPillButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double height;

  const WijiBumiPrimaryPillButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.height = 52,
  });

  @override
  State<WijiBumiPrimaryPillButton> createState() =>
      _WijiBumiPrimaryPillButtonState();
}

class _WijiBumiPrimaryPillButtonState extends State<WijiBumiPrimaryPillButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.onPressed != null && !widget.isLoading;

    return GestureDetector(
      onTapDown: isEnabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: isEnabled ? (_) => setState(() => _pressed = false) : null,
      onTapCancel: () {
        if (_pressed) setState(() => _pressed = false);
      },
      child: AnimatedScale(
        scale: _pressed ? 0.985 : 1.0,
        duration: const Duration(milliseconds: 110),
        child: Container(
          constraints: BoxConstraints(minHeight: widget.height),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            boxShadow: isEnabled
                ? [
                    BoxShadow(
                      color: AppColors.forestGreen.withValues(alpha: 0.28),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : [],
          ),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isEnabled ? widget.onPressed : null,
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, widget.height),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                backgroundColor: AppColors.forestGreen,
                disabledBackgroundColor:
                    AppColors.forestGreen.withValues(alpha: 0.65),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: widget.isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      widget.text,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: 0.2,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

