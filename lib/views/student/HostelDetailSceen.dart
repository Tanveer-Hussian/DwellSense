// ─────────────────────────────────────────────────────────────────────────────
// FR-4.3: Full hostel details – images, facilities, map, reviews, rooms & vacancies.
// FR-5.1: Student can tap "Book Now" or "Book This Room" to submit a booking request.
// FR-4.4: OpenStreetMap integration to show hostel location.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:fyp/controllers/AuthController.dart';
import 'package:fyp/controllers/BookingController.dart';
import 'package:fyp/controllers/ComplaintController.dart';
import 'package:fyp/controllers/ReviewController.dart';
import 'package:fyp/models/ComplaintModel.dart';
import 'package:fyp/models/HostelModel.dart';
import 'package:fyp/models/ReviewModel.dart';
import 'package:fyp/models/RoomModel.dart';
import 'package:fyp/routes/AppRoutes.dart';
import 'package:fyp/services/BookingService.dart';
import 'package:fyp/services/hostelService.dart';
import 'package:fyp/utils/AppColors.dart';
import 'package:fyp/utils/AppConstants.dart';
import 'package:get/get.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:latlong2/latlong.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fyp/controllers/NotificationController.dart';
import 'package:fyp/utils/Responsive.dart';
import 'package:fyp/views/shared Widgets/WebSidebarShell.dart';

class HostelDetailScreen extends StatefulWidget {
  const HostelDetailScreen({super.key});

  @override
  State<HostelDetailScreen> createState() => _HostelDetailScreenState();
}

class _HostelDetailScreenState extends State<HostelDetailScreen> {
  late final HostelModel initialHostel = Get.arguments as HostelModel;
  final HostelService _hostelService = Get.find<HostelService>();
  final BookingService _bookingService = Get.find<BookingService>();

  final ReviewController reviewCtrl = Get.find<ReviewController>();
  final AuthController authCtrl = Get.find<AuthController>();
  final BookingController bookingCtrl = Get.find<BookingController>();
  final ComplaintController complaintCtrl = Get.find<ComplaintController>();

  // Track which image is currently shown in the carousel
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    // Auto-reconcile expired bookings so beds are freed up immediately
    _bookingService.reconcileExpiredBookingsForHostel(initialHostel.id);
    // Load reviews for this specific hostel
    reviewCtrl.loadHostelReviews(initialHostel.id);
    // Load complaints for this specific hostel
    complaintCtrl.loadHostelComplaints(initialHostel.id);
  }

  // ── Open Google Maps navigation to hostel ─────────────────────────────────
  Future<void> _openMapsNavigation(double lat, double lng) async {
    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng',
    );
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      Get.snackbar('Error', 'Could not open Google Maps.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = Responsive.isWide(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return StreamBuilder<HostelModel?>(
      stream: _hostelService.getHostelStream(initialHostel.id),
      initialData: initialHostel,
      builder: (context, snapshot) {
        final hostel = snapshot.data ?? initialHostel;

        if (isWide) {
          return _buildWebLayout(context, hostel, isDark);
        }

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              // ── Image Gallery in SliverAppBar ────────────────────────────────
              SliverAppBar(
                expandedHeight: 280,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: hostel.images.isNotEmpty
                      ? PageView.builder(
                          itemCount: hostel.images.length,
                          onPageChanged: (i) =>
                              setState(() => _currentImageIndex = i),
                          itemBuilder: (ctx, i) {
                            final imageWidget = CachedNetworkImage(
                              imageUrl: hostel.images[i],
                              fit: BoxFit.cover,
                              placeholder: (_, __) => Shimmer.fromColors(
                                baseColor: Colors.grey.shade300,
                                highlightColor: Colors.grey.shade100,
                                child: Container(color: Colors.white),
                              ),
                              errorWidget: (_, __, ___) => Container(
                                color: AppColors.divider,
                                child: const Icon(Icons.home_work_outlined,
                                    size: 64, color: AppColors.textSecondary),
                              ),
                            );

                            if (i == 0) {
                              return Hero(
                                tag: 'hostel-img-${hostel.id}',
                                child: Material(
                                  type: MaterialType.transparency,
                                  child: imageWidget,
                                ),
                              );
                            }
                            return imageWidget;
                          },
                        )
                      : Hero(
                          tag: 'hostel-img-${hostel.id}',
                          child: Material(
                            type: MaterialType.transparency,
                            child: Container(
                              color: AppColors.divider,
                              child: const Icon(Icons.home_work_outlined,
                                  size: 64, color: AppColors.textSecondary),
                            ),
                          ),
                        ),
                ),
                // Image counter dots
                bottom: hostel.images.length > 1
                    ? PreferredSize(
                        preferredSize: const Size.fromHeight(20),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              hostel.images.length,
                              (i) => AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: _currentImageIndex == i ? 16 : 6,
                                height: 6,
                                margin: const EdgeInsets.symmetric(horizontal: 2),
                                decoration: BoxDecoration(
                                  color: _currentImageIndex == i
                                      ? Colors.white
                                      : Colors.white54,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ),
                          ),
                        ),
                      )
                    : null,
              ),

              // ── Detail Content ────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 900),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Name & Rating Row ──────────────────────────────────────
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(hostel.name,
                                    style:
                                        Theme.of(context).textTheme.headlineMedium),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.location_on_outlined,
                                        size: 16, color: AppColors.textSecondary),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        '${hostel.city} · ${hostel.address}',
                                        style: Theme.of(context).textTheme.bodyMedium,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                if (hostel.registrationNumber != null && hostel.registrationNumber!.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.verified, size: 14, color: AppColors.primary),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Reg #: ${hostel.registrationNumber}',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          // Rating column
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.star,
                                    color: Colors.amber,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    hostel.averageRating.toStringAsFixed(1),
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${hostel.totalReviews} reviews',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // ── Quick Info Chips ──────────────────────────────────────
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (hostel.smartScore != null)
                            _InfoChip(
                              icon: Icons.auto_graph_outlined,
                              label: 'Smart Score: ${hostel.smartScore!.toStringAsFixed(0)}/100',
                              color: Colors.amber.shade700,
                            ),
                          _InfoChip(
                            icon: Icons.hotel,
                            label: hostel.roomType,
                          ),
                          _InfoChip(
                            icon: Icons.people_outline,
                            label: hostel.genderPreference,
                          ),
                          _InfoChip(
                            icon: Icons.event_seat_outlined,
                            label: '${hostel.totalVacancies} vacancies left',
                            color: hostel.totalVacancies > 0
                                ? AppColors.success
                                : AppColors.error,
                          ),
                          _InfoChip(
                            icon: Icons.meeting_room_outlined,
                            label: '${hostel.totalRoomsWithVacancy} of ${hostel.rooms.length} rooms free',
                            color: hostel.totalRoomsWithVacancy > 0
                                ? AppColors.primary
                                : AppColors.error,
                          ),
                          _InfoChip(
                            icon: Icons.bookmark_added_outlined,
                            label: '${hostel.totalBookings} Bookings',
                            color: AppColors.primary,
                          ),
                          _InfoChip(
                            icon: Icons.check_circle_outline,
                            label: '${(hostel.complaintResolutionRate * 100).toStringAsFixed(0)}% Resolution Rate',
                            color: AppColors.primaryDark,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // ── Rooms & Vacancies Section (Prominent & Real-time) ───────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _SectionTitle(title: 'Rooms & Vacancies'),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: hostel.totalVacancies > 0
                                  ? AppColors.success.withValues(alpha: 0.1)
                                  : AppColors.error.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: hostel.totalVacancies > 0
                                    ? AppColors.success.withValues(alpha: 0.3)
                                    : AppColors.error.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  hostel.totalVacancies > 0
                                      ? Icons.check_circle_outline
                                      : Icons.remove_circle_outline,
                                  size: 14,
                                  color: hostel.totalVacancies > 0
                                      ? AppColors.success
                                      : AppColors.error,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  hostel.totalVacancies > 0
                                      ? '${hostel.totalVacancies} Total Vacancies'
                                      : 'Fully Booked',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: hostel.totalVacancies > 0
                                        ? AppColors.success
                                        : AppColors.error,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Detailed room-by-room vacancy breakdown. View which rooms have vacancies and which rooms are filled.',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                      const SizedBox(height: 14),

                      // Room Summary Metrics Bar
                      _RoomsSummaryBar(hostel: hostel),
                      const SizedBox(height: 16),

                      // Interactive Filterable Rooms List
                      _RoomsListSection(
                        hostel: hostel,
                        onBookRoom: (room) {
                          Get.toNamed(
                            AppRoutes.bookingRequest,
                            arguments: {
                              'hostel': hostel,
                              'preselectedRoom': room,
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 24),

                      // ── Description ───────────────────────────────────────────
                      _SectionTitle(title: 'About this Hostel'),
                      const SizedBox(height: 8),
                      Text(
                        hostel.description,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 20),

                      // ── Facilities ────────────────────────────────────────────
                      _SectionTitle(title: 'Facilities'),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: hostel.facilities
                            .map((f) => _FacilityChip(label: f))
                            .toList(),
                      ),
                      const SizedBox(height: 24),

                      // ── Map Location Card ───────────────────────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _SectionTitle(title: 'Google Maps Location'),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${hostel.latitude.toStringAsFixed(4)}, ${hostel.longitude.toStringAsFixed(4)}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // flutter_map — OpenStreetMap (no API key needed)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          height: 200,
                          width: double.infinity,
                          child: FlutterMap(
                            options: MapOptions(
                              initialCenter: LatLng(hostel.latitude, hostel.longitude),
                              initialZoom: 15,
                              interactionOptions: const InteractionOptions(
                                flags: InteractiveFlag.all & ~InteractiveFlag.doubleTapZoom,
                              ),
                            ),
                            children: [
                              TileLayer(
                                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName: 'com.example.fyp',
                              ),
                              MarkerLayer(
                                markers: [
                                  Marker(
                                    point: LatLng(hostel.latitude, hostel.longitude),
                                    width: 40,
                                    height: 40,
                                    child: const Icon(
                                      Icons.location_pin,
                                      color: Colors.red,
                                      size: 40,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: () => _openMapsNavigation(hostel.latitude, hostel.longitude),
                        icon: const Icon(Icons.directions, size: 18),
                        label: const Text('Open & Navigate in Google Maps'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 44),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ── Complaints Section (Conditional Visibility) ─────────────
                      Obx(() {
                        bool canViewComplaints = false;
                        if (authCtrl.isAdmin) {
                          canViewComplaints = true;
                        } else if (authCtrl.isOwner && authCtrl.currentUser.value?.uid == hostel.ownerId) {
                          canViewComplaints = true;
                        } else if (authCtrl.isStudent) {
                          // Only students with a CONFIRMED booking can see & file complaints
                          canViewComplaints = bookingCtrl.myBookings.any(
                            (b) => b.hostelId == hostel.id &&
                                   b.status == AppConstants.bookingConfirmed,
                          );
                        }

                        if (!canViewComplaints) return const SizedBox.shrink();

                        final complaints = complaintCtrl.hostelComplaints;
                        
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Divider(height: 32),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _SectionTitle(title: 'Complaints'),
                                if (authCtrl.isStudent && canViewComplaints)
                                  TextButton.icon(
                                    onPressed: () => Get.toNamed(
                                      AppRoutes.submitComplaint,
                                      arguments: hostel,
                                    ),
                                    icon: const Icon(Icons.warning_amber_rounded, size: 16),
                                    label: const Text('Report Issue'),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (complaints.isEmpty)
                              const Text(
                                'No complaints found for this hostel.',
                                style: TextStyle(color: AppColors.textSecondary),
                              )
                            else
                              Column(
                                children: complaints
                                    .map((c) => _ComplaintTile(complaint: c))
                                    .toList(),
                              ),
                            const SizedBox(height: 24),
                          ],
                        );
                      }),

                      // ── Reviews Section ───────────────────────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _SectionTitle(title: 'Reviews'),
                          // Write review button (only for students who have booked this hostel)
                          if (authCtrl.isStudent && authCtrl.currentUser.value != null)
                            FutureBuilder<bool>(
                              future: _bookingService.hasEverBookedHostel(
                                  authCtrl.currentUser.value!.uid, hostel.id),
                              builder: (context, snapshot) {
                                if (snapshot.hasData && snapshot.data == true) {
                                  return TextButton.icon(
                                    onPressed: () => Get.toNamed(
                                      AppRoutes.writeReview,
                                      arguments: hostel,
                                    ),
                                    icon: const Icon(Icons.edit_outlined, size: 16),
                                    label: const Text('Write Review'),
                                  );
                                }
                                return const SizedBox.shrink(); // Hide if not booked
                              },
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Reviews list
                      Obx(() {
                        final reviews = reviewCtrl.hostelReviews;
                        if (reviews.isEmpty) {
                          return const Text(
                            'No reviews yet. Be the first!',
                            style: TextStyle(color: AppColors.textSecondary),
                          );
                        }
                        return Column(
                          children: reviews
                              .take(5) // show max 5 reviews on detail page
                              .map((r) => _ReviewTile(review: r))
                              .toList(),
                        );
                      }),

                      // Bottom padding for FAB clearance
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),

          // ── Book Now Button ────────────────────────────────────────────────────
          bottomNavigationBar: Align(
            alignment: Alignment.bottomCenter,
            heightFactor: 1.0,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, -4),
                ),
              ],
            ),
            child: Row(
              children: [
                // Rent display
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Monthly Rent',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    Text(
                      'PKR ${hostel.rentPerMonth.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 20),
                // Book now button
                Expanded(
                  child: ElevatedButton(
                    onPressed: hostel.isAvailable && hostel.totalVacancies > 0
                        ? () => Get.toNamed(AppRoutes.bookingRequest, arguments: hostel)
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: hostel.isAvailable && hostel.totalVacancies > 0
                          ? AppColors.primary
                          : Colors.grey,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      hostel.isAvailable && hostel.totalVacancies > 0
                          ? 'Book Now (${hostel.totalVacancies} Vacancies)'
                          : 'Fully Booked',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  },
);
  }

  // ── Desktop / Web 2-Column Layout ──────────────────────────────────────────
  Widget _buildWebLayout(BuildContext context, HostelModel hostel, bool isDark) {
    final NotificationController notifCtrl = Get.find<NotificationController>();
    final surfaceColor = isDark ? const Color(0xFF1E242B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2C3238) : const Color(0xFFE2E8F0);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subTextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return WebSidebarShell(
      currentIndex: 0,
      onTap: (i) => Get.offNamed(AppRoutes.studentHome),
      items: const [
        SidebarNavItem(icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Home'),
        SidebarNavItem(icon: Icons.book_outlined, activeIcon: Icons.book, label: 'My Bookings'),
        SidebarNavItem(icon: Icons.chat_bubble_outline, activeIcon: Icons.chat_bubble, label: 'Messages'),
        SidebarNavItem(icon: Icons.report_outlined, activeIcon: Icons.report, label: 'Complaints'),
        SidebarNavItem(icon: Icons.person_outline, activeIcon: Icons.person, label: 'Profile'),
      ],
      userName: authCtrl.currentUser.value?.name ?? 'Student',
      roleLabel: 'Student Portal',
      notificationCount: notifCtrl.unreadCount.value,
      body: Container(
        color: isDark ? AppColors.darkBackground : const Color(0xFFF3F6F9),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1240),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Breadcrumbs ──
                  Row(
                    children: [
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () => Get.back(),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: surfaceColor,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: borderColor),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.arrow_back_rounded, size: 14, color: subTextColor),
                                const SizedBox(width: 6),
                                Text('Back',
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: subTextColor)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text('/', style: TextStyle(color: subTextColor, fontSize: 13)),
                      const SizedBox(width: 10),
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () => Get.back(),
                          child: Text('Explore Hostels',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: subTextColor)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text('/', style: TextStyle(color: subTextColor, fontSize: 13)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          hostel.name,
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: textColor),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // ── Title & Highlights Header ──
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              hostel.name,
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: textColor,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.star_rounded, size: 18, color: Colors.amber),
                                const SizedBox(width: 4),
                                Text(
                                  hostel.averageRating.toStringAsFixed(1),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                                ),
                                Text(
                                  ' (${hostel.totalReviews} reviews)',
                                  style: TextStyle(fontSize: 13, color: subTextColor),
                                ),
                                const SizedBox(width: 14),
                                Icon(Icons.location_on_outlined, size: 16, color: subTextColor),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    '${hostel.city} · ${hostel.address}',
                                    style: TextStyle(fontSize: 13.5, color: subTextColor),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (hostel.registrationNumber != null && hostel.registrationNumber!.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.verified, size: 15, color: AppColors.primary),
                              const SizedBox(width: 5),
                              Text(
                                'Reg: ${hostel.registrationNumber}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Hero Gallery Grid (Airbnb Style) ──
                  _buildWebGallery(hostel, borderColor, surfaceColor, isDark),
                  const SizedBox(height: 28),

                  // ── 2-Column Split: Content (Left) & Sticky Booking Card (Right) ──
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── LEFT COLUMN (Content) ───────────────────────────
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Quick Highlights Strip
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: surfaceColor,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: borderColor),
                              ),
                              child: Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: [
                                  if (hostel.smartScore != null)
                                    _InfoChip(
                                      icon: Icons.auto_graph_outlined,
                                      label: 'Smart Score: ${hostel.smartScore!.toStringAsFixed(0)}/100',
                                      color: Colors.amber.shade700,
                                    ),
                                  _InfoChip(
                                    icon: Icons.hotel,
                                    label: hostel.roomType,
                                  ),
                                  _InfoChip(
                                    icon: Icons.people_outline,
                                    label: hostel.genderPreference,
                                  ),
                                  _InfoChip(
                                    icon: Icons.event_seat_outlined,
                                    label: '${hostel.totalVacancies} vacancies left',
                                    color: hostel.totalVacancies > 0
                                        ? AppColors.success
                                        : AppColors.error,
                                  ),
                                  _InfoChip(
                                    icon: Icons.meeting_room_outlined,
                                    label: '${hostel.totalRoomsWithVacancy} of ${hostel.rooms.length} rooms free',
                                    color: hostel.totalRoomsWithVacancy > 0
                                        ? AppColors.primary
                                        : AppColors.error,
                                  ),
                                  _InfoChip(
                                    icon: Icons.bookmark_added_outlined,
                                    label: '${hostel.totalBookings} Bookings',
                                    color: AppColors.primary,
                                  ),
                                  _InfoChip(
                                    icon: Icons.check_circle_outline,
                                    label: '${(hostel.complaintResolutionRate * 100).toStringAsFixed(0)}% Resolution Rate',
                                    color: AppColors.primaryDark,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),

                            // ── Rooms & Vacancies ──
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: surfaceColor,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: borderColor),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      _SectionTitle(title: 'Rooms & Vacancies'),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: hostel.totalVacancies > 0
                                              ? AppColors.success.withValues(alpha: 0.1)
                                              : AppColors.error.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(
                                            color: hostel.totalVacancies > 0
                                                ? AppColors.success.withValues(alpha: 0.3)
                                                : AppColors.error.withValues(alpha: 0.3),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              hostel.totalVacancies > 0
                                                  ? Icons.check_circle_outline
                                                  : Icons.remove_circle_outline,
                                              size: 14,
                                              color: hostel.totalVacancies > 0
                                                  ? AppColors.success
                                                  : AppColors.error,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              hostel.totalVacancies > 0
                                                  ? '${hostel.totalVacancies} Total Vacancies'
                                                  : 'Fully Booked',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: hostel.totalVacancies > 0
                                                    ? AppColors.success
                                                    : AppColors.error,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Detailed room-by-room vacancy breakdown. Select a room directly to book your bed.',
                                    style: TextStyle(color: subTextColor, fontSize: 13),
                                  ),
                                  const SizedBox(height: 16),
                                  _RoomsSummaryBar(hostel: hostel),
                                  const SizedBox(height: 18),
                                  _RoomsListSection(
                                    hostel: hostel,
                                    onBookRoom: (room) {
                                      Get.toNamed(
                                        AppRoutes.bookingRequest,
                                        arguments: {
                                          'hostel': hostel,
                                          'preselectedRoom': room,
                                        },
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),

                            // ── Description ──
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: surfaceColor,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: borderColor),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _SectionTitle(title: 'About this Hostel'),
                                  const SizedBox(height: 12),
                                  Text(
                                    hostel.description,
                                    style: TextStyle(
                                      fontSize: 14.5,
                                      color: textColor,
                                      height: 1.6,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),

                            // ── Facilities & Amenities ──
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: surfaceColor,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: borderColor),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _SectionTitle(title: 'Facilities & Amenities'),
                                  const SizedBox(height: 14),
                                  Wrap(
                                    spacing: 10,
                                    runSpacing: 10,
                                    children: hostel.facilities
                                        .map((f) => _FacilityChip(label: f))
                                        .toList(),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),

                            // ── Google Maps Location ──
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: surfaceColor,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: borderColor),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      _SectionTitle(title: 'Location on Map'),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          '${hostel.latitude.toStringAsFixed(4)}, ${hostel.longitude.toStringAsFixed(4)}',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: SizedBox(
                                      height: 240,
                                      width: double.infinity,
                                      child: FlutterMap(
                                        options: MapOptions(
                                          initialCenter: LatLng(hostel.latitude, hostel.longitude),
                                          initialZoom: 15,
                                          interactionOptions: const InteractionOptions(
                                            flags: InteractiveFlag.all & ~InteractiveFlag.doubleTapZoom,
                                          ),
                                        ),
                                        children: [
                                          TileLayer(
                                            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                            userAgentPackageName: 'com.example.fyp',
                                          ),
                                          MarkerLayer(
                                            markers: [
                                              Marker(
                                                point: LatLng(hostel.latitude, hostel.longitude),
                                                width: 40,
                                                height: 40,
                                                child: const Icon(
                                                  Icons.location_pin,
                                                  color: Colors.red,
                                                  size: 40,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  OutlinedButton.icon(
                                    onPressed: () => _openMapsNavigation(hostel.latitude, hostel.longitude),
                                    icon: const Icon(Icons.directions, size: 18),
                                    label: const Text('Open & Navigate in Google Maps'),
                                    style: OutlinedButton.styleFrom(
                                      minimumSize: const Size(double.infinity, 44),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),

                            // ── Reviews Section ──
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: surfaceColor,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: borderColor),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      _SectionTitle(title: 'Student Reviews'),
                                      if (authCtrl.isStudent && authCtrl.currentUser.value != null)
                                        FutureBuilder<bool>(
                                          future: _bookingService.hasEverBookedHostel(
                                              authCtrl.currentUser.value!.uid, hostel.id),
                                          builder: (context, snapshot) {
                                            if (snapshot.hasData && snapshot.data == true) {
                                              return TextButton.icon(
                                                onPressed: () => Get.toNamed(
                                                  AppRoutes.writeReview,
                                                  arguments: hostel,
                                                ),
                                                icon: const Icon(Icons.edit_outlined, size: 16),
                                                label: const Text('Write Review'),
                                              );
                                            }
                                            return const SizedBox.shrink();
                                          },
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  Obx(() {
                                    final reviews = reviewCtrl.hostelReviews;
                                    if (reviews.isEmpty) {
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 20),
                                        child: Text(
                                          'No reviews yet. Be the first to share your experience!',
                                          style: TextStyle(color: subTextColor, fontSize: 13.5),
                                        ),
                                      );
                                    }
                                    return Column(
                                      children: reviews
                                          .take(5)
                                          .map((r) => _ReviewTile(review: r))
                                          .toList(),
                                    );
                                  }),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 28),

                      // ── RIGHT COLUMN (Sticky Booking Widget) ─────────────
                      SizedBox(
                        width: 380,
                        child: _WebBookingCard(
                          hostel: hostel,
                          surfaceColor: surfaceColor,
                          borderColor: borderColor,
                          textColor: textColor,
                          subTextColor: subTextColor,
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Desktop Airbnb-style Gallery ──────────────────────────────────────────
  Widget _buildWebGallery(HostelModel hostel, Color borderColor, Color surfaceColor, bool isDark) {
    if (hostel.images.isEmpty) {
      return Container(
        height: 280,
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.home_work_outlined, size: 48, color: AppColors.textSecondary),
              SizedBox(height: 8),
              Text('No hostel images available', style: TextStyle(color: AppColors.textSecondary)),
            ],
          ),
        ),
      );
    }

    if (hostel.images.length == 1) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: 380,
          width: double.infinity,
          child: CachedNetworkImage(
            imageUrl: hostel.images[0],
            fit: BoxFit.cover,
            placeholder: (_, __) => Container(color: surfaceColor),
            errorWidget: (_, __, ___) => Container(color: AppColors.divider),
          ),
        ),
      );
    }

    if (hostel.images.length == 2) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: 360,
          child: Row(
            children: [
              Expanded(
                child: CachedNetworkImage(
                  imageUrl: hostel.images[0],
                  fit: BoxFit.cover,
                  height: double.infinity,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: CachedNetworkImage(
                  imageUrl: hostel.images[1],
                  fit: BoxFit.cover,
                  height: double.infinity,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 3 or more images: 1 large on left, 2 stacked on right
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 380,
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: CachedNetworkImage(
                imageUrl: hostel.images[0],
                fit: BoxFit.cover,
                height: double.infinity,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  Expanded(
                    child: SizedBox(
                      width: double.infinity,
                      child: CachedNetworkImage(
                        imageUrl: hostel.images[1],
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: SizedBox(
                      width: double.infinity,
                      child: CachedNetworkImage(
                        imageUrl: hostel.images[2],
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Desktop Sticky Booking Card ──────────────────────────────────────────────
class _WebBookingCard extends StatelessWidget {
  final HostelModel hostel;
  final Color surfaceColor;
  final Color borderColor;
  final Color textColor;
  final Color subTextColor;
  final bool isDark;

  const _WebBookingCard({
    required this.hostel,
    required this.surfaceColor,
    required this.borderColor,
    required this.textColor,
    required this.subTextColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final bool canBook = hostel.isAvailable && hostel.totalVacancies > 0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.06),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Rent Headline ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                'PKR ${hostel.rentPerMonth.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '/ month',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: subTextColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Rating Sub-row
          Row(
            children: [
              const Icon(Icons.star_rounded, size: 16, color: Colors.amber),
              const SizedBox(width: 3),
              Text(
                hostel.averageRating.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              Text(
                ' · ${hostel.totalReviews} reviews',
                style: TextStyle(fontSize: 12.5, color: subTextColor),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: borderColor.withValues(alpha: 0.7), height: 1),
          const SizedBox(height: 16),

          // Vacancy Alert Box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: canBook
                  ? const Color(0xFF2D9D5A).withValues(alpha: 0.08)
                  : const Color(0xFFE63946).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: canBook
                    ? const Color(0xFF2D9D5A).withValues(alpha: 0.25)
                    : const Color(0xFFE63946).withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  canBook ? Icons.check_circle_rounded : Icons.cancel_rounded,
                  size: 18,
                  color: canBook ? const Color(0xFF2D9D5A) : const Color(0xFFE63946),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        canBook
                            ? '${hostel.totalVacancies} Vacancies Available'
                            : 'Fully Booked',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: canBook ? const Color(0xFF2D9D5A) : const Color(0xFFE63946),
                        ),
                      ),
                      Text(
                        canBook
                            ? '${hostel.totalRoomsWithVacancy} of ${hostel.rooms.length} rooms have vacancy'
                            : 'Check back later for openings',
                        style: TextStyle(
                          fontSize: 11,
                          color: canBook
                              ? const Color(0xFF2D9D5A).withValues(alpha: 0.85)
                              : const Color(0xFFE63946).withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Primary Book Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: canBook
                  ? () => Get.toNamed(AppRoutes.bookingRequest, arguments: hostel)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              child: Text(
                canBook
                    ? 'Book Now (${hostel.totalVacancies} Vacancies)'
                    : 'Fully Booked',
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Divider(color: borderColor.withValues(alpha: 0.7), height: 1),
          const SizedBox(height: 16),

          // Reassurance bullet points
          _buildReassuranceRow(Icons.verified_rounded, 'Verified Hostel Listing', textColor, subTextColor),
          const SizedBox(height: 8),
          _buildReassuranceRow(Icons.security_rounded, 'Secure Booking via DwellSense', textColor, subTextColor),
          const SizedBox(height: 8),
          _buildReassuranceRow(Icons.flash_on_rounded, 'Instant Booking Confirmation', textColor, subTextColor),
          const SizedBox(height: 8),
          _buildReassuranceRow(Icons.credit_card_rounded, 'In-App Payment with Safepay', textColor, subTextColor),
        ],
      ),
    );
  }

  Widget _buildReassuranceRow(IconData icon, String text, Color textColor, Color subTextColor) {
    return Row(
      children: [
        Icon(icon, size: 15, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: subTextColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ── Rooms Summary Bar ────────────────────────────────────────────────────────
class _RoomsSummaryBar extends StatelessWidget {
  final HostelModel hostel;
  const _RoomsSummaryBar({required this.hostel});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildMetric(
            label: 'Total Rooms',
            value: '${hostel.rooms.length}',
            color: AppColors.textPrimary,
            icon: Icons.meeting_room_outlined,
          ),
          _divider(),
          _buildMetric(
            label: 'Vacant Rooms',
            value: '${hostel.totalRoomsWithVacancy}',
            color: AppColors.success,
            icon: Icons.check_circle_outline,
          ),
          _divider(),
          _buildMetric(
            label: 'Filled Rooms',
            value: '${hostel.totalFilledRooms}',
            color: hostel.totalFilledRooms > 0 ? AppColors.error : AppColors.textSecondary,
            icon: Icons.do_not_disturb_on_outlined,
          ),
          _divider(),
          _buildMetric(
            label: 'Total Vacancies',
            value: '${hostel.totalVacancies}',
            color: AppColors.primary,
            icon: Icons.event_seat_outlined,
          ),
        ],
      ),
    );
  }

  Widget _divider() => Container(width: 1, height: 32, color: AppColors.divider);

  Widget _buildMetric({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

// ── Rooms List with Filter Tabs ──────────────────────────────────────────────
class _RoomsListSection extends StatefulWidget {
  final HostelModel hostel;
  final ValueChanged<RoomModel> onBookRoom;

  const _RoomsListSection({
    required this.hostel,
    required this.onBookRoom,
  });

  @override
  State<_RoomsListSection> createState() => _RoomsListSectionState();
}

class _RoomsListSectionState extends State<_RoomsListSection> {
  int _selectedFilterIndex = 0; // 0: All, 1: Has Vacancy, 2: Filled

  @override
  Widget build(BuildContext context) {
    final allRooms = widget.hostel.rooms;
    final vacancyRooms = widget.hostel.roomsWithVacancy;
    final filledRooms = widget.hostel.filledRooms;

    List<RoomModel> displayedRooms;
    if (_selectedFilterIndex == 1) {
      displayedRooms = vacancyRooms;
    } else if (_selectedFilterIndex == 2) {
      displayedRooms = filledRooms;
    } else {
      displayedRooms = allRooms;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Filter tabs
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterChip('All Rooms (${allRooms.length})', 0),
              const SizedBox(width: 8),
              _buildFilterChip('Has Vacancy (${vacancyRooms.length})', 1),
              const SizedBox(width: 8),
              _buildFilterChip('Filled (${filledRooms.length})', 2),
            ],
          ),
        ),
        const SizedBox(height: 12),

        if (displayedRooms.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.divider),
            ),
            child: Text(
              _selectedFilterIndex == 1
                  ? 'No rooms currently have vacancy.'
                  : _selectedFilterIndex == 2
                      ? 'No rooms are filled yet.'
                      : 'No rooms configured.',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          )
        else
          Column(
            children: displayedRooms.map((room) {
              return _RoomCard(
                room: room,
                onBook: () => widget.onBookRoom(room),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildFilterChip(String label, int index) {
    final isSelected = _selectedFilterIndex == index;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.background,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? Colors.white : AppColors.textPrimary,
      ),
      side: BorderSide(
        color: isSelected ? AppColors.primary : AppColors.divider,
      ),
      onSelected: (val) {
        if (val) setState(() => _selectedFilterIndex = index);
      },
    );
  }
}

// ── Room Card with Vacancy Slots Visualization ─────────────────────────────
class _RoomCard extends StatelessWidget {
  final RoomModel room;
  final VoidCallback onBook;

  const _RoomCard({
    required this.room,
    required this.onBook,
  });

  @override
  Widget build(BuildContext context) {
    final hasVacancy = room.hasVacancy;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasVacancy
              ? AppColors.primary.withValues(alpha: 0.25)
              : AppColors.divider,
          width: hasVacancy ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Room number, Type, Status Pill
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left side: icon + room info (takes all remaining space)
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: (hasVacancy ? AppColors.primary : Colors.grey)
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.meeting_room_outlined,
                        color: hasVacancy ? AppColors.primary : AppColors.textSecondary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            room.roomNumber,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${room.type} Room (${room.capacity} Bed)',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Status Pill (right side, always visible)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: hasVacancy
                      ? AppColors.success.withValues(alpha: 0.12)
                      : AppColors.error.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: hasVacancy
                        ? AppColors.success.withValues(alpha: 0.4)
                        : AppColors.error.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      hasVacancy ? Icons.check_circle : Icons.do_not_disturb_on,
                      size: 13,
                      color: hasVacancy ? AppColors.success : AppColors.error,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      hasVacancy
                          ? '${room.vacancies} ${room.vacancies == 1 ? 'Vacancy' : 'Vacancies'} Left'
                          : 'Fully Filled',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: hasVacancy ? AppColors.success : AppColors.error,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Visual Bed / Vacancy Slots
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(room.capacity, (index) {
              final isOccupied = room.isBedOccupied(index);
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isOccupied
                      ? AppColors.primary.withValues(alpha: 0.08)
                      : AppColors.success.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isOccupied
                        ? AppColors.primary.withValues(alpha: 0.3)
                        : AppColors.success.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isOccupied ? Icons.bed : Icons.single_bed_outlined,
                      size: 15,
                      color: isOccupied ? AppColors.primary : AppColors.success,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      isOccupied ? 'Bed ${index + 1}: Occupied' : 'Bed ${index + 1}: Vacant',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isOccupied ? AppColors.primaryDark : AppColors.success,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
          const SizedBox(height: 10),

          // Progress indicator & ratio
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: room.capacity > 0 ? (room.occupied / room.capacity) : 0,
                    backgroundColor: AppColors.divider,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      room.isFilled ? AppColors.error : AppColors.primary,
                    ),
                    minHeight: 6,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${room.occupied}/${room.capacity} Occupied',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),

          // Book room action button
          if (hasVacancy) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onBook,
                icon: const Icon(Icons.bookmark_add_outlined, size: 16),
                label: Text('Select ${room.roomNumber} (${room.vacancies} Left)'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Small info chip ────────────────────────────────────────────────────────
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    this.color = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ── Facility badge chip ────────────────────────────────────────────────────
class _FacilityChip extends StatelessWidget {
  final String label;
  const _FacilityChip({required this.label});

  // Map facility names to icons
  IconData _iconFor(String f) {
    switch (f) {
      case 'WiFi': return Icons.wifi;
      case 'Mess / Cafeteria': return Icons.restaurant_outlined;
      case 'Security Guard': return Icons.security;
      case 'CCTV': return Icons.videocam_outlined;
      case 'Generator': return Icons.electric_bolt_outlined;
      case 'Laundry': return Icons.local_laundry_service_outlined;
      case 'Parking': return Icons.local_parking;
      case 'Gym': return Icons.fitness_center_outlined;
      case 'Air Conditioning': return Icons.ac_unit;
      default: return Icons.check_circle_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primaryLight),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_iconFor(label), size: 16, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}

// ── Section title widget ───────────────────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(title, style: Theme.of(context).textTheme.titleLarge);
  }
}

// ── Single review tile ─────────────────────────────────────────────────────
class _ReviewTile extends StatelessWidget {
  final ReviewModel review;
  const _ReviewTile({required this.review});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Reviewer info + rating
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFF00585E).withValues(alpha: 0.12),
                backgroundImage: review.studentImage != null && review.studentImage!.isNotEmpty
                    ? NetworkImage(review.studentImage!)
                    : null,
                child: review.studentImage == null || review.studentImage!.isEmpty
                    ? Text(
                        review.studentName.isNotEmpty
                            ? review.studentName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: Color(0xFF00585E),
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.studentName.isNotEmpty ? review.studentName : 'Student',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13.5,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        RatingBarIndicator(
                          rating: review.rating,
                          itemSize: 13,
                          itemBuilder: (_, __) =>
                              const Icon(Icons.star_rounded, color: Color(0xFFF59E0B)),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          review.rating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFB45309),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Text(
                _timeAgo(review.createdAt),
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 11.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              review.comment,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF334155),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Simple "time ago" helper
  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 30) return '${(diff.inDays / 30).round()}mo ago';
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    return 'Just now';
  }
}

// ── Single complaint tile ──────────────────────────────────────────────────
class _ComplaintTile extends StatelessWidget {
  final ComplaintModel complaint;
  const _ComplaintTile({required this.complaint});

  @override
  Widget build(BuildContext context) {
    final isResolved = complaint.status == 'resolved';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  complaint.title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isResolved
                      ? AppColors.success.withValues(alpha: 0.1)
                      : AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  complaint.status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isResolved ? AppColors.success : AppColors.error,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'By ${complaint.studentName}',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Text(complaint.description),
          if (complaint.ownerResponse != null && complaint.ownerResponse!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Owner Response:',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryDark)),
                  const SizedBox(height: 4),
                  Text(complaint.ownerResponse!),
                ],
              ),
            ),
          ]
        ],
      ),
    );
  }
}
