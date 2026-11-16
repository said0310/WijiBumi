import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/store.dart';
import '../../providers/auth_provider.dart';
import '../../providers/store_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/glass_widgets.dart';
import '../../widgets/store_card.dart';
import '../../core/theme/app_colors.dart';
import '../profile/profile_screen.dart';
import 'my_store_entry_screen.dart';
import 'store_detail_screen.dart';

enum _StoreSortOption { recommended, highestRating, nameAscending }

class StoreListScreen extends StatefulWidget {
  final VoidCallback? onProfileTap;

  const StoreListScreen({super.key, this.onProfileTap});

  @override
  State<StoreListScreen> createState() => _StoreListScreenState();
}

class _StoreListScreenState extends State<StoreListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCity = '';
  _StoreSortOption _sortOption = _StoreSortOption.recommended;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool get _hasActiveFilter =>
      _selectedCity.isNotEmpty || _sortOption != _StoreSortOption.recommended;

  List<String> _extractAvailableCities(List<Store> stores) {
    final cities = stores
        .map((s) => s.city?.trim() ?? '')
        .where((c) => c.isNotEmpty)
        .toSet()
        .toList();
    cities.sort();
    return cities;
  }

  List<Store> _filterAndSortStores(List<Store> stores) {
    final q = _searchQuery.trim().toLowerCase();
    final selectedCityLower = _selectedCity.trim().toLowerCase();

    final list = stores.where((s) {
      if (selectedCityLower.isNotEmpty &&
          (s.city?.trim().toLowerCase() ?? '') != selectedCityLower) {
        return false;
      }
      if (q.isEmpty) return true;
      return s.storeName.toLowerCase().contains(q) ||
          (s.city?.toLowerCase().contains(q) ?? false) ||
          (s.district?.toLowerCase().contains(q) ?? false) ||
          (s.description?.toLowerCase().contains(q) ?? false);
    }).toList();

    switch (_sortOption) {
      case _StoreSortOption.recommended:
        break;
      case _StoreSortOption.highestRating:
        list.sort((a, b) {
          final cmp = b.rating.compareTo(a.rating);
          return cmp != 0 ? cmp : b.totalReviews.compareTo(a.totalReviews);
        });
        break;
      case _StoreSortOption.nameAscending:
        list.sort(
          (a, b) =>
              a.storeName.toLowerCase().compareTo(b.storeName.toLowerCase()),
        );
        break;
    }

    return list;
  }

  void _openProfile() {
    if (widget.onProfileTap != null) {
      widget.onProfileTap!();
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProfileScreen()),
    );
  }

  Future<void> _showFilterSheet(List<String> availableCities) async {
    var tempCity = _selectedCity;
    var tempSort = _sortOption;

    await showGlassBottomSheet<void>(
      context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final accentGreen =
            isDark ? AppColors.primaryLight : AppColors.forestGreen;
        final titleColor =
            isDark ? AppColors.textPrimaryDark : AppColors.neutralDark;
        final labelColor = isDark
            ? AppColors.textSecondaryDark
            : AppColors.textSecondaryLight;

        return StatefulBuilder(
          builder: (sheetCtx, setSheetState) {
            return SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Filter & Urutkan Toko',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: titleColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () {
                            setSheetState(() {
                              tempCity = '';
                              tempSort = _StoreSortOption.recommended;
                            });
                          },
                          child: Text(
                            'Reset',
                            style: TextStyle(
                              color: accentGreen,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Urutkan Berdasarkan',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: labelColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _FilterSheetChip(
                          label: 'Bawaan',
                          selected: tempSort == _StoreSortOption.recommended,
                          isDark: isDark,
                          onTap: () => setSheetState(
                            () => tempSort = _StoreSortOption.recommended,
                          ),
                        ),
                        _FilterSheetChip(
                          label: 'Rating Tertinggi',
                          selected: tempSort == _StoreSortOption.highestRating,
                          isDark: isDark,
                          onTap: () => setSheetState(
                            () => tempSort = _StoreSortOption.highestRating,
                          ),
                        ),
                        _FilterSheetChip(
                          label: 'Nama (A-Z)',
                          selected: tempSort == _StoreSortOption.nameAscending,
                          isDark: isDark,
                          onTap: () => setSheetState(
                            () => tempSort = _StoreSortOption.nameAscending,
                          ),
                        ),
                      ],
                    ),
                    if (availableCities.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Kota Kebun',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: labelColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _FilterSheetChip(
                            label: 'Semua Kota',
                            selected: tempCity.isEmpty,
                            isDark: isDark,
                            onTap: () => setSheetState(() => tempCity = ''),
                          ),
                          ...availableCities.map(
                            (city) => _FilterSheetChip(
                              label: city,
                              selected: tempCity == city,
                              isDark: isDark,
                              onTap: () => setSheetState(() => tempCity = city),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _selectedCity = tempCity;
                          _sortOption = tempSort;
                        });
                        Navigator.pop(sheetCtx);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.forestGreen,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                      child: const Text(
                        'Terapkan Filter',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final storeProvider = context.watch<StoreProvider>();
    final authProvider = context.watch<AuthProvider>();

    final availableCities = _extractAvailableCities(storeProvider.stores);
    if (_selectedCity.isNotEmpty && !availableCities.contains(_selectedCity)) {
      _selectedCity = '';
    }
    final filteredStores = _filterAndSortStores(storeProvider.stores);

    final totalShown = filteredStores.length;
    final verifiedShown = filteredStores.where((s) => s.isApproved).length;
    final rowCount = (totalShown / 2).ceil();

    final pageBg = isDark ? AppColors.backgroundDark : const Color(0xFFECF4EE);
    final cardBg = isDark ? AppColors.cardDark : AppColors.surfaceLight;
    final borderColor =
        isDark ? AppColors.borderDark : const Color(0xFFE0EBE3);
    final accentGreen =
        isDark ? AppColors.primaryLight : AppColors.forestGreen;
    final emeraldAccent =
        isDark ? AppColors.primaryLight : const Color(0xFF2E7D52);
    final titleColor =
        isDark ? AppColors.textPrimaryDark : AppColors.neutralDark;
    final mutedTextColor =
        isDark ? AppColors.textMutedDark : const Color(0xFF6B7280);

    return Scaffold(
      backgroundColor: pageBg,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: pageBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        toolbarHeight: 62,
        titleSpacing: 16,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'WIJIBUMI MARKETPLACE',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
                color: emeraldAccent,
              ),
            ),
            const SizedBox(height: 1),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                'Daftar Toko',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: accentGreen,
                  letterSpacing: -0.3,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: accentGreen, size: 22),
            tooltip: 'Muat ulang daftar toko',
            onPressed: () => storeProvider.loadStores(),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Tooltip(
              message: 'Profil Pengguna',
              child: InkWell(
                onTap: _openProfile,
                customBorder: const CircleBorder(),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: accentGreen,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.person_outline,
                    size: 19,
                    color: isDark ? Colors.black : Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar + Filter Button + City Chips
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: pageBg,
              border: Border(bottom: BorderSide(color: borderColor)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: (val) =>
                              setState(() => _searchQuery = val),
                          style: TextStyle(fontSize: 13.5, color: titleColor),
                          decoration: InputDecoration(
                            hintText: 'Cari nama toko atau kota kebun',
                            hintStyle: TextStyle(
                              fontSize: 13,
                              color: mutedTextColor,
                            ),
                            prefixIcon: Icon(
                              Icons.search,
                              size: 20,
                              color: mutedTextColor,
                            ),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 18),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _searchQuery = '');
                                    },
                                  )
                                : null,
                            filled: true,
                            fillColor: cardBg,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 11,
                              horizontal: 14,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(999),
                              borderSide: BorderSide(color: borderColor),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(999),
                              borderSide: BorderSide(color: borderColor),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(999),
                              borderSide: BorderSide(
                                color: accentGreen,
                                width: 1.4,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Tooltip(
                            message: 'Filter Toko',
                            child: Material(
                              color: accentGreen,
                              borderRadius: BorderRadius.circular(14),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(14),
                                onTap: () => _showFilterSheet(availableCities),
                                child: SizedBox(
                                  width: 46,
                                  height: 46,
                                  child: Icon(
                                    Icons.tune,
                                    color:
                                        isDark ? Colors.black : Colors.white,
                                    size: 21,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          if (_hasActiveFilter)
                            Positioned(
                              right: -2,
                              top: -2,
                              child: Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: AppColors.secondaryEmerald,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: pageBg,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Dynamic Location Filter Chips (only from actual store cities)
                if (availableCities.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          _CityChipPill(
                            label: 'Semua Kota',
                            selected: _selectedCity.isEmpty,
                            isDark: isDark,
                            borderColor: borderColor,
                            onTap: () => setState(() => _selectedCity = ''),
                          ),
                          ...availableCities.map(
                            (city) => Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: _CityChipPill(
                                label: city,
                                selected: _selectedCity == city,
                                isDark: isDark,
                                borderColor: borderColor,
                                onTap: () =>
                                    setState(() => _selectedCity = city),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Main Scrollable Grid + Status Summary + Farmer Partner Banner
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => storeProvider.loadStores(),
              child: filteredStores.isEmpty
                  ? SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 720),
                          child: Column(
                            children: [
                              const EmptyState(
                                icon: Icons.storefront_outlined,
                                title: 'Toko Tidak Ditemukan',
                                message:
                                    'Belum ada toko terverifikasi atau sesuai pencarian Anda.',
                              ),
                              const SizedBox(height: 16),
                              _FarmerPartnerBanner(
                                hasSellerSession:
                                    authProvider.isSellerSessionAuthenticated,
                                hasStore: storeProvider.hasStore,
                                isDark: isDark,
                                borderColor: borderColor,
                                titleColor: titleColor,
                                mutedTextColor: mutedTextColor,
                                accentGreen: accentGreen,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const MyStoreEntryScreen(),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                      // +2 items: [0] verified header row, [1..rowCount] 2-col card rows, [last] partner banner
                      itemCount: rowCount + 2,
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 720),
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _VerificationSummaryBar(
                                  totalShown: totalShown,
                                  verifiedShown: verifiedShown,
                                  accentGreen: accentGreen,
                                  mutedTextColor: mutedTextColor,
                                ),
                              ),
                            ),
                          );
                        }

                        if (index == rowCount + 1) {
                          return Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 720),
                              child: Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: _FarmerPartnerBanner(
                                  hasSellerSession:
                                      authProvider.isSellerSessionAuthenticated,
                                  hasStore: storeProvider.hasStore,
                                  isDark: isDark,
                                  borderColor: borderColor,
                                  titleColor: titleColor,
                                  mutedTextColor: mutedTextColor,
                                  accentGreen: accentGreen,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const MyStoreEntryScreen(),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          );
                        }

                        final rowIndex = index - 1;
                        final leftIdx = rowIndex * 2;
                        final rightIdx = leftIdx + 1;
                        final leftStore = filteredStores[leftIdx];
                        final rightStore = rightIdx < totalShown
                            ? filteredStores[rightIdx]
                            : null;

                        return Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 720),
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: IntrinsicHeight(
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Expanded(
                                      child: StoreCard(
                                        store: leftStore,
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => StoreDetailScreen(
                                                store: leftStore,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: rightStore != null
                                          ? StoreCard(
                                              store: rightStore,
                                              onTap: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) =>
                                                        StoreDetailScreen(
                                                      store: rightStore,
                                                    ),
                                                  ),
                                                );
                                              },
                                            )
                                          : const SizedBox.shrink(),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CityChipPill extends StatelessWidget {
  final String label;
  final bool selected;
  final bool isDark;
  final Color borderColor;
  final VoidCallback onTap;

  const _CityChipPill({
    required this.label,
    required this.selected,
    required this.isDark,
    required this.borderColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = selected
        ? (isDark ? AppColors.primaryLight : AppColors.forestGreen)
        : (isDark ? AppColors.surfaceDark : const Color(0xFFE1EEE5));
    final textColor = selected
        ? (isDark ? Colors.black : Colors.white)
        : (isDark ? AppColors.textSecondaryDark : AppColors.neutralDark);

    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: selected ? null : Border.all(color: borderColor),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }
}

class _FilterSheetChip extends StatelessWidget {
  final String label;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  const _FilterSheetChip({
    required this.label,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor:
          isDark ? AppColors.primaryLight : AppColors.forestGreen,
      backgroundColor:
          isDark ? AppColors.backgroundDark : const Color(0xFFE9F4EC),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        color: selected
            ? (isDark ? Colors.black : Colors.white)
            : (isDark ? AppColors.textPrimaryDark : AppColors.neutralDark),
      ),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      showCheckmark: false,
    );
  }
}

class _VerificationSummaryBar extends StatelessWidget {
  final int totalShown;
  final int verifiedShown;
  final Color accentGreen;
  final Color mutedTextColor;

  const _VerificationSummaryBar({
    required this.totalShown,
    required this.verifiedShown,
    required this.accentGreen,
    required this.mutedTextColor,
  });

  @override
  Widget build(BuildContext context) {
    final verificationText = verifiedShown == totalShown
        ? 'Terverifikasi WijiBumi'
        : '$verifiedShown dari $totalShown Terverifikasi';

    return Row(
      children: [
        if (verifiedShown > 0)
          Expanded(
            child: Row(
              children: [
                Icon(Icons.verified_user, size: 15, color: accentGreen),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    verificationText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: accentGreen,
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          const Spacer(),
        const SizedBox(width: 8),
        Text(
          'Menampilkan $totalShown toko',
          style: TextStyle(
            fontSize: 12,
            color: mutedTextColor,
          ),
        ),
      ],
    );
  }
}

class _FarmerPartnerBanner extends StatelessWidget {
  final bool hasSellerSession;
  final bool hasStore;
  final bool isDark;
  final Color borderColor;
  final Color titleColor;
  final Color mutedTextColor;
  final Color accentGreen;
  final VoidCallback onTap;

  const _FarmerPartnerBanner({
    required this.hasSellerSession,
    required this.hasStore,
    required this.isDark,
    required this.borderColor,
    required this.titleColor,
    required this.mutedTextColor,
    required this.accentGreen,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isManagingStore = hasSellerSession && hasStore;
    final headline =
        isManagingStore ? 'Kelola Toko Mitra Anda' : 'Punya Kebun Mandiri?';
    final subtitle = isManagingStore
        ? 'Pantau produk, pesanan & statistik kebun Anda'
        : 'Bergabunglah menjadi mitra tani WijiBumi';
    final actionText = isManagingStore ? 'Kelola' : 'Daftar';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.cardDark
            : const Color(0xFFE3EFE6),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.primary.withValues(alpha: 0.22)
                  : const Color(0xFFD0E7D6),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.agriculture_outlined,
              size: 20,
              color: accentGreen,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  headline,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: mutedTextColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Material(
            color: accentGreen,
            borderRadius: BorderRadius.circular(999),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(999),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                child: Text(
                  actionText,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.black : Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
