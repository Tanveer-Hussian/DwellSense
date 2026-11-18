// lib/views/owner/OwnerComplaintsScreen.dart
// ─────────────────────────────────────────────────────────────────────────────
// FR-7.2: Owner responds to complaints from residents.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fyp/controllers/ComplaintController.dart';
import 'package:fyp/models/ComplaintModel.dart';
import 'package:fyp/utils/AppColors.dart';
import 'package:fyp/utils/AppConstants.dart';
import 'package:fyp/views/shared%20Widgets/StatusChip.dart' show StatusChip;
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class OwnerComplaintsScreen extends StatelessWidget {
  final bool isTab;
  const OwnerComplaintsScreen({super.key, this.isTab = false});

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return _buildWebScaffold(context);
    }
    return _OwnerComplaintsMobileView(isTab: isTab);
  }

  // ── Web Scaffold (Preserved 100% Unchanged for Web) ─────────────────────────
  Widget _buildWebScaffold(BuildContext context) {
    final ctrl = Get.find<ComplaintController>();

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: !isTab,
        title: const Text('Resident Complaints'),
      ),
      body: Obx(() {
        final complaints = ctrl.myComplaints;

        if (complaints.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline,
                    size: 64, color: AppColors.success),
                SizedBox(height: 16),
                Text('No complaints!',
                    style: TextStyle(color: AppColors.textSecondary)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: complaints.length,
          itemBuilder: (_, i) {
            final c = complaints[i];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(c.title,
                              style: Theme.of(context).textTheme.titleLarge),
                        ),
                        StatusChip(status: c.status),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('by ${c.studentName} · ${c.hostelName}',
                        style: Theme.of(context).textTheme.bodyMedium),
                    const Divider(height: 20),
                    Text(c.description),
                    if (c.ownerResponse != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.2)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Your Response:',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                    fontSize: 12)),
                            Text(c.ownerResponse!),
                          ],
                        ),
                      ),
                    ],
                    if (c.status != AppConstants.complaintResolved) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () =>
                              _showWebRespondDialog(context, c, ctrl),
                          icon: const Icon(Icons.reply_outlined, size: 16),
                          label: const Text('Respond'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      }),
    );
  }

  void _showWebRespondDialog(BuildContext ctx, complaint, ctrl) {
    final responseCtrl =
        TextEditingController(text: complaint.ownerResponse ?? '');
    String selectedStatus = complaint.status == 'pending'
        ? AppConstants.complaintInProgress
        : AppConstants.complaintResolved;

    showDialog(
      context: ctx,
      builder: (_) => StatefulBuilder(
        builder: (_, setState) => AlertDialog(
          title: const Text('Respond to Complaint'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: responseCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Your response to the student...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Update Status:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              DropdownButton<String>(
                value: selectedStatus,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(
                      value: 'in_progress', child: Text('🔄 In Progress')),
                  DropdownMenuItem(
                      value: 'resolved', child: Text('✅ Resolved')),
                ],
                onChanged: (v) => setState(() => selectedStatus = v!),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Get.back(), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                Get.back();
                ctrl.respondToComplaint(
                    complaint, responseCtrl.text, selectedStatus);
              },
              child: const Text('Send Response'),
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// ── MODERN MOBILE COMPLAINTS EXPERIENCE (MOBILE APP ONLY) ─────────────────────
// ═════════════════════════════════════════════════════════════════════════════

class _OwnerComplaintsMobileView extends StatefulWidget {
  final bool isTab;
  const _OwnerComplaintsMobileView({required this.isTab});

  @override
  State<_OwnerComplaintsMobileView> createState() =>
      _OwnerComplaintsMobileViewState();
}

class _OwnerComplaintsMobileViewState extends State<_OwnerComplaintsMobileView> {
  final ComplaintController _ctrl = Get.find<ComplaintController>();
  int _selectedFilter = 0; // 0: All, 1: Pending, 2: In Progress, 3: Resolved

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
        final all = _ctrl.myComplaints;
        final pending = all
            .where((c) => c.status == AppConstants.complaintPending || c.status == 'pending')
            .toList();
        final inProgress = all
            .where((c) => c.status == AppConstants.complaintInProgress || c.status == 'in_progress')
            .toList();
        final resolved = all
            .where((c) => c.status == AppConstants.complaintResolved || c.status == 'resolved')
            .toList();

        final List<ComplaintModel> filteredComplaints;
        switch (_selectedFilter) {
          case 1:
            filteredComplaints = pending;
            break;
          case 2:
            filteredComplaints = inProgress;
            break;
          case 3:
            filteredComplaints = resolved;
            break;
          default:
            filteredComplaints = all;
        }

        final unresolvedCount = pending.length + inProgress.length;

        return CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
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
                  24,
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
                                'Resident Complaints',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Review & resolve tenant service requests',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (unresolvedCount > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444),
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
                                const Icon(Icons.error_outline_rounded,
                                    size: 13, color: Colors.white),
                                const SizedBox(width: 4),
                                Text(
                                  '$unresolvedCount Active',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.white30, width: 1),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_circle_rounded,
                                    size: 13, color: Color(0xFF34D399)),
                                SizedBox(width: 4),
                                Text(
                                  'All Clear',
                                  style: TextStyle(
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

                    // ── Filter Pills Row inside Header ───────────────────────
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterTab(0, 'All', all.length),
                          const SizedBox(width: 8),
                          _buildFilterTab(1, 'Pending', pending.length,
                              badgeColor: const Color(0xFFEF4444)),
                          const SizedBox(width: 8),
                          _buildFilterTab(2, 'In Progress', inProgress.length,
                              badgeColor: const Color(0xFF3B82F6)),
                          const SizedBox(width: 8),
                          _buildFilterTab(3, 'Resolved', resolved.length,
                              badgeColor: const Color(0xFF10B981)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Section Title ────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: [
                    Container(
                      width: 3.5,
                      height: 15,
                      decoration: BoxDecoration(
                        color: const Color(0xFF007A85),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'TICKETS (${filteredComplaints.length})',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF64748B),
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Complaints List or Empty State ───────────────────────────────
            if (filteredComplaints.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final c = filteredComplaints[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _MobileComplaintCard(
                          complaint: c,
                          avatarBg: _avatarColor(c.studentName),
                          onRespond: () => _showMobileRespondDialog(context, c),
                        ),
                      );
                    },
                    childCount: filteredComplaints.length,
                  ),
                ),
              )
            else
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.all(24),
                  padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.verified_rounded,
                          size: 44,
                          color: Color(0xFF10B981),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _selectedFilter == 0
                            ? 'All Clear! No Complaints'
                            : 'No ${_filterName(_selectedFilter)} Complaints',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _selectedFilter == 0
                            ? 'There are currently no active complaints for any of your properties.'
                            : 'There are no complaints under this status filter.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF64748B),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      }),
    );
  }

  String _filterName(int index) {
    switch (index) {
      case 1:
        return 'Pending';
      case 2:
        return 'In Progress';
      case 3:
        return 'Resolved';
      default:
        return '';
    }
  }

  Widget _buildFilterTab(int index, String label, int count,
      {Color? badgeColor}) {
    final isSelected = _selectedFilter == index;

    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(14),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? const Color(0xFF007A85) : Colors.white,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected
                    ? (badgeColor ?? const Color(0xFF007A85)).withValues(alpha: 0.15)
                    : Colors.white.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isSelected
                      ? (badgeColor ?? const Color(0xFF007A85))
                      : Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Mobile Responsive Confirmation & Response Dialog ──────────────────────
  void _showMobileRespondDialog(BuildContext ctx, ComplaintModel complaint) {
    final responseCtrl =
        TextEditingController(text: complaint.ownerResponse ?? '');
    String selectedStatus = complaint.status == 'pending'
        ? AppConstants.complaintInProgress
        : AppConstants.complaintResolved;

    showDialog(
      context: ctx,
      builder: (_) => StatefulBuilder(
        builder: (_, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20),
          actionsPadding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF007A85).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.reply_rounded,
                  color: Color(0xFF007A85),
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Respond to Complaint',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Student: ${complaint.studentName} · ${complaint.hostelName}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: responseCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Type your resolution or update to the resident...',
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
              const SizedBox(height: 14),
              const Text(
                'Update Ticket Status:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedStatus,
                    isExpanded: true,
                    icon: const Icon(Icons.arrow_drop_down_rounded,
                        color: Color(0xFF007A85)),
                    items: const [
                      DropdownMenuItem(
                        value: 'in_progress',
                        child: Row(
                          children: [
                            Icon(Icons.autorenew_rounded,
                                size: 16, color: Color(0xFF2563EB)),
                            SizedBox(width: 8),
                            Text('In Progress',
                                style: TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'resolved',
                        child: Row(
                          children: [
                            Icon(Icons.check_circle_rounded,
                                size: 16, color: Color(0xFF10B981)),
                            SizedBox(width: 8),
                            Text('Resolved',
                                style: TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w600)),
                          ],
                        ),
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
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Get.back();
                _ctrl.respondToComplaint(
                  complaint,
                  responseCtrl.text.trim(),
                  selectedStatus,
                );
              },
              icon: const Icon(Icons.send_rounded, size: 15, color: Colors.white),
              label: const Text('Send Response'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF007A85),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Mobile Complaint Card ─────────────────────────────────────────────────────
class _MobileComplaintCard extends StatelessWidget {
  final ComplaintModel complaint;
  final Color avatarBg;
  final VoidCallback onRespond;

  const _MobileComplaintCard({
    required this.complaint,
    required this.avatarBg,
    required this.onRespond,
  });

  @override
  Widget build(BuildContext context) {
    final initial = complaint.studentName.isNotEmpty
        ? complaint.studentName[0].toUpperCase()
        : 'S';
    final isResolved = complaint.status == AppConstants.complaintResolved ||
        complaint.status == 'resolved';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isResolved
              ? const Color(0xFFE2E8F0)
              : const Color(0xFF007A85).withValues(alpha: 0.25),
          width: isResolved ? 1 : 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Student info & Status
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: avatarBg.withValues(alpha: 0.12),
                  child: Text(
                    initial,
                    style: TextStyle(
                      color: avatarBg,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        complaint.studentName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.apartment_rounded,
                              size: 12, color: Color(0xFF007A85)),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              complaint.hostelName,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF007A85),
                                fontWeight: FontWeight.w600,
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
                StatusChip(status: complaint.status),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xFFF1F5F9)),

          // Body: Issue Title & Description
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.report_problem_outlined,
                        size: 16, color: Color(0xFFDC2626)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        complaint.title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ),
                    Text(
                      DateFormat('dd MMM').format(complaint.createdAt),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Text(
                    complaint.description,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF334155),
                      height: 1.45,
                    ),
                  ),
                ),

                // Existing Owner Response (if present)
                if (complaint.ownerResponse != null &&
                    complaint.ownerResponse!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF007A85).withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF007A85).withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.reply_rounded,
                                size: 14, color: Color(0xFF007A85)),
                            SizedBox(width: 4),
                            Text(
                              'Your Response',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF007A85),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          complaint.ownerResponse!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF1E293B),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Action button (Only for pending / in_progress)
          if (!isResolved)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onRespond,
                  icon: const Icon(Icons.reply_rounded,
                      size: 16, color: Colors.white),
                  label: Text(
                    complaint.ownerResponse != null
                        ? 'Update Response'
                        : 'Respond to Resident',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
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
            ),
        ],
      ),
    );
  }
}
