import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fyp/controllers/HostelController.dart' show HostelController;
import 'package:fyp/models/HostelModel.dart';
import 'package:fyp/routes/AppRoutes.dart';
import 'package:fyp/utils/AppColors.dart';
import 'package:fyp/utils/AppConstants.dart';
import 'package:fyp/views/admin/AdminSettingsScreen.dart';
import 'package:fyp/views/admin/widgets/ApprovedHostelsList.dart';
import 'package:fyp/views/admin/widgets/SegmentButton.dart';
import 'package:fyp/views/shared Widgets/StatusChip.dart';
import 'package:get/get.dart';

class HostelsTab extends StatefulWidget {
  final HostelController hostelCtrl;
  const HostelsTab({super.key, required this.hostelCtrl});

  @override
  State<HostelsTab> createState() => HostelsTabState();
}

class HostelsTabState extends State<HostelsTab> {
  int _subTabIndex = 0; // 0=All, 1=Pending, 2=Unregister, 3=Approved
  String _searchQuery = '';
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void deactivate() {
    _searchFocusNode.unfocus();
    super.deactivate();
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
    super.dispose();
  }

  List<HostelModel> _filterHostels(List<HostelModel> list) {
    final q = _searchQuery.toLowerCase().trim();
    if (q.isEmpty) return list;
    return list.where((h) {
      return h.name.toLowerCase().contains(q) ||
          h.city.toLowerCase().contains(q) ||
          h.ownerName.toLowerCase().contains(q) ||
          (h.registrationNumber != null &&
              h.registrationNumber!.toLowerCase().contains(q));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) {
      return _buildMobileLayout();
    }
    return _buildWebLayout();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // WEB REDESIGN: Matches Users Page & Owner Panel Redesign
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildWebLayout() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Obx(() {
      final all = widget.hostelCtrl.allHostels.toList();
      final pending = widget.hostelCtrl.pendingHostels.toList();
      final unreg = widget.hostelCtrl.unregistrationRequests.toList();
      final approved = all.where((h) => h.status == 'approved').toList();

      List<HostelModel> currentList;
      bool isPendingTab = false;
      bool isUnregTab = false;

      if (_subTabIndex == 0) {
        currentList = all;
      } else if (_subTabIndex == 1) {
        currentList = pending;
        isPendingTab = true;
      } else if (_subTabIndex == 2) {
        currentList = unreg;
        isUnregTab = true;
      } else {
        currentList = approved;
      }

      final filtered = _filterHostels(currentList);

      return Column(
        children: [
          // ── Hero Heading Banner + Filter & Search Row ────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 20, 28, 0),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1140),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildWebHeroBanner(),
                    const SizedBox(height: 18),
                    _buildWebFilterAndSearchRow(
                      isDark,
                      all.length,
                      pending.length,
                      unreg.length,
                      approved.length,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Hostels List ─────────────────────────────────────────────────
          Expanded(
            child: filtered.isEmpty
                ? _buildEmptyState(isDark)
                : Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1140),
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(28, 16, 28, 24),
                        itemCount: filtered.length,
                        itemBuilder: (_, i) => _WebHostelCard(
                          hostel: filtered[i],
                          hostelCtrl: widget.hostelCtrl,
                          isDark: isDark,
                          showApprovalActions: isPendingTab,
                          showUnregActions: isUnregTab,
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      );
    });
  }

  Widget _buildWebHeroBanner() {
    return Container(
      width: double.infinity,
      height: 120,
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
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Row(
              children: [
                // Leading Circular Icon Badge
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
                    Icons.apartment_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 20),

                // Title & Subtitle
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Hostels Management',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Review hostel listings, approvals, and unregistration requests',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                // Right Floating Glass Tile Artwork
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                    Transform.rotate(
                      angle: -0.1,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.35),
                          ),
                        ),
                        child: const Icon(
                          Icons.domain_rounded,
                          color: Colors.white,
                          size: 30,
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
    );
  }

  Widget _buildWebFilterAndSearchRow(
    bool isDark,
    int allCount,
    int pendingCount,
    int unregCount,
    int approvedCount,
  ) {
    return Row(
      children: [
        _buildPill(0, 'All', allCount, Icons.list_alt_rounded, AppColors.primary, isDark),
        const SizedBox(width: 10),
        _buildPill(1, 'Pending', pendingCount, Icons.hourglass_top_rounded, const Color(0xFFF59E0B), isDark),
        const SizedBox(width: 10),
        _buildPill(2, 'Unregister', unregCount, Icons.warning_amber_rounded, const Color(0xFFEF4444), isDark),
        const SizedBox(width: 10),
        _buildPill(3, 'Approved', approvedCount, Icons.verified_rounded, const Color(0xFF10B981), isDark),

        const Spacer(),

        // Web Search Box
        Container(
          width: 300,
          height: 42,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF14202E) : Colors.white,
            borderRadius: BorderRadius.circular(10),
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
              hintText: 'Search by hostel, city, owner…',
              hintStyle: TextStyle(
                fontSize: 13,
                color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary,
              ),
              prefixIcon: Icon(
                Icons.search,
                color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary,
                size: 18,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPill(
    int index,
    String label,
    int count,
    IconData icon,
    Color activeColor,
    bool isDark,
  ) {
    final isSelected = _subTabIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _subTabIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor
              : (isDark ? const Color(0xFF14202E) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? activeColor
                : (isDark ? const Color(0xFF223242) : const Color(0xFFE2E8F0)),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected
                  ? Colors.white
                  : (isDark ? Colors.white60 : Colors.grey.shade600),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white70 : Colors.grey.shade700),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.25)
                    : activeColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  color: isSelected ? Colors.white : activeColor,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.apartment_rounded, size: 48, color: AppColors.primary),
          ),
          const SizedBox(height: 14),
          Text(
            'No hostels found',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Try adjusting your search query or tab filter',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // MOBILE LAYOUT (Redesigned App Only)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildMobileLayout() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF111827) : const Color(0xFFF1F5F9);

    return Scaffold(
      backgroundColor: bgColor,
      body: Obx(() {
        final all = widget.hostelCtrl.allHostels.toList();
        final pending = widget.hostelCtrl.pendingHostels.toList();
        final unreg = widget.hostelCtrl.unregistrationRequests.toList();
        final approved = all.where((h) => h.status == 'approved').toList();

        List<HostelModel> currentList;
        bool isPendingTab = false;
        bool isUnregTab = false;

        if (_subTabIndex == 0) {
          currentList = all;
        } else if (_subTabIndex == 1) {
          currentList = pending;
          isPendingTab = true;
        } else if (_subTabIndex == 2) {
          currentList = unreg;
          isUnregTab = true;
        } else {
          currentList = approved;
        }

        final filtered = _filterHostels(currentList);

        return Column(
          children: [
            // ── Curved Teal Hero Header ────────────────────────────────────
            _buildMobileCurvedHeader(
              totalCount: all.length,
              pendingCount: pending.length,
              approvedCount: approved.length,
            ),

            // ── Filter Pills Row ───────────────────────────────────────────
            _buildMobileFilterPills(
              allCount: all.length,
              pendingCount: pending.length,
              approvedCount: approved.length,
              unregCount: unreg.length,
            ),

            // ── Hostels List ───────────────────────────────────────────────
            Expanded(
              child: filtered.isEmpty
                  ? _buildMobileEmptyState()
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                      itemCount: filtered.length,
                      itemBuilder: (ctx, i) => _MobileModernHostelCard(
                        hostel: filtered[i],
                        hostelCtrl: widget.hostelCtrl,
                        showApprovalActions: isPendingTab,
                        showUnregActions: isUnregTab,
                      ),
                    ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildMobileCurvedHeader({
    required int totalCount,
    required int pendingCount,
    required int approvedCount,
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
              // Top row: Title + Actions (Chat & Settings)
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
                    child: const Icon(Icons.domain_rounded,
                        color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Hostels Management',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: -0.3,
                          ),
                        ),
                        Text(
                          '$totalCount total · $pendingCount pending · $approvedCount approved',
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chat_outlined,
                        color: Colors.white, size: 24),
                    tooltip: 'Messages',
                    onPressed: () => Get.toNamed(AppRoutes.adminChats),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    icon: const Icon(Icons.settings_outlined,
                        color: Colors.white, size: 24),
                    tooltip: 'Settings',
                    onPressed: () => Get.to(() => const AdminSettingsScreen()),
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
                    hintText: 'Search hostel, city, owner, reg #…',
                    hintStyle:
                        const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                    prefixIcon: const Icon(Icons.search_rounded,
                        size: 20, color: Color(0xFF007A85)),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded,
                                size: 18, color: Color(0xFF94A3B8)),
                            onPressed: () {
                              setState(() => _searchQuery = '');
                              _searchFocusNode.unfocus();
                            },
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
    required int approvedCount,
    required int unregCount,
  }) {
    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            _HostelFilterChip(
              label: 'All',
              count: allCount,
              isSelected: _subTabIndex == 0,
              onTap: () => setState(() => _subTabIndex = 0),
            ),
            const SizedBox(width: 8),
            _HostelFilterChip(
              label: 'Pending',
              count: pendingCount,
              isSelected: _subTabIndex == 1,
              dotColor: const Color(0xFFEF4444),
              onTap: () => setState(() => _subTabIndex = 1),
            ),
            const SizedBox(width: 8),
            _HostelFilterChip(
              label: 'Approved',
              count: approvedCount,
              isSelected: _subTabIndex == 3,
              dotColor: const Color(0xFF10B981),
              onTap: () => setState(() => _subTabIndex = 3),
            ),
            const SizedBox(width: 8),
            _HostelFilterChip(
              label: 'Unregister',
              count: unregCount,
              isSelected: _subTabIndex == 2,
              dotColor: const Color(0xFFF59E0B),
              onTap: () => setState(() => _subTabIndex = 2),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFF007A85).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.domain_disabled_rounded,
                  size: 40, color: Color(0xFF007A85)),
            ),
            const SizedBox(height: 16),
            const Text(
              'No Hostels Found',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No results matching "$_searchQuery".'
                  : 'No hostels available in this tab.',
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Web Modern Hostel Card ───────────────────────────────────────────────────
class _WebHostelCard extends StatelessWidget {
  final HostelModel hostel;
  final HostelController hostelCtrl;
  final bool isDark;
  final bool showApprovalActions;
  final bool showUnregActions;

  const _WebHostelCard({
    required this.hostel,
    required this.hostelCtrl,
    required this.isDark,
    this.showApprovalActions = false,
    this.showUnregActions = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Get.toNamed(AppRoutes.adminHostelDetail, arguments: hostel),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF14202E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? const Color(0xFF223242) : const Color(0xFFE2E8F0),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hostel Image Thumbnail
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: 90,
                      height: 90,
                      child: hostel.images.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: hostel.images.first,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => Container(
                                color: isDark
                                    ? const Color(0xFF1B2836)
                                    : const Color(0xFFE2E8F0),
                                child: const Center(
                                    child: CircularProgressIndicator(strokeWidth: 2)),
                              ),
                              errorWidget: (_, __, ___) => Container(
                                color: isDark
                                    ? const Color(0xFF1B2836)
                                    : const Color(0xFFE2E8F0),
                                child: Icon(Icons.apartment_rounded,
                                    color: isDark
                                        ? const Color(0xFF64748B)
                                        : Colors.grey.shade400,
                                    size: 32),
                              ),
                            )
                          : Container(
                              color: isDark
                                  ? const Color(0xFF1B2836)
                                  : const Color(0xFFE2E8F0),
                              child: Icon(Icons.apartment_rounded,
                                  color: isDark
                                      ? const Color(0xFF64748B)
                                      : Colors.grey.shade400,
                                  size: 32),
                            ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Middle Information Column
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                hostel.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16.5,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 12),
                            StatusChip(status: hostel.status),
                          ],
                        ),
                        const SizedBox(height: 6),

                        // Registration badge if available
                        if (hostel.registrationNumber != null &&
                            hostel.registrationNumber!.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            margin: const EdgeInsets.only(bottom: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF14B8A6).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: const Color(0xFF14B8A6).withValues(alpha: 0.25),
                              ),
                            ),
                            child: Text(
                              'Reg: ${hostel.registrationNumber}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF14B8A6),
                              ),
                            ),
                          ),

                        // Specs Row: City · Type · Gender · Price
                        Row(
                          children: [
                            Text(
                              '${hostel.city} · ${hostel.roomType} · ${hostel.genderPreference}',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark
                                    ? const Color(0xFF94A3B8)
                                    : AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'PKR ${hostel.rentPerMonth.toStringAsFixed(0)}/mo',
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2DD4BF),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Amenities Pills
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: hostel.facilities.take(4).map((f) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF1B2836)
                                    : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: isDark
                                      ? const Color(0xFF2C3E50)
                                      : const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Text(
                                f,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark
                                      ? const Color(0xFF94A3B8)
                                      : const Color(0xFF64748B),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // ── Action Buttons for Pending & Unregistration ──────────────
              if (showApprovalActions) ...[
                const SizedBox(height: 14),
                Divider(
                    height: 1,
                    color: isDark ? const Color(0xFF223242) : const Color(0xFFE9ECEF)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => hostelCtrl.updateHostelStatus(
                          hostel.id, AppConstants.statusRejected),
                      icon: const Icon(Icons.close_rounded, size: 16),
                      label: const Text('Reject'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      onPressed: () => _showApproveDialog(context, hostel),
                      icon: const Icon(Icons.check_rounded, size: 16),
                      label: const Text('Approve Listing'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
              ],

              if (showUnregActions) ...[
                const SizedBox(height: 14),
                Divider(
                    height: 1,
                    color: isDark ? const Color(0xFF223242) : const Color(0xFFE9ECEF)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Reason: ${hostel.unregistrationReason ?? "Owner requested deletion"}',
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontStyle: FontStyle.italic,
                          color: Color(0xFFEF4444),
                        ),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => hostelCtrl.rejectUnregistration(
                          hostel.id, hostel.ownerId, hostel.name),
                      icon: const Icon(Icons.close_rounded, size: 16),
                      label: const Text('Reject Request'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isDark ? Colors.white70 : Colors.black87,
                        side: BorderSide(
                            color: isDark
                                ? const Color(0xFF64748B)
                                : Colors.grey.shade400),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () {
                        Get.defaultDialog(
                          title: 'Confirm Unregistration',
                          middleText:
                              'Are you sure you want to approve unregistration for "${hostel.name}"? This action will permanently remove this hostel.',
                          textCancel: 'Cancel',
                          textConfirm: 'Delete Hostel',
                          confirmTextColor: Colors.white,
                          buttonColor: AppColors.error,
                          onConfirm: () {
                            Get.back();
                            hostelCtrl.acceptUnregistrationAndDelete(
                                hostel.id, hostel.ownerId, hostel.name);
                          },
                        );
                      },
                      icon: const Icon(Icons.delete_forever_rounded, size: 16),
                      label: const Text('Approve & Remove'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showApproveDialog(BuildContext context, HostelModel hostel) {
    final suggested = (hostel.registrationNumber != null &&
            hostel.registrationNumber!.isNotEmpty)
        ? hostel.registrationNumber!
        : hostelCtrl.generateNextRegistrationNumber();
    final ctrl = TextEditingController(text: suggested);

    Get.defaultDialog(
      title: 'Approve Hostel',
      titleStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      content: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Assign registration number for "${hostel.name}":',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              decoration: InputDecoration(
                labelText: 'Registration Number *',
                hintText: 'e.g. DS-Hostel-1',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                prefixIcon: const Icon(Icons.verified_outlined),
              ),
              autofocus: true,
            ),
          ],
        ),
      ),
      textConfirm: 'Approve',
      textCancel: 'Cancel',
      confirmTextColor: Colors.white,
      buttonColor: AppColors.success,
      onConfirm: () {
        final regNum = ctrl.text.trim();
        if (regNum.isEmpty) {
          Get.snackbar('Error', 'Registration number cannot be empty',
              snackPosition: SnackPosition.BOTTOM);
          return;
        }
        Get.back();
        hostelCtrl.updateHostelStatus(
          hostel.id,
          AppConstants.statusApproved,
          registrationNumber: regNum,
        );
      },
    );
  }
}

// ── Mobile Filter Chip Widget ───────────────────────────────────────────────
class _HostelFilterChip extends StatelessWidget {
  final String label;
  final int count;
  final bool isSelected;
  final Color? dotColor;
  final VoidCallback onTap;

  const _HostelFilterChip({
    required this.label,
    required this.count,
    required this.isSelected,
    this.dotColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF007A85) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF007A85) : const Color(0xFFE2E8F0),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isSelected ? 0.08 : 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (dotColor != null) ...[
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF334155),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                fontSize: 12.5,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.25)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF64748B),
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
}

// ── Mobile Modern Hostel Card ───────────────────────────────────────────────
class _MobileModernHostelCard extends StatelessWidget {
  final HostelModel hostel;
  final HostelController hostelCtrl;
  final bool showApprovalActions;
  final bool showUnregActions;

  const _MobileModernHostelCard({
    required this.hostel,
    required this.hostelCtrl,
    this.showApprovalActions = false,
    this.showUnregActions = false,
  });

  @override
  Widget build(BuildContext context) {
    final hasImages = hostel.images.isNotEmpty;
    final isApproved = hostel.status == 'approved';
    final isPending = hostel.status == 'pending';

    final Color statusColor = isApproved
        ? const Color(0xFF10B981)
        : isPending
            ? const Color(0xFFF59E0B)
            : const Color(0xFFEF4444);

    final Color statusBg = isApproved
        ? const Color(0xFFECFDF5)
        : isPending
            ? const Color(0xFFFFFBEB)
            : const Color(0xFFFEF2F2);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => Get.toNamed(AppRoutes.adminHostelDetail, arguments: hostel),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Top Image & Core Info Row ───────────────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Hostel Image
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        width: 82,
                        height: 82,
                        color: const Color(0xFFF1F5F9),
                        child: hasImages
                            ? CachedNetworkImage(
                                imageUrl: hostel.images.first,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => Container(
                                  color: const Color(0xFFE2E8F0),
                                  child: const Center(
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                  ),
                                ),
                                errorWidget: (_, __, ___) => const Icon(
                                  Icons.home_work_rounded,
                                  color: Color(0xFF94A3B8),
                                  size: 32,
                                ),
                              )
                            : const Icon(
                                Icons.home_work_rounded,
                                color: Color(0xFF94A3B8),
                                size: 32,
                              ),
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  hostel.name,
                                  style: const TextStyle(
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F172A),
                                    letterSpacing: -0.2,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: statusBg,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: statusColor.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Text(
                                  hostel.status.toUpperCase(),
                                  style: TextStyle(
                                    color: statusColor,
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),

                          // City & Gender Row
                          Row(
                            children: [
                              const Icon(Icons.location_on_outlined,
                                  size: 13, color: Color(0xFF64748B)),
                              const SizedBox(width: 3),
                              Text(
                                '${hostel.city} · ${hostel.genderPreference}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),

                          // Registration Number Badge if present
                          if (hostel.registrationNumber != null &&
                              hostel.registrationNumber!.isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF007A85).withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Reg: ${hostel.registrationNumber}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF007A85),
                                ),
                              ),
                            ),
                            const SizedBox(height: 3),
                          ],

                          // Price
                          Text(
                            'PKR ${hostel.rentPerMonth.toStringAsFixed(0)} / mo',
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF007A85),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 8),

                // ── Owner & Facilities Row ──────────────────────────────────
                Row(
                  children: [
                    const Icon(Icons.person_outline_rounded,
                        size: 14, color: Color(0xFF94A3B8)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Owner: ${hostel.ownerName}',
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (hostel.facilities.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Wrap(
                        spacing: 4,
                        children: hostel.facilities.take(2).map((f) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Text(
                              f,
                              style: const TextStyle(
                                fontSize: 10,
                                color: Color(0xFF475569),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),

                // ── Approval Actions for Pending Listings ────────────────────
                if (showApprovalActions) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => hostelCtrl.updateHostelStatus(
                            hostel.id,
                            AppConstants.statusRejected,
                          ),
                          icon: const Icon(Icons.close_rounded, size: 16),
                          label: const Text('Reject'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFDC2626),
                            side: const BorderSide(color: Color(0xFFDC2626)),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _showApproveDialog(context),
                          icon: const Icon(Icons.check_rounded, size: 16),
                          label: const Text('Approve'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],

                // ── Unregistration Actions ──────────────────────────────────
                if (showUnregActions) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFFEE2E2)),
                    ),
                    child: Text(
                      'Reason: ${hostel.unregistrationReason ?? "Closing hostel"}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF991B1B),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => hostelCtrl.rejectUnregistration(
                            hostel.id,
                            hostel.ownerId,
                            hostel.name,
                          ),
                          icon: const Icon(Icons.close_rounded, size: 16),
                          label: const Text('Reject Request'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF475569),
                            side: const BorderSide(color: Color(0xFFCBD5E1)),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Get.defaultDialog(
                              title: 'Confirm Delete',
                              middleText:
                                  'Are you sure you want to approve unregistration for "${hostel.name}"? This permanently removes the hostel.',
                              textCancel: 'Cancel',
                              textConfirm: 'Delete Hostel',
                              confirmTextColor: Colors.white,
                              buttonColor: const Color(0xFFDC2626),
                              onConfirm: () {
                                Get.back();
                                hostelCtrl.acceptUnregistrationAndDelete(
                                  hostel.id,
                                  hostel.ownerId,
                                  hostel.name,
                                );
                              },
                            );
                          },
                          icon: const Icon(Icons.delete_forever_rounded, size: 16),
                          label: const Text('Delete Hostel'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFDC2626),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showApproveDialog(BuildContext context) {
    final suggested = (hostel.registrationNumber != null &&
            hostel.registrationNumber!.isNotEmpty)
        ? hostel.registrationNumber!
        : hostelCtrl.generateNextRegistrationNumber();
    final ctrl = TextEditingController(text: suggested);

    Get.defaultDialog(
      title: 'Approve Hostel',
      titleStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      content: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Assign registration number for "${hostel.name}":',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              decoration: InputDecoration(
                labelText: 'Registration Number *',
                hintText: 'e.g. DS-Hostel-1',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                prefixIcon: const Icon(Icons.verified_outlined),
              ),
              autofocus: true,
            ),
          ],
        ),
      ),
      textConfirm: 'Approve',
      textCancel: 'Cancel',
      confirmTextColor: Colors.white,
      buttonColor: const Color(0xFF10B981),
      onConfirm: () {
        final regNum = ctrl.text.trim();
        if (regNum.isEmpty) {
          Get.snackbar('Error', 'Registration number cannot be empty',
              snackPosition: SnackPosition.BOTTOM);
          return;
        }
        Get.back();
        hostelCtrl.updateHostelStatus(
          hostel.id,
          AppConstants.statusApproved,
          registrationNumber: regNum,
        );
      },
    );
  }
}
