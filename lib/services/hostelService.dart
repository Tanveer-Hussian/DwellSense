import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fyp/utils/AppConstants.dart';
import 'package:get/get.dart';
import 'package:fyp/models/HostelModel.dart';
import 'package:fyp/models/RoomModel.dart';


class HostelService extends GetxService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection(AppConstants.colHostels);

  // FR-3.1: Add a new hostel listing
  Future<String> addHostel(HostelModel hostel) async {
    final docRef = await _col.add(hostel.toMap());
    return docRef.id;
  }

  // FR-3.4: Update hostel
  Future<void> updateHostel(
      String hostelId, Map<String, dynamic> updates) async {
    updates['updatedAt'] = FieldValue.serverTimestamp();
    await _col.doc(hostelId).update(updates);
  }

  // FR-3.4: Delete hostel (called by admin upon accepting un-registration request or admin deletion)
  Future<void> deleteHostel(String hostelId) async {
    await _col.doc(hostelId).delete();
  }

  // Owner submits request to admin to unregister / close hostel with reason
  Future<void> requestUnregistration(String hostelId, String reason) async {
    await _col.doc(hostelId).update({
      'unregistrationRequested': true,
      'unregistrationReason': reason,
      'unregistrationRequestedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Admin rejects unregistration request — hostel remains registered and active
  Future<void> rejectUnregistration(String hostelId) async {
    await _col.doc(hostelId).update({
      'unregistrationRequested': false,
      'unregistrationReason': FieldValue.delete(),
      'unregistrationRequestedAt': FieldValue.delete(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // FR-8.1: Admin approves or rejects a listing, optionally assigning registration number
  Future<void> updateHostelStatus(
    String hostelId,
    String status, {
    String? registrationNumber,
  }) async {
    final updates = <String, dynamic>{
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (registrationNumber != null && registrationNumber.isNotEmpty) {
      updates['registrationNumber'] = registrationNumber;
    }
    await _col.doc(hostelId).update(updates);
  }

  // Admin assigns or updates registration number for any hostel
  Future<void> updateRegistrationNumber(
    String hostelId,
    String registrationNumber,
  ) async {
    await _col.doc(hostelId).update({
      'registrationNumber': registrationNumber,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // FR-4.1 & FR-4.2: Stream approved hostels with optional filters
  // Uses only .where('status') — single field, auto-indexed.
  // All other filters applied client-side to avoid composite index requirement.
  Stream<List<HostelModel>> getApprovedHostelsStream({
    String? city,
    String? genderPreference,
    double? minRent,
    double? maxRent,
  }) {
    return _col
        .where('status', isEqualTo: AppConstants.statusApproved)
        // NO .orderBy here — sort client-side
        .snapshots()
        .map((snap) {
          var list = snap.docs
              .map((doc) => HostelModel.fromMap(doc.data(), doc.id))
              .toList();

          // Client-side filters
          if (city != null && city.isNotEmpty) {
            list = list.where((h) => h.city == city).toList();
          }
          if (genderPreference != null && genderPreference.isNotEmpty) {
            list = list
                .where((h) => h.genderPreference == genderPreference)
                .toList();
          }
          if (minRent != null) {
            list = list.where((h) => h.rentPerMonth >= minRent).toList();
          }
          if (maxRent != null) {
            list = list.where((h) => h.rentPerMonth <= maxRent).toList();
          }

          // Sort client-side — newest first
          list.sort((a, b) { final aTime = a.createdAt; final bTime = b.createdAt; return bTime.compareTo(aTime); });
          return list;
        });
  }

  // Owner's own listings — sort client-side
  Stream<List<HostelModel>> getOwnerHostelsStream(String ownerId) {
    return _col
        .where('ownerId', isEqualTo: ownerId)
        // NO .orderBy — sort client-side
        .snapshots()
        .map((snap) {
          final list = snap.docs
              .map((doc) => HostelModel.fromMap(doc.data(), doc.id))
              .toList();
          list.sort((a, b) { final aTime = a.createdAt; final bTime = b.createdAt; return bTime.compareTo(aTime); });
          return list;
        });
  }

  // All hostels for admin — sort client-side to handle missing/pending createdAt fields
  Stream<List<HostelModel>> getAllHostelsStream() {
    return _col
        .snapshots()
        .map((snap) {
          final list = snap.docs
              .map((doc) => HostelModel.fromMap(doc.data(), doc.id))
              .toList();
          list.sort((a, b) { final aTime = a.createdAt; final bTime = b.createdAt; return bTime.compareTo(aTime); });
          return list;
        });
  }

  // Pending hostels for admin approval queue — sort client-side
  Stream<List<HostelModel>> getPendingHostelsStream() {
    return _col
        .where('status', isEqualTo: AppConstants.statusPending)
        // NO .orderBy — sort client-side
        .snapshots()
        .map((snap) {
          final list = snap.docs
              .map((doc) => HostelModel.fromMap(doc.data(), doc.id))
              .toList();
          list.sort((a, b) { final aTime = a.createdAt; final bTime = b.createdAt; return bTime.compareTo(aTime); });
          return list;
        });
  }

  // Fetch single hostel by ID
  Future<HostelModel?> getHostelById(String hostelId) async {
    final doc = await _col.doc(hostelId).get();
    if (!doc.exists) return null;
    return HostelModel.fromMap(doc.data()!, doc.id);
  }

  // Stream a single hostel for real-time room vacancy and detail updates
  Stream<HostelModel?> getHostelStream(String hostelId) {
    return _col.doc(hostelId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return HostelModel.fromMap(doc.data()!, doc.id);
    });
  }

  // Decrement available rooms after confirmed booking
  Future<void> decrementAvailableRooms(String hostelId) async {
    await _col.doc(hostelId).update({
      'availableRooms': FieldValue.increment(-1),
    });
  }

  // Increment available rooms after cancellation
  Future<void> incrementAvailableRooms(String hostelId) async {
    await _col.doc(hostelId).update({
      'availableRooms': FieldValue.increment(1),
    });
  }

  // Update average rating using a transaction for consistency
  Future<void> updateHostelRating(String hostelId, double newRating) async {
    await _db.runTransaction((transaction) async {
      final docRef = _col.doc(hostelId);
      final snap = await transaction.get(docRef);
      if (!snap.exists) return;

      final currentAvg = (snap.data()!['averageRating'] ?? 0.0).toDouble();
      final currentCount = (snap.data()!['totalReviews'] ?? 0) as int;
      final newCount = currentCount + 1;
      final newAvg = ((currentAvg * currentCount) + newRating) / newCount;

      transaction.update(docRef, {
        'averageRating': double.parse(newAvg.toStringAsFixed(1)),
        'totalReviews': newCount,
      });
    });
  }

  // ── FR-9: Atomically update ranking stat counters ─────────────────────────
  // Called by BookingController / ComplaintController after state changes.
  // Each parameter is a delta (e.g. +1 or -1) applied via FieldValue.increment.
  Future<void> updateHostelStats(
    String hostelId, {
    int totalBookingsDelta = 0,
    int confirmedBookingsDelta = 0,
    int totalComplaintsDelta = 0,
    int resolvedComplaintsDelta = 0,
    int resolutionTimeHoursDelta = 0,
  }) async {
    final updates = <String, dynamic>{};
    if (totalBookingsDelta != 0) {
      updates['totalBookings'] = FieldValue.increment(totalBookingsDelta);
    }
    if (confirmedBookingsDelta != 0) {
      updates['confirmedBookings'] = FieldValue.increment(confirmedBookingsDelta);
    }
    if (totalComplaintsDelta != 0) {
      updates['totalComplaints'] = FieldValue.increment(totalComplaintsDelta);
    }
    if (resolvedComplaintsDelta != 0) {
      updates['resolvedComplaints'] = FieldValue.increment(resolvedComplaintsDelta);
    }
    if (resolutionTimeHoursDelta != 0) {
      updates['totalResolutionTimeHours'] = FieldValue.increment(resolutionTimeHoursDelta);
    }
    if (updates.isNotEmpty) {
      await _col.doc(hostelId).update(updates);
    }
  }

  // ── Manual Bed Allocation: Atomically update room's assigned students ────
  // Used by owners to manually mark beds as occupied/vacant and by admins
  // to vacate manually-assigned beds.
  Future<void> updateRoomAllocation(
    String hostelId,
    String roomId, {
    required List<String> assignedStudents,
    required List<String> assignedStudentNames,
  }) async {
    await _db.runTransaction((transaction) async {
      final hostelRef = _col.doc(hostelId);
      final hostelSnap = await transaction.get(hostelRef);
      if (!hostelSnap.exists || hostelSnap.data() == null) {
        throw Exception('Hostel document does not exist.');
      }

      final hostel = HostelModel.fromMap(hostelSnap.data()!, hostelId);
      List<RoomModel> updatedRooms = List.from(hostel.rooms);

      final roomIdx = updatedRooms.indexWhere((r) => r.id == roomId);
      if (roomIdx == -1) {
        throw Exception('Room not found in hostel.');
      }

      final room = updatedRooms[roomIdx];
      updatedRooms[roomIdx] = room.copyWith(
        assignedStudents: assignedStudents,
        assignedStudentNames: assignedStudentNames,
      );

      final remainingAvailableRooms =
          updatedRooms.where((r) => r.hasVacancy).length;

      transaction.update(hostelRef, {
        'rooms': updatedRooms.map((r) => r.toMap()).toList(),
        'availableRooms': remainingAvailableRooms,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }
}
