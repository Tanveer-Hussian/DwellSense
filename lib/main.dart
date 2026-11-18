import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:fyp/SplashScreen.dart';
import 'package:fyp/bindings/AppBindings.dart';
import 'package:fyp/routes/AppRoutes.dart';
import 'package:fyp/utils/AppConstants.dart';
import 'package:fyp/utils/AppTheme.dart';
import 'package:fyp/views/SharedScreens/NotificationsScreen.dart';
import 'package:fyp/views/SharedScreens/ProfileScreen.dart';
import 'package:fyp/views/admin/AdminHomeScreen.dart';
import 'package:fyp/views/admin/AdminHostelDetailScreen.dart';
import 'package:fyp/views/admin/AdminUserDetailScreen.dart';
import 'package:fyp/views/auth/ForgetPasswordScreen.dart';
import 'package:fyp/views/auth/LoginScreen.dart';
import 'package:fyp/views/auth/RegistrationScreen.dart';
import 'package:fyp/views/auth/WelcomeScreen.dart';
import 'package:fyp/views/owner/AddHostelScreen.dart';
import 'package:fyp/views/owner/OwnerBookingsScreen.dart' show OwnerBookingsScreen;
import 'package:fyp/views/owner/OwnerComplaintsScreen.dart';
import 'package:fyp/views/owner/OwnerHomeScreen.dart';
import 'package:fyp/views/owner/OwnerHostelDetailScreen.dart';
import 'package:fyp/views/owner/OwnerHostelResidentsScreen.dart';
import 'package:fyp/views/owner/OwnerSettingsScreen.dart';
import 'package:fyp/views/student/BookingRequestScreen.dart';
import 'package:fyp/views/student/HostelDetailSceen.dart';
import 'package:fyp/views/student/MyComplaintScreen.dart';
import 'package:fyp/views/student/StudentSettingsScreen.dart';
import 'package:fyp/views/admin/AdminSettingsScreen.dart';
import 'package:fyp/views/student/StudentHomeScreen.dart';
import 'package:fyp/views/student/SubmitComplainScreen.dart';
import 'package:fyp/views/student/WriteReviewScreen.dart';
import 'package:fyp/views/student/StudentAllHostelsScreen.dart';
import 'package:fyp/views/student/HostelSearchScreen.dart';
import 'package:fyp/views/student/SafepayCheckoutScreen.dart';
import 'package:fyp/views/admin/AdminChatListScreen.dart';
import 'package:fyp/views/owner/OwnerChatListScreen.dart';
import 'package:fyp/views/owner/OwnerStudentChatListScreen.dart';
import 'package:fyp/views/student/StudentChatListScreen.dart';
import 'package:fyp/views/shared Widgets/ChatConversationScreen.dart';
import 'package:fyp/views/shared Widgets/OnboardingScreen.dart';
import 'package:get/get.dart';      


Future<void> main() async {
  // Ensure Flutter is initialized before calling native plugins
    WidgetsFlutterBinding.ensureInitialized();
  
    // Initialize Firebase (reads google-services.json / GoogleService-Info.plist)
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyDkyPpECie2QGI3SPeCx4kQPzn15v6_YIc", 
        appId: "1:1024160107828:android:5bb9cbc57381d7f552a961", 
        messagingSenderId: "1024160107828", 
        projectId: "smart-hostel-system-9f924",
        authDomain: "smart-hostel-system-9f924.firebaseapp.com",
        storageBucket: "smart-hostel-system-9f924.firebasestorage.app"
      ),
   ); 

  runApp(const SmartHostelApp());
}
 
class SmartHostelApp extends StatelessWidget {
  const SmartHostelApp({super.key});
 
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
 
      // ── Theme ──────────────────────────────────────────────────────────────
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
 
      // ── Initial Binding: registers all services + controllers ──────────────
      initialBinding: AppBinding(),
 
      // ── Initial route: splash while Firebase loads ─────────────────────────
      initialRoute: AppRoutes.splash,
 
      // ── All app routes ─────────────────────────────────────────────────────
      getPages: [
        // Auth
        GetPage(
          name: AppRoutes.splash,
          page: () => const SplashScreen(),
        ),
        GetPage(
          name: AppRoutes.welcome,
          page: () => const WelcomeScreen(),
          transition: Transition.fadeIn,
        ),
        GetPage(
          name: AppRoutes.onboarding,
          page: () => const OnboardingScreen(),
          transition: Transition.fadeIn,
        ),
        GetPage(
          name: AppRoutes.login,
          page: () => const LoginScreen(),
          transition: Transition.fadeIn,
        ),
        GetPage(
          name: AppRoutes.register,
          page: () => const RegisterScreen(),
          transition: Transition.rightToLeft,
        ),
        GetPage(
          name: AppRoutes.forgotPassword,
          page: () => const ForgotPasswordScreen(),
        ),
 
        // Student
        GetPage(
          name: AppRoutes.studentHome,
          page: () => const StudentHomeScreen(),
          transition: Transition.fadeIn,
        ),
        GetPage(
          name: AppRoutes.allHostels,
          page: () => const StudentAllHostelsScreen(),
          transition: Transition.rightToLeft,
        ),
        GetPage(
          name: AppRoutes.hostelSearch,
          page: () => const HostelSearchScreen(),
          transition: Transition.fadeIn,
        ),
        GetPage(
          name: AppRoutes.hostelDetail,
          page: () => const HostelDetailScreen(),
          transition: Transition.rightToLeft,
        ),
        GetPage(
          name: AppRoutes.bookingRequest,
          page: () => const BookingRequestScreen(),
          transition: Transition.rightToLeft,
        ),
        GetPage(
          name: AppRoutes.myBookings,
          page: () => const MyBookingsScreen(),
        ),
        GetPage(
          name: AppRoutes.writeReview,
          page: () => const WriteReviewScreen(),
        ),
        GetPage(
          name: AppRoutes.submitComplaint,
          page: () => const SubmitComplaintScreen(),
        ),
        GetPage(
          name: AppRoutes.myComplaints,
          page: () => const MyComplaintsScreen(),
        ),
        GetPage(
          name: AppRoutes.safepayCheckout,
          page: () {
            final args = Get.arguments as Map<String, dynamic>;
            return SafepayCheckoutScreen(
              bookingId    : args['bookingId']    as String,
              amount       : args['amount']       as double,
              studentEmail : args['studentEmail'] as String,
              hostelName   : args['hostelName']   as String,
            );
          },
          transition: Transition.downToUp,
        ),
 
        // Owner
        GetPage(
          name: AppRoutes.ownerHome,
          page: () => const OwnerHomeScreen(),
          transition: Transition.fadeIn,
        ),
        GetPage(
          name: AppRoutes.addHostel,
          page: () => const AddHostelScreen(),
          transition: Transition.rightToLeft,
        ),
        GetPage(
          name: AppRoutes.editHostel,
          page: () => const AddHostelScreen(), // reuse same form; args has hostel
          transition: Transition.rightToLeft,
        ),
        GetPage(
          name: AppRoutes.ownerHostelDetail,
          page: () => const OwnerHostelDetailScreen(),
          transition: Transition.rightToLeft,
        ),
        GetPage(
          name: AppRoutes.ownerHostelResidents,
          page: () => const OwnerHostelResidentsScreen(),
          transition: Transition.rightToLeft,
        ),
        GetPage(
          name: AppRoutes.ownerBookings,
          page: () => const OwnerBookingsScreen(),
        ),
        GetPage(
          name: AppRoutes.ownerComplaints,
          page: () => const OwnerComplaintsScreen(),
        ),
 
        // Admin
        GetPage(
          name: AppRoutes.adminHome,
          page: () => const AdminHomeScreen(),
          transition: Transition.fadeIn,
        ),
        GetPage(
          name: AppRoutes.adminHostels,
          page: () => const AdminHomeScreen(), // Navigates to Admin Panel
          transition: Transition.fadeIn,
        ),
        GetPage(
          name: AppRoutes.adminUsers,
          page: () => const AdminHomeScreen(),
          transition: Transition.fadeIn,
        ),
        GetPage(
          name: AppRoutes.adminUserDetail,
          page: () => const AdminUserDetailScreen(),
          transition: Transition.rightToLeft,
        ),
        GetPage(
          name: AppRoutes.adminReviews,
          page: () => const AdminHomeScreen(),
          transition: Transition.fadeIn,
        ),
        GetPage(
          name: AppRoutes.adminHostelDetail,
          page: () => const AdminHostelDetailScreen(),
          transition: Transition.rightToLeft,
        ),
 
        // Chat
        GetPage(
          name: AppRoutes.adminChats,
          page: () => const AdminChatListScreen(),
          transition: Transition.rightToLeft,
        ),
        GetPage(
          name: AppRoutes.ownerChats,
          page: () => const OwnerChatListScreen(),
          transition: Transition.rightToLeft,
        ),
        GetPage(
          name: AppRoutes.ownerStudentChats,
          page: () => const OwnerStudentChatListScreen(),
          transition: Transition.rightToLeft,
        ),
        GetPage(
          name: AppRoutes.studentChats,
          page: () => const StudentChatListScreen(),
          transition: Transition.rightToLeft,
        ),
        GetPage(
          name: AppRoutes.chatConversation,
          page: () => const ChatConversationScreen(),
          transition: Transition.rightToLeft,
        ),

        // Shared
        GetPage(
          name: AppRoutes.profile,
          page: () => const ProfileScreen(),
        ),
        GetPage(
          name: AppRoutes.notifications,
          page: () => const NotificationsScreen(),
        ),
        GetPage(
          name: AppRoutes.adminSettings,
          page: () => const AdminSettingsScreen(),
          transition: Transition.rightToLeft,
        ),
        GetPage(
          name: AppRoutes.ownerSettings,
          page: () => const OwnerSettingsScreen(),
          transition: Transition.rightToLeft,
        ),
        GetPage(
          name: AppRoutes.studentSettings,
          page: () => const StudentSettingsScreen(),
          transition: Transition.rightToLeft,
        ),
      ],
 
      // ── Global snackbar theme ──────────────────────────────────────────────
      defaultTransition: Transition.cupertino,
  
    );
  }

}

