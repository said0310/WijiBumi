import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

/// Shared stroke-outline Lucide `message-circle` icon (`24x24` viewBox).
class LucideMessageCircleIcon extends StatelessWidget {
  final double size;
  final Color? color;
  final double strokeWidth;

  const LucideMessageCircleIcon({
    super.key,
    this.size = 24,
    this.color,
    this.strokeWidth = 2.0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final resolvedColor = color ??
        IconTheme.of(context).color ??
        (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight);

    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _LucideMessageCirclePainter(
          color: resolvedColor,
          strokeWidth: strokeWidth,
        ),
      ),
    );
  }
}

class _LucideMessageCirclePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  const _LucideMessageCirclePainter({
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 24.0;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth * scale
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Official Lucide `message-circle` SVG path: M7.9 20A9 9 0 1 0 4 16.1L2 22Z
    final path = Path()
      ..moveTo(7.9 * scale, 20.0 * scale)
      ..arcToPoint(
        Offset(4.0 * scale, 16.1 * scale),
        radius: Radius.circular(9.0 * scale),
        largeArc: true,
        clockwise: false,
      )
      ..lineTo(2.0 * scale, 22.0 * scale)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_LucideMessageCirclePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
}

/// Shared stroke-outline Lucide `shopping-cart` icon (`24x24` viewBox).
class LucideShoppingCartIcon extends StatelessWidget {
  final double size;
  final Color? color;
  final double strokeWidth;

  const LucideShoppingCartIcon({
    super.key,
    this.size = 24,
    this.color,
    this.strokeWidth = 2.0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final resolvedColor = color ??
        IconTheme.of(context).color ??
        (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight);

    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _LucideShoppingCartPainter(
          color: resolvedColor,
          strokeWidth: strokeWidth,
        ),
      ),
    );
  }
}

class _LucideShoppingCartPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  const _LucideShoppingCartPainter({
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 24.0;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth * scale
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Official Lucide `shopping-cart` SVG geometry:
    // circle cx="8" cy="21" r="1", circle cx="19" cy="21" r="1"
    // path d="M2.05 2.05h2l2.66 12.42a2 2 0 0 0 2 1.58h9.78a2 2 0 0 0 1.95-1.57l1.65-7.43H5.12"
    final cartPath = Path()
      ..moveTo(2.05 * scale, 2.05 * scale)
      ..lineTo(4.05 * scale, 2.05 * scale)
      ..lineTo(6.71 * scale, 14.47 * scale)
      ..arcToPoint(
        Offset(8.71 * scale, 16.05 * scale),
        radius: Radius.circular(2.0 * scale),
        clockwise: false,
      )
      ..lineTo(18.49 * scale, 16.05 * scale)
      ..arcToPoint(
        Offset(20.44 * scale, 14.48 * scale),
        radius: Radius.circular(2.0 * scale),
        clockwise: false,
      )
      ..lineTo(22.09 * scale, 7.05 * scale)
      ..lineTo(5.12 * scale, 7.05 * scale);

    canvas.drawPath(cartPath, paint);
    canvas.drawCircle(Offset(8.0 * scale, 21.0 * scale), 1.0 * scale, paint);
    canvas.drawCircle(Offset(19.0 * scale, 21.0 * scale), 1.0 * scale, paint);
  }

  @override
  bool shouldRepaint(_LucideShoppingCartPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
}

