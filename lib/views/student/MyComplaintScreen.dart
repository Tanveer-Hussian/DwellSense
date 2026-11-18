// ─────────────────────────────────────────────────────────────────────────────
// lib/views/student/my_complaints_screen.dart
// FR-7.3: Student tracks their complaint status.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fyp/controllers/BookingController.dart';
import 'package:fyp/controllers/ComplaintController.dart';
import 'package:fyp/controllers/HostelController.dart';
import 'package:fyp/models/ComplaintModel.dart';
import 'package:fyp/models/HostelModel.dart';
import 'package:fyp/routes/AppRoutes.dart';
import 'package:fyp/utils/AppColors.dart';
import 'package:fyp/views/shared Widgets/StatusChip.dart';
import 'package:fyp/views/student/StudentSettingsScreen.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class MyComplaintsScreen extends StatefulWidget {
  const MyComplaintsScreen({super.key});

  @override
  State<MyComplaintsScreen> createState() => _MyComplaintsScreenState();
}

class _MyComplaintsScreenState extends State<MyComplaintsScreen> {
  String _filter = 'all'; // 'all' | 'pending' | 'in_progress' | 'resolved'
  String _searchQuery = '';
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void dispose() {
    _searchFocusNode.dispose();
    super.dispose();
  }

  List<ComplaintModel> _applyFilters(List<ComplaintModel> list) {
    final q = _searchQuery.toLowerCase().trim();
    return list.where((c) {
      final matchesStatus = _filter == 'all' || c.status == _filter;
      final matchesSearch = q.isEmpty ||
          c.title.toLowerCase().contains(q) ||
          c.hostelName.toLowerCase().contains(q) ||
          c.description.toLowerCase().contains(q);
      return matchesStatus && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<ComplaintController>();

    if (!kIsWeb) {
      return _buildMobileLayout(context, ctrl);
    }
    return _buildWebLayout(context, ctrl);
  }

  // ── Web Layout (Matches Modern Admin & Owner Complaints Redesign) ────────
  Widget _buildWebLayout(BuildContext context, ComplaintController ctrl) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F171E) : const Color(0xFFF6F8FA),
      body: Obx(() {
        final all = ctrl.myComplaints;
        final pendingCount = all.where((c) => c.status == 'pending').length;
        final inProgressCount = all.where((c) => c.status == 'in_progress').length;
        final resolvedCount = all.where((c) => c.status == 'resolved').length;

        final filtered = _applyFilters(all);

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1140),
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              children: [
                // ── Top Hero Gradient Banner ──────────────────────────────
                _buildWebHeroBanner(),
                const SizedBox(height: 20),

                // ── Filter Chips, Search Bar & New Complaint Button ───────
                _buildWebFilterAndSearchRow(
                  isDark: isDark,
                  allCount: all.length,
                  pendingCount: pendingCount,
                  inProgressCount: inProgressCount,
                  resolvedCount: resolvedCount,
                ),
                const SizedBox(height: 20),

                // ── Complaints List ───────────────────────────────────────
                if (filtered.isEmpty)
                  _buildWebEmptyState(isDark)
                else
                  ...filtered.map((c) => Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _WebStudentComplaintCard(
                          complaint: c,
                          isDark: isDark,
                          onConfirm: (resolved) =>
                              ctrl.confirmResolution(c, resolved),
                        ),
                      )),
                const SizedBox(height: 30),
              ],
            ),
          ),
        );
      }),
    );
  }

  // ── Web Top Hero Gradient Banner ──────────────────────────────────────────
  Widget _buildWebHeroBanner() {
    return Container(
      height: 120,
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF00545C),
            Color(0xFF007A7F),
            Color(0xFF048A76),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF004D55).withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          // Left Icon badge
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.35),
                width: 1.5,
              ),
            ),
            child: const Icon(
              Icons.assignment_late_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 20),

          // Title & subtitle
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'My Complaints',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Track filed complaints, view hostel owner responses, and confirm resolutions',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // File Complaint Button
          ElevatedButton.icon(
            onPressed: () => _onFileComplaint(context),
            icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
            label: const Text('File Complaint'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF006168),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  // ── Web Filter & Search Row ───────────────────────────────────────────────
  Widget _buildWebFilterAndSearchRow({
    required bool isDark,
    required int allCount,
    required int pendingCount,
    required int inProgressCount,
    required int resolvedCount,
  }) {
    return Row(
      children: [
        _buildPill('all', 'All', allCount, Icons.list_alt_rounded, const Color(0xFF00A896), isDark),
        const SizedBox(width: 8),
        _buildPill('pending', 'Pending', pendingCount, Icons.error_outline_rounded, const Color(0xFFEF4444), isDark),
        const SizedBox(width: 8),
        _buildPill('in_progress', 'In Progress', inProgressCount, Icons.autorenew_rounded, const Color(0xFFF59E0B), isDark),
        const SizedBox(width: 8),
        _buildPill('resolved', 'Resolved', resolvedCount, Icons.check_circle_outline_rounded, const Color(0xFF10B981), isDark),

        const Spacer(),

        // Web Search Box
        Container(
          width: 320,
          height: 42,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF14202E) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? const Color(0xFF223242) : const Color(0xFFE2E8F0),
            ),
          ),
          child: TextField(
            focusNode: _searchFocusNode,
            onChanged: (v) => setState(() => _searchQuery = v),
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
            decoration: InputDecoration(
              hintText: 'Search complaints by title, hostel...',
              hintStyle: TextStyle(
                fontSize: 13,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF94A3B8),
              ),
              prefixIcon: const Icon(
                Icons.search,
                color: Color(0xFF2DD4BF),
                size: 18,
              ),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close, size: 16),
                      onPressed: () => setState(() => _searchQuery = ''),
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPill(
    String value,
    String label,
    int count,
    IconData icon,
    Color activeColor,
    bool isDark,
  ) {
    final isSelected = _filter == value;

    return InkWell(
      onTap: () => setState(() => _filter = value),
      borderRadius: BorderRadius.circular(24),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor
              : (isDark ? const Color(0xFF14202E) : Colors.white),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF2DD4BF)
                : (isDark ? const Color(0xFF223242) : const Color(0xFFE2E8F0)),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: activeColor.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected
                  ? Colors.white
                  : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : (isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155)),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                fontSize: 12.5,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.25)
                    : activeColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  color: isSelected ? Colors.white : activeColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Web Empty State ───────────────────────────────────────────────────────
  Widget _buildWebEmptyState(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 60),
      alignment: Alignment.center,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: const Color(0xFF2DD4BF).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_outline_rounded,
              size: 48,
              color: Color(0xFF2DD4BF),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty ? 'No matching complaints found' : 'No Complaints Filed',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _searchQuery.isNotEmpty
                ? 'Try adjusting your search query or filter status.'
                : 'All clear! If you experience any issues at your hostel, file a complaint.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => _onFileComplaint(context),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('File a Complaint'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00A896),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  void _onFileComplaint(BuildContext context) {
    final bookingCtrl = Get.find<BookingController>();
    final hostelCtrl = Get.find<HostelController>();

    final bookings = bookingCtrl.myBookings;
    if (bookings.isNotEmpty) {
      if (bookings.length == 1) {
        final b = bookings.first;
        final hostel = hostelCtrl.approvedHostels.firstWhereOrNull((h) => h.id == b.hostelId) ??
            hostelCtrl.allHostels.firstWhereOrNull((h) => h.id == b.hostelId);
        if (hostel != null) {
          Get.toNamed(AppRoutes.submitComplaint, arguments: hostel);
          return;
        }
      } else {
        final hostels = bookings
            .map((b) =>
                hostelCtrl.approvedHostels.firstWhereOrNull((h) => h.id == b.hostelId) ??
                hostelCtrl.allHostels.firstWhereOrNull((h) => h.id == b.hostelId))
            .whereType<HostelModel>()
            .toList();
        if (hostels.isNotEmpty) {
          _showHostelPicker(context, hostels);
          return;
        }
      }
    }

    final availableHostels = hostelCtrl.approvedHostels.isNotEmpty
        ? hostelCtrl.approvedHostels
        : hostelCtrl.allHostels;

    if (availableHostels.isNotEmpty) {
      _showHostelPicker(context, availableHostels);
    } else {
      Get.snackbar(
        'No Hostels Available',
        'Please wait for hostels to load or book a hostel first.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFEF4444).withValues(alpha: 0.9),
        colorText: Colors.white,
      );
    }
  }

  void _showHostelPicker(BuildContext context, List<HostelModel> hostels) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF14202E) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textMuted = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: cardBg,
        child: Container(
          width: 440,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select Hostel',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Choose the hostel you want to file a complaint for:',
                style: TextStyle(fontSize: 13, color: textMuted),
              ),
              const SizedBox(height: 16),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 280),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: hostels.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (ctx, i) {
                    final h = hostels[i];
                    return InkWell(
                      onTap: () {
                        Get.back();
                        Get.toNamed(AppRoutes.submitComplaint, arguments: h);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1B2836) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark ? const Color(0xFF2C3E50) : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: const Color(0xFF2DD4BF).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.domain_rounded, color: Color(0xFF2DD4BF), size: 18),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                h.name,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: textPrimary,
                                ),
                              ),
                            ),
                            const Icon(Icons.chevron_right_rounded, color: Color(0xFF2DD4BF), size: 18),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Get.back(),
                  child: Text('Cancel', style: TextStyle(color: textMuted)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Mobile Layout Redesign ────────────────────────────────────────────────
  Widget _buildMobileLayout(BuildContext context, ComplaintController ctrl) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF111827) : const Color(0xFFF1F5F9);

    return Scaffold(
      backgroundColor: bgColor,
      body: Obx(() {
        final all = ctrl.myComplaints;
        final pendingCount = all.where((c) => c.status == 'pending').length;
        final inProgressCount = all.where((c) => c.status == 'in_progress').length;
        final resolvedCount = all.where((c) => c.status == 'resolved').length;

        final filtered = _applyFilters(all);

        return Column(
          children: [
            // ── Curved Teal Hero Header ─────────────────────────────────────
            _buildMobileCurvedHeader(
              context: context,
              allCount: all.length,
              pendingCount: pendingCount,
            ),

            // ── Filter Pills Row ─────────────────────────────────────────────
            _buildMobileFilterPills(
              allCount: all.length,
              pendingCount: pendingCount,
              inProgressCount: inProgressCount,
              resolvedCount: resolvedCount,
            ),

            // ── Complaints List ──────────────────────────────────────────────
            Expanded(
              child: filtered.isEmpty
                  ? _buildMobileEmptyState(isDark)
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 90),
                      itemCount: filtered.length,
                      itemBuilder: (_, i) => _MobileModernStudentComplaintCard(
                        complaint: filtered[i],
                        isDark: isDark,
                        onConfirm: (resolved) =>
                            ctrl.confirmResolution(filtered[i], resolved),
                      ),
                    ),
            ),
          ],
        );
      }),

      // ── Floating Action Button: File Complaint ────────────────────────────
      floatingActionButton: GestureDetector(
        onTap: () => _onFileComplaint(context),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
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
              Icon(Icons.add_rounded, size: 20, color: Colors.white),
              SizedBox(width: 6),
              Text(
                'File Complaint',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileCurvedHeader({
    required BuildContext context,
    required int allCount,
    required int pendingCount,
  }) {
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
          padding: const EdgeInsets.fromLTRB(20, 12, 16, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Title + Settings
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                    ),
                    child: const Icon(Icons.report_problem_rounded,
                        color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'My Complaints',
                          style: TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: -0.3,
                          ),
                        ),
                        Text(
                          '$allCount filed · $pendingCount pending',
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings_outlined,
                        color: Colors.white, size: 24),
                    tooltip: 'Settings',
                    onPressed: () => Get.to(() => const StudentSettingsScreen()),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Search Bar
              Container(
                height: 44,
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
                child: TextField(
                  focusNode: _searchFocusNode,
                  onChanged: (val) => setState(() => _searchQuery = val),
                  style: const TextStyle(fontSize: 13.5, color: Color(0xFF0F172A)),
                  decoration: InputDecoration(
                    hintText: 'Search title, hostel, description...',
                    hintStyle:
                        const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                    prefixIcon: const Icon(Icons.search_rounded,
                        color: Color(0xFF007A85), size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? GestureDetector(
                            onTap: () {
                              setState(() => _searchQuery = '');
                              _searchFocusNode.unfocus();
                            },
                            child: const Icon(Icons.close_rounded,
                                size: 18, color: Color(0xFF94A3B8)),
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileFilterPills({
    required int allCount,
    required int pendingCount,
    required int inProgressCount,
    required int resolvedCount,
  }) {
    final pills = [
      {'key': 'all', 'label': 'All', 'count': allCount},
      {'key': 'pending', 'label': 'Pending', 'count': pendingCount},
      {'key': 'in_progress', 'label': 'In Progress', 'count': inProgressCount},
      {'key': 'resolved', 'label': 'Resolved', 'count': resolvedCount},
    ];

    return Container(
      height: 46,
      margin: const EdgeInsets.only(top: 10, bottom: 6),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: pills.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final item = pills[i];
          final isSelected = _filter == item['key'];
          return GestureDetector(
            onTap: () => setState(() => _filter = item['key'] as String),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF00585E) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF00585E)
                      : const Color(0xFFE2E8F0),
                  width: 1.2,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: const Color(0xFF00585E).withValues(alpha: 0.25),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item['label'] as String,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? Colors.white : const Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.22)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${item['count']}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? Colors.white
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMobileEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF00585E).withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_outline_rounded,
                size: 40,
                color: Color(0xFF00585E),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No matching complaints'
                  : 'No complaints filed',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Try searching with different keywords.'
                  : 'Have an issue with your hostel stay? Tap "File Complaint" below.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Modern Card for Student Mobile Complaints
// ─────────────────────────────────────────────────────────────────────────────
class _MobileModernStudentComplaintCard extends StatelessWidget {
  final ComplaintModel complaint;
  final bool isDark;
  final void Function(bool resolved) onConfirm;

  const _MobileModernStudentComplaintCard({
    required this.complaint,
    required this.isDark,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final c = complaint;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final cardBorder = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);

    Color statusColor;
    String statusLabel;
    IconData statusIcon;

    switch (c.status.toLowerCase()) {
      case 'resolved':
        statusColor = const Color(0xFF10B981);
        statusLabel = 'Resolved';
        statusIcon = Icons.check_circle_rounded;
        break;
      case 'in_progress':
        statusColor = const Color(0xFFF59E0B);
        statusLabel = 'In Progress';
        statusIcon = Icons.autorenew_rounded;
        break;
      default:
        statusColor = const Color(0xFFEF4444);
        statusLabel = 'Pending';
        statusIcon = Icons.hourglass_top_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Chip & Date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 13, color: statusColor),
                      const SizedBox(width: 5),
                      Text(
                        statusLabel,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  DateFormat('MMM d, yyyy').format(c.createdAt),
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Title
            Text(
              c.title,
              style: TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 4),

            // Hostel tag
            Row(
              children: [
                const Icon(Icons.apartment_rounded,
                    size: 14, color: Color(0xFF007A85)),
                const SizedBox(width: 4),
                Text(
                  c.hostelName,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF007A85),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Description container
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Text(
                c.description,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: Color(0xFF334155),
                ),
              ),
            ),

            // Owner response (if exists)
            if (c.ownerResponse != null && c.ownerResponse!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF00585E).withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF00585E).withValues(alpha: 0.18),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.mark_chat_read_rounded,
                            size: 14, color: Color(0xFF00585E)),
                        SizedBox(width: 6),
                        Text(
                          'Owner Response',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF00585E),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      c.ownerResponse!,
                      style: const TextStyle(
                        fontSize: 12.5,
                        height: 1.4,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Student confirmation buttons (when status is resolved and student hasn't confirmed)
            if (c.status == 'resolved' && !c.studentConfirmed) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Has this complaint been resolved to your satisfaction?',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFB45309),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => onConfirm(true),
                            icon: const Icon(Icons.check_rounded, size: 16),
                            label: const Text('Confirmed'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => onConfirm(false),
                            icon: const Icon(Icons.close_rounded, size: 16),
                            label: const Text('Not Resolved'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.error,
                              side: const BorderSide(color: AppColors.error),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
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
          ],
        ),
      ),
    );
  }
}


// ── Web Student Complaint Card ──────────────────────────────────────────────
class _WebStudentComplaintCard extends StatelessWidget {
  final ComplaintModel complaint;
  final bool isDark;
  final void Function(bool resolved) onConfirm;

  const _WebStudentComplaintCard({
    required this.complaint,
    required this.isDark,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final c = complaint;
    final cardBg = isDark ? const Color(0xFF14202E) : Colors.white;
    final cardBorder = isDark ? const Color(0xFF223242) : const Color(0xFFE2E8F0);
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textMuted = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final responseBg = isDark ? const Color(0xFF1B2836) : const Color(0xFFF0FDF4);
    final responseBorder = isDark ? const Color(0xFF2A3D50) : const Color(0xFFDCFCE7);

    Color statusColor;
    String statusLabel;
    IconData statusIcon;

    switch (c.status.toLowerCase()) {
      case 'resolved':
        statusColor = const Color(0xFF10B981);
        statusLabel = 'Resolved';
        statusIcon = Icons.check_circle_rounded;
        break;
      case 'in_progress':
        statusColor = const Color(0xFFF59E0B);
        statusLabel = 'In Progress';
        statusIcon = Icons.autorenew_rounded;
        break;
      default:
        statusColor = const Color(0xFFEF4444);
        statusLabel = 'Pending';
        statusIcon = Icons.hourglass_top_rounded;
    }

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Title, Hostel tag & Status Badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2DD4BF).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFF2DD4BF).withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.domain_rounded, size: 12, color: Color(0xFF2DD4BF)),
                              const SizedBox(width: 4),
                              Text(
                                c.hostelName,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2DD4BF),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          DateFormat('MMM dd, yyyy • hh:mm a').format(c.createdAt),
                          style: TextStyle(fontSize: 12, color: textMuted),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),

              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withValues(alpha: 0.35)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 13, color: statusColor),
                    const SizedBox(width: 5),
                    Text(
                      statusLabel,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Description box
          Text(
            c.description,
            style: TextStyle(
              fontSize: 13.5,
              height: 1.5,
              color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
            ),
          ),

          // Owner Response section
          if (c.ownerResponse != null && c.ownerResponse!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: responseBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: responseBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.reply_rounded, size: 16, color: Color(0xFF10B981)),
                      SizedBox(width: 6),
                      Text(
                        'Hostel Owner Response:',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    c.ownerResponse!,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.45,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),

                  // Student confirmation action
                  if (c.status == 'resolved' && !c.studentConfirmed) ...[
                    const Divider(height: 20),
                    Row(
                      children: [
                        Text(
                          'Has this issue been satisfactorily resolved?',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: textPrimary,
                          ),
                        ),
                        const Spacer(),
                        OutlinedButton(
                          onPressed: () => onConfirm(false),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFEF4444),
                            side: const BorderSide(color: Color(0xFFEF4444)),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          child: const Text('Not Resolved'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () => onConfirm(true),
                          icon: const Icon(Icons.check, size: 14),
                          label: const Text('Confirm Resolution'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            elevation: 0,
                          ),
                        ),
                      ],
                    ),
                  ] else if (c.status == 'resolved' && c.studentConfirmed) ...[
                    const SizedBox(height: 8),
                    const Row(
                      children: [
                        Icon(Icons.verified_rounded, size: 14, color: Color(0xFF10B981)),
                        SizedBox(width: 4),
                        Text(
                          'You confirmed this issue as resolved.',
                          style: TextStyle(fontSize: 11.5, color: Color(0xFF10B981), fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
