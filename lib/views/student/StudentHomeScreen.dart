import 'package:fyp/views/shared Widgets/ResponsiveHostelGrid.dart';
// ─────────────────────────────────────────────────────────────────────────────
// Student shell screen — persistent bottom nav via IndexedStack.
// Tab 0: Home (active-booking card OR hostel list)
// Tab 1: My Bookings   Tab 2: Messages
// Tab 3: Complaints    Tab 4: Profile
// FR-4.1, FR-4.2, FR-4.3
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fyp/controllers/AuthController.dart';
import 'package:fyp/controllers/BookingController.dart';
import 'package:fyp/controllers/HostelController.dart';
import 'package:fyp/controllers/NotificationController.dart';
import 'package:fyp/routes/AppRoutes.dart';
import 'package:fyp/utils/AppColors.dart';
import 'package:fyp/utils/AppConstants.dart';
import 'package:fyp/utils/Responsive.dart';
import 'package:fyp/views/SharedScreens/ProfileScreen.dart';
import 'package:fyp/views/shared Widgets/FloatingBottomNavBar.dart';
import 'package:fyp/views/shared Widgets/AnimatedStates.dart';
import 'package:fyp/views/shared%20Widgets/HostelCardSkeleton.dart';
import 'package:fyp/views/shared Widgets/WebSidebarShell.dart';
import 'package:fyp/views/student/BookingRequestScreen.dart';
import 'package:fyp/views/student/MyComplaintScreen.dart';
import 'package:fyp/views/student/StudentChatListScreen.dart';
import 'package:fyp/views/student/StudentMyHostelCard.dart';
import 'package:fyp/views/student/StudentSettingsScreen.dart';
import 'package:get/get.dart';


// ── Shell ──────────────────────────────────────────────────────────────────
class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  int _currentIndex = 0;

  static const _webNavItems = [
    SidebarNavItem(icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Home'),
    SidebarNavItem(icon: Icons.book_outlined, activeIcon: Icons.book, label: 'My Bookings'),
    SidebarNavItem(icon: Icons.chat_bubble_outline, activeIcon: Icons.chat_bubble, label: 'Messages'),
    SidebarNavItem(icon: Icons.report_outlined, activeIcon: Icons.report, label: 'Complaints'),
    SidebarNavItem(icon: Icons.person_outline, activeIcon: Icons.person, label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    final isWide = Responsive.isWide(context);
    final authCtrl = Get.find<AuthController>();
    final notifCtrl = Get.find<NotificationController>();

    final List<Widget> tabs = [
      const _StudentHomeTab(),
      const MyBookingsScreen(),
      const StudentChatListScreen(),
      const MyComplaintsScreen(),
      kIsWeb
          ? const ProfileScreen()
          : StudentSettingsScreen(
              onBackToHome: () => setState(() => _currentIndex = 0),
            ),
    ];

    // ── Web layout: sidebar shell ──────────────────────────────────────────
    if (isWide) {
      return Obx(() => WebSidebarShell(
            currentIndex: _currentIndex,
            onTap: (i) => setState(() => _currentIndex = i),
            items: _webNavItems,
            userName: authCtrl.currentUser.value?.name ?? 'Student',
            roleLabel: 'Student Portal',
            notificationCount: notifCtrl.unreadCount.value,
            body: IndexedStack(
              index: _currentIndex,
              children: tabs,
            ),
          ));
    }

    // ── Mobile layout: floating bottom nav (unchanged) ─────────────────────
    return Scaffold(
      body: PopScope(
        canPop: _currentIndex == 0,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop && _currentIndex != 0) {
            setState(() => _currentIndex = 0);
          }
        },
        child: IndexedStack(
          index: _currentIndex,
          children: tabs,
        ),
      ),
      bottomNavigationBar: FloatingBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          FloatingNavItem(
            icon: Icons.home_outlined,
            activeIcon: Icons.home,
            label: 'Home',
          ),
          FloatingNavItem(
            icon: Icons.book_outlined,
            activeIcon: Icons.book,
            label: 'Bookings',
          ),
          FloatingNavItem(
            icon: Icons.chat_bubble_outline,
            activeIcon: Icons.chat_bubble,
            label: 'Messages',
          ),
          FloatingNavItem(
            icon: Icons.report_outlined,
            activeIcon: Icons.report,
            label: 'Complaints',
          ),
          FloatingNavItem(
            icon: Icons.settings_outlined,
            activeIcon: Icons.settings_rounded,
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}


// ── Tab 0: Home content ────────────────────────────────────────────────────
class _StudentHomeTab extends StatelessWidget {
  const _StudentHomeTab();

  @override
  Widget build(BuildContext context) {
    final isWide = Responsive.isWide(context);
    if (isWide) {
      return _buildWebLayout(context);
    }
    return _buildMobileLayout(context);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // MOBILE REDESIGN: Curved Teal Header, Integrated Search, Filter Pills
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildMobileLayout(BuildContext context) {
    final AuthController authCtrl = Get.find<AuthController>();
    final HostelController hostelCtrl = Get.find<HostelController>();
    final NotificationController notifCtrl = Get.find<NotificationController>();
    final BookingController bookingCtrl = Get.find<BookingController>();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF111827) : const Color(0xFFF1F5F9);

    return Scaffold(
      backgroundColor: bgColor,
      body: Obx(() {
        if (!bookingCtrl.isBookingsLoaded.value) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF00585E)),
          );
        }

        final activeBooking =
            bookingCtrl.myBookings.where((b) => b.isActive).toList();

        final hasActiveStay = activeBooking.isNotEmpty;

        return Column(
          children: [
            // ── Curved Teal Hero Header ─────────────────────────────────────
            _buildMobileCurvedHeader(
              context: context,
              authCtrl: authCtrl,
              notifCtrl: notifCtrl,
              hostelCtrl: hostelCtrl,
              hasActiveStay: hasActiveStay,
              activeHostelName: hasActiveStay ? activeBooking.first.hostelName : null,
            ),

            // ── Content ─────────────────────────────────────────────────────
            if (hasActiveStay)
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                  child: Column(
                    children: [
                      StudentMyHostelCard(booking: activeBooking.first),
                    ],
                  ),
                ),
              )
            else ...[
              // ── Sub-Bar: Hostels Count & Modern Sort Selector ──────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.apartment_rounded,
                            size: 18, color: Color(0xFF00585E)),
                        const SizedBox(width: 6),
                        Text(
                          'Available Hostels',
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Obx(() => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF00585E)
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${hostelCtrl.approvedHostels.length}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF00585E),
                                ),
                              ),
                            )),
                      ],
                    ),
                    _buildMobileSortButton(context, hostelCtrl, isDark),
                  ],
                ),
              ),

              // ── Hostel List Grid ──────────────────────────────────────────
              Expanded(
                child: Obx(() {
                  if (hostelCtrl.approvedHostels.isEmpty &&
                      hostelCtrl.isLoading.value) {
                    return const HostelListSkeleton();
                  }

                  if (hostelCtrl.approvedHostels.isEmpty) {
                    return const AnimatedEmptyState(
                      message: 'No hostels found.\nTry a different city or filter.',
                    );
                  }

                  return RefreshIndicator(
                    color: const Color(0xFF00585E),
                    onRefresh: () async => hostelCtrl.loadApprovedHostels(),
                    child: ResponsiveHostelGrid(
                      hostels: hostelCtrl.approvedHostels,
                    ),
                  );
                }),
              ),
            ],
          ],
        );
      }),

      // ── FAB: Filter button (when browsing) ─────────────────────────────────
      floatingActionButton: Obx(() {
        final activeBooking =
            bookingCtrl.myBookings.where((b) => b.isActive).toList();
        if (activeBooking.isNotEmpty) return const SizedBox.shrink();

        final activeCount = [
          hostelCtrl.selectedCity.value.isNotEmpty,
          hostelCtrl.selectedGender.value.isNotEmpty,
        ].where((v) => v).length;

        return GestureDetector(
          onTap: () => _showFilterSheet(context, hostelCtrl),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00585E), Color(0xFF007A85)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00585E).withValues(alpha: 0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.tune_rounded, size: 17, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'Filter',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              if (activeCount > 0)
                Positioned(
                  top: -6,
                  right: -6,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF007A85), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        '$activeCount',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF007A85),
                          height: 1,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  // ── Mobile Header ─────────────────────────────────────────────────────────
  Widget _buildMobileCurvedHeader({
    required BuildContext context,
    required AuthController authCtrl,
    required NotificationController notifCtrl,
    required HostelController hostelCtrl,
    required bool hasActiveStay,
    String? activeHostelName,
  }) {
    final user = authCtrl.currentUser.value;
    final firstName = user?.name.split(' ').first ?? 'Student';

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF00585E), Color(0xFF007A85)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 16, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: User Avatar, Greeting, Notifications & Settings
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Get.to(() => const ProfileScreen()),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.35),
                          width: 1.5,
                        ),
                        color: Colors.white.withValues(alpha: 0.18),
                      ),
                      child: ClipOval(
                        child: user?.profileImage != null &&
                                user!.profileImage!.isNotEmpty
                            ? Image.network(
                                user.profileImage!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    _avatarFallback(user.name),
                              )
                            : _avatarFallback(user?.name ?? 'S'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_getGreeting()}, $firstName 👋',
                          style: const TextStyle(
                            fontSize: 16.5,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: -0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          hasActiveStay
                              ? 'Active Stay · ${activeHostelName ?? "Hostel"}'
                              : 'Find your ideal student hostel',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.82),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Notifications
                  Obx(() {
                    final count = notifCtrl.unreadCount.value;
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                              width: 1.2,
                            ),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.notifications_outlined,
                                color: Colors.white, size: 20),
                            padding: EdgeInsets.zero,
                            onPressed: () =>
                                Get.toNamed(AppRoutes.notifications),
                          ),
                        ),
                        if (count > 0)
                          Positioned(
                            right: -2,
                            top: -2,
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: const BoxDecoration(
                                color: Color(0xFFEF4444),
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(
                                  minWidth: 16, minHeight: 16),
                              child: Text(
                                count > 9 ? '9+' : '$count',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    );
                  }),
                  const SizedBox(width: 8),
                  // Settings
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 1.2,
                      ),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.settings_outlined,
                          color: Colors.white, size: 20),
                      padding: EdgeInsets.zero,
                      onPressed: () => Get.to(() => const StudentSettingsScreen()),
                    ),
                  ),
                ],
              ),

              if (!hasActiveStay) ...[
                const SizedBox(height: 14),

                // Search Bar with in-header filter button
                GestureDetector(
                  onTap: () => Get.toNamed(AppRoutes.hostelSearch),
                  child: Container(
                    height: 46,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.search_rounded,
                            color: Color(0xFF007A85), size: 20),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Search by hostel name, city, university...',
                            style: TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Filter button inside search bar
                        Obx(() {
                          final hasFilter =
                              hostelCtrl.selectedCity.value.isNotEmpty ||
                                  hostelCtrl.selectedGender.value.isNotEmpty;
                          return GestureDetector(
                            onTap: () =>
                                _showFilterSheet(context, hostelCtrl),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: hasFilter
                                    ? const Color(0xFF00585E)
                                    : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(9),
                              ),
                              child: Icon(
                                Icons.tune_rounded,
                                size: 16,
                                color: hasFilter
                                    ? Colors.white
                                    : const Color(0xFF00585E),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // City Quick-Filter Chips
                SizedBox(
                  height: 34,
                  child: Obx(() => ListView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        children: [
                          _MobileCityPill(
                            label: 'All Cities',
                            isSelected:
                                hostelCtrl.selectedCity.value.isEmpty,
                            onTap: () => hostelCtrl.applyFilters(city: ''),
                          ),
                          ...AppConstants.supportedCities.map(
                            (city) => _MobileCityPill(
                              label: city,
                              isSelected:
                                  hostelCtrl.selectedCity.value == city,
                              onTap: () => hostelCtrl.applyFilters(city: city),
                            ),
                          ),
                        ],
                      )),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _avatarFallback(String name) {
    final letter = name.isNotEmpty ? name[0].toUpperCase() : 'S';
    return Center(
      child: Text(
        letter,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }

  // ── Mobile Sort Button ────────────────────────────────────────────────────
  Widget _buildMobileSortButton(
      BuildContext context, HostelController hostelCtrl, bool isDark) {
    const labels = {
      'smart': 'Smart Ranking',
      'rating': 'Highest Rating',
      'priceLow': 'Price ↑',
      'priceHigh': 'Price ↓',
      'newest': 'Newest First',
    };
    const icons = {
      'smart': Icons.leaderboard_rounded,
      'rating': Icons.star_rounded,
      'priceLow': Icons.trending_up_rounded,
      'priceHigh': Icons.trending_down_rounded,
      'newest': Icons.schedule_rounded,
    };

    final cardColor = Theme.of(context).cardColor;
    final textColor =
        isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final subTextColor =
        isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;

    return Obx(() {
      final current = hostelCtrl.sortMode.value;
      return PopupMenuButton<String>(
        onSelected: hostelCtrl.applySortMode,
        color: cardColor,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        offset: const Offset(0, 36),
        itemBuilder: (_) => labels.entries.map((e) {
          final isActive = e.key == current;
          return PopupMenuItem<String>(
            value: e.key,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Icon(
                  icons[e.key],
                  size: 16,
                  color: isActive ? const Color(0xFF00585E) : subTextColor,
                ),
                const SizedBox(width: 10),
                Text(
                  e.value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight:
                        isActive ? FontWeight.w700 : FontWeight.w400,
                    color: isActive ? const Color(0xFF00585E) : textColor,
                  ),
                ),
                if (isActive) ...[
                  const Spacer(),
                  const Icon(Icons.check_rounded,
                      size: 16, color: Color(0xFF00585E)),
                ],
              ],
            ),
          );
        }).toList(),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF00585E),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icons[current], size: 13, color: Colors.white),
              const SizedBox(width: 5),
              Text(
                labels[current] ?? 'Sort',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.keyboard_arrow_down_rounded,
                  size: 14, color: Colors.white),
            ],
          ),
        ),
      );
    });
  }

  // ─────────────────────────────────────────────────────────────────────────
  // WEB LAYOUT: 100% Preserved for Desktop
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildWebLayout(BuildContext context) {
    final AuthController authCtrl = Get.find<AuthController>();
    final HostelController hostelCtrl = Get.find<HostelController>();
    final BookingController bookingCtrl = Get.find<BookingController>();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final subTextColor = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final cardColor = Theme.of(context).cardColor;

    return Scaffold(
      body: Obx(() {
        if (!bookingCtrl.isBookingsLoaded.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final activeBooking =
            bookingCtrl.myBookings.where((b) => b.isActive).toList();

        if (activeBooking.isNotEmpty) {
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1080),
                child: StudentMyHostelCard(booking: activeBooking.first),
              ),
            ),
          );
        }

        return Column(
          children: [
            // ── Web Search & Filter Header ─────────────────────────────────
            Container(
              color: isDark ? const Color(0xFF0F171E) : const Color(0xFFF6F8FA),
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1140),
                  child: Column(
                    children: [
                      _buildHeroCard(context, isDark, authCtrl),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => Get.toNamed(AppRoutes.hostelSearch),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF14202E)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isDark
                                        ? const Color(0xFF223242)
                                        : const Color(0xFFE2E8F0),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black
                                          .withValues(alpha: isDark ? 0.2 : 0.04),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.search_rounded,
                                      color: Color(0xFF2DD4BF),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      'Search hostels by name, city, university...',
                                      style: TextStyle(
                                        color: isDark
                                            ? const Color(0xFF94A3B8)
                                            : const Color(0xFF64748B),
                                        fontSize: 13.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Obx(() => Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _CityChip(
                                    label: 'All',
                                    isSelected:
                                        hostelCtrl.selectedCity.value.isEmpty,
                                    onTap: () =>
                                        hostelCtrl.applyFilters(city: ''),
                                    isWide: true,
                                  ),
                                  ...AppConstants.supportedCities.map(
                                    (city) => _CityChip(
                                      label: city,
                                      isSelected:
                                          hostelCtrl.selectedCity.value == city,
                                      onTap: () =>
                                          hostelCtrl.applyFilters(city: city),
                                      isWide: true,
                                    ),
                                  ),
                                ],
                              )),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Sort Mode Selector (Web) ───────────────────────────────────
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1140),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Icon(Icons.sort_rounded, size: 16, color: subTextColor),
                      const SizedBox(width: 6),
                      Text(
                        'Sort:',
                        style: TextStyle(
                          fontSize: 12,
                          color: subTextColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Obx(() {
                        const labels = {
                          'smart': 'Smart Ranking',
                          'rating': 'Highest Rating',
                          'priceLow': 'Price ↑',
                          'priceHigh': 'Price ↓',
                          'newest': 'Newest First',
                        };
                        const icons = {
                          'smart': Icons.leaderboard_rounded,
                          'rating': Icons.star_rounded,
                          'priceLow': Icons.trending_up_rounded,
                          'priceHigh': Icons.trending_down_rounded,
                          'newest': Icons.schedule_rounded,
                        };
                        final current = hostelCtrl.sortMode.value;
                        return PopupMenuButton<String>(
                          onSelected: hostelCtrl.applySortMode,
                          color: cardColor,
                          elevation: 8,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          offset: const Offset(0, 36),
                          itemBuilder: (_) => labels.entries.map((e) {
                            final isActive = e.key == current;
                            return PopupMenuItem<String>(
                              value: e.key,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 4),
                              child: Row(
                                children: [
                                  Icon(
                                    icons[e.key],
                                    size: 16,
                                    color: isActive
                                        ? AppColors.primary
                                        : subTextColor,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    e.value,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: isActive
                                          ? FontWeight.w700
                                          : FontWeight.w400,
                                      color: isActive
                                          ? AppColors.primary
                                          : textColor,
                                    ),
                                  ),
                                  if (isActive) ...[
                                    const Spacer(),
                                    const Icon(Icons.check_rounded,
                                        size: 16, color: AppColors.primary),
                                  ],
                                ],
                              ),
                            );
                          }).toList(),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(icons[current],
                                    size: 13, color: Colors.white),
                                const SizedBox(width: 5),
                                Text(
                                  labels[current] ?? 'Sort',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.keyboard_arrow_down_rounded,
                                    size: 14, color: Colors.white),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),

            // ── Web Hostel List ────────────────────────────────────────────
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1140),
                  child: Obx(() {
                    if (hostelCtrl.approvedHostels.isEmpty &&
                        hostelCtrl.isLoading.value) {
                      return const HostelListSkeleton();
                    }

                    if (hostelCtrl.approvedHostels.isEmpty) {
                      return const AnimatedEmptyState(
                        message:
                            'No hostels found.\nTry a different city or filter.',
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: () async =>
                          hostelCtrl.loadApprovedHostels(),
                      child: ResponsiveHostelGrid(
                        hostels: hostelCtrl.approvedHostels,
                      ),
                    );
                  }),
                ),
              ),
            ),
          ],
        );
      }),
      // ── FAB: Filter button ─────────────────────────────────────────────────
      floatingActionButton: Obx(() {
        final activeBooking = bookingCtrl.myBookings
            .where((b) => b.isActive)
            .toList();
        if (activeBooking.isNotEmpty) return const SizedBox.shrink();

        final activeCount = [
          hostelCtrl.selectedCity.value.isNotEmpty,
          hostelCtrl.selectedGender.value.isNotEmpty,
        ].where((v) => v).length;

        return GestureDetector(
          onTap: () => _showFilterSheet(context, hostelCtrl),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // ── Main pill ──────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.accent,
                      AppColors.accent.withValues(alpha: 0.82),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.45),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.10),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.tune_rounded, size: 17, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'Filter',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ),

              // ── Active filter badge ────────────────────────────────────
              if (activeCount > 0)
                Positioned(
                  top: -6,
                  right: -6,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.accent, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        '$activeCount',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.accent,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  // ── Bottom Sheet for advanced filters ─────────────────────────────────────
  void _showFilterSheet(BuildContext context, HostelController ctrl) {
    // Local temp values for filter (applied only on tap "Apply")
    double tempMin = ctrl.minRent.value;
    double tempMax = ctrl.maxRent.value;
    String tempGender = ctrl.selectedGender.value;
    final isWide = Responsive.isWide(context);

    Get.bottomSheet(
      StatefulBuilder(
        builder: (ctx, setState) {
          final isDark = Theme.of(context).brightness == Brightness.dark ||
              Theme.of(ctx).brightness == Brightness.dark ||
              Get.isDarkMode;
          final sheetBg = isDark ? const Color(0xFF1E242B) : Colors.white;
          final borderColor = isDark ? const Color(0xFF2C3238) : const Color(0xFFE2E8F0);
          final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);
          final textColor = isDark ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B);
          final subTextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
          final chipUnselectedBg = isDark ? const Color(0xFF14191E) : const Color(0xFFF8FAFC);

          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: isWide ? 500 : double.infinity),
              child: Container(
                margin: isWide ? const EdgeInsets.all(24) : EdgeInsets.zero,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: sheetBg,
                  borderRadius: isWide
                      ? BorderRadius.circular(20)
                      : const BorderRadius.vertical(top: Radius.circular(20)),
                  border: Border.all(color: borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.1),
                      blurRadius: 24,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!isWide)
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF2C3238) : AppColors.divider,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Filter Hostels',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: titleColor,
                          ),
                        ),
                        if (isWide)
                          IconButton(
                            icon: Icon(Icons.close_rounded, size: 20, color: subTextColor),
                            onPressed: () => Get.back(),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // ── Rent Range Slider ──────────────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Rent Range',
                            style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: textColor)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
                          ),
                          child: Text(
                            'PKR ${tempMin.round()} – ${tempMax.round()}',
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SliderTheme(
                      data: SliderThemeData(
                        activeTrackColor: AppColors.primary,
                        inactiveTrackColor: isDark ? const Color(0xFF2C3238) : const Color(0xFFE2E8F0),
                        thumbColor: AppColors.primary,
                        overlayColor: AppColors.primary.withValues(alpha: 0.15),
                        trackHeight: 4,
                        rangeThumbShape: const RoundRangeSliderThumbShape(enabledThumbRadius: 9),
                      ),
                      child: RangeSlider(
                        values: RangeValues(tempMin, tempMax),
                        min: 0,
                        max: 50000,
                        divisions: 50,
                        onChanged: (v) => setState(() {
                          tempMin = v.start;
                          tempMax = v.end;
                        }),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Gender Filter ──────────────────────────────────────────
                    Text('Gender Preference',
                        style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: textColor)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: ['All', ...AppConstants.genderOptions].map((g) {
                        final selected = tempGender == (g == 'All' ? '' : g);
                        return InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () => setState(() {
                            tempGender = g == 'All' ? '' : g;
                          }),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: selected ? AppColors.primary : chipUnselectedBg,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: selected ? AppColors.primary : borderColor,
                                width: selected ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (selected) ...[
                                  const Icon(Icons.check_rounded, size: 14, color: Colors.white),
                                  const SizedBox(width: 6),
                                ],
                                Text(
                                  g,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                                    color: selected
                                        ? Colors.white
                                        : (isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),

                    // ── Action Buttons ─────────────────────────────────────────
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              ctrl.clearFilters();
                              Get.back();
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF475569),
                              backgroundColor: isDark ? const Color(0xFF14191E) : const Color(0xFFF8FAFC),
                              side: BorderSide(color: borderColor),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: const Text('Clear All', style: TextStyle(fontWeight: FontWeight.w600)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              ctrl.applyFilters(
                                gender: tempGender,
                                min: tempMin,
                                max: tempMax,
                              );
                              Get.back();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              elevation: 0,
                            ),
                            child: const Text('Apply', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  Widget _buildHeroCard(BuildContext context, bool isDark, AuthController authCtrl) {
    return Container(
      width: double.infinity,
      height: 160,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  const Color(0xFF0F262C),
                  const Color(0xFF13202E),
                  const Color(0xFF162534),
                ]
              : [
                  const Color(0xFF004D56),
                  const Color(0xFF006670),
                  const Color(0xFF007A87),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? const Color(0xFF223242) : Colors.white.withValues(alpha: 0.15),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            // Left Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      const Text('👋', style: TextStyle(fontSize: 24)),
                      const SizedBox(width: 10),
                      Text(
                        _getGreeting(),
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Obx(() => Text(
                        authCtrl.currentUser.value?.name ?? 'Student',
                        style: const TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      )),
                  const SizedBox(height: 6),
                  const Text(
                    "Discover verified student hostels, check vacancies & book rooms.",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),

            // Right Architectural Building Illustration
            Positioned(
              right: 28,
              top: 0,
              bottom: 0,
              child: Center(
                child: _buildBuildingIllustration(isDark),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBuildingIllustration(bool isDark) {
    return Container(
      width: 250,
      height: 120,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Container(
              height: 75,
              decoration: BoxDecoration(
                color: const Color(0xFF1E3545),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.teal.withValues(alpha: 0.3)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _windowRow(2),
                  _windowRow(2),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Container(
              height: 95,
              decoration: BoxDecoration(
                color: const Color(0xFF244358),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.teal.withValues(alpha: 0.4)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _windowRow(3),
                  _windowRow(3),
                  _windowRow(3),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.teal.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.nightlight_round, size: 14, color: Colors.tealAccent),
              ),
              const SizedBox(height: 8),
              const Icon(Icons.park, size: 18, color: Colors.greenAccent),
            ],
          ),
        ],
      ),
    );
  }

  Widget _windowRow(int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(
        count,
        (_) => Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: const Color(0xFFFFF7C2),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}


// ── City filter chip ───────────────────────────────────────────────────────
class _CityChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isWide;

  const _CityChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.isWide = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isWide) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      final chipBg = isSelected
          ? const Color(0xFF00A896)
          : (isDark ? const Color(0xFF14202E) : Colors.white);
      final chipBorder = isSelected
          ? const Color(0xFF2DD4BF)
          : (isDark ? const Color(0xFF223242) : const Color(0xFFE2E8F0));
      final textColor = isSelected
          ? Colors.white
          : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B));

      return GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
          decoration: BoxDecoration(
            color: chipBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: chipBorder),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF00A896).withValues(alpha: 0.35),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: textColor,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
        ),
      );
    }

    // Mobile layout (unchanged)
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white24,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.primary : Colors.white,
            fontWeight:
                isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

// ── Mobile City Filter Pill ────────────────────────────────────────────────
class _MobileCityPill extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _MobileCityPill({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? Colors.white
                : Colors.white.withValues(alpha: 0.28),
            width: 1.2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? const Color(0xFF00585E) : Colors.white,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              fontSize: 12.5,
            ),
          ),
        ),
      ),
    );
  }
}


