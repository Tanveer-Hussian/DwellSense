import 'package:cloud_firestore/cloud_firestore.dart';

// lib/models/BookingModel.dart
// ─────────────────────────────────────────────────────────────────────────────
// Represents a booking/reservation request made by a student.
// Stored in Firestore: /bookings/{bookingId}
// ─────────────────────────────────────────────────────────────────────────────

class BookingModel {
  final String id;
  final String studentId;
  final String studentName;
  final String studentEmail;
  final String hostelId;
  final String hostelName;
  final String ownerId;
  final String? roomId;        // ID of assigned/requested room
  final String? roomNumber;    // Display number of assigned/requested room e.g. "Room 1"
  final String? bedNumber;     // Assigned bed e.g. "Bed 1", "Bed 2"
  final DateTime checkInDate;
  final DateTime checkOutDate;
  final double totalAmount;
  final String status; // 'pending' | 'confirmed' | 'rejected' | 'cancelled'
  final String paymentStatus; // 'unpaid' | 'paid'
  final String? ownerNote; // Owner's response message
  final DateTime createdAt;
  final DateTime updatedAt;

  BookingModel({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.studentEmail,
    required this.hostelId,
    required this.hostelName,
    required this.ownerId,
    this.roomId,
    this.roomNumber,
    this.bedNumber,
    required this.checkInDate,
    required this.checkOutDate,
    required this.totalAmount,
    this.status = 'pending',
    this.paymentStatus = 'unpaid',
    this.ownerNote,
    required this.createdAt,
    required this.updatedAt,
  });

  // ── Helper Getters for Expiration & Active Status ────────────────────────
  bool get isExpired =>
      status == 'expired' ||
      (status == 'confirmed' && DateTime.now().isAfter(checkOutDate));

  bool get isActive => status == 'confirmed' && !isExpired;
  bool get isCancelled => status == 'cancelled';
  bool get isPending => status == 'pending';
  bool get isPaid => paymentStatus == 'paid';
  
  // Method A logic: 6 hours without payment
  bool get isPaymentExpired => 
      status == 'confirmed' && 
      paymentStatus == 'unpaid' && 
      DateTime.now().difference(updatedAt).inHours >= 6;

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    return DateTime.now();
  }

  static double _parseDouble(dynamic value, [double defaultValue = 0.0]) {
    if (value == null) return defaultValue;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  factory BookingModel.fromMap(Map<String, dynamic> map, String id) {
    return BookingModel(
      id: id,
      studentId: map['studentId']?.toString() ?? '',
      studentName: map['studentName']?.toString() ?? '',
      studentEmail: map['studentEmail']?.toString() ?? '',
      hostelId: map['hostelId']?.toString() ?? '',
      hostelName: map['hostelName']?.toString() ?? '',
      ownerId: map['ownerId']?.toString() ?? '',
      roomId: map['roomId']?.toString(),
      roomNumber: map['roomNumber']?.toString(),
      bedNumber: map['bedNumber']?.toString(),
      checkInDate: _parseDateTime(map['checkInDate']),
      checkOutDate: _parseDateTime(map['checkOutDate']),
      totalAmount: _parseDouble(map['totalAmount']),
      status: map['status']?.toString() ?? 'pending',
      paymentStatus: map['paymentStatus']?.toString() ?? 'unpaid',
      ownerNote: map['ownerNote']?.toString(),
      createdAt: _parseDateTime(map['createdAt']),
      updatedAt: _parseDateTime(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'studentName': studentName,
      'studentEmail': studentEmail,
      'hostelId': hostelId,
      'hostelName': hostelName,
      'ownerId': ownerId,
      'roomId': roomId,
      'roomNumber': roomNumber,
      'bedNumber': bedNumber,
      'checkInDate': checkInDate,
      'checkOutDate': checkOutDate,
      'totalAmount': totalAmount,
      'status': status,
      'paymentStatus': paymentStatus,
      'ownerNote': ownerNote,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  BookingModel copyWith({
    String? id,
    String? studentId,
    String? studentName,
    String? studentEmail,
    String? hostelId,
    String? hostelName,
    String? ownerId,
    String? roomId,
    String? roomNumber,
    String? bedNumber,
    DateTime? checkInDate,
    DateTime? checkOutDate,
    double? totalAmount,
    String? status,
    String? paymentStatus,
    String? ownerNote,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BookingModel(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      studentEmail: studentEmail ?? this.studentEmail,
      hostelId: hostelId ?? this.hostelId,
      hostelName: hostelName ?? this.hostelName,
      ownerId: ownerId ?? this.ownerId,
      roomId: roomId ?? this.roomId,
      roomNumber: roomNumber ?? this.roomNumber,
      bedNumber: bedNumber ?? this.bedNumber,
      checkInDate: checkInDate ?? this.checkInDate,
      checkOutDate: checkOutDate ?? this.checkOutDate,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      ownerNote: ownerNote ?? this.ownerNote,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
