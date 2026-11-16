import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/date_formatter.dart';
import '../models/review.dart';
import 'smart_image.dart';

/// Shared buyer review card used across store & product detail screens.
class BuyerReviewTileCard extends StatelessWidget {
  final Review review;
  final bool showProductName;

  const BuyerReviewTileCard({
    super.key,
    required this.review,
    this.showProductName = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final mutedColor =
        isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    final borderColor =
        isDark ? AppColors.borderDark : AppColors.borderLight;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipOval(
                child: SizedBox(
                  width: 34,
                  height: 34,
                  child: (review.reviewerAvatar != null &&
                          review.reviewerAvatar!.trim().isNotEmpty)
                      ? SmartImage(
                          source: review.reviewerAvatar!,
                          fit: BoxFit.cover,
                          fallback: _defaultAvatar(isDark),
                        )
                      : _defaultAvatar(isDark),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.reviewerName ?? 'Pembeli WijiBumi',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      DateFormatter.formatShort(review.createdAt),
                      style: TextStyle(fontSize: 11, color: mutedColor),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (index) {
                  return Icon(
                    index < review.rating ? Icons.star : Icons.star_border,
                    size: 15,
                    color: index < review.rating
                        ? AppColors.secondary
                        : mutedColor,
                  );
                }),
              ),
            ],
          ),
          if (showProductName &&
              review.productName != null &&
              review.productName!.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                review.productName!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.primaryLight : AppColors.primary,
                ),
              ),
            ),
          ],
          if (review.reviewText != null &&
              review.reviewText!.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              review.reviewText!,
              style: TextStyle(
                fontSize: 13,
                height: 1.45,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
          ],
          if (review.replyText != null &&
              review.replyText!.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.04)
                    : const Color(0xFFF3F8F4),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Balasan Penjual',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color:
                          isDark ? AppColors.primaryLight : AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    review.replyText!,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _defaultAvatar(bool isDark) {
    return Container(
      color: AppColors.primary.withValues(alpha: 0.12),
      alignment: Alignment.center,
      child: Icon(
        Icons.person_outline,
        size: 18,
        color: isDark ? AppColors.primaryLight : AppColors.primary,
      ),
    );
  }
}

