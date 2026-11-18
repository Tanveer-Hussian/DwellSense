// ─────────────────────────────────────────────────────────────────────────────
// FR-6.1: Student submits a rating and written review.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:fyp/controllers/AuthController.dart';
import 'package:fyp/controllers/NotificationController.dart';
import 'package:fyp/controllers/ReviewController.dart';
import 'package:fyp/models/HostelModel.dart';
import 'package:fyp/routes/AppRoutes.dart';
import 'package:fyp/utils/AppColors.dart';
import 'package:fyp/utils/Responsive.dart';
import 'package:fyp/views/shared%20Widgets/CustomButtons.dart';
import 'package:fyp/views/shared%20Widgets/WebSidebarShell.dart';
import 'package:get/get.dart';
import '../shared Widgets/CustomTextField.dart';

class WriteReviewScreen extends StatefulWidget {
  const WriteReviewScreen({super.key});

  @override
  State<WriteReviewScreen> createState() => _WriteReviewScreenState();
}

class _WriteReviewScreenState extends State<WriteReviewScreen> {
  late final String _hostelId;
  late final String _hostelName;

  final ReviewController _reviewCtrl = Get.find<ReviewController>();
  final _commentController = TextEditingController();
  double _selectedRating = 0;

  @override
  void initState() {
    super.initState();
    final arg = Get.arguments;
    if (arg is HostelModel) {
      _hostelId = arg.id;
      _hostelName = arg.name;
    } else {
      _hostelId = arg as String;
      _hostelName = 'Hostel';
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    if (_selectedRating == 0) {
      Get.snackbar('Required', 'Please select a star rating.');
      return;
    }
    if (_commentController.text.trim().length < 10) {
      Get.snackbar('Too Short', 'Please write at least 10 characters.');
      return;
    }
    final success = await _reviewCtrl.submitReview(
      hostelId: _hostelId,
      rating: _selectedRating,
      comment: _commentController.text.trim(),
    );
    if (success) Get.back();
  }

  String _ratingLabel(double r) {
    if (r == 0) return 'Tap a star to rate';
    if (r <= 1) return 'Poor ★';
    if (r <= 2) return 'Fair ★★';
    if (r <= 3) return 'Good ★★★';
    if (r <= 4) return 'Very Good ★★★★';
    return 'Excellent! ★★★★★';
  }

  @override
  Widget build(BuildContext context) {
    final isWide = Responsive.isWide(context);

    if (isWide) return _buildWeb(context);
    return _buildMobile(context);
  }

  // ── Mobile layout ──────────────────────────────────────────────────────────
  Widget _buildMobile(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF111827) : const Color(0xFFF1F5F9);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: bgColor,
      body: Column(
        children: [
          // ── Curved Teal Hero Header ───────────────────────────────────────
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
                padding: const EdgeInsets.fromLTRB(16, 10, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Get.back(),
                          icon: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.3),
                                width: 1.2,
                              ),
                            ),
                            child: const Icon(Icons.arrow_back_rounded,
                                color: Colors.white, size: 20),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Write a Review',
                                style: TextStyle(
                                  fontSize: 21,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              Text(
                                'Share your authentic experience',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: Colors.white.withValues(alpha: 0.85),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.25),
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.rate_review_rounded, color: Colors.white, size: 14),
                              SizedBox(width: 5),
                              Text(
                                'Student',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Hostel indicator pill inside header
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.apartment_rounded, color: Colors.white, size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _hostelName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Verified Stay',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Scrollable Review Form ────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Rating Selection Card ─────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: borderColor),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Overall Rating',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'How was your overall stay at this hostel?',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 16),
                        RatingBar.builder(
                          initialRating: _selectedRating,
                          minRating: 1,
                          glow: false,
                          itemCount: 5,
                          itemSize: 42,
                          itemPadding: const EdgeInsets.symmetric(horizontal: 5),
                          itemBuilder: (_, __) => const Icon(
                            Icons.star_rounded,
                            color: Color(0xFFF59E0B),
                          ),
                          onRatingUpdate: (r) => setState(() => _selectedRating = r),
                        ),
                        const SizedBox(height: 12),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: _selectedRating > 0
                                ? const Color(0xFFFFFBEB)
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _selectedRating > 0
                                  ? const Color(0xFFFDE68A)
                                  : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Text(
                            _ratingLabel(_selectedRating),
                            style: TextStyle(
                              color: _selectedRating > 0
                                  ? const Color(0xFFB45309)
                                  : const Color(0xFF64748B),
                              fontWeight: FontWeight.bold,
                              fontSize: 13.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Review Comment Card ───────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: borderColor),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.edit_note_rounded,
                                color: Color(0xFF007A85), size: 22),
                            SizedBox(width: 8),
                            Text(
                              'Your Written Review',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              ' *',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.error,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Help other students by detailing room condition, facilities, security, wifi, and management.',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: Color(0xFF64748B),
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _commentController,
                          maxLines: 6,
                          maxLength: 500,
                          onChanged: (_) => setState(() {}),
                          style: const TextStyle(fontSize: 14, height: 1.45),
                          decoration: InputDecoration(
                            hintText: 'Share the pros, cons, cleanliness, food, warden behavior, or any tips for new students...',
                            hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                            filled: true,
                            fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: borderColor),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: borderColor),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: Color(0xFF007A85), width: 1.6),
                            ),
                            contentPadding: const EdgeInsets.all(14),
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _commentController.text.trim().length < 10
                                  ? 'Min 10 characters required (${10 - _commentController.text.trim().length} left)'
                                  : '✓ Requirement met',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: _commentController.text.trim().length < 10
                                    ? const Color(0xFFE11D48)
                                    : const Color(0xFF10B981),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── AI Moderation Card ────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00585E).withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF00585E).withValues(alpha: 0.18),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00585E).withValues(alpha: 0.14),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.verified_user_rounded,
                            size: 18,
                            color: Color(0xFF00585E),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'AI Authenticity Check',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: Color(0xFF00585E),
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Every review is analyzed by our NLP detector to prevent spam and preserve trust. Please write honest feedback.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF475569),
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Submit Button ─────────────────────────────────────────
                  Obx(() => Container(
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF00585E), Color(0xFF007A85)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00585E).withValues(alpha: 0.35),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _reviewCtrl.isLoading.value ? null : _submitReview,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: _reviewCtrl.isLoading.value
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.4,
                                  ),
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.send_rounded, size: 18, color: Colors.white),
                                    SizedBox(width: 8),
                                    Text(
                                      'Submit Review',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Web layout ────────────────────────────────────────────────────────────
  Widget _buildWeb(BuildContext context) {
    final authCtrl = Get.find<AuthController>();
    final notifCtrl = Get.find<NotificationController>();
    final isDark = Theme.of(context).brightness == Brightness.dark || Get.isDarkMode;
    final surface = isDark ? const Color(0xFF1E242B) : Colors.white;
    final border = isDark ? const Color(0xFF2C3238) : const Color(0xFFE2E8F0);
    final text = isDark ? Colors.white : const Color(0xFF0F172A);
    final sub = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final fill = isDark ? const Color(0xFF14191E) : const Color(0xFFF8FAFC);

    return WebSidebarShell(
      currentIndex: 0,
      onTap: (_) => Get.offNamed(AppRoutes.studentHome),
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
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 740),
              child: Container(
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                      blurRadius: 24,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── Header ──
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF171C22) : const Color(0xFFF8FAFC),
                        border: Border(bottom: BorderSide(color: border)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                            ),
                            child: const Icon(Icons.star_rounded, color: Colors.amber, size: 26),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Write a Review',
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: text)),
                                const SizedBox(height: 2),
                                Text('Help other students find the right hostel',
                                    style: TextStyle(fontSize: 12.5, color: sub)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
                            ),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              const Icon(Icons.domain_rounded, size: 13, color: AppColors.primary),
                              const SizedBox(width: 5),
                              Text(_hostelName,
                                  style: const TextStyle(
                                      fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
                            ]),
                          ),
                        ],
                      ),
                    ),

                    // ── Body ──
                    Padding(
                      padding: const EdgeInsets.all(28),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left: Rating Panel
                          Expanded(
                            flex: 4,
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF14191E) : const Color(0xFFFFFBEB),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                    color: isDark
                                        ? const Color(0xFF2C3238)
                                        : Colors.amber.withValues(alpha: 0.3)),
                              ),
                              child: Column(
                                children: [
                                  Icon(Icons.hotel_rounded,
                                      size: 36, color: AppColors.primary.withValues(alpha: 0.6)),
                                  const SizedBox(height: 10),
                                  Text(_hostelName,
                                      style: TextStyle(
                                          fontSize: 15, fontWeight: FontWeight.w700, color: text),
                                      textAlign: TextAlign.center),
                                  const SizedBox(height: 6),
                                  Text('Rate your stay', style: TextStyle(fontSize: 12, color: sub)),
                                  const SizedBox(height: 20),
                                  RatingBar.builder(
                                    initialRating: _selectedRating,
                                    minRating: 1,
                                    itemCount: 5,
                                    itemSize: 36,
                                    itemPadding: const EdgeInsets.symmetric(horizontal: 3),
                                    itemBuilder: (_, __) =>
                                        const Icon(Icons.star_rounded, color: Colors.amber),
                                    onRatingUpdate: (r) => setState(() => _selectedRating = r),
                                  ),
                                  const SizedBox(height: 12),
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding:
                                        const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: _selectedRating > 0
                                          ? Colors.amber.withValues(alpha: 0.15)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      _ratingLabel(_selectedRating),
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w700,
                                        color: _selectedRating > 0 ? Colors.amber.shade700 : sub,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  // Quick rating hints
                                  ...['Poor', 'Fair', 'Good', 'Very Good', 'Excellent'].asMap().entries.map((e) {
                                    final idx = e.key + 1;
                                    final active = _selectedRating == idx.toDouble();
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 2),
                                      child: Row(children: [
                                        Icon(Icons.star_rounded,
                                            size: 12,
                                            color: active ? Colors.amber : sub.withValues(alpha: 0.4)),
                                        const SizedBox(width: 6),
                                        Text('$idx – ${e.value}',
                                            style: TextStyle(
                                              fontSize: 11.5,
                                              color: active ? Colors.amber.shade700 : sub,
                                              fontWeight: active ? FontWeight.w700 : FontWeight.normal,
                                            )),
                                      ]),
                                    );
                                  }),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 20),

                          // Right: Review text + submit
                          Expanded(
                            flex: 6,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Your Review',
                                    style: TextStyle(
                                        fontSize: 13.5, fontWeight: FontWeight.w700, color: text)),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _commentController,
                                  maxLines: 7,
                                  maxLength: 500,
                                  style: TextStyle(fontSize: 13.5, color: text),
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: fill,
                                    hintText:
                                        'Describe your experience with facilities, cleanliness, management, food, and overall environment...',
                                    hintStyle: TextStyle(color: sub, fontSize: 13),
                                    counterStyle: TextStyle(color: sub, fontSize: 11),
                                    contentPadding: const EdgeInsets.all(14),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: border),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide:
                                          const BorderSide(color: AppColors.primary, width: 2),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                // AI moderation notice
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.info.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                        color: AppColors.info.withValues(alpha: 0.2)),
                                  ),
                                  child: Row(children: [
                                    const Icon(Icons.smart_toy_outlined,
                                        size: 16, color: AppColors.info),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Reviews are moderated by our AI system to ensure quality.',
                                        style: TextStyle(fontSize: 12, color: sub),
                                      ),
                                    ),
                                  ]),
                                ),
                                const SizedBox(height: 20),
                                // Buttons
                                Row(
                                  children: [
                                    OutlinedButton(
                                      onPressed: () => Get.back(),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: sub,
                                        side: BorderSide(color: border),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 20, vertical: 13),
                                        shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10)),
                                      ),
                                      child: const Text('Cancel',
                                          style: TextStyle(fontWeight: FontWeight.w600)),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Obx(() => ElevatedButton.icon(
                                            onPressed: _reviewCtrl.isLoading.value
                                                ? null
                                                : _submitReview,
                                            icon: _reviewCtrl.isLoading.value
                                                ? const SizedBox(
                                                    width: 15,
                                                    height: 15,
                                                    child: CircularProgressIndicator(
                                                        strokeWidth: 2, color: Colors.white))
                                                : const Icon(Icons.star_rounded, size: 17),
                                            label: Text(
                                              _reviewCtrl.isLoading.value
                                                  ? 'Submitting...'
                                                  : 'Submit Review',
                                              style: const TextStyle(fontWeight: FontWeight.w700),
                                            ),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppColors.primary,
                                              foregroundColor: Colors.white,
                                              padding: const EdgeInsets.symmetric(vertical: 13),
                                              shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(10)),
                                              elevation: 0,
                                            ),
                                          )),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
