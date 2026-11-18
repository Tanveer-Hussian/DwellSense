import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fyp/controllers/AuthController.dart';
import 'package:fyp/controllers/HostelController.dart';
import 'package:fyp/models/BookingModel.dart';
import 'package:fyp/models/UserModel.dart';
import 'package:fyp/routes/AppRoutes.dart';
import 'package:fyp/services/AuthService.dart';
import 'package:fyp/services/BookingService.dart';
import 'package:fyp/utils/AppColors.dart';
import 'package:fyp/views/admin/AdminSettingsScreen.dart';
import 'package:fyp/views/admin/widgets/AdminStatCard.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' hide TextDirection;

class OverviewTab extends StatelessWidget {
  final HostelController hostelCtrl;
  final AuthController authCtrl = Get.find<AuthController>();
  final BookingService bookingService = Get.find<BookingService>();
  final AuthService authService = Get.find<AuthService>();

  OverviewTab({required this.hostelCtrl, super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  /// Calculates Month-over-Month (MoM) growth based on creation timestamps.
  /// Compares items created in the current month vs. the previous month.
  /// Formula: ((currentMonth - prevMonth) / prevMonth) * 100
  static String _calculateGrowth(List<DateTime> dates) {
    if (dates.isEmpty) return '0% this mo';

    final now = DateTime.now();
    final currentYear = now.year;
    final currentMonth = now.month;

    // Previous month (adjusts for year rollover in January)
    final prevMonth = currentMonth == 1 ? 12 : currentMonth - 1;
    final prevYear = currentMonth == 1 ? currentYear - 1 : currentYear;

    int thisMonthCount = 0;
    int prevMonthCount = 0;

    for (final date in dates) {
      if (date.year == currentYear && date.month == currentMonth) {
        thisMonthCount++;
      } else if (date.year == prevYear && date.month == prevMonth) {
        prevMonthCount++;
      }
    }

    if (prevMonthCount == 0) {
      if (thisMonthCount > 0) {
        return '↑ +$thisMonthCount new this mo';
      }
      return '0% this mo';
    }

    final double growthPct = ((thisMonthCount - prevMonthCount) / prevMonthCount) * 100;
    if (growthPct > 0) {
      final formatted = growthPct.toStringAsFixed(growthPct.truncateToDouble() == growthPct ? 0 : 1);
      return '↑ +$formatted% this mo';
    } else if (growthPct < 0) {
      final formatted = growthPct.abs().toStringAsFixed(growthPct.truncateToDouble() == growthPct ? 0 : 1);
      return '↓ -$formatted% this mo';
    } else {
      return '↑ +0% this mo';
    }
  }

  /// Calculates real activity data points for the last 7 days
  static List<double> _calculateLast7DaysData(List<DateTime> dates) {
    final now = DateTime.now();
    final values = List<double>.filled(7, 0.0);
    for (int i = 0; i < 7; i++) {
      final day = DateTime(now.year, now.month, now.day).subtract(Duration(days: 6 - i));
      final nextDay = day.add(const Duration(days: 1));
      final count = dates.where((d) => d.isAfter(day) && d.isBefore(nextDay)).length;
      values[i] = count.toDouble();
    }
    return values;
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return _buildWebLayout(context);
    }
    return _buildMobileLayout(context);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // WEB REDESIGN: Exact reproduction of the high-fidelity dashboard layout
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildWebLayout(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final webBg = isDark ? const Color(0xFF0F171E) : const Color(0xFFF6F8FA);

    return Container(
      color: webBg,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── 1. Top Hero Welcome Banner with Architecture Illustration ──
                _buildWebHeroBanner(isDark),
                const SizedBox(height: 22),

                // ── 2. Four Modern KPI Stat Cards Row ─────────────────────────
                _buildWebStatCardsRow(isDark),
                const SizedBox(height: 22),

                // ── 3. Bottom Row: Quick Overview (Chart) & System Status ─────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Quick Overview with Line Chart
                    Expanded(
                      flex: 6,
                      child: _buildQuickOverviewCard(isDark),
                    ),
                    const SizedBox(width: 20),

                    // System Status Card
                    Expanded(
                      flex: 4,
                      child: _buildSystemStatusCard(isDark),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWebHeroBanner(bool isDark) {
    return Container(
      constraints: const BoxConstraints(minHeight: 175),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  const Color(0xFF0F262C),
                  const Color(0xFF13202E),
                  const Color(0xFF162534),
                ]
              : [
                  const Color(0xFF004D56),
                  const Color(0xFF006670),
                  const Color(0xFF007A87),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? const Color(0xFF223242) : Colors.white.withValues(alpha: 0.15),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            // Left Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      const Text('👋', style: TextStyle(fontSize: 24)),
                      const SizedBox(width: 10),
                      Text(
                        _getGreeting(),
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Admin',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "Here's what's happening with your system today.",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),

            // Right Architectural Building Illustration
            Positioned(
              right: 28,
              top: 0,
              bottom: 0,
              child: Center(
                child: _buildBuildingIllustration(isDark),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBuildingIllustration(bool isDark) {
    return Container(
      width: 250,
      height: 120,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          // Left smaller building block
          Expanded(
            flex: 2,
            child: Container(
              height: 75,
              decoration: BoxDecoration(
                color: const Color(0xFF1E3545),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.teal.withValues(alpha: 0.3)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _windowRow(2),
                  _windowRow(2),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Main hostel block
          Expanded(
            flex: 3,
            child: Container(
              height: 95,
              decoration: BoxDecoration(
                color: const Color(0xFF244358),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF2DD4BF).withValues(alpha: 0.4)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _windowRow(3),
                  _windowRow(3),
                  _windowRow(3),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Ambient trees / moon
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.teal.withValues(alpha: 0.2),
                ),
                child: const Icon(Icons.nightlight_round, color: Color(0xFF2DD4BF), size: 16),
              ),
              const SizedBox(height: 10),
              const Icon(Icons.park_rounded, color: Color(0xFF10B981), size: 24),
            ],
          ),
        ],
      ),
    );
  }

  Widget _windowRow(int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(
        count,
        (_) => Container(
          width: 10,
          height: 12,
          decoration: BoxDecoration(
            color: const Color(0xFFFEF08A), // Warm glowing window light
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }

  Widget _buildWebStatCardsRow(bool isDark) {
    return LayoutBuilder(builder: (context, constraints) {
      return Row(
        children: [
          // Registered Hostels with dynamic MoM growth
          Expanded(
            child: Obx(() {
              final hostels = hostelCtrl.allHostels;
              final dates = hostels.map((h) => h.createdAt).toList();
              return _WebStatKpiCard(
                title: 'Registered Hostels',
                value: '${hostels.length}',
                trend: _calculateGrowth(dates),
                icon: Icons.home_rounded,
                accentColor: const Color(0xFF14B8A6),
                isDark: isDark,
              );
            }),
          ),
          const SizedBox(width: 16),

          // Approved Hostels with dynamic MoM growth
          Expanded(
            child: Obx(() {
              final approved = hostelCtrl.allHostels.where((h) => h.status == "approved").toList();
              final dates = approved.map((h) => h.createdAt).toList();
              return _WebStatKpiCard(
                title: 'Approved Hostels',
                value: '${approved.length}',
                trend: _calculateGrowth(dates),
                icon: Icons.verified_user_rounded,
                accentColor: const Color(0xFF22C55E),
                isDark: isDark,
              );
            }),
          ),
          const SizedBox(width: 16),

          // Total Bookings with dynamic MoM growth
          Expanded(
            child: StreamBuilder<List<BookingModel>>(
              stream: bookingService.getAllBookingsStream(),
              builder: (context, snapshot) {
                final bookings = snapshot.data ?? [];
                final dates = bookings.map((b) => b.createdAt).toList();
                return _WebStatKpiCard(
                  title: 'Total Bookings',
                  value: '${bookings.length}',
                  trend: _calculateGrowth(dates),
                  icon: Icons.bookmark_rounded,
                  accentColor: const Color(0xFF3B82F6),
                  isDark: isDark,
                );
              },
            ),
          ),
          const SizedBox(width: 16),

          // Total Accounts with dynamic MoM growth
          Expanded(
            child: StreamBuilder<List<UserModel>>(
              stream: authService.getAllUsersStream(),
              builder: (context, snapshot) {
                final users = snapshot.data ?? [];
                final dates = users.map((u) => u.createdAt).toList();
                return _WebStatKpiCard(
                  title: 'Total Accounts',
                  value: '${users.length}',
                  trend: _calculateGrowth(dates),
                  icon: Icons.people_alt_rounded,
                  accentColor: const Color(0xFFF97316),
                  isDark: isDark,
                );
              },
            ),
          ),
        ],
      );
    });
  }

  Widget _buildQuickOverviewCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF14202E) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF223242) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF14B8A6).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.bar_chart_rounded, color: Color(0xFF14B8A6), size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                'Quick Overview',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {},
                child: const Row(
                  children: [
                    Text(
                      'View Details',
                      style: TextStyle(
                        color: Color(0xFF14B8A6),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward_rounded, color: Color(0xFF14B8A6), size: 15),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Line Chart with real activity data
          SizedBox(
            height: 190,
            child: StreamBuilder<List<BookingModel>>(
              stream: bookingService.getAllBookingsStream(),
              builder: (context, snapshot) {
                final bookings = snapshot.data ?? [];
                final dates = bookings.map((b) => b.createdAt).toList();
                final realData = _calculateLast7DaysData(dates);
                return _OverviewLineChart(
                  isDark: isDark,
                  weeklyData: realData,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemStatusCard(bool isDark) {
    final nowFormatted = DateFormat('h:mm a').format(DateTime.now());

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF14202E) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF223242) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.bolt_rounded, color: Color(0xFFF59E0B), size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                'System Status',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Operational banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF22C55E).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFF22C55E).withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Color(0xFF22C55E),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_rounded, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'All Systems Operational',
                        style: TextStyle(
                          color: Color(0xFF22C55E),
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Everything is running smoothly.',
                        style: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Footer info tiles
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(Icons.access_time_rounded,
                        size: 20,
                        color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Last Updated',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Today, $nowFormatted',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Row(
                  children: [
                    Icon(Icons.dns_rounded,
                        size: 20,
                        color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Uptime',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          '99.9%',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF22C55E),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // MOBILE LAYOUT — Modern redesign mirroring the web dashboard
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildMobileLayout(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Column(
        children: [
          // ── Curved Teal Hero Header ──────────────────────────────────────
          _MobileAdminHeader(
            greeting: _getGreeting(),
            onNotificationTap: () => Get.toNamed(AppRoutes.notifications),
            onProfileTap: () => kIsWeb
                ? Get.toNamed(AppRoutes.profile)
                : Get.to(() => const AdminSettingsScreen()),
          ),
          // ── Scrollable Body ──────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  // ── KPI Cards horizontal scroll ──────────────────────
                  _buildMobileKpiRow(),
                  const SizedBox(height: 24),
                  // ── Pending Approvals ────────────────────────────────
                  _buildSectionLabel('Pending Approvals'),
                  const SizedBox(height: 12),
                  _buildMobilePendingApprovals(context),
                  const SizedBox(height: 24),
                  // ── System Status ────────────────────────────────────
                  _buildSectionLabel('System Status'),
                  const SizedBox(height: 12),
                  _buildMobileSystemStatus(),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: Color(0xFF0F172A),
        letterSpacing: -0.2,
      ),
    );
  }

  Widget _buildMobileKpiRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          Obx(() {
            final count = hostelCtrl.allHostels.length;
            return _MobileKpiCard(
              label: 'Total Hostels',
              value: '$count',
              icon: Icons.home_rounded,
              accentColor: const Color(0xFF14B8A6),
            );
          }),
          const SizedBox(width: 12),
          Obx(() {
            final pending = hostelCtrl.allHostels.where((h) => h.status == 'pending').length;
            return _MobileKpiCard(
              label: 'Pending',
              value: '$pending',
              icon: Icons.hourglass_top_rounded,
              accentColor: const Color(0xFFF97316),
            );
          }),
          const SizedBox(width: 12),
          StreamBuilder<List<BookingModel>>(
            stream: bookingService.getAllBookingsStream(),
            builder: (context, snapshot) {
              final count = snapshot.data?.length ?? 0;
              return _MobileKpiCard(
                label: 'Bookings',
                value: '$count',
                icon: Icons.bookmark_rounded,
                accentColor: const Color(0xFF3B82F6),
              );
            },
          ),
          const SizedBox(width: 12),
          StreamBuilder<List<UserModel>>(
            stream: authService.getAllUsersStream(),
            builder: (context, snapshot) {
              final count = snapshot.data?.length ?? 0;
              return _MobileKpiCard(
                label: 'Accounts',
                value: '$count',
                icon: Icons.people_alt_rounded,
                accentColor: const Color(0xFF8B5CF6),
              );
            },
          ),
          const SizedBox(width: 12),
          Obx(() {
            final approved = hostelCtrl.allHostels.where((h) => h.status == 'approved').length;
            return _MobileKpiCard(
              label: 'Approved',
              value: '$approved',
              icon: Icons.verified_rounded,
              accentColor: const Color(0xFF22C55E),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMobileQuickActions(BuildContext context) {
    final actions = [
      _QuickAction(label: 'Hostels', icon: Icons.domain_rounded, color: const Color(0xFF14B8A6)),
      _QuickAction(label: 'Users', icon: Icons.people_rounded, color: const Color(0xFF3B82F6)),
      _QuickAction(label: 'Complaints', icon: Icons.report_problem_rounded, color: const Color(0xFFF97316)),
      _QuickAction(label: 'Reviews', icon: Icons.star_rounded, color: const Color(0xFFF59E0B)),
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.85,
      ),
      itemCount: actions.length,
      itemBuilder: (context, i) {
        final a = actions[i];
        return GestureDetector(
          onTap: () {},
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: a.color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(a.icon, color: a.color, size: 22),
                ),
                const SizedBox(height: 8),
                Text(
                  a.label,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF334155),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMobilePendingApprovals(BuildContext context) {
    return Obx(() {
      final pending = hostelCtrl.allHostels.where((h) => h.status == 'pending').toList();
      if (pending.isEmpty) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Color(0xFF22C55E), size: 28),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'No pending approvals — all hostels are reviewed!',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        );
      }
      final display = pending.take(3).toList();
      return Column(
        children: [
          ...display.map((hostel) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.home_work_rounded, color: Color(0xFFF97316), size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hostel.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0F172A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        hostel.address,
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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFFED7AA)),
                  ),
                  child: const Text(
                    'Pending',
                    style: TextStyle(
                      color: Color(0xFFEA580C),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          )),
          if (pending.length > 3)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '+ ${pending.length - 3} more pending',
                style: const TextStyle(
                  color: Color(0xFF007A85),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      );
    });
  }

  Widget _buildMobileSystemStatus() {
    final nowFormatted = DateFormat('h:mm a').format(DateTime.now());
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF22C55E).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF22C55E).withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: Color(0xFF22C55E),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_rounded, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'All Systems Operational',
                        style: TextStyle(
                          color: Color(0xFF16A34A),
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Everything is running smoothly.',
                        style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.access_time_rounded, size: 18, color: Color(0xFF64748B)),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Last Updated', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                        Text('Today, $nowFormatted',
                            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Row(
                  children: const [
                    Icon(Icons.dns_rounded, size: 18, color: Color(0xFF64748B)),
                    SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Uptime', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                        Text('99.9%',
                            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF22C55E))),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Mobile Hero Header Widget
// ─────────────────────────────────────────────────────────────────────────────
class _MobileAdminHeader extends StatelessWidget {
  final String greeting;
  final VoidCallback onNotificationTap;
  final VoidCallback onProfileTap;

  const _MobileAdminHeader({
    required this.greeting,
    required this.onNotificationTap,
    required this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    final authCtrl = Get.find<AuthController>();
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
          padding: const EdgeInsets.fromLTRB(20, 12, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Avatar
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1.5),
                    ),
                    child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          greeting,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.white70,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        Obx(() {
                          final name = authCtrl.currentUser.value?.name ?? 'Admin';
                          return Text(
                            name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: -0.3,
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined, color: Colors.white, size: 26),
                    onPressed: onNotificationTap,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    icon: const Icon(Icons.settings_outlined, color: Colors.white, size: 26),
                    onPressed: onProfileTap,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Admin Panel',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                "Here's what's happening with your system today.",
                style: TextStyle(fontSize: 13, color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Mobile KPI Card
// ─────────────────────────────────────────────────────────────────────────────
class _MobileKpiCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color accentColor;

  const _MobileKpiCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 130,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [accentColor, accentColor.withValues(alpha: 0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: accentColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Quick Action data model
// ─────────────────────────────────────────────────────────────────────────────
class _QuickAction {
  final String label;
  final IconData icon;
  final Color color;
  const _QuickAction({required this.label, required this.icon, required this.color});
}

// ── Web Stat KPI Card with Wave Decoration ───────────────────────────────────
class _WebStatKpiCard extends StatelessWidget {
  final String title;
  final String value;
  final String trend;
  final IconData icon;
  final Color accentColor;
  final bool isDark;

  const _WebStatKpiCard({
    required this.title,
    required this.value,
    required this.trend,
    required this.icon,
    required this.accentColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF14202E) : Colors.white,
        borderRadius: BorderRadius.circular(18),
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          children: [
            // Wave Custom Paint at bottom
            Positioned(
              right: 0,
              bottom: 0,
              width: 110,
              height: 48,
              child: CustomPaint(
                painter: _KpiWavePainter(color: accentColor),
              ),
            ),

            // Card content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Icon
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: accentColor, size: 24),
                  ),
                  const SizedBox(width: 14),

                  // Data
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          value,
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          trend,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: accentColor,
                          ),
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
    );
  }
}

// ── Decorative KPI Card Wave Painter ─────────────────────────────────────────
class _KpiWavePainter extends CustomPainter {
  final Color color;
  _KpiWavePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, size.height)
      ..quadraticBezierTo(size.width * 0.35, size.height * 0.7, size.width * 0.65, size.height * 0.3)
      ..quadraticBezierTo(size.width * 0.85, size.height * 0.05, size.width, 0)
      ..lineTo(size.width, size.height)
      ..close();

    canvas.drawPath(path, paint);

    final linePaint = Paint()
      ..color = color.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final linePath = Path()
      ..moveTo(0, size.height)
      ..quadraticBezierTo(size.width * 0.35, size.height * 0.7, size.width * 0.65, size.height * 0.3)
      ..quadraticBezierTo(size.width * 0.85, size.height * 0.05, size.width, 0);

    canvas.drawPath(linePath, linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Quick Overview Interactive Line Chart ────────────────────────────────────
class _OverviewLineChart extends StatelessWidget {
  final bool isDark;
  final List<double> weeklyData;
  const _OverviewLineChart({required this.isDark, required this.weeklyData});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return CustomPaint(
        size: Size(constraints.maxWidth, constraints.maxHeight),
        painter: _LineChartPainter(isDark: isDark, data: weeklyData),
      );
    });
  }
}

class _LineChartPainter extends CustomPainter {
  final bool isDark;
  final List<double> data;
  _LineChartPainter({required this.isDark, required this.data});

  @override
  void paint(Canvas canvas, Size size) {
    final textStyle = TextStyle(
      color: isDark ? const Color(0xFF64748B) : Colors.grey.shade500,
      fontSize: 11,
    );

    const leftPadding = 30.0;
    const bottomPadding = 24.0;
    final chartWidth = size.width - leftPadding;
    final chartHeight = size.height - bottomPadding;

    // Determine max value dynamically (at least 10 for clean grid)
    final double maxVal = data.fold<double>(10.0, (prev, val) => math.max(prev, val));
    final double step = maxVal / 4.0;
    final yValues = [
      maxVal.toStringAsFixed(0),
      (step * 3).toStringAsFixed(0),
      (step * 2).toStringAsFixed(0),
      step.toStringAsFixed(0),
      '0',
    ];

    final yGridPaint = Paint()
      ..color = isDark ? const Color(0xFF1E2D3D) : const Color(0xFFE2E8F0)
      ..strokeWidth = 1;

    for (int i = 0; i < yValues.length; i++) {
      final y = (chartHeight / (yValues.length - 1)) * i;
      final textSpan = TextSpan(text: yValues[i], style: textStyle);
      final textPainter = TextPainter(text: textSpan, textDirection: TextDirection.ltr);
      textPainter.layout();
      textPainter.paint(canvas, Offset(leftPadding - textPainter.width - 8, y - textPainter.height / 2));

      // Draw horizontal subtle grid line
      canvas.drawLine(Offset(leftPadding, y), Offset(size.width, y), yGridPaint);
    }

    // Dynamic past 7 weekdays labels (e.g. Mon, Tue, ...)
    final now = DateTime.now();
    final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final days = List.generate(7, (i) {
      final d = now.subtract(Duration(days: 6 - i));
      return dayNames[d.weekday - 1];
    });

    final dataValues = data.length == 7 ? data : [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0];

    final points = <Offset>[];
    for (int i = 0; i < days.length; i++) {
      final x = leftPadding + (chartWidth / (days.length - 1)) * i;
      final normalizedY = (1.0 - (dataValues[i] / (maxVal > 0 ? maxVal : 1.0))) * chartHeight;
      points.add(Offset(x, normalizedY));

      // Day label
      final textSpan = TextSpan(text: days[i], style: textStyle);
      final textPainter = TextPainter(text: textSpan, textDirection: TextDirection.ltr);
      textPainter.layout();
      textPainter.paint(canvas, Offset(x - textPainter.width / 2, chartHeight + 6));
    }

    // Gradient fill under the curve
    final path = Path();
    path.moveTo(points.first.dx, points.first.dy);
    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final cx = (p0.dx + p1.dx) / 2;
      path.cubicTo(cx, p0.dy, cx, p1.dy, p1.dx, p1.dy);
    }

    final fillPath = Path.from(path)
      ..lineTo(points.last.dx, chartHeight)
      ..lineTo(points.first.dx, chartHeight)
      ..close();

    final fillGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        const Color(0xFF2DD4BF).withValues(alpha: 0.35),
        const Color(0xFF2DD4BF).withValues(alpha: 0.0),
      ],
    );

    final fillPaint = Paint()
      ..shader = fillGradient.createShader(Rect.fromLTWH(leftPadding, 0, chartWidth, chartHeight))
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);

    // Glowing curved stroke
    final strokePaint = Paint()
      ..color = const Color(0xFF2DD4BF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, strokePaint);

    // Point circles
    final dotPaint = Paint()..color = const Color(0xFF2DD4BF);
    final dotBorder = Paint()
      ..color = isDark ? const Color(0xFF14202E) : Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    for (final pt in points) {
      canvas.drawCircle(pt, 4.5, dotPaint);
      canvas.drawCircle(pt, 4.5, dotBorder);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
