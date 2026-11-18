// ─────────────────────────────────────────────────────────────────────────────
// Manages booking state for students, owners, and admins.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:async';

import 'package:fyp/controllers/AuthController.dart';
import 'package:fyp/models/BookingModel.dart';
import 'package:fyp/models/HostelModel.dart';
import 'package:fyp/services/BookingService.dart';
import 'package:fyp/services/NotificationService.dart';
import 'package:fyp/utils/AppConstants.dart';
import 'package:get/get.dart';


class BookingController extends GetxController {
  
  final BookingService _bookingService = Get.find<BookingService>();
  final NotificationService _notificationService =Get.find<NotificationService>();
  final AuthController _authController = Get.find<AuthController>();

  // ── Observable state ──────────────────────────────────────────────────────
  final RxList<BookingModel> myBookings = <BookingModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isBookingsLoaded = false.obs;

  StreamSubscription<List<BookingModel>>? _bookingsSub;

  @override
  void onInit() {
    super.onInit();
    // Re-subscribe reactive to auth status changes
    ever(_authController.currentUser, (user) {
      _subscribeToBookings(user);
    });
    _subscribeToBookings(_authController.currentUser.value);
  }

  void _subscribeToBookings(dynamic user) {
    _bookingsSub?.cancel();
    if (user == null) {
      myBookings.clear();
      isBookingsLoaded.value = true;
      return;
    }
    isBookingsLoaded.value = false;
    if (_authController.isStudent) {
      _bookingsSub = _bookingService
          .getStudentBookingsStream(user.uid)
          .listen((bookings) {
        myBookings.value = bookings;
        isBookingsLoaded.value = true;
      });
    } else if (_authController.isOwner) {
      _bookingsSub = _bookingService
          .getOwnerBookingsStream(user.uid)
          .listen((bookings) {
        myBookings.value = bookings;
        isBookingsLoaded.value = true;
      });
    } else {
      isBookingsLoaded.value = true;
    }
  }

  @override
  void onClose() {
    _bookingsSub?.cancel();
    super.onClose();
  }

  // ────────────────────────────────────────────────────────────────────────────
  // FR-5.1: Student requests a booking
  // ────────────────────────────────────────────────────────────────────────────
  Future<bool> requestBooking({
    required HostelModel hostel,
    required DateTime checkInDate,
    required DateTime checkOutDate,
    String? roomId,
    String? roomNumber,
  }) async {
    try {
      isLoading.value = true;

      final student = _authController.currentUser.value!;

      // Check if student already has an active booking for this hostel
      final alreadyBooked = await _bookingService.hasActiveBooking(
        student.uid,
        hostel.id,
      );

      if (alreadyBooked) {
        Get.snackbar(
          'Already Booked',
          'You already have an active booking for this hostel.',
          snackPosition: SnackPosition.BOTTOM,
        );
        return false;
      }

      // Calculate total amount (check-out − check-in in months × rent)
      final months = checkOutDate.difference(checkInDate).inDays / 30;
      final totalAmount = hostel.rentPerMonth * months;

      final booking = BookingModel(
        id: '',
        studentId: student.uid,
        studentName: student.name,
        studentEmail: student.email,
        hostelId: hostel.id,
        hostelName: hostel.name,
        ownerId: hostel.ownerId,
        roomId: roomId,
        roomNumber: roomNumber,
        checkInDate: checkInDate,
        checkOutDate: checkOutDate,
        totalAmount: totalAmount,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _bookingService.createBooking(booking);

      // FR-9.2: Notify the hostel owner about new booking request
      final roomMsg = (roomNumber != null && roomNumber.isNotEmpty)
          ? ' for $roomNumber'
          : '';
      await _notificationService.sendNotification(
        userId: hostel.ownerId,
        title: 'New Booking Request',
        body: '${student.name} requested to book ${hostel.name}$roomMsg.',
        type: 'booking',
      );

      Get.snackbar(
        'Request Sent',
        'Your booking request has been sent to the owner.',
        snackPosition: SnackPosition.BOTTOM,
      );

      return true;
    } catch (e) {
      Get.snackbar('Error', 'Booking failed. Please try again.');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // ────────────────────────────────────────────────────────────────────────────
  // FR-5.2: Owner accepts or rejects a booking
  // FR-5.3: Room availability is updated after confirmation
  // FR-10.2: Executed via atomic Firestore Transaction
  // ────────────────────────────────────────────────────────────────────────────
  Future<void> respondToBooking(
    BookingModel booking,
    String status, {
    String? note,
    String? assignedRoomId,
    String? assignedRoomNumber,
    String? assignedBedNumber,
  }) async {
    try {
      isLoading.value = true;

      // Execute atomic transaction for status update + room availability + stats
      await _bookingService.respondToBookingWithTransaction(
        booking.id,
        booking.hostelId,
        status,
        ownerNote: note,
        assignedRoomId: assignedRoomId,
        assignedRoomNumber: assignedRoomNumber,
        assignedBedNumber: assignedBedNumber,
      );

      // FR-9.1: Notify the student of the decision
      final statusMsg = status == AppConstants.bookingConfirmed
          ? 'confirmed'
          : 'rejected';
      await _notificationService.sendNotification(
        userId: booking.studentId,
        title: 'Booking $statusMsg',
        body: 'Your booking for ${booking.hostelName} has been $statusMsg.',
        type: 'booking',
        relatedId: booking.id,
      );

      Get.snackbar('Done', 'Booking $statusMsg successfully.');
    } catch (e) {
      Get.snackbar('Error', e.toString().replaceFirst('Exception: ', ''));
    } finally {
      isLoading.value = false;
    }
  }

  // ────────────────────────────────────────────────────────────────────────────
  // FR-5.4: Student cancels a booking
  // FR-10.2: Executed via atomic Firestore Transaction
  // ────────────────────────────────────────────────────────────────────────────
  Future<void> cancelBooking(BookingModel booking) async {
    try {
      await _bookingService.cancelBookingWithTransaction(
        booking.id,
        booking.hostelId,
        booking.status,
      );

      Get.snackbar('Cancelled', 'Booking cancelled successfully.');
    } catch (e) {
      Get.snackbar('Error', 'Could not cancel booking.');
    }
  }

  // ── Get pending bookings count (for notification badge) ───────────────────
  int get pendingBookingsCount =>
      myBookings.where((b) => b.status == AppConstants.bookingPending).length;
}

