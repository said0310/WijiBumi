import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/chat_provider.dart';
import '../../../providers/store_provider.dart';
import '../../../widgets/lucide_icons.dart';
import 'manage_orders_screen.dart';
import 'manage_products_screen.dart';
import 'seller_chat_list_screen.dart';
import 'seller_dashboard_screen.dart';
import 'seller_profile_screen.dart';
import 'seller_ui_components.dart';

class SellerMainNavigationScreen extends StatefulWidget {
  final int initialIndex;

  const SellerMainNavigationScreen({super.key, this.initialIndex = 0});

  @override
  State<SellerMainNavigationScreen> createState() =>
      _SellerMainNavigationScreenState();
}

class _SellerMainNavigationScreenState
    extends State<SellerMainNavigationScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, 4);
  }

  void _selectTab(int index) {
    setState(() => _currentIndex = index.clamp(0, 4));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tokens = SellerThemeTokens(isDark);
    final storeProvider = context.watch<StoreProvider>();
    final chatProvider = context.watch<ChatProvider>();
    final storeId = storeProvider.myStore?.id;

    final unreadChats =
        storeId != null ? chatProvider.sellerUnreadCount(storeId) : 0;
    final incomingOrders = storeProvider.incomingOrdersCount;

    final screens = [
      SellerDashboardScreen(onSelectTab: _selectTab),
      const SellerChatListScreen(),
      const ManageOrdersScreen(),
      const ManageProductsScreen(),
      const SellerProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: tokens.pageBg,
      extendBody: false,
      resizeToAvoidBottomInset: false,
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Material(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        elevation: 8,
        shadowColor:
            AppColors.forestGreen.withValues(alpha: isDark ? 0.24 : 0.12),
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          side: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : AppColors.borderLight,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 62,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _SellerNavItem(
                  icon: Icons.dashboard_outlined,
                  activeIcon: Icons.dashboard_rounded,
                  label: 'Beranda',
                  isActive: _currentIndex == 0,
                  onTap: () => _selectTab(0),
                ),
                _SellerNavItem(
                  icon: Icons.chat_bubble_outline,
                  activeIcon: Icons.chat_bubble_rounded,
                  customIconBuilder: (color, isActive) =>
                      LucideMessageCircleIcon(
                    size: 22,
                    color: color,
                    strokeWidth: isActive ? 2.3 : 1.9,
                  ),
                  label: 'Chat',
                  badgeCount: unreadChats,
                  isActive: _currentIndex == 1,
                  onTap: () => _selectTab(1),
                ),
                _SellerNavItem(
                  icon: Icons.receipt_long_outlined,
                  activeIcon: Icons.receipt_long,
                  label: 'Pesanan',
                  badgeCount: incomingOrders,
                  isActive: _currentIndex == 2,
                  onTap: () => _selectTab(2),
                ),
                _SellerNavItem(
                  icon: Icons.inventory_2_outlined,
                  activeIcon: Icons.inventory_2_rounded,
                  label: 'Produk',
                  isActive: _currentIndex == 3,
                  onTap: () => _selectTab(3),
                ),
                _SellerNavItem(
                  icon: Icons.person_outline,
                  activeIcon: Icons.person,
                  label: 'Profile',
                  isActive: _currentIndex == 4,
                  onTap: () => _selectTab(4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SellerNavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final Widget Function(Color color, bool isActive)? customIconBuilder;
  final String label;
  final int badgeCount;
  final bool isActive;
  final VoidCallback onTap;

  const _SellerNavItem({
    required this.icon,
    required this.activeIcon,
    this.customIconBuilder,
    required this.label,
    this.badgeCount = 0,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor =
        isDark ? AppColors.primaryLight : AppColors.forestGreen;
    final inactiveColor =
        isDark ? AppColors.textMutedDark : const Color(0xFF6B7280);

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: isActive
                          ? activeColor.withValues(alpha: 0.14)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: customIconBuilder != null
                        ? customIconBuilder!(
                            isActive ? activeColor : inactiveColor,
                            isActive,
                          )
                        : Icon(
                            isActive ? activeIcon : icon,
                            size: 22,
                            color: isActive ? activeColor : inactiveColor,
                          ),
                  ),
                  if (badgeCount > 0)
                    Positioned(
                      right: 2,
                      top: -2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          badgeCount > 99 ? '99+' : '$badgeCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: isActive ? activeColor : inactiveColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
