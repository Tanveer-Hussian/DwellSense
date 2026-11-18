import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fyp/models/ChatRoomModel.dart';
import 'package:fyp/models/MessageModel.dart';
import 'package:fyp/models/OwnerStudentChatRoomModel.dart';
import 'package:fyp/services/NotificationService.dart';
import 'package:get/get.dart';

class ChatService extends GetxService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Admin ↔ Owner chats ──────────────────────────────────────────────────
  CollectionReference<Map<String, dynamic>> get _chatsCol =>
      _db.collection('chats');

  // Deterministic room ID between admin and owner
  String getRoomId(String ownerId) => 'admin_$ownerId';

  // Get or create a chat room document
  Future<ChatRoomModel> getOrCreateChatRoom({
    required String ownerId,
    required String ownerName,
    required String ownerEmail,
  }) async {
    final roomId = getRoomId(ownerId);
    final docRef = _chatsCol.doc(roomId);
    final snap = await docRef.get();

    if (snap.exists) {
      return ChatRoomModel.fromMap(snap.data()!, snap.id);
    } else {
      final room = ChatRoomModel(
        id: roomId,
        ownerId: ownerId,
        ownerName: ownerName,
        ownerEmail: ownerEmail,
        lastMessage: 'Conversation started',
        lastMessageTime: DateTime.now(),
        unreadCountByAdmin: 0,
        unreadCountByOwner: 0,
      );
      await docRef.set(room.toMap());
      return room;
    }
  }

  // Stream active conversations for admin (ordered by last message time)
  Stream<List<ChatRoomModel>> getAdminChatRoomsStream() {
    return _chatsCol
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => ChatRoomModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Stream active conversation for a specific owner
  Stream<ChatRoomModel?> getOwnerChatRoomStream(String ownerId) {
    final roomId = getRoomId(ownerId);
    return _chatsCol.doc(roomId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return ChatRoomModel.fromMap(doc.data()!, doc.id);
    });
  }

  // Stream messages in a chat room (ordered by createdAt ascending)
  Stream<List<MessageModel>> getMessagesStream(String roomId) {
    return _chatsCol
        .doc(roomId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => MessageModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Send a message (Admin ↔ Owner)
  Future<void> sendMessage({
    required String roomId,
    required String senderId,
    required String senderName,
    required String content,
    required bool isAdminSender,
  }) async {
    final batch = _db.batch();

    // 1. Add message document
    final messageDocRef = _chatsCol.doc(roomId).collection('messages').doc();
    final message = MessageModel(
      id: '',
      senderId: senderId,
      senderName: senderName,
      content: content,
      createdAt: DateTime.now(),
      isRead: false,
    );
    batch.set(messageDocRef, message.toMap());

    // 2. Update room summary
    final roomDocRef = _chatsCol.doc(roomId);
    final Map<String, dynamic> roomUpdate = {
      'lastMessage': content,
      'lastMessageTime': FieldValue.serverTimestamp(),
    };

    if (isAdminSender) {
      roomUpdate['unreadCountByOwner'] = FieldValue.increment(1);
    } else {
      roomUpdate['unreadCountByAdmin'] = FieldValue.increment(1);
    }

    batch.update(roomDocRef, roomUpdate);
    await batch.commit();
  }

  // Clear unread counts for admin
  Future<void> clearUnreadForAdmin(String roomId) async {
    await _chatsCol.doc(roomId).update({'unreadCountByAdmin': 0});
  }

  // Clear unread counts for owner
  Future<void> clearUnreadForOwner(String roomId) async {
    await _chatsCol.doc(roomId).update({'unreadCountByOwner': 0});
  }

  // Mark all unread messages in admin-owner room as read
  Future<void> markAdminOwnerMessagesRead(
      String roomId, String readerUid) async {
    final snap = await _chatsCol
        .doc(roomId)
        .collection('messages')
        .where('isRead', isEqualTo: false)
        .where('senderId', isNotEqualTo: readerUid)
        .get();

    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  // ── Owner ↔ Student chats ────────────────────────────────────────────────
  CollectionReference<Map<String, dynamic>> get _owStCol =>
      _db.collection('ow_st_chats');

  /// Deterministic room ID between owner and student
  String getOwnerStudentRoomId(String ownerId, String studentId) =>
      '${ownerId}_$studentId';

  /// Get or create an owner-student chat room (with retry for transient errors)
  Future<OwnerStudentChatRoomModel> getOrCreateOwnerStudentRoom({
    required String ownerId,
    required String ownerName,
    required String studentId,
    required String studentName,
    required String hostelId,
    required String hostelName,
  }) async {
    const maxAttempts = 4;
    int attempt = 0;

    while (true) {
      try {
        final roomId = getOwnerStudentRoomId(ownerId, studentId);
        final docRef = _owStCol.doc(roomId);
        final snap = await docRef.get();

        if (snap.exists) {
          return OwnerStudentChatRoomModel.fromMap(snap.data()!, snap.id);
        } else {
          final room = OwnerStudentChatRoomModel(
            id: roomId,
            ownerId: ownerId,
            ownerName: ownerName,
            studentId: studentId,
            studentName: studentName,
            hostelId: hostelId,
            hostelName: hostelName,
            lastMessage: 'Conversation started',
            lastMessageTime: DateTime.now(),
            lastMessageSenderId: ownerId,
            unreadByStudent: 0,
            unreadByOwner: 0,
          );
          await docRef.set(room.toMap());
          return room;
        }
      } catch (e) {
        attempt++;
        final isTransient = e.toString().contains('unavailable') ||
            e.toString().contains('network') ||
            e.toString().contains('deadline');

        if (!isTransient || attempt >= maxAttempts) rethrow;

        // Exponential backoff: 500ms, 1s, 2s
        final delay = Duration(milliseconds: 500 * (1 << (attempt - 1)));
        await Future.delayed(delay);
      }
    }
  }

  /// Stream all owner-student rooms for a given owner
  Stream<List<OwnerStudentChatRoomModel>> getOwnerStudentRoomsForOwner(
      String ownerId) {
    return _owStCol
        .where('ownerId', isEqualTo: ownerId)
        .snapshots()
        .map((snap) {
          final list = snap.docs
              .map((d) => OwnerStudentChatRoomModel.fromMap(d.data(), d.id))
              .toList();
          list.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
          return list;
        });
  }

  /// Stream all owner-student rooms for a given student
  Stream<List<OwnerStudentChatRoomModel>> getOwnerStudentRoomsForStudent(
      String studentId) {
    return _owStCol
        .where('studentId', isEqualTo: studentId)
        .snapshots()
        .map((snap) {
          final list = snap.docs
              .map((d) => OwnerStudentChatRoomModel.fromMap(d.data(), d.id))
              .toList();
          list.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
          return list;
        });
  }

  /// Stream messages in an owner-student room
  Stream<List<MessageModel>> getOwnerStudentMessagesStream(String roomId) {
    return _owStCol
        .doc(roomId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => MessageModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Send a message in an owner-student room; also fires a Firestore notification
  Future<void> sendOwnerStudentMessage({
    required String roomId,
    required String senderId,
    required String senderName,
    required String content,
    required bool isOwnerSender,
    // Recipient info for notification
    required String recipientId,
    required String hostelName,
  }) async {
    final batch = _db.batch();

    // 1. Add message
    final msgRef = _owStCol.doc(roomId).collection('messages').doc();
    batch.set(msgRef, {
      'senderId': senderId,
      'senderName': senderName,
      'content': content,
      'createdAt': FieldValue.serverTimestamp(),
      'isRead': false,
    });

    // 2. Update room summary
    final Map<String, dynamic> update = {
      'lastMessage': content,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'lastMessageSenderId': senderId,
    };
    if (isOwnerSender) {
      update['unreadByStudent'] = FieldValue.increment(1);
    } else {
      update['unreadByOwner'] = FieldValue.increment(1);
    }
    batch.update(_owStCol.doc(roomId), update);

    await batch.commit();

    // 3. Send in-app notification to recipient
    try {
      final notifService = Get.find<NotificationService>();
      await notifService.sendNotification(
        userId: recipientId,
        title: isOwnerSender ? 'New message from $senderName' : 'New message from $senderName',
        body: content.length > 80 ? '${content.substring(0, 80)}...' : content,
        type: 'chat_message',
        relatedId: roomId,
      );
    } catch (_) {
      // Notification is best-effort; do not fail the send
    }
  }

  /// Mark all messages sent by the other party as read in an owner-student room
  Future<void> markOwnerStudentMessagesRead(
      String roomId, String readerUid) async {
    final snap = await _owStCol
        .doc(roomId)
        .collection('messages')
        .where('isRead', isEqualTo: false)
        .get();

    final batch = _db.batch();
    for (final doc in snap.docs) {
      final data = doc.data();
      // Only mark messages from the other person as read
      if ((data['senderId'] ?? '') != readerUid) {
        batch.update(doc.reference, {'isRead': true});
      }
    }
    await batch.commit();
  }

  /// Clear unread count for student
  Future<void> clearUnreadByStudent(String roomId) async {
    await _owStCol.doc(roomId).update({'unreadByStudent': 0});
  }

  /// Clear unread count for owner (when owner views student messages)
  Future<void> clearUnreadByOwner(String roomId) async {
    await _owStCol.doc(roomId).update({'unreadByOwner': 0});
  }
}
