import 'package:flutter/material.dart';
import '../models/product.dart';
import '../core/utils/currency_formatter.dart';
import '../core/theme/app_colors.dart';
import 'lucide_icons.dart';
import 'smart_image.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  final VoidCallback? onAddToCart;

  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    this.onAddToCart,
  });

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
    final storeColor =
        isDark ? AppColors.primaryLight : const Color(0xFF2E7D52);

    Color gradeColor = AppColors.gradeA;
    if (product.qualityGrade == 'B') gradeColor = AppColors.gradeB;
    if (product.qualityGrade == 'C') gradeColor = AppColors.gradeC;

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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Proportional Product Photo + Existing Grade / Stock Badges
              Expanded(
                flex: 5,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(7, 7, 7, 0),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: SmartImage(
                          source: product.primaryImage,
                          fit: BoxFit.cover,
                          fallback: Container(
                            color: isDark
                                ? AppColors.backgroundDark
                                : const Color(0xFFEAF5ED),
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.eco_outlined,
                              color: accentGreen,
                              size: 28,
                            ),
                          ),
                        ),
                      ),
                      if (product.qualityGrade != null ||
                          product.stock <= 0 ||
                          (product.stock <= 5 && product.stock > 0))
                        Positioned(
                          top: 6,
                          left: 6,
                          right: 6,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              if (product.qualityGrade != null)
                                Flexible(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 7,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: gradeColor,
                                      borderRadius: BorderRadius.circular(999),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Colors.black26,
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      'Grade ${product.qualityGrade}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                )
                              else
                                const SizedBox.shrink(),
                              if (product.stock <= 0 ||
                                  (product.stock <= 5 && product.stock > 0)) ...[
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 7,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: product.stock <= 0
                                          ? Colors.grey.shade800
                                          : AppColors.error,
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      product.stock <= 0
                                          ? 'Stok Habis'
                                          : 'Sisa Sedikit',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Product Details
              Expanded(
                flex: 5,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            product.storeName ?? 'WijiBumi Store',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: storeColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            product.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              height: 1.2,
                              color: titleColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.star,
                                size: 12,
                                color: Colors.amber,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                product.rating.toStringAsFixed(1),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: titleColor,
                                ),
                              ),
                              if (product.totalSales > 0) ...[
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    '(${product.totalSales} terjual)',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      color: mutedTextColor,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),

                      // Price + Forest Green Add-to-Cart Button
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  CurrencyFormatter.format(product.price),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: accentGreen,
                                  ),
                                ),
                                Text(
                                  '/ ${product.unit}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: mutedTextColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (onAddToCart != null) ...[
                            const SizedBox(width: 6),
                            Tooltip(
                              message: 'Tambah ke Keranjang',
                              child: Material(
                                color: product.isAvailable
                                    ? accentGreen
                                    : Colors.grey.shade400,
                                shape: const CircleBorder(),
                                child: InkWell(
                                  onTap:
                                      product.isAvailable ? onAddToCart : null,
                                  customBorder: const CircleBorder(),
                                  child: SizedBox(
                                    width: 32,
                                    height: 32,
                                    child: Center(
                                      child: LucideShoppingCartIcon(
                                        size: 16,
                                        color: isDark && product.isAvailable
                                            ? Colors.black
                                            : Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
