import 'dart:async';
import 'package:fyp/controllers/AuthController.dart';
import 'package:fyp/models/ChatRoomModel.dart';
import 'package:fyp/models/MessageModel.dart';
import 'package:fyp/models/OwnerStudentChatRoomModel.dart';
import 'package:fyp/services/ChatService.dart';
import 'package:get/get.dart';

class ChatController extends GetxController {
  final ChatService _chatService = Get.find<ChatService>();
  final AuthController _authCtrl = Get.find<AuthController>();

  // ── Admin ↔ Owner observables ────────────────────────────────────────────
  final RxList<ChatRoomModel> adminChatRooms = <ChatRoomModel>[].obs;
  final Rxn<ChatRoomModel> ownerChatRoom = Rxn<ChatRoomModel>();

  // ── Owner ↔ Student observables ──────────────────────────────────────────
  final RxList<OwnerStudentChatRoomModel> ownerStudentRooms =
      <OwnerStudentChatRoomModel>[].obs;
  final RxList<OwnerStudentChatRoomModel> studentChatRooms =
      <OwnerStudentChatRoomModel>[].obs;

  // ── Active messages (shared for both chat types) ─────────────────────────
  final RxList<MessageModel> activeRoomMessages = <MessageModel>[].obs;
  final RxBool isLoading = false.obs;

  // ── Subscriptions ────────────────────────────────────────────────────────
  StreamSubscription<List<ChatRoomModel>>? _adminRoomsSub;
  StreamSubscription<ChatRoomModel?>? _ownerRoomSub;
  StreamSubscription<List<OwnerStudentChatRoomModel>>? _ownerStudentRoomsSub;
  StreamSubscription<List<OwnerStudentChatRoomModel>>? _studentChatRoomsSub;
  StreamSubscription<List<MessageModel>>? _messagesSub;

  @override
  void onInit() {
    super.onInit();
    ever(_authCtrl.currentUser, (user) {
      _cancelAllSubs();
      if (user != null) {
        _initForRole(user.role, user.uid);
      }
    });

    final currentUser = _authCtrl.currentUser.value;
    if (currentUser != null) {
      _initForRole(currentUser.role, currentUser.uid);
    }
  }

  void _initForRole(String role, String uid) {
    if (role == 'admin') {
      _listenToAdminRooms();
    } else if (role == 'owner') {
      _listenToOwnerRoom(uid);
      _listenToOwnerStudentRooms(uid);
    } else if (role == 'student') {
      _listenToStudentChatRooms(uid);
    }
  }

  @override
  void onClose() {
    _cancelAllSubs();
    super.onClose();
  }

  void _cancelAllSubs() {
    _adminRoomsSub?.cancel();
    _ownerRoomSub?.cancel();
    _ownerStudentRoomsSub?.cancel();
    _studentChatRoomsSub?.cancel();
    _messagesSub?.cancel();
    activeRoomMessages.clear();
  }

  // ── Admin ↔ Owner listeners ──────────────────────────────────────────────
  void _listenToAdminRooms() {
    _adminRoomsSub?.cancel();
    _adminRoomsSub = _chatService.getAdminChatRoomsStream().listen((rooms) {
      adminChatRooms.value = rooms;
    });
  }

  void _listenToOwnerRoom(String ownerId) {
    _ownerRoomSub?.cancel();
    _ownerRoomSub =
        _chatService.getOwnerChatRoomStream(ownerId).listen((room) {
      ownerChatRoom.value = room;
    });
  }

  // ── Owner ↔ Student listeners ────────────────────────────────────────────
  void _listenToOwnerStudentRooms(String ownerId) {
    _ownerStudentRoomsSub?.cancel();
    _ownerStudentRoomsSub = _chatService
        .getOwnerStudentRoomsForOwner(ownerId)
        .listen((rooms) {
      ownerStudentRooms.value = rooms;
    });
  }

  void _listenToStudentChatRooms(String studentId) {
    _studentChatRoomsSub?.cancel();
    _studentChatRoomsSub = _chatService
        .getOwnerStudentRoomsForStudent(studentId)
        .listen((rooms) {
      studentChatRooms.value = rooms;
    });
  }

  // ── Message streaming ────────────────────────────────────────────────────

  /// Listen to messages for an admin-owner room
  void listenToMessages(String roomId) {
    _messagesSub?.cancel();
    activeRoomMessages.clear();
    _messagesSub = _chatService.getMessagesStream(roomId).listen((msgs) {
      activeRoomMessages.value = msgs;
      _clearUnreadAdminOwner(roomId);
    });
  }

  /// Listen to messages for an owner-student room
  void listenToOwnerStudentMessages(String roomId) {
    _messagesSub?.cancel();
    activeRoomMessages.clear();
    _messagesSub =
        _chatService.getOwnerStudentMessagesStream(roomId).listen((msgs) {
      activeRoomMessages.value = msgs;
      _clearUnreadOwnerStudent(roomId);
      _markMessagesRead(roomId);
    });
  }

  void stopListeningToMessages() {
    _messagesSub?.cancel();
    activeRoomMessages.clear();
  }

  // ── Send messages ────────────────────────────────────────────────────────

  /// Send message in admin-owner room
  Future<void> sendChatMessage(String roomId, String content) async {
    if (content.trim().isEmpty) return;
    final user = _authCtrl.currentUser.value;
    if (user == null) return;
    final isAdmin = user.role == 'admin';
    await _chatService.sendMessage(
      roomId: roomId,
      senderId: user.uid,
      senderName: user.name,
      content: content.trim(),
      isAdminSender: isAdmin,
    );
  }

  /// Send message in owner-student room
  Future<void> sendOwnerStudentChatMessage({
    required String roomId,
    required String content,
    required String recipientId,
    required String hostelName,
  }) async {
    if (content.trim().isEmpty) return;
    final user = _authCtrl.currentUser.value;
    if (user == null) return;
    final isOwner = user.role == 'owner';
    await _chatService.sendOwnerStudentMessage(
      roomId: roomId,
      senderId: user.uid,
      senderName: user.name,
      content: content.trim(),
      isOwnerSender: isOwner,
      recipientId: recipientId,
      hostelName: hostelName,
    );
  }

  /// Get or create an owner-student room; returns the room ID
  Future<String> startOwnerStudentConversation({
    required String ownerId,
    required String ownerName,
    required String studentId,
    required String studentName,
    required String hostelId,
    required String hostelName,
  }) async {
    try {
      isLoading.value = true;
      final room = await _chatService.getOrCreateOwnerStudentRoom(
        ownerId: ownerId,
        ownerName: ownerName,
        studentId: studentId,
        studentName: studentName,
        hostelId: hostelId,
        hostelName: hostelName,
      );
      return room.id;
    } finally {
      isLoading.value = false;
    }
  }

  /// Get or create admin-owner room; returns room ID
  Future<String> startOrGetConversation({
    required String ownerId,
    required String ownerName,
    required String ownerEmail,
  }) async {
    try {
      isLoading.value = true;
      final room = await _chatService.getOrCreateChatRoom(
        ownerId: ownerId,
        ownerName: ownerName,
        ownerEmail: ownerEmail,
      );
      return room.id;
    } finally {
      isLoading.value = false;
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  void _clearUnreadAdminOwner(String roomId) {
    final user = _authCtrl.currentUser.value;
    if (user == null) return;
    if (user.role == 'admin') {
      _chatService.clearUnreadForAdmin(roomId);
    } else if (user.role == 'owner') {
      _chatService.clearUnreadForOwner(roomId);
    }
  }

  void _clearUnreadOwnerStudent(String roomId) {
    final user = _authCtrl.currentUser.value;
    if (user == null) return;
    if (user.role == 'student') {
      _chatService.clearUnreadByStudent(roomId);
    } else if (user.role == 'owner') {
      _chatService.clearUnreadByOwner(roomId);
    }
  }

  void _markMessagesRead(String roomId) {
    final uid = _authCtrl.currentUser.value?.uid;
    if (uid == null) return;
    _chatService.markOwnerStudentMessagesRead(roomId, uid);
  }

  /// Unread count for student across all owner-student rooms
  int get studentTotalUnread =>
      studentChatRooms.fold(0, (sum, r) => sum + r.unreadByStudent);

  /// Unread count for owner across all owner-student rooms
  int get ownerStudentTotalUnread =>
      ownerStudentRooms.fold(0, (sum, r) => sum + r.unreadByOwner);
}
