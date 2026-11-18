import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fyp/controllers/ReviewController.dart';
import 'package:fyp/models/ReviewModel.dart';
import 'package:fyp/routes/AppRoutes.dart';
import 'package:fyp/utils/AppColors.dart';
import 'package:fyp/utils/Responsive.dart';
import 'package:fyp/views/admin/AdminSettingsScreen.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class ReviewsTab extends StatefulWidget {
  final ReviewController reviewCtrl;
  const ReviewsTab({required this.reviewCtrl, super.key});

  @override
  State<ReviewsTab> createState() => _ReviewsTabState();
}

class _ReviewsTabState extends State<ReviewsTab> {
  String _filter = 'all'; // 'all' | 'flagged' | 'high' | 'low'
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

  List<ReviewModel> _applyFilters(List<ReviewModel> list) {
    final q = _searchQuery.toLowerCase().trim();
    return list.where((r) {
      bool matchesFilter = true;
      if (_filter == 'flagged') {
        matchesFilter = r.isFlagged;
      } else if (_filter == 'high') {
        matchesFilter = r.rating >= 4.0;
      } else if (_filter == 'low') {
        matchesFilter = r.rating <= 2.0;
      }

      final matchesSearch = q.isEmpty ||
          r.studentName.toLowerCase().contains(q) ||
          r.comment.toLowerCase().contains(q) ||
          (r.flagReason?.toLowerCase().contains(q) ?? false) ||
          r.hostelId.toLowerCase().contains(q);

      return matchesFilter && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb && !Responsive.isWide(context)) {
      return _buildMobileLayout();
    }
    return _buildWebLayout();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // WEB LAYOUT: Preserved and clean
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildWebLayout() {
    return Obx(() {
      final flagged = widget.reviewCtrl.flaggedReviews.toList();

      if (flagged.isEmpty) {
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.verified_outlined, size: 64, color: AppColors.success),
              SizedBox(height: 16),
              Text('No flagged reviews!',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: flagged.length,
        itemBuilder: (_, i) {
          final review = flagged[i];
          return Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            margin: const EdgeInsets.only(bottom: 14),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.flag_outlined, size: 16, color: AppColors.error),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            review.flagReason ?? 'Flagged by AI detector',
                            style: const TextStyle(
                              color: AppColors.error,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: AppColors.primaryLight,
                        child: Text(
                          review.studentName.isNotEmpty
                              ? review.studentName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(review.studentName,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 14)),
                          Text('Rating: ${review.rating}/5',
                              style: const TextStyle(
                                  color: AppColors.textSecondary, fontSize: 12)),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        DateFormat('MMM d, yyyy').format(review.createdAt),
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(review.comment, style: const TextStyle(fontSize: 14, height: 1.4)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => widget.reviewCtrl.approveReview(review.id, hostelId: review.hostelId, rating: review.rating),
                        icon: const Icon(Icons.check_circle_outline, size: 16),
                        label: const Text('Approve'),
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: () => widget.reviewCtrl.deleteReview(review.id),
                        icon: const Icon(Icons.delete_outline, size: 16),
                        label: const Text('Remove'),
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    });
  }

  // ─────────────────────────────────────────────────────────────────────────
  // MOBILE REDESIGN: Hero Curved Header, Filter Pills, Modern Cards
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildMobileLayout() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF111827) : const Color(0xFFF1F5F9);

    return Scaffold(
      backgroundColor: bgColor,
      body: Obx(() {
        final all = widget.reviewCtrl.flaggedReviews.toList();
        final flaggedCount = all.where((r) => r.isFlagged).length;
        final highRatingCount = all.where((r) => r.rating >= 4.0).length;
        final lowRatingCount = all.where((r) => r.rating <= 2.0).length;

        final filtered = _applyFilters(all);

        return Column(
          children: [
            // ── Curved Teal Hero Header ──────────────────────────────────────
            _buildMobileCurvedHeader(
              totalCount: all.length,
              flaggedCount: flaggedCount,
            ),

            // ── Filter Pills Row ─────────────────────────────────────────────
            _buildMobileFilterPills(
              totalCount: all.length,
              flaggedCount: flaggedCount,
              highCount: highRatingCount,
              lowCount: lowRatingCount,
            ),

            // ── Review Cards List ────────────────────────────────────────────
            Expanded(
              child: filtered.isEmpty
                  ? _buildMobileEmptyState()
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                      itemCount: filtered.length,
                      itemBuilder: (ctx, i) => _MobileModernReviewCard(
                        review: filtered[i],
                        onApprove: () => _confirmApprove(filtered[i]),
                        onDelete: () => _confirmDelete(filtered[i]),
                      ),
                    ),
            ),
          ],
        );
      }),
    );
  }

  // ── Mobile Header ─────────────────────────────────────────────────────────
  Widget _buildMobileCurvedHeader({
    required int totalCount,
    required int flaggedCount,
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
                    child: const Icon(Icons.rate_review_rounded,
                        color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Reviews Moderation',
                          style: TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: -0.3,
                          ),
                        ),
                        Text(
                          '$totalCount reviews · $flaggedCount flagged',
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
                    hintText: 'Search student, comment, reason...',
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

  // ── Mobile Filter Pills ───────────────────────────────────────────────────
  Widget _buildMobileFilterPills({
    required int totalCount,
    required int flaggedCount,
    required int highCount,
    required int lowCount,
  }) {
    final pills = [
      {'key': 'all', 'label': 'All', 'count': totalCount},
      {'key': 'flagged', 'label': 'AI Flagged', 'count': flaggedCount},
      {'key': 'high', 'label': 'High (4-5★)', 'count': highCount},
      {'key': 'low', 'label': 'Low (1-2★)', 'count': lowCount},
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

  // ── Mobile Empty State ────────────────────────────────────────────────────
  Widget _buildMobileEmptyState() {
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
                Icons.rate_review_outlined,
                size: 40,
                color: Color(0xFF00585E),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No reviews found',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'No reviews match your selected filter or search query.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
    );
  }

  // ── Confirmation Dialogs ──────────────────────────────────────────────────
  void _confirmApprove(ReviewModel review) {
    Get.defaultDialog(
      title: 'Approve Review',
      titleStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
      content: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Text(
          'Are you sure you want to approve this review by "${review.studentName}" and clear its flag?',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13.5, color: Color(0xFF475569)),
        ),
      ),
      textConfirm: 'Approve',
      confirmTextColor: Colors.white,
      buttonColor: AppColors.success,
      textCancel: 'Cancel',
      cancelTextColor: const Color(0xFF64748B),
      onConfirm: () {
        Get.back();
        widget.reviewCtrl.approveReview(review.id, hostelId: review.hostelId, rating: review.rating);
      },
    );
  }

  void _confirmDelete(ReviewModel review) {
    Get.defaultDialog(
      title: 'Remove Review',
      titleStyle: const TextStyle(
          fontWeight: FontWeight.bold, fontSize: 17, color: AppColors.error),
      content: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Text(
          'Are you sure you want to permanently remove this review by "${review.studentName}"?',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13.5, color: Color(0xFF475569)),
        ),
      ),
      textConfirm: 'Remove',
      confirmTextColor: Colors.white,
      buttonColor: AppColors.error,
      textCancel: 'Cancel',
      cancelTextColor: const Color(0xFF64748B),
      onConfirm: () {
        Get.back();
        widget.reviewCtrl.deleteReview(review.id);
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Modern Card for Mobile Reviews Moderation
// ─────────────────────────────────────────────────────────────────────────────
class _MobileModernReviewCard extends StatelessWidget {
  final ReviewModel review;
  final VoidCallback onApprove;
  final VoidCallback onDelete;

  const _MobileModernReviewCard({
    required this.review,
    required this.onApprove,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final dateStr = DateFormat('MMM d, yyyy · h:mm a').format(review.createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: review.isFlagged
              ? AppColors.error.withValues(alpha: 0.35)
              : const Color(0xFFE2E8F0),
          width: review.isFlagged ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
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
            // ── AI Flag Banner (if flagged) ──────────────────────────────────
            if (review.isFlagged)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: AppColors.error, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        review.flagReason ?? 'Suspicious review flagged by AI',
                        style: const TextStyle(
                          color: AppColors.error,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // ── Header: Student Info + Star Rating Badge ─────────────────────
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: const Color(0xFF00585E).withValues(alpha: 0.12),
                  backgroundImage: review.studentImage != null &&
                          review.studentImage!.isNotEmpty
                      ? NetworkImage(review.studentImage!)
                      : null,
                  child: review.studentImage == null ||
                          review.studentImage!.isEmpty
                      ? Text(
                          review.studentName.isNotEmpty
                              ? review.studentName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: Color(0xFF00585E),
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review.studentName.isNotEmpty
                            ? review.studentName
                            : 'Anonymous Student',
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        dateStr,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ),
                // Star rating pill
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 4.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star_rounded,
                          size: 16, color: Color(0xFFF59E0B)),
                      const SizedBox(width: 4),
                      Text(
                        review.rating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFB45309),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ── Review Comment ───────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFE2E8F0),
                ),
              ),
              child: Text(
                review.comment.isNotEmpty
                    ? review.comment
                    : '(No comment written)',
                style: const TextStyle(
                  fontSize: 13.5,
                  height: 1.45,
                  color: Color(0xFF334155),
                ),
              ),
            ),

            const SizedBox(height: 14),

            // ── Action Buttons ───────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onApprove,
                    icon: const Icon(Icons.check_circle_outline_rounded,
                        size: 16, color: Color(0xFF10B981)),
                    label: const Text(
                      'Approve',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF10B981),
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      side: const BorderSide(color: Color(0xFF10B981), width: 1.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline_rounded,
                        size: 16, color: AppColors.error),
                    label: const Text(
                      'Remove',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.error,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      side: const BorderSide(color: AppColors.error, width: 1.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
