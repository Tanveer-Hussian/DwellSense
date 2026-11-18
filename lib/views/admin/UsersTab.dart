import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fyp/models/UserModel.dart';
import 'package:fyp/routes/AppRoutes.dart';
import 'package:fyp/services/AuthService.dart';
import 'package:fyp/utils/AppColors.dart';
import 'package:fyp/views/admin/AdminSettingsScreen.dart';
import 'package:get/get.dart';

// Returns a distinct background color based on the first letter (web avatars)
Color _letterColor(String letter) {
  const colors = [
    Color(0xFF1565C0), Color(0xFF6A1B9A), Color(0xFF00695C), Color(0xFFBF360C),
    Color(0xFF283593), Color(0xFF558B2F), Color(0xFFAD1457), Color(0xFF00838F),
    Color(0xFFE65100), Color(0xFF4527A0), Color(0xFF2E7D32), Color(0xFFC62828),
    Color(0xFF37474F), Color(0xFF00695C), Color(0xFF6D4C41), Color(0xFF1565C0),
    Color(0xFF880E4F), Color(0xFF004D40), Color(0xFF4A148C), Color(0xFF01579B),
    Color(0xFF827717), Color(0xFF33691E), Color(0xFF5D4037), Color(0xFF212121),
    Color(0xFF1A237E), Color(0xFF263238),
  ];
  if (letter.isEmpty) return colors[0];
  final idx = letter.toUpperCase().codeUnitAt(0) - 65;
  return colors[idx.clamp(0, 25)];
}

class UsersTab extends StatefulWidget {
  const UsersTab({super.key});

  @override
  State<UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends State<UsersTab> {
  final AuthService _authService = Get.find<AuthService>();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';
  String _filterRole = 'all'; // 'all' | 'student' | 'owner' | 'admin'

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

  List<UserModel> _applyFilters(List<UserModel> users) {
    return users.where((u) {
      final matchRole = _filterRole == 'all' || u.role == _filterRole;
      final q = _searchQuery.toLowerCase();
      final matchSearch = q.isEmpty ||
          u.name.toLowerCase().contains(q) ||
          u.email.toLowerCase().contains(q);
      return matchRole && matchSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) {
      return _buildMobileLayout();
    }
    return _buildWebLayout();
  }

  // ── Web Layout (Matches Owner Panel redesign) ──────────────────────────────
  Widget _buildWebLayout() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return StreamBuilder<List<UserModel>>(
      stream: _authService.getAllUsersStream(),
      builder: (ctx, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final allUsers = snap.data!;
        final filtered = _applyFilters(allUsers);

        final studentCount = allUsers.where((u) => u.role == 'student').length;
        final ownerCount = allUsers.where((u) => u.role == 'owner').length;
        final adminCount = allUsers.where((u) => u.role == 'admin').length;

        return Column(
          children: [
            // ── Top Hero Banner + Search & Filter Row ───────────────────────
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
                        allUsers.length,
                        studentCount,
                        ownerCount,
                        adminCount,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── User Cards List ─────────────────────────────────────────────
            Expanded(
              child: filtered.isEmpty
                  ? _buildEmptyState(isDark)
                  : Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1140),
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(28, 16, 28, 24),
                          itemCount: filtered.length,
                          itemBuilder: (_, i) => _WebUserCard(
                            user: filtered[i],
                            isDark: isDark,
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        );
      },
    );
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
                // Circular leading badge
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
                    Icons.people_alt_rounded,
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
                        'Users Management',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'View, search, and manage all registered accounts across the platform',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                // Right floating artwork
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
                          Icons.manage_accounts_rounded,
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
    int total,
    int students,
    int owners,
    int admins,
  ) {
    return Row(
      children: [
        // Role Pills
        _buildPill('all', 'All', total, Icons.list_alt_rounded, AppColors.primary, isDark),
        const SizedBox(width: 10),
        _buildPill('student', 'Students', students, Icons.school_outlined, const Color(0xFF0EA5E9), isDark),
        const SizedBox(width: 10),
        _buildPill('owner', 'Owners', owners, Icons.home_work_outlined, const Color(0xFF10B981), isDark),
        const SizedBox(width: 10),
        _buildPill('admin', 'Admins', admins, Icons.admin_panel_settings_outlined, const Color(0xFFEF4444), isDark),

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
              hintText: 'Search by name or email…',
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
    String role,
    String label,
    int count,
    IconData icon,
    Color activeColor,
    bool isDark,
  ) {
    final isSelected = _filterRole == role;

    return GestureDetector(
      onTap: () => setState(() => _filterRole = role),
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
            child: const Icon(Icons.people_outline, size: 48, color: AppColors.primary),
          ),
          const SizedBox(height: 14),
          Text(
            'No users found',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Try adjusting your search query or role filter',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ── Mobile Layout (Redesigned App Only) ────────────────────────────────────
  Widget _buildMobileLayout() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF111827) : const Color(0xFFF1F5F9);

    return Scaffold(
      backgroundColor: bgColor,
      body: StreamBuilder<List<UserModel>>(
        stream: _authService.getAllUsersStream(),
        builder: (ctx, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final allUsers = snap.data!;
          final filtered = _applyFilters(allUsers);

          final studentCount = allUsers.where((u) => u.role == 'student').length;
          final ownerCount = allUsers.where((u) => u.role == 'owner').length;
          final adminCount = allUsers.where((u) => u.role == 'admin').length;

          return Column(
            children: [
              // ── Curved Teal Hero Header ──────────────────────────────────
              _buildMobileCurvedHeader(
                totalCount: allUsers.length,
                studentCount: studentCount,
                ownerCount: ownerCount,
              ),

              // ── Filter Pills Row ─────────────────────────────────────────
              _buildMobileFilterPills(
                allCount: allUsers.length,
                studentCount: studentCount,
                ownerCount: ownerCount,
                adminCount: adminCount,
              ),

              // ── Users List ───────────────────────────────────────────────
              Expanded(
                child: filtered.isEmpty
                    ? _buildMobileEmptyState()
                    : ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                        itemCount: filtered.length,
                        itemBuilder: (ctx, i) => _MobileModernUserCard(
                          user: filtered[i],
                          onTap: () => Get.toNamed(
                            AppRoutes.adminUserDetail,
                            arguments: filtered[i],
                          ),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMobileCurvedHeader({
    required int totalCount,
    required int studentCount,
    required int ownerCount,
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
                    child: const Icon(Icons.people_alt_rounded,
                        color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Users Management',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: -0.3,
                          ),
                        ),
                        Text(
                          '$totalCount users · $studentCount students · $ownerCount owners',
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
                    hintText: 'Search by name or email…',
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
    required int studentCount,
    required int ownerCount,
    required int adminCount,
  }) {
    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            _UserFilterChip(
              label: 'All',
              count: allCount,
              value: 'all',
              current: _filterRole,
              onTap: () => setState(() => _filterRole = 'all'),
            ),
            const SizedBox(width: 8),
            _UserFilterChip(
              label: 'Students',
              count: studentCount,
              value: 'student',
              current: _filterRole,
              dotColor: const Color(0xFF0EA5E9),
              onTap: () => setState(() => _filterRole = 'student'),
            ),
            const SizedBox(width: 8),
            _UserFilterChip(
              label: 'Owners',
              count: ownerCount,
              value: 'owner',
              current: _filterRole,
              dotColor: const Color(0xFF10B981),
              onTap: () => setState(() => _filterRole = 'owner'),
            ),
            const SizedBox(width: 8),
            _UserFilterChip(
              label: 'Admins',
              count: adminCount,
              value: 'admin',
              current: _filterRole,
              dotColor: const Color(0xFF8B5CF6),
              onTap: () => setState(() => _filterRole = 'admin'),
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
              child: const Icon(Icons.people_outline_rounded,
                  size: 40, color: Color(0xFF007A85)),
            ),
            const SizedBox(height: 16),
            const Text(
              'No Users Found',
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
                  : 'No users found in "${_filterRole.capitalizeFirst}" category.',
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Web User Card ────────────────────────────────────────────────────────────
class _WebUserCard extends StatelessWidget {
  final UserModel user;
  final bool isDark;

  const _WebUserCard({required this.user, required this.isDark});

  Color get _roleColor {
    switch (user.role) {
      case 'admin':
        return const Color(0xFFEF4444);
      case 'owner':
        return const Color(0xFF10B981);
      default:
        return const Color(0xFF0EA5E9);
    }
  }

  IconData get _roleIcon {
    switch (user.role) {
      case 'admin':
        return Icons.admin_panel_settings_outlined;
      case 'owner':
        return Icons.home_work_outlined;
      default:
        return Icons.school_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Get.toNamed(AppRoutes.adminUserDetail, arguments: user),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
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
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              // Letter-colored Avatar with white initial
              CircleAvatar(
                radius: 24,
                backgroundColor: _letterColor(
                  user.name.isNotEmpty ? user.name[0] : 'U',
                ),
                backgroundImage: user.profileImage != null &&
                        user.profileImage!.isNotEmpty
                    ? NetworkImage(user.profileImage!)
                    : null,
                child: user.profileImage == null || user.profileImage!.isEmpty
                    ? Text(
                        user.name.isNotEmpty
                            ? user.name[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 16),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      user.email,
                      style: TextStyle(
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : AppColors.textSecondary,
                        fontSize: 12.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    // Role & status badges
                    Row(
                      children: [
                        _badge(
                          icon: _roleIcon,
                          label: user.role.capitalizeFirst ?? user.role,
                          color: _roleColor,
                        ),
                        const SizedBox(width: 8),
                        _badge(
                          icon: user.isActive
                              ? Icons.check_circle_outline
                              : Icons.block_outlined,
                          label: user.isActive ? 'Active' : 'Suspended',
                          color: user.isActive
                              ? AppColors.success
                              : AppColors.error,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Arrow
              Icon(
                Icons.chevron_right,
                color: isDark ? const Color(0xFF64748B) : Colors.grey.shade400,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _badge({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Mobile Filter Chip Widget ───────────────────────────────────────────────
class _UserFilterChip extends StatelessWidget {
  final String label;
  final int count;
  final String value;
  final String current;
  final Color? dotColor;
  final VoidCallback onTap;

  const _UserFilterChip({
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

// ── Mobile Modern User Card ─────────────────────────────────────────────────
class _MobileModernUserCard extends StatelessWidget {
  final UserModel user;
  final VoidCallback onTap;

  const _MobileModernUserCard({
    required this.user,
    required this.onTap,
  });

  Color get _roleColor {
    switch (user.role) {
      case 'admin':
        return const Color(0xFF7C3AED);
      case 'owner':
        return const Color(0xFF059669);
      default:
        return const Color(0xFF0284C7);
    }
  }

  Color get _roleBg {
    switch (user.role) {
      case 'admin':
        return const Color(0xFFF5F3FF);
      case 'owner':
        return const Color(0xFFECFDF5);
      default:
        return const Color(0xFFF0F9FF);
    }
  }

  IconData get _roleIcon {
    switch (user.role) {
      case 'admin':
        return Icons.admin_panel_settings_rounded;
      case 'owner':
        return Icons.home_work_rounded;
      default:
        return Icons.school_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final photoUrl = user.profileImage;
    final hasPhoto = photoUrl != null && photoUrl.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // ── Avatar ───────────────────────────────────────────────────
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: _roleColor.withValues(alpha: 0.4), width: 1.5),
                  ),
                  child: ClipOval(
                    child: hasPhoto
                        ? CachedNetworkImage(
                            imageUrl: photoUrl,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(
                              color: const Color(0xFFE2E8F0),
                              child: const Center(
                                child: SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              ),
                            ),
                            errorWidget: (_, __, ___) => _fallbackAvatar(),
                          )
                        : _fallbackAvatar(),
                  ),
                ),
                const SizedBox(width: 14),

                // ── Details ──────────────────────────────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: const TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user.email,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: Color(0xFF64748B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (user.university != null && user.university!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.school_outlined,
                                size: 12, color: Color(0xFF94A3B8)),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                user.university!,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF64748B),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 7),

                      // ── Badges Row ─────────────────────────────────────────
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: _roleBg,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _roleColor.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(_roleIcon, size: 12, color: _roleColor),
                                const SizedBox(width: 4),
                                Text(
                                  user.role.toUpperCase(),
                                  style: TextStyle(
                                    color: _roleColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: user.isActive
                                  ? const Color(0xFFECFDF5)
                                  : const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: user.isActive
                                    ? const Color(0xFF10B981).withValues(alpha: 0.3)
                                    : const Color(0xFFEF4444).withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  user.isActive
                                      ? Icons.check_circle_rounded
                                      : Icons.block_rounded,
                                  size: 11,
                                  color: user.isActive
                                      ? const Color(0xFF10B981)
                                      : const Color(0xFFEF4444),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  user.isActive ? 'Active' : 'Suspended',
                                  style: TextStyle(
                                    color: user.isActive
                                        ? const Color(0xFF059669)
                                        : const Color(0xFFDC2626),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ── Trailing Arrow ───────────────────────────────────────────
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFF94A3B8),
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _fallbackAvatar() {
    final initial = user.name.isNotEmpty ? user.name[0].toUpperCase() : '?';
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_roleColor, _roleColor.withValues(alpha: 0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
