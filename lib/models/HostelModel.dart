import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fyp/models/RoomModel.dart';

// lib/models/HostelModel.dart
// ─────────────────────────────────────────────────────────────────────────────
// Represents a hostel listing created by an owner.
// Stored in Firestore: /hostels/{hostelId}
// ─────────────────────────────────────────────────────────────────────────────

class HostelModel {
  final String id;              // Firestore document ID
  final String ownerId;         // UID of the owner who created this listing
  final String ownerName;       // Denormalized for display (avoids extra query)
  final String name;            // Hostel display name
  final String description;
  final String city;
  final String address;
  final double latitude;        // For Google Maps pin
  final double longitude;
  final double rentPerMonth;    // in PKR
  final String roomType;        // 'Single' | 'Double' | etc.
  final String genderPreference; // 'Male Only' | 'Female Only' | 'Co-ed'
  final List<String> facilities; // e.g. ['WiFi', 'Mess', 'Security']
  final List<String> images;    // Firebase Storage download URLs
  final bool isAvailable;       // Can students book right now?
  final String status;          // 'pending' | 'approved' | 'rejected'
  final double averageRating;    // Computed from reviews (updated on new review)
  final int totalReviews;
  final int totalRooms;
  final int availableRooms;
  final List<RoomModel> rooms;  // Individual rooms & vacancies
  // ── Ranking counters (updated atomically when bookings/complaints change) ──
  final int totalBookings;        // FR-9.1: booking confirmation rate denominator
  final int confirmedBookings;    // FR-9.1: booking confirmation rate numerator
  final int totalComplaints;      // FR-9.1: complaint resolution rate denominator
  final int resolvedComplaints;   // FR-9.1: complaint resolution rate numerator
  final int totalResolutionTimeHours; // FR-9: for complaint resolution speed
  final String? registrationNumber; // Unique registration number assigned by admin e.g. "DS-Hostel-1"
  final bool unregistrationRequested; // True if owner submitted closure/unregistration request
  final String? unregistrationReason; // Reason provided by owner for unregistering/closing
  final DateTime? unregistrationRequestedAt; // Timestamp when owner requested unregistration
  final DateTime createdAt;
  final DateTime updatedAt;

  // Ephemeral property computed locally by ML model for display
  double? smartScore;

  // New getters for ML Ranking features
  double get complaintResolutionRate => totalComplaints == 0 ? 1.0 : resolvedComplaints / totalComplaints;
  double get bookingConfirmationRate => totalBookings == 0 ? 0.0 : confirmedBookings / totalBookings;
  double get complaintFrequency => totalBookings == 0
      ? (totalComplaints > 0 ? 1.0 : 0.0)
      : (totalComplaints / totalBookings).clamp(0.0, 1.0);
  double get resolutionSpeedHours => resolvedComplaints == 0
      ? (totalComplaints == 0 ? 24.0 : 72.0)
      : (totalResolutionTimeHours / resolvedComplaints).toDouble();

  // ── Room & Vacancy getters ─────────────────────────────────────────────────
  int get totalVacancies => rooms.fold(0, (acc, r) => acc + r.vacancies);
  int get totalCapacity => rooms.fold(0, (acc, r) => acc + r.capacity);
  int get totalOccupiedBeds => rooms.fold(0, (acc, r) => acc + r.occupied);
  int get totalFilledRooms => rooms.where((r) => r.isFilled).length;
  int get totalRoomsWithVacancy => rooms.where((r) => r.hasVacancy).length;
  List<RoomModel> get roomsWithVacancy => rooms.where((r) => r.hasVacancy).toList();
  List<RoomModel> get filledRooms => rooms.where((r) => r.isFilled).toList();

  HostelModel({
    required this.id,
    required this.ownerId,
    required this.ownerName,
    required this.name,
    required this.description,
    required this.city,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.rentPerMonth,
    required this.roomType,
    required this.genderPreference,
    required this.facilities,
    required this.images,
    this.isAvailable = true,
    this.status = 'pending',
    this.registrationNumber,
    this.unregistrationRequested = false,
    this.unregistrationReason,
    this.unregistrationRequestedAt,
    this.averageRating = 0.0,
    this.totalReviews = 0,
    this.totalRooms = 1,
    this.availableRooms = 1,
    this.rooms = const [],
    this.totalBookings = 0,
    this.confirmedBookings = 0,
    this.totalComplaints = 0,
    this.resolvedComplaints = 0,
    this.totalResolutionTimeHours = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  // Helper method for safe DateTime parsing
  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    return DateTime.now();
  }

  // Helper method for safe double parsing
  static double _parseDouble(dynamic value, [double defaultValue = 0.0]) {
    if (value == null) return defaultValue;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  // Helper method for safe int parsing
  static int _parseInt(dynamic value, [int defaultValue = 0]) {
    if (value == null) return defaultValue;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  // Generate fallback rooms when a document does not have rooms array yet
  static List<RoomModel> generateDefaultRooms({
    required int totalRooms,
    required String roomType,
    int? availableRooms,
  }) {
    final count = totalRooms > 0 ? totalRooms : 1;
    final cap = RoomModel.defaultCapacityForType(roomType);

    final List<RoomModel> generated = [];
    for (int i = 0; i < count; i++) {
      generated.add(
        RoomModel(
          id: 'room_${i + 1}',
          roomNumber: 'Room ${i + 1}',
          type: roomType,
          capacity: cap,
          vacancies: cap,
          assignedStudents: const [],
          assignedStudentNames: const [],
        ),
      );
    }
    return generated;
  }

  // ── fromMap: used when reading from Firestore ──────────────────────────────
  factory HostelModel.fromMap(Map<String, dynamic> map, String id) {
    final parsedTotalRooms = _parseInt(map['totalRooms'], 1);
    final parsedAvailRooms = _parseInt(map['availableRooms'], 1);
    final parsedRoomType = map['roomType']?.toString() ?? 'Single';

    List<RoomModel> parsedRooms = [];
    if (map['rooms'] != null && map['rooms'] is List && (map['rooms'] as List).isNotEmpty) {
      parsedRooms = (map['rooms'] as List)
          .asMap()
          .entries
          .map((entry) => RoomModel.fromMap(
                Map<String, dynamic>.from(entry.value),
                'room_${entry.key + 1}',
              ))
          .toList();
    } else {
      parsedRooms = generateDefaultRooms(
        totalRooms: parsedTotalRooms,
        roomType: parsedRoomType,
        availableRooms: parsedAvailRooms,
      );
    }

    return HostelModel(
      id: id,
      ownerId: map['ownerId']?.toString() ?? '',
      ownerName: map['ownerName']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      city: map['city']?.toString() ?? '',
      address: map['address']?.toString() ?? '',
      latitude: _parseDouble(map['latitude']),
      longitude: _parseDouble(map['longitude']),
      rentPerMonth: _parseDouble(map['rentPerMonth']),
      roomType: parsedRoomType,
      genderPreference: map['genderPreference']?.toString() ?? 'Co-ed',
      facilities: List<String>.from(map['facilities'] ?? []),
      images: List<String>.from(map['images'] ?? []),
      isAvailable: map['isAvailable'] == true,
      status: map['status']?.toString() ?? 'pending',
      registrationNumber: map['registrationNumber']?.toString(),
      unregistrationRequested: map['unregistrationRequested'] == true,
      unregistrationReason: map['unregistrationReason']?.toString(),
      unregistrationRequestedAt: map['unregistrationRequestedAt'] != null
          ? _parseDateTime(map['unregistrationRequestedAt'])
          : null,
      averageRating: _parseDouble(map['averageRating']),
      totalReviews: _parseInt(map['totalReviews']),
      totalRooms: parsedTotalRooms,
      availableRooms: parsedAvailRooms,
      rooms: parsedRooms,
      totalBookings: _parseInt(map['totalBookings']),
      confirmedBookings: _parseInt(map['confirmedBookings']),
      totalComplaints: _parseInt(map['totalComplaints']),
      resolvedComplaints: _parseInt(map['resolvedComplaints']),
      totalResolutionTimeHours: _parseInt(map['totalResolutionTimeHours']),
      createdAt: _parseDateTime(map['createdAt']),
      updatedAt: _parseDateTime(map['updatedAt']),
    );
  }

  // ── toMap: used when writing to Firestore ─────────────────────────────────
  Map<String, dynamic> toMap() {
    return {
      'ownerId': ownerId,
      'ownerName': ownerName,
      'name': name,
      'description': description,
      'city': city,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'rentPerMonth': rentPerMonth,
      'roomType': roomType,
      'genderPreference': genderPreference,
      'facilities': facilities,
      'images': images,
      'isAvailable': isAvailable,
      'status': status,
      'registrationNumber': registrationNumber,
      'unregistrationRequested': unregistrationRequested,
      'unregistrationReason': unregistrationReason,
      if (unregistrationRequestedAt != null)
        'unregistrationRequestedAt': unregistrationRequestedAt,
      'averageRating': averageRating,
      'totalReviews': totalReviews,
      'totalRooms': totalRooms,
      'availableRooms': availableRooms,
      'rooms': rooms.map((r) => r.toMap()).toList(),
      'totalBookings': totalBookings,
      'confirmedBookings': confirmedBookings,
      'totalComplaints': totalComplaints,
      'resolvedComplaints': resolvedComplaints,
      'totalResolutionTimeHours': totalResolutionTimeHours,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  // ── copyWith: returns a modified copy (useful in GetX controllers) ─────────
  HostelModel copyWith({
    String? name,
    String? description,
    String? city,
    String? address,
    double? latitude,
    double? longitude,
    double? rentPerMonth,
    String? roomType,
    String? genderPreference,
    List<String>? facilities,
    List<String>? images,
    bool? isAvailable,
    String? status,
    String? registrationNumber,
    bool? unregistrationRequested,
    String? unregistrationReason,
    DateTime? unregistrationRequestedAt,
    double? averageRating,
    int? totalReviews,
    int? totalRooms,
    int? availableRooms,
    List<RoomModel>? rooms,
    int? totalBookings,
    int? confirmedBookings,
    int? totalComplaints,
    int? resolvedComplaints,
    int? totalResolutionTimeHours,
  }) {
    return HostelModel(
      id: id,
      ownerId: ownerId,
      ownerName: ownerName,
      name: name ?? this.name,
      description: description ?? this.description,
      city: city ?? this.city,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      rentPerMonth: rentPerMonth ?? this.rentPerMonth,
      roomType: roomType ?? this.roomType,
      genderPreference: genderPreference ?? this.genderPreference,
      facilities: facilities ?? this.facilities,
      images: images ?? this.images,
      isAvailable: isAvailable ?? this.isAvailable,
      status: status ?? this.status,
      registrationNumber: registrationNumber ?? this.registrationNumber,
      unregistrationRequested: unregistrationRequested ?? this.unregistrationRequested,
      unregistrationReason: unregistrationReason ?? this.unregistrationReason,
      unregistrationRequestedAt: unregistrationRequestedAt ?? this.unregistrationRequestedAt,
      averageRating: averageRating ?? this.averageRating,
      totalReviews: totalReviews ?? this.totalReviews,
      totalRooms: totalRooms ?? this.totalRooms,
      availableRooms: availableRooms ?? this.availableRooms,
      rooms: rooms ?? this.rooms,
      totalBookings: totalBookings ?? this.totalBookings,
      confirmedBookings: confirmedBookings ?? this.confirmedBookings,
      totalComplaints: totalComplaints ?? this.totalComplaints,
      resolvedComplaints: resolvedComplaints ?? this.resolvedComplaints,
      totalResolutionTimeHours: totalResolutionTimeHours ?? this.totalResolutionTimeHours,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
