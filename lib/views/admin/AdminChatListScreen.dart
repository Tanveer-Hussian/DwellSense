import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fyp/controllers/AuthController.dart';
import 'package:fyp/controllers/ChatController.dart';
import 'package:fyp/models/ChatRoomModel.dart';
import 'package:fyp/models/UserModel.dart';
import 'package:fyp/routes/AppRoutes.dart';
import 'package:fyp/services/AuthService.dart';
import 'package:fyp/utils/AppColors.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class AdminChatListScreen extends StatefulWidget {
  const AdminChatListScreen({super.key});

  @override
  State<AdminChatListScreen> createState() => _AdminChatListScreenState();
}

class _AdminChatListScreenState extends State<AdminChatListScreen> {
  late final ChatController _chatCtrl;
  late final AuthService _authService;
  late final AuthController _authCtrl;

  List<UserModel> _owners = [];
  bool _loadingOwners = true;

  @override
  void initState() {
    super.initState();
    _chatCtrl = Get.find<ChatController>();
    _authService = Get.find<AuthService>();
    _authCtrl = Get.find<AuthController>();
    _fetchOwners();
  }

  Future<void> _fetchOwners() async {
    try {
      _authService.getAllUsersStream().first.then((users) {
        if (mounted) {
          setState(() {
            _owners = users.where((u) => u.role == 'owner').toList();
            _loadingOwners = false;
          });
        }
      });
    } catch (_) {
      if (mounted) setState(() => _loadingOwners = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) return _buildWebLayout(context);
    return _buildMobileLayout(context);
  }

  // ── Web layout (unchanged plain list) ──────────────────────────────────────
  Widget _buildWebLayout(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F171E) : const Color(0xFFF6F8FA),
      appBar: AppBar(
        title: const Text('Messages'),
        backgroundColor: AppColors.primary,
      ),
      body: _buildList(),
    );
  }

  // ── Mobile layout — modern curved header ───────────────────────────────────
  Widget _buildMobileLayout(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Column(
        children: [
          // Curved teal header
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
                padding: const EdgeInsets.fromLTRB(20, 14, 16, 22),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white, size: 20),
                      onPressed: () => Get.back(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Messages',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Obx(() {
                      final name = _authCtrl.currentUser.value?.name ?? 'Admin';
                      return Text(
                        name,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.white70,
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
          // List
          Expanded(child: _buildList()),
        ],
      ),
    );
  }

  Widget _buildList() {
    if (_loadingOwners) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_owners.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline,
                size: 72, color: AppColors.textSecondary.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            const Text(
              'No Hostel Owners',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            const Text(
              'Owner accounts will appear here',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return Obx(() {
      final rooms = _chatCtrl.adminChatRooms;
      return ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: kIsWeb ? 0 : 16),
        itemCount: _owners.length,
        separatorBuilder: (_, __) => kIsWeb
            ? const Divider(height: 1, indent: 72)
            : const SizedBox(height: 10),
        itemBuilder: (ctx, i) {
          final owner = _owners[i];
          final room = rooms.where((r) => r.ownerId == owner.uid).firstOrNull;

          if (room != null) {
            return kIsWeb
                ? _WebChatRoomTile(
                    room: room,
                    onTap: () => Get.toNamed(AppRoutes.chatConversation,
                        arguments: {'roomId': room.id, 'title': room.ownerName}),
                  )
                : _MobileChatOwnerCard(
                    name: room.ownerName,
                    lastMessage: room.lastMessage,
                    lastTime: room.lastMessageTime,
                    unread: room.unreadCountByAdmin,
                    onTap: () => Get.toNamed(AppRoutes.chatConversation,
                        arguments: {'roomId': room.id, 'title': room.ownerName}),
                  );
          } else {
            return kIsWeb
                ? _WebNoRoomTile(
                    owner: owner,
                    onTap: () => _startChat(owner),
                  )
                : _MobileChatOwnerCard(
                    name: owner.name,
                    lastMessage: 'Tap to start conversation',
                    lastTime: null,
                    unread: 0,
                    onTap: () => _startChat(owner),
                  );
          }
        },
      );
    });
  }

  Future<void> _startChat(UserModel owner) async {
    final roomId = await _chatCtrl.startOrGetConversation(
      ownerId: owner.uid,
      ownerName: owner.name,
      ownerEmail: owner.email,
    );
    Get.toNamed(AppRoutes.chatConversation,
        arguments: {'roomId': roomId, 'title': owner.name});
  }
}

// ── Mobile Card ──────────────────────────────────────────────────────────────
class _MobileChatOwnerCard extends StatelessWidget {
  final String name;
  final String lastMessage;
  final DateTime? lastTime;
  final int unread;
  final VoidCallback onTap;

  const _MobileChatOwnerCard({
    required this.name,
    required this.lastMessage,
    required this.lastTime,
    required this.unread,
    required this.onTap,
  });

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) return DateFormat('hh:mm a').format(dt);
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return DateFormat('EEE').format(dt);
    return DateFormat('MMM d').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final hasUnread = unread > 0;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasUnread
                ? const Color(0xFF007A85).withValues(alpha: 0.3)
                : const Color(0xFFE2E8F0),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00585E), Color(0xFF007A85)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Name + preview
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w600,
                      fontSize: 15,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    lastMessage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: hasUnread
                          ? const Color(0xFF0F172A)
                          : const Color(0xFF64748B),
                      fontWeight:
                          hasUnread ? FontWeight.w500 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Time + badge
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (lastTime != null)
                  Text(
                    _formatTime(lastTime!),
                    style: TextStyle(
                      fontSize: 11.5,
                      color: hasUnread
                          ? const Color(0xFF007A85)
                          : const Color(0xFF94A3B8),
                      fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                const SizedBox(height: 6),
                if (hasUnread)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF007A85),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      unread > 9 ? '9+' : '$unread',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
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

// ── Web tiles (unchanged behaviour) ─────────────────────────────────────────
class _WebChatRoomTile extends StatelessWidget {
  final ChatRoomModel room;
  final VoidCallback onTap;
  const _WebChatRoomTile({required this.room, required this.onTap});

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) return DateFormat('hh:mm a').format(dt);
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return DateFormat('EEE').format(dt);
    return DateFormat('MMM d').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final unread = room.unreadCountByAdmin;
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: CircleAvatar(
        radius: 26,
        backgroundColor: AppColors.primaryLight,
        child: Text(
          room.ownerName.isNotEmpty ? room.ownerName[0].toUpperCase() : '?',
          style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryDark),
        ),
      ),
      title: Text(room.ownerName,
          style: TextStyle(
              fontWeight: unread > 0 ? FontWeight.bold : FontWeight.w500,
              fontSize: 15)),
      subtitle: Text(room.lastMessage,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
              color: unread > 0 ? AppColors.textPrimary : AppColors.textSecondary,
              fontWeight: unread > 0 ? FontWeight.w600 : FontWeight.normal)),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(_formatTime(room.lastMessageTime),
              style: TextStyle(
                  fontSize: 11,
                  color: unread > 0 ? AppColors.primary : AppColors.textSecondary)),
          const SizedBox(height: 4),
          if (unread > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12)),
              child: Text(unread > 9 ? '9+' : '$unread',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }
}

class _WebNoRoomTile extends StatelessWidget {
  final UserModel owner;
  final VoidCallback onTap;
  const _WebNoRoomTile({required this.owner, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: CircleAvatar(
        radius: 26,
        backgroundColor: AppColors.primaryLight,
        child: Text(
          owner.name.isNotEmpty ? owner.name[0].toUpperCase() : '?',
          style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryDark),
        ),
      ),
      title: Text(owner.name,
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
      subtitle: const Text('Tap to message',
          style: TextStyle(color: AppColors.textSecondary)),
    );
  }
}
