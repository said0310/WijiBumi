import 'package:flutter/material.dart';
import '../models/store.dart';
import '../core/theme/app_colors.dart';
import 'smart_image.dart';

class StoreCard extends StatelessWidget {
  final Store store;
  final VoidCallback onTap;

  const StoreCard({
    super.key,
    required this.store,
    required this.onTap,
  });

  String _formatLocation() {
    final city = store.city?.trim();
    if (city != null && city.isNotEmpty) return city;
    final district = store.district?.trim();
    if (district != null && district.isNotEmpty) return district;
    final province = store.province?.trim();
    if (province != null && province.isNotEmpty) return province;
    return 'Indonesia';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.cardDark : AppColors.surfaceLight;
    final borderColor =
        isDark ? AppColors.borderDark : const Color(0xFFE0EBE3);
    final titleColor =
        isDark ? AppColors.textPrimaryDark : AppColors.neutralDark;
    final mutedTextColor =
        isDark ? AppColors.textMutedDark : const Color(0xFF6B7280);
    final accentGreen =
        isDark ? AppColors.primaryLight : AppColors.forestGreen;
    final softMintBg = isDark
        ? AppColors.primary.withValues(alpha: 0.16)
        : const Color(0xFFEAF5ED);
    final hasLogo = store.logoPath != null && store.logoPath!.trim().isNotEmpty;
    final isCompact = MediaQuery.sizeOf(context).width < 360;
    final avatarSize = isCompact ? 62.0 : 72.0;

    return Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.045),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  isCompact ? 10 : 12,
                  14,
                  isCompact ? 10 : 12,
                  12,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Top Content: Avatar, Name, Location, Description
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: avatarSize,
                              height: avatarSize,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: softMintBg,
                                border: Border.all(color: borderColor, width: 1.5),
                              ),
                              child: ClipOval(
                                child: hasLogo
                                    ? SmartImage(
                                        source: store.logoPath,
                                        fit: BoxFit.cover,
                                        fallback: _StoreAvatarFallback(
                                          softMintBg: softMintBg,
                                          accentGreen: accentGreen,
                                        ),
                                      )
                                    : _StoreAvatarFallback(
                                        softMintBg: softMintBg,
                                        accentGreen: accentGreen,
                                      ),
                              ),
                            ),
                            if (store.isApproved)
                              Positioned(
                                right: -1,
                                bottom: -1,
                                child: Container(
                                  width: 22,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    color: accentGreen,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: cardBg,
                                      width: 2,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.check,
                                    size: 12,
                                    color: isDark ? Colors.black : Colors.white,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          store.storeName,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            height: 1.25,
                            color: titleColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 13,
                              color: isDark
                                  ? AppColors.primaryLight
                                  : AppColors.primary,
                            ),
                            const SizedBox(width: 3),
                            Flexible(
                              child: Text(
                                _formatLocation(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: mutedTextColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (store.description != null &&
                            store.description!.trim().isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            store.description!,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11.5,
                              height: 1.3,
                              color: mutedTextColor,
                            ),
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Bottom Section: Rating Pill + CTA Button
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (store.rating > 0) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: softMintBg,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            alignment: Alignment.center,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.star,
                                    size: 14,
                                    color: isDark
                                        ? const Color(0xFFFBBF24)
                                        : AppColors.forestGreen,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    store.rating.toStringAsFixed(1),
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: titleColor,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '(${store.totalReviews})',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: mutedTextColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                        Material(
                          color: isDark
                              ? AppColors.primaryLight
                              : AppColors.forestGreen,
                          borderRadius: BorderRadius.circular(999),
                          child: InkWell(
                            onTap: onTap,
                            borderRadius: BorderRadius.circular(999),
                            child: Container(
                              constraints: const BoxConstraints(minHeight: 38),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              alignment: Alignment.center,
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Lihat Toko',
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w700,
                                        color: isDark
                                            ? Colors.black
                                            : Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    Icon(
                                      Icons.arrow_forward,
                                      size: 14,
                                      color: isDark
                                          ? Colors.black
                                          : Colors.white,
                                    ),
                                  ],
                                ),
                              ),
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
  }
}

class _StoreAvatarFallback extends StatelessWidget {
  final Color softMintBg;
  final Color accentGreen;

  const _StoreAvatarFallback({
    required this.softMintBg,
    required this.accentGreen,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: softMintBg,
      alignment: Alignment.center,
      child: Icon(
        Icons.storefront_outlined,
        size: 28,
        color: accentGreen,
      ),
    );
  }
}
