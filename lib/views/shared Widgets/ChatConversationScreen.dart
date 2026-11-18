import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fyp/controllers/AuthController.dart';
import 'package:fyp/controllers/ChatController.dart';
import 'package:fyp/models/MessageModel.dart';
import 'package:fyp/utils/AppColors.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class ChatConversationScreen extends StatefulWidget {
  const ChatConversationScreen({super.key});

  @override
  State<ChatConversationScreen> createState() => _ChatConversationScreenState();
}

class _ChatConversationScreenState extends State<ChatConversationScreen> {
  final ChatController _chatCtrl = Get.find<ChatController>();
  final AuthController _authCtrl = Get.find<AuthController>();
  final TextEditingController _msgCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  late final String roomId;
  late final String title;
  late final bool isOwnerStudentChat;
  late final String recipientId;
  late final String hostelName;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments as Map<String, dynamic>;
    roomId = args['roomId'] as String;
    title = args['title'] as String;
    isOwnerStudentChat =
        (args['chatType'] as String? ?? 'admin_owner') == 'owner_student';
    recipientId = args['recipientId'] as String? ?? '';
    hostelName = args['hostelName'] as String? ?? '';

    if (isOwnerStudentChat) {
      _chatCtrl.listenToOwnerStudentMessages(roomId);
    } else {
      _chatCtrl.listenToMessages(roomId);
    }
  }

  @override
  void dispose() {
    _chatCtrl.stopListeningToMessages();
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage([String? quickText]) async {
    final text = quickText ?? _msgCtrl.text.trim();
    if (text.isEmpty) return;
    if (quickText == null) {
      _msgCtrl.clear();
    }
    if (isOwnerStudentChat) {
      await _chatCtrl.sendOwnerStudentChatMessage(
        roomId: roomId,
        content: text,
        recipientId: recipientId,
        hostelName: hostelName,
      );
    } else {
      await _chatCtrl.sendChatMessage(roomId, text);
    }
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final myUid = _authCtrl.currentUser.value?.uid ?? '';

    // If NOT web (e.g. Android/iOS app), preserve existing UI with zero impact
    if (!kIsWeb) {
      return _buildMobileScaffold(context, myUid);
    }

    // Otherwise render modern web-optimized experience
    return _buildWebScaffold(context, myUid);
  }

  // ── Original Mobile Layout (Untouched for App) ───────────────────────────
  Widget _buildMobileScaffold(BuildContext context, String myUid) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            const Text('Chat',
                style: TextStyle(fontSize: 11, color: Colors.white70)),
          ],
        ),
        leading: const BackButton(color: Colors.white),
      ),
      body: Column(
        children: [
          // ── Messages list ────────────────────────────────────────────────
          Expanded(
            child: Obx(() {
              final msgs = _chatCtrl.activeRoomMessages;
              if (msgs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chat_bubble_outline,
                          size: 64,
                          color: AppColors.textSecondary.withValues(alpha: 0.3)),
                      const SizedBox(height: 12),
                      const Text(
                          'No messages yet.\nSend one to start the conversation!',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textSecondary)),
                    ],
                  ),
                );
              }
              _scrollToBottom();
              return ListView.builder(
                controller: _scrollCtrl,
                padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
                itemCount: msgs.length,
                itemBuilder: (ctx, i) {
                  final msg = msgs[i];
                  final isMe = msg.senderId == myUid;
                  final showDate = i == 0 ||
                      !_isSameDay(msgs[i - 1].createdAt, msg.createdAt);
                  return Column(
                    children: [
                      if (showDate) _DateDivider(date: msg.createdAt),
                      _MessageBubble(msg: msg, isMe: isMe, isWeb: false),
                    ],
                  );
                },
              );
            }),
          ),

          // ── Input bar ────────────────────────────────────────────────────
          Container(
            padding: EdgeInsets.fromLTRB(
                12, 8, 12, MediaQuery.of(context).padding.bottom + 8),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                    offset: Offset(0, -2))
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F4F4),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: _msgCtrl,
                      minLines: 1,
                      maxLines: 4,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle:
                            TextStyle(color: AppColors.textSecondary),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Material(
                  color: AppColors.primary,
                  shape: const CircleBorder(),
                  child: InkWell(
                    onTap: () => _sendMessage(),
                    customBorder: const CircleBorder(),
                    child: const Padding(
                      padding: EdgeInsets.all(12),
                      child:
                          Icon(Icons.send, color: Colors.white, size: 20),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Enhanced Web Layout (Owner, Student, Admin Panels) ────────────────────
  Widget _buildWebScaffold(BuildContext context, String myUid) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final initial = title.isNotEmpty ? title[0].toUpperCase() : '?';
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2C2C2C) : const Color(0xFFE9ECEF);
    final scaffoldBg = isDark ? const Color(0xFF141414) : const Color(0xFFF7F9FA);

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
        title: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  child: Text(
                    initial,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.greenAccent,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    children: [
                      Text(
                        hostelName.isNotEmpty
                            ? hostelName
                            : (isOwnerStudentChat ? 'Resident Chat' : 'Support Chat'),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '• Active',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.greenAccent.shade100,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 980),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Column(
                children: [
                  // ── Messages Area ─────────────────────────────────────────
                  Expanded(
                    child: Obx(() {
                      final msgs = _chatCtrl.activeRoomMessages;
                      if (msgs.isEmpty) {
                        return _buildWebEmptyState(isDark);
                      }
                      _scrollToBottom();
                      return ListView.builder(
                        controller: _scrollCtrl,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 20),
                        itemCount: msgs.length,
                        itemBuilder: (ctx, i) {
                          final msg = msgs[i];
                          final isMe = msg.senderId == myUid;
                          final showDate = i == 0 ||
                              !_isSameDay(msgs[i - 1].createdAt, msg.createdAt);
                          return Column(
                            children: [
                              if (showDate) _DateDivider(date: msg.createdAt),
                              _MessageBubble(msg: msg, isMe: isMe, isWeb: true),
                            ],
                          );
                        },
                      );
                    }),
                  ),

                  // ── Web Input Bar ─────────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 14),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                      border: Border(top: BorderSide(color: borderColor)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF272727)
                                  : const Color(0xFFF4F6F8),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: isDark
                                    ? const Color(0xFF383838)
                                    : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: TextField(
                              controller: _msgCtrl,
                              minLines: 1,
                              maxLines: 4,
                              textCapitalization: TextCapitalization.sentences,
                              decoration: const InputDecoration(
                                hintText:
                                    'Type a message... (Press Enter to send)',
                                hintStyle: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 13),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 18, vertical: 12),
                              ),
                              onSubmitted: (_) => _sendMessage(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Material(
                          color: AppColors.primary,
                          shape: const CircleBorder(),
                          child: InkWell(
                            onTap: () => _sendMessage(),
                            customBorder: const CircleBorder(),
                            child: const Padding(
                              padding: EdgeInsets.all(12),
                              child: Icon(Icons.send_rounded,
                                  color: Colors.white, size: 20),
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
      ),
    );
  }

  Widget _buildWebEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chat_bubble_outline_rounded,
                size: 48,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Start conversation with $title',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 6),
            Text(
              hostelName.isNotEmpty
                  ? 'Ask about bed vacancies, amenities, check-in dates, or hostel policies for $hostelName.'
                  : 'Send a message to begin real-time communication.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _buildQuickReplyChip('👋 Hello!'),
                _buildQuickReplyChip('Could you share check-in details?'),
                _buildQuickReplyChip('Is room service & Wi-Fi available?'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickReplyChip(String text) {
    return ActionChip(
      label: Text(text, style: const TextStyle(fontSize: 12)),
      onPressed: () => _sendMessage(text),
      backgroundColor: AppColors.primary.withValues(alpha: 0.08),
      side: BorderSide(color: AppColors.primary.withValues(alpha: 0.25)),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

// ── Date divider ──────────────────────────────────────────────────────────────
class _DateDivider extends StatelessWidget {
  final DateTime date;
  const _DateDivider({required this.date});

  @override
  Widget build(BuildContext context) {
    final label = _label(date);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          const Expanded(child: Divider()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF2A2A2A)
                    : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
          const Expanded(child: Divider()),
        ],
      ),
    );
  }

  String _label(DateTime dt) {
    final now = DateTime.now();
    if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
      return 'Today';
    }
    final yesterday = now.subtract(const Duration(days: 1));
    if (dt.year == yesterday.year &&
        dt.month == yesterday.month &&
        dt.day == yesterday.day) {
      return 'Yesterday';
    }
    return DateFormat('MMM d, yyyy').format(dt);
  }
}

// ── Single message bubble with WhatsApp-style read ticks ──────────────────────
class _MessageBubble extends StatelessWidget {
  final MessageModel msg;
  final bool isMe;
  final bool isWeb;
  const _MessageBubble({
    required this.msg,
    required this.isMe,
    this.isWeb = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final maxBubbleWidth = isWeb
        ? 560.0
        : MediaQuery.of(context).size.width * 0.75;

    final receivedBubbleBg = isWeb
        ? (isDark ? const Color(0xFF262626) : Colors.white)
        : Colors.white;

    final receivedTextColor = isWeb
        ? (isDark ? Colors.white : AppColors.textPrimary)
        : AppColors.textPrimary;

    final receivedBorder = isWeb
        ? Border.all(
            color: isDark ? const Color(0xFF333333) : const Color(0xFFE2E8F0))
        : null;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: maxBubbleWidth),
        margin: const EdgeInsets.only(bottom: 10),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isMe)
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 3),
                child: Text(
                  msg.senderName,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? AppColors.primary : receivedBubbleBg,
                border: isMe ? null : receivedBorder,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: isMe
                      ? const Radius.circular(16)
                      : const Radius.circular(4),
                  bottomRight: isMe
                      ? const Radius.circular(4)
                      : const Radius.circular(16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                msg.content,
                style: TextStyle(
                  color: isMe ? Colors.white : receivedTextColor,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 3, left: 4, right: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    DateFormat('hh:mm a').format(msg.createdAt),
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (isMe) ...[
                    const SizedBox(width: 3),
                    _ReadTick(isRead: msg.isRead),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── WhatsApp-style double tick ────────────────────────────────────────────────
class _ReadTick extends StatelessWidget {
  final bool isRead;
  const _ReadTick({required this.isRead});

  @override
  Widget build(BuildContext context) {
    final color = isRead ? Colors.blue : Colors.grey;
    return Stack(
      children: [
        Icon(Icons.done, size: 13, color: color),
        Positioned(
          left: 5,
          child: Icon(Icons.done, size: 13, color: color),
        ),
      ],
    );
  }
}
