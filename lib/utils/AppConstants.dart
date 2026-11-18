// ─────────────────────────────────────────────────────────────────────────────
// Central place for all app-wide constants.
// Keeping them here avoids magic strings/numbers scattered across the codebase.
// ─────────────────────────────────────────────────────────────────────────────
 
class AppConstants {
  // ── Prevent instantiation ──────────────────────────────────────────────────
  AppConstants._();
 
  // ── App Info ───────────────────────────────────────────────────────────────
  static const String appName = 'DwellSense';
  static const String appVersion = '1.0.0';
 
  // ── User Roles (stored in Firestore "users" collection) ───────────────────
  static const String roleStudent = 'student';
  static const String roleOwner = 'owner';
  static const String roleAdmin = 'admin';
 
  // ── Firestore Collection Names ─────────────────────────────────────────────
  static const String colUsers = 'users';
  static const String colHostels = 'hostels';
  static const String colBookings = 'bookings';
  static const String colReviews = 'reviews';
  static const String colComplaints = 'complaints';
  static const String colNotifications = 'notifications';
 
  // ── Hostel Status Values ───────────────────────────────────────────────────
  static const String statusPending = 'pending';       // awaiting admin approval
  static const String statusApproved = 'approved';     // visible to students
  static const String statusRejected = 'rejected';     // hidden, needs revision
 
  // ── Booking Status Values ──────────────────────────────────────────────────
  static const String bookingPending = 'pending';
  static const String bookingConfirmed = 'confirmed';
  static const String bookingRejected = 'rejected';
  static const String bookingCancelled = 'cancelled';
  static const String bookingExpired = 'expired';
 
  // ── Complaint Status Values ────────────────────────────────────────────────
  static const String complaintPending = 'pending';
  static const String complaintInProgress = 'in_progress';
  static const String complaintResolved = 'resolved';
 
  // ── Room Types ─────────────────────────────────────────────────────────────
  static const List<String> roomTypes = [
    'Single',
    'Double',
    'Triple',
    'Dormitory',
  ];
 
  // ── Gender Preferences ─────────────────────────────────────────────────────
  static const List<String> genderOptions = [
    'Male Only',
    'Female Only',
  ];
 
  // ── Available Facilities (shown as checkboxes in listing form) ─────────────
  static const List<String> facilities = [
    'WiFi',
    'Mess / Cafeteria',
    'Security Guard',
    'CCTV',
    'Generator',
    'Laundry',
    'Parking',
    'Study Room',
    'Gym',
    'Air Conditioning',
    'Water 24/7',
    'Geyser',
  ];
 
  // ── Cities Supported ──────────────────────────────────────────────────────
  static const List<String> supportedCities = [
    'Hyderabad',
    'Jamshoro',
  ];
 
  // ── Storage Paths (Firebase Storage folder structure) ─────────────────────
  static const String storageHostelImages = 'hostel_images';
  static const String storageProfileImages = 'profile_images';
 
  // ── SharedPreferences Keys ─────────────────────────────────────────────────
  static const String prefUserRole = 'user_role';
  static const String prefOnboarded = 'onboarded';
}

