
class AppRoutes {
  AppRoutes._();

  // ── Auth ──────────────────────────────────────────────────────────────────
  static const String splash = '/';
  static const String welcome = '/welcome';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';

  // ── Student ───────────────────────────────────────────────────────────────
  static const String studentHome = '/student/home';
  static const String allHostels = '/student/all-hostels';
  static const String hostelSearch = '/student/search';
  static const String hostelDetail = '/student/hostel-detail';
  static const String bookingRequest = '/student/booking-request';
  static const String myBookings = '/student/my-bookings';
  static const String writeReview = '/student/write-review';
  static const String submitComplaint = '/student/submit-complaint';
  static const String myComplaints = '/student/my-complaints';
  static const String safepayCheckout = '/student/pay-rent';
  static const String studentSettings = '/student/settings';

  // ── Owner ─────────────────────────────────────────────────────────────────
  static const String ownerHome = '/owner/home';
  static const String addHostel = '/owner/add-hostel';
  static const String editHostel = '/owner/edit-hostel';
  static const String ownerHostelDetail = '/owner/hostel-detail';
  static const String ownerHostelResidents = '/owner/hostel-residents';
  static const String ownerBookings = '/owner/bookings';
  static const String ownerComplaints = '/owner/complaints';
  static const String ownerSettings = '/owner/settings';

  // ── Admin ─────────────────────────────────────────────────────────────────
  static const String adminHome = '/admin/home';
  static const String adminUsers = '/admin/users';
  static const String adminHostels = '/admin/hostels';
  static const String adminUserDetail = '/admin/user-detail';
  static const String adminComplaints = '/admin/complaints';
  static const String adminReviews = '/admin/reviews';
  static const String adminHostelDetail = '/admin/hostel-detail';
  static const String adminSettings = '/admin/settings';

  // ── Shared ────────────────────────────────────────────────────────────────
  static const String profile = '/profile';
  static const String notifications = '/notifications';

  // ── Chat ──────────────────────────────────────────────────────────────────
  static const String adminChats = '/admin/chats';
  static const String ownerChats = '/owner/chats';
  static const String ownerStudentChats = '/owner/student-chats';
  static const String studentChats = '/student/chats';
  static const String chatConversation = '/chat/conversation';
}
