// Owner Chat List: shows the owner's conversation with the admin
import 'package:flutter/material.dart';
import 'package:fyp/controllers/AuthController.dart';
import 'package:fyp/controllers/ChatController.dart';
import 'package:fyp/routes/AppRoutes.dart';
import 'package:fyp/utils/AppColors.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class OwnerChatListScreen extends StatefulWidget {
  const OwnerChatListScreen({super.key});

  @override
  State<OwnerChatListScreen> createState() => _OwnerChatListScreenState();
}

class _OwnerChatListScreenState extends State<OwnerChatListScreen> {
  final ChatController _chatCtrl = Get.find<ChatController>();

  @override
  void initState() {
    super.initState();
    // Ensure active messages are cleared/reset
    _chatCtrl.stopListeningToMessages();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text('Messages'),
        
      ),
      body: Obx(() {
        final room = _chatCtrl.ownerChatRoom.value;

        if (room == null) {
          return ListView(
            children: [
              ListTile(
                onTap: () async {
                  final auth = Get.find<AuthController>();
                  final user = auth.currentUser.value;
                  if (user != null) {
                    final roomId = await _chatCtrl.startOrGetConversation(
                      ownerId: user.uid,
                      ownerName: user.name,
                      ownerEmail: user.email,
                    );
                    Get.toNamed(
                      AppRoutes.chatConversation,
                      arguments: {
                        'roomId': roomId,
                        'title': 'Admin Support',
                      },
                    );
                  }
                },
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                leading: CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.primaryLight,
                  child: const Icon(Icons.admin_panel_settings,
                      color: AppColors.primaryDark, size: 28),
                ),
                title: const Text(
                  'Admin Support',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15),
                ),
                subtitle: const Text(
                  'Tap to message admin',
                  style: TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.normal),
                ),
              ),
            ],
          );
        }

        final unread = room.unreadCountByOwner;

        return ListView(
          children: [
            ListTile(
              onTap: () => Get.toNamed(
                AppRoutes.chatConversation,
                arguments: {
                  'roomId': room.id,
                  'title': 'Admin Support',
                },
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              leading: CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.primaryLight,
                child: const Icon(Icons.admin_panel_settings,
                    color: AppColors.primaryDark, size: 28),
              ),
              title: Text(
                'Admin Support',
                style: TextStyle(
                    fontWeight:
                        unread > 0 ? FontWeight.bold : FontWeight.w600,
                    fontSize: 15),
              ),
              subtitle: Text(
                room.lastMessage,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: unread > 0
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                    fontWeight:
                        unread > 0 ? FontWeight.w600 : FontWeight.normal),
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatTime(room.lastMessageTime),
                    style: TextStyle(
                        fontSize: 11,
                        color: unread > 0
                            ? AppColors.primary
                            : AppColors.textSecondary),
                  ),
                  const SizedBox(height: 4),
                  if (unread > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        unread > 9 ? '9+' : '$unread',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) return DateFormat('hh:mm a').format(dt);
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return DateFormat('EEE').format(dt);
    return DateFormat('MMM d').format(dt);
  }
}


