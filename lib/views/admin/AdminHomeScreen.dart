import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fyp/controllers/AuthController.dart';
import 'package:fyp/controllers/BookingController.dart';
import 'package:fyp/controllers/ComplaintController.dart';
import 'package:fyp/controllers/HostelController.dart';
import 'package:fyp/controllers/NotificationController.dart';
import 'package:fyp/controllers/ReviewController.dart';
import 'package:fyp/routes/AppRoutes.dart';
import 'package:fyp/utils/AppColors.dart';
import 'package:fyp/utils/Responsive.dart';
import 'package:fyp/views/admin/AdminSettingsScreen.dart';
import 'package:fyp/views/admin/ComplaintsTab.dart';
import 'package:fyp/views/admin/HostelsTab.dart';
import 'package:fyp/views/admin/OverviewTab.dart';
import 'package:fyp/views/admin/ReviewsTab.dart';
import 'package:fyp/views/admin/UsersTab.dart';
import 'package:fyp/views/shared%20Widgets/FloatingBottomNavBar.dart';
import 'package:fyp/views/shared%20Widgets/WebSidebarShell.dart';
import 'package:get/get.dart';


class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  late final HostelController hostelCtrl;
  late final BookingController bookingCtrl;
  late final ReviewController reviewCtrl;
  late final ComplaintController complaintCtrl;
  
  int _currentIndex = 0;

  static const _webNavItems = [
    SidebarNavItem(icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Overview'),
    SidebarNavItem(icon: Icons.domain_outlined, activeIcon: Icons.domain, label: 'Hostels'),
    SidebarNavItem(icon: Icons.people_outline, activeIcon: Icons.people, label: 'Users'),
    SidebarNavItem(icon: Icons.report_problem_outlined, activeIcon: Icons.report_problem, label: 'Complaints'),
    SidebarNavItem(icon: Icons.star_outline, activeIcon: Icons.star, label: 'Reviews'),
  ];

  @override
  void initState() {
    super.initState();
    hostelCtrl = Get.find<HostelController>();
    bookingCtrl = Get.find<BookingController>();
    reviewCtrl = Get.find<ReviewController>();
    complaintCtrl = Get.find<ComplaintController>();

    hostelCtrl.ensureAdminStreamsLoaded();
    reviewCtrl.loadFlaggedReviews();
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    FocusManager.instance.primaryFocus?.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final isWide = Responsive.isWide(context);
    final authCtrl = Get.find<AuthController>();
    final notifCtrl = Get.find<NotificationController>();

    final tabs = [
      OverviewTab(hostelCtrl: hostelCtrl),
      isWide
          ? _wrapWithAppBar('Hostels', HostelsTab(hostelCtrl: hostelCtrl), isWide: true)
          : HostelsTab(hostelCtrl: hostelCtrl),
      isWide
          ? _wrapWithAppBar('Users', const UsersTab(), isWide: true)
          : const UsersTab(),
      isWide
          ? _wrapWithAppBar('Complaints', ComplaintsTab(complaintCtrl: complaintCtrl), isWide: true)
          : ComplaintsTab(complaintCtrl: complaintCtrl),
      isWide
          ? _wrapWithAppBar('Reviews', ReviewsTab(reviewCtrl: reviewCtrl), isWide: true)
          : ReviewsTab(reviewCtrl: reviewCtrl),
    ];

    // ── Web layout: sidebar shell ──────────────────────────────────────────
    if (isWide) {
      return Obx(() => WebSidebarShell(
            currentIndex: _currentIndex,
            onTap: _onTabTapped,
            items: _webNavItems,
            userName: authCtrl.currentUser.value?.name ?? 'Admin',
            roleLabel: 'Admin Panel',
            notificationCount: notifCtrl.unreadCount.value,
            body: IndexedStack(
              index: _currentIndex,
              children: tabs,
            ),
          ));
    }

    // ── Mobile layout (unchanged) ──────────────────────────────────────────
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: PopScope(
        canPop: _currentIndex == 0,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop && _currentIndex != 0) {
            setState(() => _currentIndex = 0);
          }
        },
        child: IndexedStack(
          index: _currentIndex,
          children: tabs,
        ),
      ),
      bottomNavigationBar: FloatingBottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        items: const [
          FloatingNavItem(
            icon: Icons.home_outlined,
            activeIcon: Icons.home,
            label: 'Overview',
          ),
          FloatingNavItem(
            icon: Icons.domain_outlined,
            activeIcon: Icons.domain,
            label: 'Hostels',
          ),
          FloatingNavItem(
            icon: Icons.people_outline,
            activeIcon: Icons.people,
            label: 'Users',
          ),
          FloatingNavItem(
            icon: Icons.report_problem_outlined,
            activeIcon: Icons.report_problem,
            label: 'Complaints',
          ),
          FloatingNavItem(
            icon: Icons.star_outline,
            activeIcon: Icons.star,
            label: 'Reviews',
          ),
        ],
      ),
    );
  }

  Widget _wrapWithAppBar(String title, Widget child, {bool isWide = false}) {
    // On web, tabs are inside the sidebar shell — no extra AppBar needed.
    if (isWide) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return Container(
        color: isDark ? const Color(0xFF0F171E) : const Color(0xFFF6F8FA),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1140),
            child: child,
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: AppColors.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_outlined),
            tooltip: 'Messages',
            onPressed: () => Get.toNamed(AppRoutes.adminChats),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () => kIsWeb
                ? Get.toNamed(AppRoutes.profile)
                : Get.to(() => const AdminSettingsScreen()),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1140),
          child: child,
        ),
      ),
    );
  }
}
