import 'dart:ui';
import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

/// Semi-transparent glassmorphism container with soft blur and subtle green accent.
class GlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final double blurSigma;
  final Color? tintColor;
  final Gradient? gradient;
  final Border? border;
  final bool enableGlow;
  final Color? glowColor;

  const GlassContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 16,
    this.blurSigma = 12,
    this.tintColor,
    this.gradient,
    this.border,
    this.enableGlow = false,
    this.glowColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultTint = isDark
        ? AppColors.surfaceDark.withValues(alpha: 0.72)
        : Colors.white.withValues(alpha: 0.78);
    final defaultBorder = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : AppColors.primary.withValues(alpha: 0.14);
    final effectiveGlow = glowColor ?? AppColors.secondaryEmerald;

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
          if (enableGlow)
            BoxShadow(
              color: effectiveGlow.withValues(alpha: isDark ? 0.22 : 0.16),
              blurRadius: 18,
              spreadRadius: 1,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: gradient == null ? (tintColor ?? defaultTint) : null,
              gradient: gradient,
              borderRadius: BorderRadius.circular(borderRadius),
              border: border ?? Border.all(color: defaultBorder, width: 1.1),
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

/// Shows a glassmorphic confirmation dialog with soft blur and rounded corners.
Future<bool> showGlassConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String cancelText = 'Batal',
  String confirmText = 'Ya, Lanjutkan',
  Color? confirmColor,
  IconData? icon,
}) async {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final effectiveConfirmColor = confirmColor ?? AppColors.primary;

  final result = await showDialog<bool>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    builder: (ctx) => Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: GlassContainer(
        borderRadius: 20,
        blurSigma: 16,
        enableGlow: true,
        glowColor: effectiveConfirmColor,
        padding: const EdgeInsets.all(20),
        tintColor: isDark
            ? AppColors.neutralDark.withValues(alpha: 0.88)
            : Colors.white.withValues(alpha: 0.9),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: effectiveConfirmColor.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: effectiveConfirmColor, size: 28),
                ),
                const SizedBox(height: 14),
              ],
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 12,
                        ),
                      ),
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text(
                        cancelText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: effectiveConfirmColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 12,
                        ),
                      ),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: Text(
                        confirmText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
  return result ?? false;
}

/// Shows a glassmorphic modal bottom sheet.
Future<T?> showGlassBottomSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) {
      final maxHeight = MediaQuery.sizeOf(ctx).height * 0.88;
      return Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.neutralDark.withValues(alpha: 0.92)
                      : Colors.white.withValues(alpha: 0.94),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(24)),
                  border: Border(
                    top: BorderSide(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.14)
                          : AppColors.primary.withValues(alpha: 0.16),
                    ),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: Material(
                    type: MaterialType.transparency,
                    child: builder(ctx),
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
