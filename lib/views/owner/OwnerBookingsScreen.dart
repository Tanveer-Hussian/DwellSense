// lib/views/owner/OwnerBookingsScreen.dart
// ─────────────────────────────────────────────────────────────────────────────
// FR-5.2: Owner accepts or rejects booking requests.
// FR-5.5: Owner views booking history.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fyp/controllers/BookingController.dart';
import 'package:fyp/models/BookingModel.dart';
import 'package:fyp/utils/AppColors.dart';
import 'package:fyp/utils/AppConstants.dart';
import 'package:fyp/views/shared%20Widgets/StatusChip.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class OwnerBookingsScreen extends StatelessWidget {
  final bool isTab;
  const OwnerBookingsScreen({super.key, this.isTab = false});

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return _buildWebScaffold(context);
    }
    return _OwnerBookingsMobileView(isTab: isTab);
  }

  // ── Web Scaffold (Preserved 100% Unchanged for Web) ─────────────────────────
  Widget _buildWebScaffold(BuildContext context) {
    final BookingController ctrl = Get.find<BookingController>();

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: !isTab,
          title: const Text('Booking Requests'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Pending'),
              Tab(text: 'Confirmed'),
              Tab(text: 'All'),
            ],
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
          ),
        ),
        body: Obx(() {
          final all = ctrl.myBookings;
          final pending =
              all.where((b) => b.status == AppConstants.bookingPending).toList();
          final confirmed = all
              .where((b) => b.status == AppConstants.bookingConfirmed)
              .toList();

          return TabBarView(
            children: [
              _WebBookingList(
                bookings: pending,
                showActions: true,
                emptyMessage: 'No pending booking requests.',
                ctrl: ctrl,
              ),
              _WebBookingList(
                bookings: confirmed,
                showActions: false,
                emptyMessage: 'No confirmed bookings.',
                ctrl: ctrl,
              ),
              _WebBookingList(
                bookings: all,
                showActions: false,
                emptyMessage: 'No bookings yet.',
                ctrl: ctrl,
              ),
            ],
          );
        }),
      ),
    );
  }
}

// ── Web Booking list tab content (Preserved 100% Unchanged) ───────────────────
class _WebBookingList extends StatelessWidget {
  final List<BookingModel> bookings;
  final bool showActions;
  final String emptyMessage;
  final BookingController ctrl;

  const _WebBookingList({
    required this.bookings,
    required this.showActions,
    required this.emptyMessage,
    required this.ctrl,
  });

  @override
  Widget build(BuildContext context) {
    if (bookings.isEmpty) {
      return Center(
        child: Text(emptyMessage,
            style: const TextStyle(color: AppColors.textSecondary)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: bookings.length,
      itemBuilder: (_, i) {
        final booking = bookings[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.primaryLight,
                      child: Text(booking.studentName[0].toUpperCase(),
                          style: const TextStyle(color: AppColors.primaryDark)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(booking.studentName,
                              style: Theme.of(context).textTheme.titleLarge),
                          Text(booking.studentEmail,
                              style: Theme.of(context).textTheme.bodyMedium),
                        ],
                      ),
                    ),
                    StatusChip(status: booking.status),
                  ],
                ),
                const Divider(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _WebDetailItem(
                            label: 'Hostel',
                            value: booking.hostelName,
                          ),
                          _WebDetailItem(
                            label: 'Check-in',
                            value: DateFormat('MMM dd, yyyy')
                                .format(booking.checkInDate),
                          ),
                          _WebDetailItem(
                            label: 'Check-out',
                            value: DateFormat('MMM dd, yyyy')
                                .format(booking.checkOutDate),
                          ),
                          _WebDetailItem(
                            label: 'Total',
                            value: 'PKR ${booking.totalAmount.toStringAsFixed(0)}',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (showActions &&
                    booking.status == AppConstants.bookingPending) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              _showWebResponseDialog(context, booking, false, ctrl),
                          icon: const Icon(Icons.close, color: AppColors.error),
                          label: const Text('Reject'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.error,
                            side: const BorderSide(color: AppColors.error),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () =>
                              _showWebResponseDialog(context, booking, true, ctrl),
                          icon: const Icon(Icons.check, size: 16),
                          label: const Text('Accept'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  void _showWebResponseDialog(
    BuildContext ctx,
    BookingModel booking,
    bool isAccepting,
    BookingController ctrl,
  ) {
    final noteCtrl = TextEditingController();

    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        title: Text(isAccepting ? 'Accept Booking' : 'Reject Booking'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isAccepting
                  ? 'Accept booking request from ${booking.studentName}?'
                  : 'Reject booking request from ${booking.studentName}?',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: noteCtrl,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: isAccepting
                    ? 'Optional: welcome message...'
                    : 'Optional: reason for rejection...',
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              ctrl.respondToBooking(
                booking,
                isAccepting
                    ? AppConstants.bookingConfirmed
                    : AppConstants.bookingRejected,
                note: noteCtrl.text.isNotEmpty ? noteCtrl.text : null,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isAccepting ? AppColors.success : AppColors.error,
            ),
            child: Text(isAccepting ? 'Accept' : 'Reject'),
          ),
        ],
      ),
    );
  }
}

class _WebDetailItem extends StatelessWidget {
  final String label;
  final String value;

  const _WebDetailItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text('$label: ',
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 13)),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// ── MODERN MOBILE BOOKINGS EXPERIENCE (MOBILE APP ONLY) ───────────────────────
// ═════════════════════════════════════════════════════════════════════════════

class _OwnerBookingsMobileView extends StatefulWidget {
  final bool isTab;
  const _OwnerBookingsMobileView({required this.isTab});

  @override
  State<_OwnerBookingsMobileView> createState() => _OwnerBookingsMobileViewState();
}

class _OwnerBookingsMobileViewState extends State<_OwnerBookingsMobileView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final BookingController _ctrl = Get.find<BookingController>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Color _avatarColor(String name) {
    const colors = [
      Color(0xFF007A85),
      Color(0xFF2563EB),
      Color(0xFF7C3AED),
      Color(0xFFD97706),
      Color(0xFF059669),
      Color(0xFFDB2777),
      Color(0xFF4B5563),
    ];
    if (name.isEmpty) return colors[0];
    return colors[name.codeUnitAt(0) % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF111827) : const Color(0xFFF8FAFC);

    return Scaffold(
      backgroundColor: bgColor,
      body: Obx(() {
        final all = _ctrl.myBookings;
        final pending = all
            .where((b) => b.status == AppConstants.bookingPending)
            .toList();
        final confirmed = all
            .where((b) => b.status == AppConstants.bookingConfirmed)
            .toList();

        return NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              // ── Curved Teal Hero Header ─────────────────────────────────────
              SliverToBoxAdapter(
                child: Container(
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
                  padding: EdgeInsets.fromLTRB(
                    20,
                    MediaQuery.of(context).padding.top + 16,
                    20,
                    22,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (!widget.isTab) ...[
                            IconButton(
                              icon: const Icon(Icons.arrow_back, color: Colors.white),
                              onPressed: () => Navigator.of(context).maybePop(),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                            const SizedBox(width: 12),
                          ],
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Booking Requests',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Manage student reservations & approvals',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (pending.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF59E0B),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.15),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.pending_actions_rounded,
                                      size: 13, color: Colors.white),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${pending.length} Action${pending.length > 1 ? 's' : ''}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // ── Modern Pill Tab Bar inside Header ───────────────────
                      Container(
                        height: 44,
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: TabBar(
                          controller: _tabController,
                          indicator: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          indicatorSize: TabBarIndicatorSize.tab,
                          dividerColor: Colors.transparent,
                          labelColor: const Color(0xFF007A85),
                          unselectedLabelColor: Colors.white.withValues(alpha: 0.85),
                          labelStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                          unselectedLabelStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          tabs: [
                            Tab(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text('Pending'),
                                  if (pending.isNotEmpty) ...[
                                    const SizedBox(width: 5),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF59E0B),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '${pending.length}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            Tab(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text('Confirmed'),
                                  if (confirmed.isNotEmpty) ...[
                                    const SizedBox(width: 5),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF10B981),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '${confirmed.length}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            Tab(
                              child: Text('All (${all.length})'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ];
          },
          body: TabBarView(
            controller: _tabController,
            children: [
              _MobileBookingListView(
                bookings: pending,
                showActions: true,
                emptyTitle: 'No Pending Requests',
                emptySubtitle:
                    'When students request a reservation, you will be able to review and accept or reject them right here.',
                ctrl: _ctrl,
                avatarColorBuilder: _avatarColor,
              ),
              _MobileBookingListView(
                bookings: confirmed,
                showActions: false,
                emptyTitle: 'No Confirmed Bookings',
                emptySubtitle:
                    'Bookings that you approve will appear here with active check-in details.',
                ctrl: _ctrl,
                avatarColorBuilder: _avatarColor,
              ),
              _MobileBookingListView(
                bookings: all,
                showActions: false,
                emptyTitle: 'No Bookings Found',
                emptySubtitle: 'Your complete booking history will be recorded here.',
                ctrl: _ctrl,
                avatarColorBuilder: _avatarColor,
              ),
            ],
          ),
        );
      }),
    );
  }
}

// ── Mobile Booking List View ──────────────────────────────────────────────────
class _MobileBookingListView extends StatelessWidget {
  final List<BookingModel> bookings;
  final bool showActions;
  final String emptyTitle;
  final String emptySubtitle;
  final BookingController ctrl;
  final Color Function(String) avatarColorBuilder;

  const _MobileBookingListView({
    required this.bookings,
    required this.showActions,
    required this.emptyTitle,
    required this.emptySubtitle,
    required this.ctrl,
    required this.avatarColorBuilder,
  });

  @override
  Widget build(BuildContext context) {
    if (bookings.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFF007A85).withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.event_note_rounded,
                    size: 42,
                    color: Color(0xFF007A85),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  emptyTitle,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  emptySubtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      itemCount: bookings.length,
      itemBuilder: (context, i) {
        final booking = bookings[i];
        final initial = booking.studentName.isNotEmpty
            ? booking.studentName[0].toUpperCase()
            : 'S';
        final isPending = booking.status == AppConstants.bookingPending;
        final avatarBg = avatarColorBuilder(booking.studentName);

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isPending
                  ? const Color(0xFFF59E0B).withValues(alpha: 0.35)
                  : const Color(0xFFE2E8F0),
              width: isPending ? 1.4 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isPending
                    ? const Color(0xFFF59E0B).withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top student row
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 23,
                      backgroundColor: avatarBg.withValues(alpha: 0.12),
                      child: Text(
                        initial,
                        style: TextStyle(
                          color: avatarBg,
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            booking.studentName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            booking.studentEmail,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    StatusChip(status: booking.status),
                  ],
                ),
              ),

              const Divider(height: 1, color: Color(0xFFF1F5F9)),

              // Booking specifications grid
              Padding(
                padding: const EdgeInsets.all(14),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.apartment_rounded,
                              size: 16, color: Color(0xFF007A85)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              booking.hostelName,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFF007A85).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'PKR ${booking.totalAmount.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF007A85),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _MobileDatePill(
                              label: 'Check-in',
                              date: booking.checkInDate,
                              icon: Icons.login_rounded,
                              color: const Color(0xFF2563EB),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _MobileDatePill(
                              label: 'Check-out',
                              date: booking.checkOutDate,
                              icon: Icons.logout_rounded,
                              color: const Color(0xFFF59E0B),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Action buttons (Only for pending requests)
              if (showActions && isPending) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                  child: Row(
                    children: [
                      // Reject Button
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              _showMobileResponseDialog(context, booking, false, ctrl),
                          icon: const Icon(Icons.close_rounded,
                              size: 16, color: Color(0xFFDC2626)),
                          label: const Text(
                            'Reject',
                            style: TextStyle(
                              color: Color(0xFFDC2626),
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: const Color(0xFFFEE2E2).withValues(alpha: 0.3),
                            side: const BorderSide(color: Color(0xFFFCA5A5)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Accept Button
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () =>
                              _showMobileResponseDialog(context, booking, true, ctrl),
                          icon: const Icon(Icons.check_rounded,
                              size: 16, color: Colors.white),
                          label: const Text(
                            'Accept',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF007A85),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  // ── Mobile Responsive Confirmation Dialog ─────────────────────────────────
  void _showMobileResponseDialog(
    BuildContext ctx,
    BookingModel booking,
    bool isAccepting,
    BookingController ctrl,
  ) {
    final noteCtrl = TextEditingController();

    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20),
        actionsPadding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (isAccepting ? const Color(0xFF007A85) : const Color(0xFFDC2626))
                    .withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isAccepting ? Icons.check_circle_rounded : Icons.cancel_rounded,
                color: isAccepting ? const Color(0xFF007A85) : const Color(0xFFDC2626),
                size: 22,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                isAccepting ? 'Accept Booking' : 'Reject Booking',
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isAccepting
                  ? 'Confirm booking request from ${booking.studentName}?'
                  : 'Are you sure you want to decline booking for ${booking.studentName}?',
              style: const TextStyle(fontSize: 14, color: Color(0xFF475569)),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: noteCtrl,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: isAccepting
                    ? 'Optional: Welcome note or room info...'
                    : 'Optional: Reason for declining...',
                hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                contentPadding: const EdgeInsets.all(12),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
              style: const TextStyle(fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              ctrl.respondToBooking(
                booking,
                isAccepting
                    ? AppConstants.bookingConfirmed
                    : AppConstants.bookingRejected,
                note: noteCtrl.text.isNotEmpty ? noteCtrl.text : null,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isAccepting ? const Color(0xFF007A85) : const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: Text(isAccepting ? 'Confirm' : 'Reject'),
          ),
        ],
      ),
    );
  }
}

// ── Mobile Date Pill ──────────────────────────────────────────────────────────
class _MobileDatePill extends StatelessWidget {
  final String label;
  final DateTime date;
  final IconData icon;
  final Color color;

  const _MobileDatePill({
    required this.label,
    required this.date,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 9,
                    color: Color(0xFF94A3B8),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  DateFormat('dd MMM yyyy').format(date),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
