// lib/views/owner/owner_home_screen.dart
// ─────────────────────────────────────────────────────────────────────────────
// Hostel owner's shell screen with persistent bottom navigation bar.
// Tab 0: Listings   Tab 1: Bookings   Tab 2: Complaints
// Tab 3: Messages   Tab 4: Profile
// FR-3.x, FR-5.2, FR-7.2
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fyp/routes/AppRoutes.dart';
import 'package:fyp/utils/AppColors.dart';
import 'package:fyp/utils/AppConstants.dart';
import 'package:get/get.dart';
import 'package:fyp/controllers/AuthController.dart';
import 'package:fyp/controllers/HostelController.dart';
import 'package:fyp/controllers/BookingController.dart';
import 'package:fyp/controllers/NotificationController.dart';
import 'package:fyp/models/HostelModel.dart';
import 'package:fyp/views/owner/OwnerBookingsScreen.dart';
import 'package:fyp/views/owner/OwnerComplaintsScreen.dart';
import 'package:fyp/views/owner/OwnerStudentChatListScreen.dart';
import 'package:fyp/views/owner/OwnerSettingsScreen.dart';
import 'package:fyp/views/shared%20Widgets/FloatingBottomNavBar.dart';
import 'package:fyp/views/SharedScreens/ProfileScreen.dart';

class OwnerHomeScreen extends StatefulWidget {
  final int initialTab;
  const OwnerHomeScreen({super.key, this.initialTab = 0});

  @override
  State<OwnerHomeScreen> createState() => _OwnerHomeScreenState();
}

class _OwnerHomeScreenState extends State<OwnerHomeScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex =
        (Get.arguments is int) ? (Get.arguments as int) : widget.initialTab;
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> tabs = [
      _OwnerListingsTab(
        onNavigateTab: (index) {
          setState(() => _currentIndex = index);
        },
      ),
      const OwnerBookingsScreen(isTab: true),
      const OwnerComplaintsScreen(isTab: true),
      const OwnerStudentChatListScreen(isTab: true),
      kIsWeb
          ? const ProfileScreen()
          : OwnerSettingsScreen(
              onBackToHome: () => setState(() => _currentIndex = 0),
            ),
    ];

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
            activeIcon: Icons.home_rounded,
            label: 'Listings',
          ),
          FloatingNavItem(
            icon: Icons.book_outlined,
            activeIcon: Icons.book_rounded,
            label: 'Bookings',
          ),
          FloatingNavItem(
            icon: Icons.report_outlined,
            activeIcon: Icons.report_rounded,
            label: 'Complaints',
          ),
          FloatingNavItem(
            icon: Icons.chat_outlined,
            activeIcon: Icons.chat_rounded,
            label: 'Messages',
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

// ── Tab 0: Listings Tab ────────────────────────────────────────────────────
class _OwnerListingsTab extends StatelessWidget {
  final ValueChanged<int>? onNavigateTab;
  const _OwnerListingsTab({this.onNavigateTab});

  @override
  Widget build(BuildContext context) {
    final AuthController authCtrl = Get.find<AuthController>();
    final HostelController hostelCtrl = Get.find<HostelController>();
    final BookingController bookingCtrl = Get.put(BookingController());
    final NotificationController? notifCtrl =
        Get.isRegistered<NotificationController>()
            ? Get.find<NotificationController>()
            : null;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF111827) : const Color(0xFFF7FAFB),

      // ── FAB to add new hostel ──────────────────────────────────────────────
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.toNamed(AppRoutes.addHostel),
        icon: const Icon(Icons.add_home_work_rounded, color: Colors.white, size: 20),
        label: const Text(
          'Add Hostel',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF007A85),
      ),

      body: RefreshIndicator(
        onRefresh: () async => hostelCtrl.loadOwnerHostels(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── 1. Top Curved Hero Header ─────────────────────────────────
              Container(
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
                    padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
                    child: Row(
                      children: [
                        // Profile Avatar
                        Obx(() {
                          final user = authCtrl.currentUser.value;
                          final img = user?.profileImage;
                          return Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              color: Colors.white,
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: (img != null && img.isNotEmpty)
                                ? CachedNetworkImage(
                                    imageUrl: img,
                                    fit: BoxFit.cover,
                                    placeholder: (_, __) => const Center(
                                      child: SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      ),
                                    ),
                                    errorWidget: (_, __, ___) => const Icon(
                                      Icons.person,
                                      color: Color(0xFF007A85),
                                      size: 34,
                                    ),
                                  )
                                : const Icon(
                                    Icons.person,
                                    color: Color(0xFF007A85),
                                    size: 34,
                                  ),
                          );
                        }),
                        const SizedBox(width: 14),

                        // Name & Owner Dashboard title
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Obx(() => Text(
                                    authCtrl.currentUser.value?.name ?? 'Owner',
                                    style: const TextStyle(
                                      fontSize: 13.5,
                                      color: Colors.white70,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  )),
                              const SizedBox(height: 2),
                              const Text(
                                'Owner Dashboard',
                                style: TextStyle(
                                  fontSize: 21,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: -0.3,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Notification bell with unread badge
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.notifications_none_rounded,
                                color: Colors.white,
                                size: 28,
                              ),
                              onPressed: () => Get.toNamed(AppRoutes.notifications),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Obx(() {
                                final unread = notifCtrl?.unreadCount.value ?? 0;
                                return unread > 0
                                    ? Container(
                                        width: 9,
                                        height: 9,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFFEF4444),
                                          shape: BoxShape.circle,
                                        ),
                                      )
                                    : const SizedBox.shrink();
                              }),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ── 2. Top Stats Row (3 Side-by-Side Cards) ────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Obx(() {
                  final totalListings = hostelCtrl.ownerHostels.length;
                  final pendingBookings = bookingCtrl.pendingBookingsCount;
                  final approvedListings = hostelCtrl.ownerHostels
                      .where((h) => h.status == AppConstants.statusApproved)
                      .length;

                  return Row(
                    children: [
                      // Card 1: Total Listings
                      Expanded(
                        child: _OwnerStatsCard(
                          title: 'Total Listings',
                          count: '$totalListings',
                          icon: Icons.home_rounded,
                          iconColor: const Color(0xFF007882),
                          bgColor: const Color(0xFFE8F6FC),
                          borderColor: const Color(0xFFD0ECFB),
                          watermarkIcon: Icons.home_rounded,
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Card 2: Pending Bookings (tappable to jump to Bookings tab)
                      Expanded(
                        child: GestureDetector(
                          onTap: () => onNavigateTab?.call(1),
                          child: _OwnerStatsCard(
                            title: 'Pending\nBookings',
                            count: '$pendingBookings',
                            icon: Icons.access_time_rounded,
                            iconColor: const Color(0xFFEA580C),
                            bgColor: const Color(0xFFFFF4EB),
                            borderColor: const Color(0xFFFFE3D1),
                            watermarkIcon: Icons.calendar_month_rounded,
                            countColor: const Color(0xFFEA580C),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Card 3: Approved
                      Expanded(
                        child: _OwnerStatsCard(
                          title: 'Approved',
                          count: '$approvedListings',
                          icon: Icons.check_circle_outline_rounded,
                          iconColor: const Color(0xFF059669),
                          bgColor: const Color(0xFFEAF8F1),
                          borderColor: const Color(0xFFD1F2E2),
                          watermarkIcon: Icons.check_circle_rounded,
                          countColor: const Color(0xFF059669),
                        ),
                      ),
                    ],
                  );
                }),
              ),

              const SizedBox(height: 22),

              // ── 3. Section Title ("My Listings" + "View All ->") ──────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 4.5,
                          height: 20,
                          decoration: BoxDecoration(
                            color: const Color(0xFF007A85),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'My Listings',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                            letterSpacing: -0.3,
                          ),
                        ),
                      ],
                    ),
                    InkWell(
                      onTap: () => hostelCtrl.loadOwnerHostels(),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2F4F5),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'View All',
                              style: TextStyle(
                                color: Color(0xFF007A85),
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(
                              Icons.arrow_forward_rounded,
                              size: 14,
                              color: Color(0xFF007A85),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // ── 4. Listings List ──────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Obx(() {
                  if (hostelCtrl.ownerHostels.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: const Color(0xFF007A85).withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.home_work_outlined,
                                size: 54,
                                color: Color(0xFF007A85),
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No listings yet.',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF334155),
                              ),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              onPressed: () => Get.toNamed(AppRoutes.addHostel),
                              icon: const Icon(Icons.add, color: Colors.white),
                              label: const Text(
                                'Add Your First Hostel',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF007A85),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: hostelCtrl.ownerHostels.length,
                    itemBuilder: (_, i) {
                      return _OwnerHostelCard(
                        hostel: hostelCtrl.ownerHostels[i],
                        hostelCtrl: hostelCtrl,
                      );
                    },
                  );
                }),
              ),

              // Spacer for FAB clearance
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Stats card matching mockup ─────────────────────────────────────────────
class _OwnerStatsCard extends StatelessWidget {
  final String title;
  final String count;
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final Color borderColor;
  final IconData watermarkIcon;
  final Color? countColor;

  const _OwnerStatsCard({
    required this.title,
    required this.count,
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.borderColor,
    required this.watermarkIcon,
    this.countColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 82,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Subtle Watermark in bottom-right corner
          Positioned(
            right: -8,
            bottom: -8,
            child: Icon(
              watermarkIcon,
              size: 52,
              color: iconColor.withOpacity(0.12),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(icon, color: iconColor, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      count,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: countColor ?? const Color(0xFF1E293B),
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF475569),
                    height: 1.15,
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Owner's hostel management card matching mockup ─────────────────────────
class _OwnerHostelCard extends StatelessWidget {
  final HostelModel hostel;
  final HostelController hostelCtrl;

  const _OwnerHostelCard({required this.hostel, required this.hostelCtrl});

  @override
  Widget build(BuildContext context) {
    final isPending = hostel.status == AppConstants.statusPending;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEEF2F6), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Get.toNamed(
          AppRoutes.ownerHostelDetail,
          arguments: hostel,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Hostel image thumbnail with status badge overlay ────────────
            Stack(
              children: [
                if (hostel.images.isNotEmpty)
                  CachedNetworkImage(
                    imageUrl: hostel.images[0],
                    height: 155,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      height: 155,
                      color: const Color(0xFFF1F5F9),
                      child: const Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      height: 155,
                      color: const Color(0xFFF1F5F9),
                      child: const Icon(
                        Icons.home_work_outlined,
                        size: 48,
                        color: Colors.grey,
                      ),
                    ),
                  )
                else
                  Container(
                    height: 155,
                    width: double.infinity,
                    color: const Color(0xFFF1F5F9),
                    child: const Icon(
                      Icons.home_work_outlined,
                      size: 48,
                      color: Colors.grey,
                    ),
                  ),

                // Top-right status pill badge (e.g. "Pending" with clock or "Approved")
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: isPending
                          ? const Color(0xD91F2937)
                          : const Color(0xD9064E3B),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isPending
                              ? Icons.access_time_rounded
                              : Icons.check_circle_rounded,
                          size: 13,
                          color: isPending
                              ? const Color(0xFFFBBF24)
                              : const Color(0xFF34D399),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isPending ? 'Pending' : 'Approved',
                          style: TextStyle(
                            color: isPending
                                ? const Color(0xFFFBBF24)
                                : const Color(0xFF34D399),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // ── Card Details ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Light teal rounded bed icon container
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2F4F5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.bed_rounded,
                          color: Color(0xFF007A85),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              hostel.name,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on,
                                  size: 15,
                                  color: Color(0xFF64748B),
                                ),
                                const SizedBox(width: 3),
                                Expanded(
                                  child: Text(
                                    '${hostel.city} · PKR ${hostel.rentPerMonth.toStringAsFixed(0)}/mo',
                                    style: const TextStyle(
                                      color: Color(0xFF64748B),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                const Icon(
                                  Icons.king_bed_outlined,
                                  size: 15,
                                  color: Color(0xFF64748B),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${hostel.availableRooms}/${hostel.totalRooms} rooms available',
                                  style: const TextStyle(
                                    color: Color(0xFF64748B),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Awaiting approval notice (if pending)
                  if (isPending) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3E8),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.error_rounded,
                            size: 16,
                            color: Color(0xFFEA580C),
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Awaiting admin approval',
                            style: TextStyle(
                              color: Color(0xFFC2410C),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),

                  // ── Actions Row: [ Edit ] | [ Delete ]  (Toggle Switch) ───
                  Row(
                    children: [
                      // Edit button
                      Expanded(
                        child: InkWell(
                          onTap: () => Get.toNamed(
                            AppRoutes.editHostel,
                            arguments: hostel,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            height: 38,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(0xFF007A85),
                                width: 1.5,
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.edit_outlined,
                                  size: 16,
                                  color: Color(0xFF007A85),
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'Edit',
                                  style: TextStyle(
                                    color: Color(0xFF007A85),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Vertical divider
                      Container(
                        height: 20,
                        width: 1,
                        color: const Color(0xFFE2E8F0),
                        margin: const EdgeInsets.symmetric(horizontal: 10),
                      ),

                      // Delete button
                      Expanded(
                        child: InkWell(
                          onTap: () => _confirmDelete(context),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            height: 38,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(0xFFFCA5A5),
                                width: 1,
                              ),
                              color: const Color(0xFFFFF5F5),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.delete_rounded,
                                  size: 16,
                                  color: Color(0xFFDC2626),
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'Delete',
                                  style: TextStyle(
                                    color: Color(0xFFDC2626),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      // Availability Capsule Toggle Switch
                      GestureDetector(
                        onTap: () => hostelCtrl.updateHostel(
                          hostel.id,
                          {'isAvailable': !hostel.isAvailable},
                        ),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 48,
                          height: 28,
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            color: hostel.isAvailable
                                ? const Color(0xFF22C55E)
                                : const Color(0xFFCBD5E1),
                          ),
                          child: AnimatedAlign(
                            duration: const Duration(milliseconds: 200),
                            alignment: hostel.isAvailable
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              width: 22,
                              height: 22,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 4,
                                    offset: Offset(0, 1),
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
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext ctx) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('Delete Listing'),
        content: Text('Delete "${hostel.name}"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Get.back();
              hostelCtrl.deleteHostel(hostel.id);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}


