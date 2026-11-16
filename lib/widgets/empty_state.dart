import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

class EmptyState extends StatelessWidget {
  final IconData icon;
  final Widget Function(Color color, double size)? iconBuilder;
  final String title;
  final String message;
  final String? buttonText;
  final VoidCallback? onButtonPressed;

  const EmptyState({
    super.key,
    required this.icon,
    this.iconBuilder,
    required this.title,
    required this.message,
    this.buttonText,
    this.onButtonPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = isDark ? AppColors.primaryLight : AppColors.primary;

    return LayoutBuilder(
      builder: (context, constraints) {
        final hasBoundedHeight = constraints.hasBoundedHeight;
        final isShort = hasBoundedHeight && constraints.maxHeight < 340;
        final minHeight = hasBoundedHeight ? constraints.maxHeight : 0.0;

        return SingleChildScrollView(
          physics: hasBoundedHeight
              ? const AlwaysScrollableScrollPhysics()
              : const NeverScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: minHeight),
            child: Center(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: isShort ? 20 : 40,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.all(isShort ? 16 : 24),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: iconBuilder != null
                          ? iconBuilder!(accentColor, isShort ? 40 : 56)
                          : Icon(
                              icon,
                              size: isShort ? 40 : 56,
                              color: accentColor,
                            ),
                    ),
                    SizedBox(height: isShort ? 14 : 20),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? AppColors.textMutedDark
                            : AppColors.textMutedLight,
                        height: 1.4,
                      ),
                    ),
                    if (buttonText != null && onButtonPressed != null) ...[
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: onButtonPressed,
                        child: Text(buttonText!),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
