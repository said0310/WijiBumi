import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Palet & komponen visual bersama agar seluruh halaman Mode Penjual
/// konsisten dengan tema Nature-Inspired WijiBumi.
class SellerThemeTokens {
  final bool isDark;

  const SellerThemeTokens(this.isDark);

  Color get pageBg =>
      isDark ? AppColors.backgroundDark : const Color(0xFFECF4EE);

  Color get cardBg => isDark ? AppColors.cardDark : AppColors.surfaceLight;

  Color get borderColor =>
      isDark ? AppColors.borderDark : const Color(0xFFE0EBE3);

  Color get titleColor =>
      isDark ? AppColors.textPrimaryDark : AppColors.neutralDark;

  Color get mutedTextColor =>
      isDark ? AppColors.textMutedDark : const Color(0xFF6B7280);

  Color get secondaryTextColor =>
      isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

  Color get accentGreen =>
      isDark ? AppColors.primaryLight : AppColors.forestGreen;

  Color get emeraldAccent =>
      isDark ? AppColors.primaryLight : const Color(0xFF2E7D52);

  Color get softMintBg => isDark
      ? AppColors.primary.withValues(alpha: 0.16)
      : const Color(0xFFEAF5ED);
}

/// Permukaan card Warm White seragam dengan border halus dan shadow lembut.
class SellerCardSurface extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final Color? borderColor;
  final VoidCallback? onTap;

  const SellerCardSurface({
    super.key,
    required this.child,
    this.borderRadius = 20,
    this.padding,
    this.backgroundColor,
    this.borderColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tokens = SellerThemeTokens(isDark);
    final bg = backgroundColor ?? tokens.cardBg;
    final border = borderColor ?? tokens.borderColor;

    final inner = padding != null
        ? Padding(padding: padding!, child: child)
        : child;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.045),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Material(
          type: MaterialType.transparency,
          child: onTap != null
              ? InkWell(
                  borderRadius: BorderRadius.circular(borderRadius),
                  onTap: onTap,
                  child: inner,
                )
              : inner,
        ),
      ),
    );
  }
}

/// Container ikon persegi-bulat bernuansa soft mint.
class SellerIconBox extends StatelessWidget {
  final IconData icon;
  final Color? color;
  final Color? backgroundColor;
  final double size;
  final double iconSize;

  const SellerIconBox({
    super.key,
    required this.icon,
    this.color,
    this.backgroundColor,
    this.size = 40,
    this.iconSize = 20,
  });

  @override
  Widget build(BuildContext context) {
    final tokens =
        SellerThemeTokens(Theme.of(context).brightness == Brightness.dark);
    final effectiveColor = color ?? tokens.accentGreen;
    final effectiveBg =
        backgroundColor ?? effectiveColor.withValues(alpha: 0.13);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: effectiveBg,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Icon(icon, color: effectiveColor, size: iconSize),
    );
  }
}

/// Chip/pill seragam untuk kategori produk atau filter mode penjual.
class SellerPillChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const SellerPillChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tokens = SellerThemeTokens(isDark);
    final bg = selected ? tokens.accentGreen : tokens.cardBg;
    final fg = selected
        ? (isDark ? Colors.black : Colors.white)
        : tokens.titleColor;

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: selected ? null : Border.all(color: tokens.borderColor),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: fg,
            ),
          ),
        ),
      ),
    );
  }
}

