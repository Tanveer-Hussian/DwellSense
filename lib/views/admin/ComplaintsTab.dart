import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fyp/controllers/ComplaintController.dart';
import 'package:fyp/models/ComplaintModel.dart';
import 'package:fyp/routes/AppRoutes.dart';
import 'package:fyp/utils/AppColors.dart';
import 'package:fyp/views/admin/AdminSettingsScreen.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class ComplaintsTab extends StatefulWidget {
  final ComplaintController complaintCtrl;
  const ComplaintsTab({required this.complaintCtrl, super.key});

  @override
  State<ComplaintsTab> createState() => _ComplaintsTabState();
}

class _ComplaintsTabState extends State<ComplaintsTab> {
  String _filter = 'all'; // 'all' | 'pending' | 'in_progress' | 'resolved'
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

  List<ComplaintModel> _applyFilters(List<ComplaintModel> list) {
    final q = _searchQuery.toLowerCase().trim();
    return list.where((c) {
      final matchesStatus = _filter == 'all' || c.status == _filter;
      final matchesSearch = q.isEmpty ||
          c.title.toLowerCase().contains(q) ||
          c.hostelName.toLowerCase().contains(q) ||
          c.studentName.toLowerCase().contains(q) ||
          c.description.toLowerCase().contains(q);
      return matchesStatus && matchesSearch;
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
  // WEB REDESIGN: Matches Users and Hostels Page Redesign
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildWebLayout() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Obx(() {
      final all = widget.complaintCtrl.allComplaints;
      final pendingCount = all.where((c) => c.status == 'pending').length;
      final inProgressCount = all.where((c) => c.status == 'in_progress').length;
      final resolvedCount = all.where((c) => c.status == 'resolved').length;

      final filtered = _applyFilters(all);

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
                      pendingCount,
                      inProgressCount,
                      resolvedCount,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Complaints List ──────────────────────────────────────────────
          Expanded(
            child: filtered.isEmpty
                ? _buildEmptyState(isDark)
                : Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1140),
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(28, 16, 28, 24),
                        itemCount: filtered.length,
                        itemBuilder: (_, i) => _WebAdminComplaintCard(
                          complaint: filtered[i],
                          isDark: isDark,
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
                    Icons.report_problem_rounded,
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
                        'Complaints Management',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Monitor resident grievances, response statuses and resolution history',
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
                          Icons.assignment_late_rounded,
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
    int inProgressCount,
    int resolvedCount,
  ) {
    return Row(
      children: [
        _buildPill('all', 'All', allCount, Icons.list_alt_rounded, AppColors.primary, isDark),
        const SizedBox(width: 10),
        _buildPill('pending', 'Pending', pendingCount, Icons.error_outline_rounded, const Color(0xFFEF4444), isDark),
        const SizedBox(width: 10),
        _buildPill('in_progress', 'In Progress', inProgressCount, Icons.autorenew_rounded, const Color(0xFFF59E0B), isDark),
        const SizedBox(width: 10),
        _buildPill('resolved', 'Resolved', resolvedCount, Icons.check_circle_outline_rounded, const Color(0xFF10B981), isDark),

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
              hintText: 'Search by complaint, hostel, student…',
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
    String value,
    String label,
    int count,
    IconData icon,
    Color activeColor,
    bool isDark,
  ) {
    final isSelected = _filter == value;

    return GestureDetector(
      onTap: () => setState(() => _filter = value),
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
            child: const Icon(Icons.check_circle_outline, size: 48, color: AppColors.primary),
          ),
          const SizedBox(height: 14),
          Text(
            'No complaints found',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Try adjusting your search query or status filter',
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
  // MOBILE REDESIGN (APP ONLY) — Matches modern curved header & card language
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildMobileLayout() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF111827) : const Color(0xFFF1F5F9);

    return Scaffold(
      backgroundColor: bgColor,
      body: Obx(() {
        final all = widget.complaintCtrl.allComplaints;
        final pendingCount = all.where((c) => c.status == 'pending').length;
        final inProgressCount = all.where((c) => c.status == 'in_progress').length;
        final resolvedCount = all.where((c) => c.status == 'resolved').length;

        final filtered = _applyFilters(all);

        return Column(
          children: [
            // ── Curved Teal Hero Header ────────────────────────────────────
            _buildMobileCurvedHeader(
              allCount: all.length,
              pendingCount: pendingCount,
            ),

            // ── Filter Pills Row ───────────────────────────────────────────
            _buildMobileFilterPills(
              allCount: all.length,
              pendingCount: pendingCount,
              inProgressCount: inProgressCount,
              resolvedCount: resolvedCount,
            ),

            // ── Complaints List ────────────────────────────────────────────
            Expanded(
              child: filtered.isEmpty
                  ? _buildMobileEmptyState()
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                      itemCount: filtered.length,
                      itemBuilder: (ctx, i) => _MobileModernAdminComplaintCard(
                        complaint: filtered[i],
                        onManage: () => _showStatusDialog(context, filtered[i]),
                      ),
                    ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildMobileCurvedHeader({
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
                    child: const Icon(Icons.report_problem_rounded,
                        color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Complaints',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: -0.3,
                          ),
                        ),
                        Text(
                          '$allCount total · $pendingCount pending',
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
                    hintText: 'Search title, student, hostel...',
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
    required int inProgressCount,
    required int resolvedCount,
  }) {
    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            _ModernFilterChip(
              label: 'All',
              count: allCount,
              value: 'all',
              current: _filter,
              onTap: () => setState(() => _filter = 'all'),
            ),
            const SizedBox(width: 8),
            _ModernFilterChip(
              label: 'Pending',
              count: pendingCount,
              value: 'pending',
              current: _filter,
              dotColor: const Color(0xFFEF4444),
              onTap: () => setState(() => _filter = 'pending'),
            ),
            const SizedBox(width: 8),
            _ModernFilterChip(
              label: 'In Progress',
              count: inProgressCount,
              value: 'in_progress',
              current: _filter,
              dotColor: const Color(0xFFF59E0B),
              onTap: () => setState(() => _filter = 'in_progress'),
            ),
            const SizedBox(width: 8),
            _ModernFilterChip(
              label: 'Resolved',
              count: resolvedCount,
              value: 'resolved',
              current: _filter,
              dotColor: const Color(0xFF10B981),
              onTap: () => setState(() => _filter = 'resolved'),
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
                color: const Color(0xFF10B981).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded,
                  size: 40, color: Color(0xFF10B981)),
            ),
            const SizedBox(height: 16),
            const Text(
              'No Complaints Found',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _filter == 'all'
                  ? 'All resident tickets across hostels are resolved.'
                  : 'No complaints in "${_filter.replaceAll('_', ' ')}" status.',
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showStatusDialog(BuildContext context, ComplaintModel complaint) {
    String selectedStatus = complaint.status;
    final responseCtrl = TextEditingController(text: complaint.ownerResponse ?? '');

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20),
          actionsPadding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF007A85).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.edit_note_rounded,
                    color: Color(0xFF007A85), size: 22),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Manage Complaint',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  complaint.title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  '${complaint.studentName} · ${complaint.hostelName}',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Update Status:',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedStatus,
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(
                          value: 'pending',
                          child: Text('⏳ Pending'),
                        ),
                        DropdownMenuItem(
                          value: 'in_progress',
                          child: Text('🔄 In Progress'),
                        ),
                        DropdownMenuItem(
                          value: 'resolved',
                          child: Text('✅ Resolved'),
                        ),
                      ],
                      onChanged: (v) {
                        if (v != null) {
                          setDialogState(() => selectedStatus = v);
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Administrative Note / Response:',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: responseCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Add administrative note or feedback...',
                    hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
            ),
            ElevatedButton(
              onPressed: () async {
                Get.back();
                await widget.complaintCtrl.respondToComplaint(
                  complaint,
                  responseCtrl.text.trim(),
                  selectedStatus,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF007A85),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              child: const Text('Save & Update'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Web Modern Admin Complaint Card ──────────────────────────────────────────
class _WebAdminComplaintCard extends StatelessWidget {
  final ComplaintModel complaint;
  final bool isDark;

  const _WebAdminComplaintCard({
    required this.complaint,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final status = complaint.status;
    final Color statusColor;
    final IconData statusIcon;

    switch (status) {
      case 'resolved':
        statusColor = const Color(0xFF10B981);
        statusIcon = Icons.check_circle_outline_rounded;
        break;
      case 'in_progress':
        statusColor = const Color(0xFFF59E0B);
        statusIcon = Icons.autorenew_rounded;
        break;
      default:
        statusColor = const Color(0xFFEF4444);
        statusIcon = Icons.error_outline_rounded;
    }

    final formattedDate = DateFormat('dd MMM yyyy').format(complaint.createdAt);

    return Container(
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
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header Row: Title, Hostel & Status ─────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        complaint.title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16.5,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        complaint.hostelName,
                        style: const TextStyle(
                          color: Color(0xFF2DD4BF),
                          fontWeight: FontWeight.w600,
                          fontSize: 13.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 14, color: statusColor),
                      const SizedBox(width: 5),
                      Text(
                        complaint.status.replaceAll('_', ' ').toUpperCase(),
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // ── Meta Info (Student & Date) ─────────────────────────────────
            Row(
              children: [
                Icon(Icons.person_outline,
                    size: 15,
                    color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary),
                const SizedBox(width: 5),
                Text(
                  'By ${complaint.studentName}',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(Icons.calendar_today_outlined,
                    size: 14,
                    color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary),
                const SizedBox(width: 5),
                Text(
                  formattedDate,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── Description ────────────────────────────────────────────────
            Text(
              complaint.description,
              style: TextStyle(
                fontSize: 13.5,
                color: isDark ? Colors.white70 : const Color(0xFF334155),
                height: 1.45,
              ),
            ),

            // ── Owner Response if available ────────────────────────────────
            if (complaint.ownerResponse != null && complaint.ownerResponse!.isNotEmpty) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1B2836) : const Color(0xFFF0FDFA),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFF14B8A6).withValues(alpha: 0.25),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.reply_rounded, size: 15, color: Color(0xFF14B8A6)),
                        SizedBox(width: 6),
                        Text(
                          'Owner Response:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF14B8A6),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      complaint.ownerResponse!,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
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

// ── Mobile Filter chip widget ───────────────────────────────────────────────
class _ModernFilterChip extends StatelessWidget {
  final String label;
  final int count;
  final String value;
  final String current;
  final Color? dotColor;
  final VoidCallback onTap;

  const _ModernFilterChip({
    required this.label,
    required this.count,
    required this.value,
    required this.current,
    this.dotColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = value == current;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF007A85) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? const Color(0xFF007A85) : const Color(0xFFE2E8F0),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isActive ? 0.08 : 0.02),
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
                color: isActive ? Colors.white : const Color(0xFF334155),
                fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                fontSize: 12.5,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isActive
                    ? Colors.white.withValues(alpha: 0.25)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  color: isActive ? Colors.white : const Color(0xFF64748B),
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

// ── Mobile Modern Admin Complaint Card ──────────────────────────────────────
class _MobileModernAdminComplaintCard extends StatelessWidget {
  final ComplaintModel complaint;
  final VoidCallback onManage;

  const _MobileModernAdminComplaintCard({
    required this.complaint,
    required this.onManage,
  });

  @override
  Widget build(BuildContext context) {
    final status = complaint.status;
    final Color statusColor;
    final Color statusBg;
    final IconData statusIcon;
    final String statusLabel;

    switch (status) {
      case 'resolved':
        statusColor = const Color(0xFF10B981);
        statusBg = const Color(0xFFECFDF5);
        statusIcon = Icons.check_circle_rounded;
        statusLabel = 'RESOLVED';
        break;
      case 'in_progress':
        statusColor = const Color(0xFFF59E0B);
        statusBg = const Color(0xFFFFFBEB);
        statusIcon = Icons.autorenew_rounded;
        statusLabel = 'IN PROGRESS';
        break;
      default:
        statusColor = const Color(0xFFEF4444);
        statusBg = const Color(0xFFFEF2F2);
        statusIcon = Icons.error_rounded;
        statusLabel = 'PENDING';
    }

    final formattedDate = DateFormat('dd MMM yyyy').format(complaint.createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top Header Row: Icon, Title & Status Chip ───────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Icon(statusIcon, color: statusColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        complaint.title,
                        style: const TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(Icons.home_work_rounded,
                              size: 14, color: Color(0xFF007A85)),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              complaint.hostelName,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF007A85),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── Meta Info (Student & Date) ─────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.person_outline_rounded,
                      size: 15, color: Color(0xFF64748B)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      complaint.studentName,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF334155),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.calendar_today_outlined,
                      size: 13, color: Color(0xFF94A3B8)),
                  const SizedBox(width: 4),
                  Text(
                    formattedDate,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── Description ────────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFF1F5F9)),
              ),
              child: Text(
                complaint.description,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF334155),
                  height: 1.4,
                ),
              ),
            ),

            // ── Owner Response (if exists) ─────────────────────────────────
            if (complaint.ownerResponse != null &&
                complaint.ownerResponse!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDFA),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF14B8A6).withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.reply_rounded,
                            size: 15, color: Color(0xFF007A85)),
                        SizedBox(width: 6),
                        Text(
                          'Owner Response:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF007A85),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      complaint.ownerResponse!,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 12),

            // ── Admin Action Button ─────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onManage,
                icon: const Icon(Icons.tune_rounded, size: 16),
                label: const Text('Manage Ticket Status'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF007A85),
                  side: const BorderSide(color: Color(0xFF007A85)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
