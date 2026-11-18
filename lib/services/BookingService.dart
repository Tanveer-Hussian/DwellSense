import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:fyp/models/BookingModel.dart';
import 'package:fyp/models/HostelModel.dart';
import 'package:fyp/models/RoomModel.dart';
import 'package:fyp/utils/AppConstants.dart';

// ─────────────────────────────────────────────────────────────────────────────
// BookingService
// ─────────────────────────────────────────────────────────────────────────────
class BookingService extends GetxService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection(AppConstants.colBookings);

  // FR-5.1: Student submits a booking request
  Future<String> createBooking(BookingModel booking) async {
    final docRef = await _col.add(booking.toMap());
    return docRef.id;
  }

  // FR-5.2 / FR-5.3 / FR-10.2: Respond to booking status atomically via Firestore Transaction
  // Assigns a specific vacant bed at a specific room, fills the vacancy slot, and updates hostel room vacancies.
  Future<void> respondToBookingWithTransaction(
    String bookingId,
    String hostelId,
    String status, {
    String? ownerNote,
    String? assignedRoomId,
    String? assignedRoomNumber,
    String? assignedBedNumber,
  }) async {
    await _db.runTransaction((transaction) async {
      final bookingRef = _col.doc(bookingId);
      final hostelRef = _db.collection(AppConstants.colHostels).doc(hostelId);

      final bookingSnap = await transaction.get(bookingRef);
      if (!bookingSnap.exists) {
        throw Exception('Booking document does not exist.');
      }
      final bookingData = bookingSnap.data()!;
      final studentId = bookingData['studentId']?.toString() ?? '';
      final studentName = bookingData['studentName']?.toString() ?? 'Student';
      final targetRoomId = assignedRoomId ?? bookingData['roomId']?.toString();

      final hostelSnap = await transaction.get(hostelRef);
      if (!hostelSnap.exists) {
        throw Exception('Hostel document does not exist.');
      }
      final hostelData = hostelSnap.data()!;

      // 1. Prepare booking updates
      final bookingUpdates = <String, dynamic>{
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (ownerNote != null) bookingUpdates['ownerNote'] = ownerNote;

      // 2. Prepare hostel updates
      final hostelUpdates = <String, dynamic>{
        'totalBookings': FieldValue.increment(1),
      };

      if (status == AppConstants.bookingConfirmed) {
        final parsedHostel = HostelModel.fromMap(hostelData, hostelId);
        List<RoomModel> currentRooms = List.from(parsedHostel.rooms);

        // Find the requested/assigned room with available vacancy
        int roomIndex = -1;
        if (targetRoomId != null && targetRoomId.isNotEmpty) {
          roomIndex = currentRooms.indexWhere((r) => r.id == targetRoomId && r.hasVacancy);
        }

        // If requested room not found or filled, pick the first available room with vacancy
        if (roomIndex == -1) {
          roomIndex = currentRooms.indexWhere((r) => r.hasVacancy);
        }

        if (roomIndex == -1) {
          throw Exception('Cannot confirm booking: The selected room or all rooms are fully occupied. No vacancy remaining.');
        }

        final selectedRoom = currentRooms[roomIndex];
        final updatedStudentIds = List<String>.generate(
          selectedRoom.capacity,
          (i) => (i < selectedRoom.assignedStudents.length) ? selectedRoom.assignedStudents[i] : '',
        );
        final updatedStudentNames = List<String>.generate(
          selectedRoom.capacity,
          (i) => (i < selectedRoom.assignedStudentNames.length) ? selectedRoom.assignedStudentNames[i] : '',
        );

        // Find target bed slot
        int targetBedIndex = -1;
        if (assignedBedNumber != null && assignedBedNumber.startsWith('Bed ')) {
          final numStr = assignedBedNumber.replaceAll('Bed ', '').trim();
          final parsed = int.tryParse(numStr);
          if (parsed != null && parsed >= 1 && parsed <= selectedRoom.capacity) {
            targetBedIndex = parsed - 1;
          }
        }
        // If no slot or slot already occupied, find first vacant bed slot
        if (targetBedIndex == -1 || updatedStudentIds[targetBedIndex].trim().isNotEmpty) {
          targetBedIndex = updatedStudentIds.indexWhere((id) => id.trim().isEmpty);
        }

        if (targetBedIndex != -1 && targetBedIndex < selectedRoom.capacity) {
          updatedStudentIds[targetBedIndex] = studentId;
          updatedStudentNames[targetBedIndex] = studentName;
        }

        final updatedRoom = selectedRoom.copyWith(
          assignedStudents: updatedStudentIds,
          assignedStudentNames: updatedStudentNames,
        );

        currentRooms[roomIndex] = updatedRoom;

        // Compute rooms that still have vacancy
        final remainingAvailableRooms = currentRooms.where((r) => r.hasVacancy).length;

        hostelUpdates['rooms'] = currentRooms.map((r) => r.toMap()).toList();
        hostelUpdates['availableRooms'] = remainingAvailableRooms;
        hostelUpdates['confirmedBookings'] = FieldValue.increment(1);

        // Record assigned room and bed details in booking document
        final effectiveBedNumber = targetBedIndex != -1 ? 'Bed ${targetBedIndex + 1}' : assignedBedNumber;
        bookingUpdates['roomId'] = updatedRoom.id;
        bookingUpdates['roomNumber'] = assignedRoomNumber ?? updatedRoom.roomNumber;
        if (effectiveBedNumber != null && effectiveBedNumber.isNotEmpty) {
          bookingUpdates['bedNumber'] = effectiveBedNumber;
        }
      }

      transaction.update(bookingRef, bookingUpdates);
      transaction.update(hostelRef, hostelUpdates);
    });
  }

  // FR-5.4 / FR-10.2: Cancel booking atomically via Firestore Transaction
  // Restores room vacancy slot if booking was confirmed
  Future<void> cancelBookingWithTransaction(
    String bookingId,
    String hostelId,
    String previousStatus,
  ) async {
    await _db.runTransaction((transaction) async {
      final bookingRef = _col.doc(bookingId);
      final hostelRef = _db.collection(AppConstants.colHostels).doc(hostelId);

      final bookingSnap = await transaction.get(bookingRef);
      if (!bookingSnap.exists) {
        throw Exception('Booking document does not exist.');
      }
      final bookingData = bookingSnap.data()!;
      final studentId = bookingData['studentId']?.toString() ?? '';
      final bookedRoomId = bookingData['roomId']?.toString();

      final hostelSnap = await transaction.get(hostelRef);

      // Update booking status
      transaction.update(bookingRef, {
        'status': AppConstants.bookingCancelled,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Restore available room vacancy if booking was confirmed
      if (previousStatus == AppConstants.bookingConfirmed && hostelSnap.exists) {
        final hostelData = hostelSnap.data()!;
        final parsedHostel = HostelModel.fromMap(hostelData, hostelId);
        List<RoomModel> currentRooms = List.from(parsedHostel.rooms);

        int roomIndex = -1;
        if (bookedRoomId != null && bookedRoomId.isNotEmpty) {
          roomIndex = currentRooms.indexWhere((r) => r.id == bookedRoomId);
        }
        if (roomIndex == -1 && studentId.isNotEmpty) {
          roomIndex = currentRooms.indexWhere((r) => r.assignedStudents.contains(studentId));
        }

        if (roomIndex != -1) {
          final targetRoom = currentRooms[roomIndex];
          final updatedStudentIds = List<String>.from(targetRoom.assignedStudents);
          final updatedStudentNames = List<String>.from(targetRoom.assignedStudentNames);
          final studentIdx = updatedStudentIds.indexOf(studentId);
          if (studentIdx != -1) {
            updatedStudentIds[studentIdx] = '';
            if (studentIdx < updatedStudentNames.length) {
              updatedStudentNames[studentIdx] = '';
            }
          }

          currentRooms[roomIndex] = targetRoom.copyWith(
            assignedStudents: updatedStudentIds,
            assignedStudentNames: updatedStudentNames,
          );

          final remainingAvailableRooms = currentRooms.where((r) => r.hasVacancy).length;

          transaction.update(hostelRef, {
            'rooms': currentRooms.map((r) => r.toMap()).toList(),
            'availableRooms': remainingAvailableRooms,
          });
        } else {
          transaction.update(hostelRef, {
            'availableRooms': FieldValue.increment(1),
          });
        }
      }
    });
  }

  // Helper to auto-cancel unpaid expired bookings (Method A)
  void _checkAndCancelExpired(List<BookingModel> bookings) {
    for (var b in bookings) {
      if (b.isPaymentExpired) {
        // Run in background to free bed automatically
        cancelBookingWithTransaction(b.id, b.hostelId, b.status);
      }
    }
  }

  // Student booking history — sorted client-side to avoid composite index
  Stream<List<BookingModel>> getStudentBookingsStream(String studentId) {
    return _col
        .where('studentId', isEqualTo: studentId)
        .snapshots()
        .map((snap) {
          final list = snap.docs
              .map((doc) => BookingModel.fromMap(doc.data(), doc.id))
              .toList();
          _checkAndCancelExpired(list);
          list.sort((a, b) { final aTime = a.createdAt; final bTime = b.createdAt; return bTime.compareTo(aTime); });
          return list;
        });
  }

  // Owner booking requests — sorted client-side
  Stream<List<BookingModel>> getOwnerBookingsStream(String ownerId) {
    return _col
        .where('ownerId', isEqualTo: ownerId)
        .snapshots()
        .map((snap) {
          final list = snap.docs
              .map((doc) => BookingModel.fromMap(doc.data(), doc.id))
              .toList();
          _checkAndCancelExpired(list);
          list.sort((a, b) { final aTime = a.createdAt; final bTime = b.createdAt; return bTime.compareTo(aTime); });
          return list;
        });
  }

  // All bookings admin view — sort client-side
  Stream<List<BookingModel>> getAllBookingsStream() {
    return _col
        .snapshots()
        .map((snap) {
          final list = snap.docs
              .map((doc) => BookingModel.fromMap(doc.data(), doc.id))
              .toList();
          _checkAndCancelExpired(list);
          list.sort((a, b) { final aTime = a.createdAt; final bTime = b.createdAt; return bTime.compareTo(aTime); });
          return list;
        });
  }

  // ── Auto-Expire bookings & release bed vacancies ────────────────────────
  // Checks if any confirmed booking has passed its checkout date.
  // If expired, marks status as 'expired', removes student from room assigned lists,
  // and increments room vacancies so the bed immediately displays as vacant.
  Future<void> reconcileExpiredBookingsForHostel(String hostelId) async {
    try {
      final now = DateTime.now();
      final snap = await _col
          .where('hostelId', isEqualTo: hostelId)
          .where('status', isEqualTo: AppConstants.bookingConfirmed)
          .get();

      final expiredDocs = snap.docs.where((doc) {
        final data = doc.data();
        final checkOut = (data['checkOutDate'] is Timestamp)
            ? (data['checkOutDate'] as Timestamp).toDate()
            : DateTime.tryParse(data['checkOutDate']?.toString() ?? '');
        return checkOut != null && checkOut.isBefore(now);
      }).toList();

      if (expiredDocs.isEmpty) return;

      final hostelRef = _db.collection(AppConstants.colHostels).doc(hostelId);
      final hostelSnap = await hostelRef.get();
      if (!hostelSnap.exists || hostelSnap.data() == null) return;

      final hostel = HostelModel.fromMap(hostelSnap.data()!, hostelId);
      List<RoomModel> updatedRooms = List.from(hostel.rooms);

      for (final doc in expiredDocs) {
        final data = doc.data();
        final studentId = data['studentId']?.toString() ?? '';
        final roomId = data['roomId']?.toString();

        // 1. Mark booking document as expired in Firestore
        await doc.reference.update({
          'status': AppConstants.bookingExpired,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // 2. Locate room and free up the bed
        int roomIdx = -1;
        if (roomId != null && roomId.isNotEmpty) {
          roomIdx = updatedRooms.indexWhere((r) => r.id == roomId);
        }
        if (roomIdx == -1 && studentId.isNotEmpty) {
          roomIdx = updatedRooms.indexWhere((r) => r.assignedStudents.contains(studentId));
        }

        if (roomIdx != -1) {
          final room = updatedRooms[roomIdx];
          final newStudentIds = List<String>.from(room.assignedStudents);
          final newStudentNames = List<String>.from(room.assignedStudentNames);
          final studentIdx = newStudentIds.indexOf(studentId);
          if (studentIdx != -1) {
            newStudentIds[studentIdx] = '';
            if (studentIdx < newStudentNames.length) {
              newStudentNames[studentIdx] = '';
            }
          }

          updatedRooms[roomIdx] = room.copyWith(
            assignedStudents: newStudentIds,
            assignedStudentNames: newStudentNames,
          );
        }
      }

      final remainingAvailableRooms = updatedRooms.where((r) => r.hasVacancy).length;
      await hostelRef.update({
        'rooms': updatedRooms.map((r) => r.toMap()).toList(),
        'availableRooms': remainingAvailableRooms,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  // Reconciles all hostels for an owner
  Future<void> reconcileAllExpiredBookingsForOwner(String ownerId) async {
    try {
      final snap = await _db
          .collection(AppConstants.colHostels)
          .where('ownerId', isEqualTo: ownerId)
          .get();
      for (final doc in snap.docs) {
        await reconcileExpiredBookingsForHostel(doc.id);
      }
    } catch (_) {}
  }

  // Check for existing active booking (pending or active confirmed)
  Future<bool> hasActiveBooking(String studentId, String hostelId) async {
    final snap = await _col
        .where('studentId', isEqualTo: studentId)
        .where('hostelId', isEqualTo: hostelId)
        .where('status', whereIn: [AppConstants.bookingPending, AppConstants.bookingConfirmed])
        .get();

    final now = DateTime.now();
    for (final doc in snap.docs) {
      final data = doc.data();
      final status = data['status']?.toString();
      if (status == AppConstants.bookingPending) return true;
      if (status == AppConstants.bookingConfirmed) {
        final checkOut = (data['checkOutDate'] is Timestamp)
            ? (data['checkOutDate'] as Timestamp).toDate()
            : DateTime.tryParse(data['checkOutDate']?.toString() ?? '');
        if (checkOut != null && checkOut.isAfter(now)) {
          return true; // Still active
        }
      }
    }
    return false;
  }

  // Check if student has ever booked (confirmed or expired) this hostel - used for allowing reviews
  Future<bool> hasEverBookedHostel(String studentId, String hostelId) async {
    final snap = await _col
        .where('studentId', isEqualTo: studentId)
        .where('hostelId', isEqualTo: hostelId)
        .where('status', whereIn: [AppConstants.bookingConfirmed, AppConstants.bookingExpired])
        .limit(1) // Optimization: we only need to know if at least one exists
        .get();
    
    return snap.docs.isNotEmpty;
  }

  // ── FR-PAY: Mark booking as paid via Safepay ───────────────────────────────
  Future<void> markAsPaid(String bookingId) async {
    await _col.doc(bookingId).update({
      'paymentStatus' : 'paid',
      'paymentMethod' : 'safepay',
      'paidAt'        : FieldValue.serverTimestamp(),
      'updatedAt'     : FieldValue.serverTimestamp(),
    });
  }

  // ── Active residents for a hostel (confirmed + not expired) ───────────────
  Future<List<BookingModel>> getActiveBookingsByHostel(String hostelId) async {
    final now = DateTime.now();
    final snap = await _col
        .where('hostelId', isEqualTo: hostelId)
        .where('status', isEqualTo: AppConstants.bookingConfirmed)
        .get();

    return snap.docs
        .map((doc) => BookingModel.fromMap(doc.data(), doc.id))
        .where((b) => b.checkOutDate.isAfter(now))   // non-expired only
        .toList()
      ..sort((a, b) => a.checkOutDate.compareTo(b.checkOutDate));
  }
}
