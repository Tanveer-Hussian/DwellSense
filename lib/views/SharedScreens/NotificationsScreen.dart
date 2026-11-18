import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fyp/controllers/NotificationController.dart';
import 'package:fyp/models/NotificationModel.dart';
import 'package:fyp/utils/AppColors.dart';
import 'package:get/get.dart';

// FR-9.x: Displays in-app notifications for all roles (Admin, Owner, Student).
// ─────────────────────────────────────────────────────────────────────────────

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  // Mobile filter: 0 = All, 1 = Unread, 2 = Bookings, 3 = Complaints
  int _selectedFilter = 0;

  // ── Helpers ────────────────────────────────────────────────────────────────
  Color _typeColor(String type) {
    switch (type.toLowerCase()) {
      case 'booking':
        return const Color(0xFF007A85); // Teal
      case 'complaint':
        return const Color(0xFFF59E0B); // Amber
      case 'review':
        return const Color(0xFF8B5CF6); // Purple
      case 'warning':
      case 'error':
        return const Color(0xFFEF4444); // Red
      default:
        return const Color(0xFF2563EB); // Blue
    }
  }

  IconData _typeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'booking':
        return Icons.calendar_today_rounded;
      case 'complaint':
        return Icons.report_problem_rounded;
      case 'review':
        return Icons.star_rounded;
      case 'warning':
      case 'error':
        return Icons.warning_amber_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 7) return '${(diff.inDays / 7).round()}w ago';
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<NotificationController>();
    if (kIsWeb) return _buildWeb(context, ctrl);
    return _buildMobile(context, ctrl);
  }

  // ── Modern Mobile Layout (All Panels: Admin, Owner, Student) ────────────────
  Widget _buildMobile(BuildContext context, NotificationController ctrl) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF111827) : const Color(0xFFF8FAFC);

    return Scaffold(
      backgroundColor: bgColor,
      body: Obx(() {
        final allNotifs = ctrl.notifications;
        final unreadCount = allNotifs.where((n) => !n.isRead).length;

        // Apply selected filter
        final filteredNotifs = allNotifs.where((n) {
          if (_selectedFilter == 1) return !n.isRead;
          if (_selectedFilter == 2) return n.type.toLowerCase() == 'booking';
          if (_selectedFilter == 3) return n.type.toLowerCase() == 'complaint';
          return true;
        }).toList();

        return CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // ── 1. Curved Hero Header ───────────────────────────────────────
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
                  16,
                  MediaQuery.of(context).padding.top + 12,
                  16,
                  22,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Bar
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                          onPressed: () => Navigator.of(context).maybePop(),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Notifications',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Updates, alerts & activity',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (unreadCount > 0)
                          TextButton.icon(
                            onPressed: ctrl.markAllAsRead,
                            icon: const Icon(Icons.done_all_rounded, size: 16, color: Colors.white),
                            label: const Text(
                              'Mark all read',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.white.withValues(alpha: 0.2),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Filter Pills
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildMobileFilterPill(0, 'All', allNotifs.length),
                          const SizedBox(width: 8),
                          _buildMobileFilterPill(1, 'Unread', unreadCount,
                              accentColor: const Color(0xFFEF4444)),
                          const SizedBox(width: 8),
                          _buildMobileFilterPill(
                            2,
                            'Bookings',
                            allNotifs.where((n) => n.type.toLowerCase() == 'booking').length,
                          ),
                          const SizedBox(width: 8),
                          _buildMobileFilterPill(
                            3,
                            'Complaints',
                            allNotifs.where((n) => n.type.toLowerCase() == 'complaint').length,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── 2. Content List or Empty State ──────────────────────────────
            if (filteredNotifs.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final notif = filteredNotifs[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _buildModernMobileCard(notif, ctrl, isDark),
                      );
                    },
                    childCount: filteredNotifs.length,
                  ),
                ),
              )
            else
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.all(24),
                  padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
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
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF007A85).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.notifications_none_rounded,
                          size: 46,
                          color: Color(0xFF007A85),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        _selectedFilter == 1
                            ? 'No Unread Notifications'
                            : "You're All Caught Up!",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _selectedFilter == 1
                            ? 'All received notifications have been marked as read.'
                            : 'New notifications and alerts will show up here.',
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

  Widget _buildMobileFilterPill(int index, String label, int count,
      {Color? accentColor}) {
    final isSelected = _selectedFilter == index;

    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.16),
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
                    ? (accentColor ?? const Color(0xFF007A85)).withValues(alpha: 0.15)
                    : Colors.white.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isSelected
                      ? (accentColor ?? const Color(0xFF007A85))
                      : Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernMobileCard(
      NotificationModel n, NotificationController ctrl, bool isDark) {
    final accent = _typeColor(n.type);

    return Dismissible(
      key: Key(n.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => ctrl.markAsRead(n.id),
      background: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF007A85),
          borderRadius: BorderRadius.circular(18),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.check_rounded, color: Colors.white, size: 24),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: n.isRead ? Colors.white : const Color(0xFFF0FDFC),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: n.isRead
                ? const Color(0xFFE2E8F0)
                : accent.withValues(alpha: 0.35),
            width: n.isRead ? 1 : 1.3,
          ),
          boxShadow: [
            BoxShadow(
              color: n.isRead
                  ? Colors.black.withValues(alpha: 0.02)
                  : accent.withValues(alpha: 0.06),
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
            onTap: () => ctrl.markAsRead(n.id),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon badge
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(_typeIcon(n.type), color: accent, size: 22),
                  ),
                  const SizedBox(width: 12),

                  // Text content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: accent.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                n.type.capitalize ?? n.type,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: accent,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              _timeAgo(n.createdAt),
                              style: TextStyle(
                                fontSize: 11,
                                color: n.isRead
                                    ? const Color(0xFF94A3B8)
                                    : const Color(0xFF007A85),
                                fontWeight: n.isRead
                                    ? FontWeight.normal
                                    : FontWeight.bold,
                              ),
                            ),
                            if (!n.isRead) ...[
                              const SizedBox(width: 6),
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: accent,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          n.title,
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: n.isRead
                                ? FontWeight.w600
                                : FontWeight.bold,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          n.body,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: Color(0xFF475569),
                            height: 1.4,
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
    );
  }

  // ── Web Layout (Preserved 100% Unchanged) ───────────────────────────────────
  Widget _buildWeb(BuildContext context, NotificationController ctrl) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pageBg = isDark ? const Color(0xFF0F171E) : const Color(0xFFF6F8FA);
    final cardBg = isDark ? const Color(0xFF14202E) : Colors.white;
    final cardBorder = isDark ? const Color(0xFF223242) : const Color(0xFFE2E8F0);
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    const teal = Color(0xFF2DD4BF);

    return Scaffold(
      backgroundColor: pageBg,
      body: Obx(() {
        final notifications = ctrl.notifications;
        final unread = notifications.where((n) => !n.isRead).length;

        return Column(
          children: [
            // ── Header bar ──────────────────────────────────────────────────
            Container(
              color: cardBg,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: textPrimary),
                    onPressed: () => Get.back(),
                    tooltip: 'Back',
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.notifications_outlined, color: teal, size: 22),
                  const SizedBox(width: 10),
                  Text(
                    'Notifications',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: textPrimary),
                  ),
                  if (unread > 0) ...[
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: teal.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: teal.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        '$unread unread',
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: teal),
                      ),
                    ),
                  ],
                  const Spacer(),
                  if (notifications.isNotEmpty)
                    TextButton.icon(
                      icon: const Icon(Icons.done_all, size: 16),
                      label: const Text('Mark all read'),
                      style: TextButton.styleFrom(foregroundColor: teal),
                      onPressed: ctrl.markAllAsRead,
                    ),
                ],
              ),
            ),
            Container(height: 1, color: cardBorder),

            // ── Notification list ────────────────────────────────────────────
            Expanded(
              child: notifications.isEmpty
                  ? _webEmptyState(textSecondary)
                  : Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 820),
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(
                              vertical: 24, horizontal: 16),
                          itemCount: notifications.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (_, i) => _webNotifCard(
                            notifications[i],
                            ctrl,
                            isDark,
                            cardBg,
                            cardBorder,
                            textPrimary,
                            textSecondary,
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        );
      }),
    );
  }

  Widget _webEmptyState(Color textSecondary) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: const Color(0xFF2DD4BF).withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.notifications_off_outlined,
                size: 48, color: Color(0xFF2DD4BF)),
          ),
          const SizedBox(height: 20),
          Text(
            "You're all caught up!",
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textSecondary),
          ),
          const SizedBox(height: 6),
          Text(
            'No notifications yet.',
            style: TextStyle(
                fontSize: 13, color: textSecondary.withValues(alpha: 0.7)),
          ),
        ],
      ),
    );
  }

  Widget _webNotifCard(
    NotificationModel n,
    NotificationController ctrl,
    bool isDark,
    Color cardBg,
    Color cardBorder,
    Color textPrimary,
    Color textSecondary,
  ) {
    final accent = _typeColor(n.type);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => ctrl.markAsRead(n.id),
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: n.isRead
                ? cardBg
                : (isDark
                    ? const Color(0xFF162032)
                    : const Color(0xFFF0FDFC)),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: n.isRead ? cardBorder : accent.withValues(alpha: 0.4),
              width: n.isRead ? 1 : 1.5,
            ),
            boxShadow: n.isRead
                ? null
                : [
                    BoxShadow(
                        color: accent.withValues(alpha: 0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2))
                  ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_typeIcon(n.type), color: accent, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            n.type.capitalize ?? n.type,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: accent,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _timeAgo(n.createdAt),
                          style: TextStyle(fontSize: 11, color: textSecondary),
                        ),
                        if (!n.isRead) ...[
                          const SizedBox(width: 8),
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: accent,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                    color: accent.withValues(alpha: 0.5),
                                    blurRadius: 4)
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      n.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight:
                            n.isRead ? FontWeight.w500 : FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      n.body,
                      style: TextStyle(
                          fontSize: 13, color: textSecondary, height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              if (!n.isRead)
                Tooltip(
                  message: 'Mark as read',
                  child: InkWell(
                    onTap: () => ctrl.markAsRead(n.id),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.check, size: 15, color: accent),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
