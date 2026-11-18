import 'package:firebase_auth/firebase_auth.dart';
import 'package:fyp/models/UserModel.dart';
import 'package:fyp/routes/AppRoutes.dart';
import 'package:fyp/services/AuthService.dart';
import 'package:fyp/utils/AppConstants.dart';
import 'package:get/get.dart';


class AuthController extends GetxController {

  final AuthService _authService = Get.find<AuthService>();

  // ── Observable state ──────────────────────────────────────────────────────
  final Rx<UserModel?> currentUser = Rx<UserModel?>(null);
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  // Convenience getters
  bool get isLoggedIn => currentUser.value != null;
  String get userRole => currentUser.value?.role ?? '';
  bool get isStudent => userRole == AppConstants.roleStudent;
  bool get isOwner => userRole == AppConstants.roleOwner;
  bool get isAdmin => userRole == AppConstants.roleAdmin;

  @override
  void onInit() {
    super.onInit();
    // Listen to Firebase auth state changes.
    // Fires on: app start (restore session), login, logout, registration.
    _authService.authStateChanges.listen(_onAuthStateChanged);
  }

  // ────────────────────────────────────────────────────────────────────────────
  // Called automatically when Firebase auth state changes.
  //
  // IMPORTANT: We skip processing while isRegistering == true.
  // Registration calls this TWICE:
  //   - Once when the Auth account is created (Firestore doc NOT written yet)
  //   - Once when we manually trigger after Firestore doc IS written
  // Without the guard, the first call would find no Firestore doc and sign out.
  // ────────────────────────────────────────────────────────────────────────────
  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    // ── Guard: skip during registration ──────────────────────────────────────
    // isRegistering is set to true in AuthService.registerUser() and released
    // only after the Firestore document has been successfully written.
    if (_authService.isRegistering) {
      print('AuthController: skipping auth event — registration in progress');
      return;
    }

    if (firebaseUser == null) {
      // Logged out → clear local state and go to welcome screen
      currentUser.value = null;
      // Only navigate if we're not already on welcome/login/register
      if (Get.currentRoute != AppRoutes.welcome &&
          Get.currentRoute != AppRoutes.login &&
          Get.currentRoute != AppRoutes.register) {
        Get.offAllNamed(AppRoutes.welcome);
      }
      return;
    }

    // ── Fetch Firestore profile ───────────────────────────────────────────────
    final user = await _authService.getUserById(firebaseUser.uid);

    if (user == null) {
      // Auth account exists but no Firestore doc.
      // This should only happen if registration failed mid-way.
      // Sign out and show a helpful message.
      print('AuthController: Firestore profile missing for ${firebaseUser.uid}');
      await _authService.signOut();
      errorMessage.value =
          'Account setup incomplete. Please register again.';
      return;
    }

    // ── Check if account is suspended by admin ────────────────────────────────
    if (!user.isActive) {
      await _authService.signOut();
      Get.snackbar(
        'Account Suspended',
        'Your account has been suspended. Please contact support.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    // ── All checks passed — set user and navigate ─────────────────────────────
    currentUser.value = user;
    _navigateByRole(user.role, isNewUser: false);
  }

  // ── Navigate to the correct home screen based on role ─────────────────────
  void _navigateByRole(String role, {bool isNewUser = false}) async {
    if (isNewUser && (role == AppConstants.roleStudent || role == AppConstants.roleOwner)) {
      Get.offAllNamed(AppRoutes.onboarding);
      return;
    }

    switch (role) {
      case AppConstants.roleStudent:
        Get.offAllNamed(AppRoutes.studentHome);
        break;
      case AppConstants.roleOwner:
        Get.offAllNamed(AppRoutes.ownerHome);
        break;
      case AppConstants.roleAdmin:
        Get.offAllNamed(AppRoutes.adminHome);
        break;
      default:
        Get.offAllNamed(AppRoutes.welcome);
    }
  }

  // ────────────────────────────────────────────────────────────────────────────
  // FR-1.1 / FR-1.2: Register a new user
  // ────────────────────────────────────────────────────────────────────────────
  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String role,
    required String phone,
    String? university,
    String? cnicImageUrl,
  }) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final user = await _authService.registerUser(
        name: name,
        email: email,
        password: password,
        role: role,
        phone: phone,
        university: university,
        cnicImageUrl: cnicImageUrl,
      );

      currentUser.value = user;

      // New user registration — trigger onboarding for student/owner
      _navigateByRole(user.role, isNewUser: true);

    } on FirebaseAuthException catch (e) {
      errorMessage.value = _getAuthErrorMessage(e.code);
    } catch (e) {
      print('Registration error: $e');
      errorMessage.value = 'Registration failed. Please try again.';
    } finally {
      isLoading.value = false;
    }
  }

  // ────────────────────────────────────────────────────────────────────────────
  // FR-1.3: Login
  // ────────────────────────────────────────────────────────────────────────────
  Future<void> login(String email, String password) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      // loginUser() signs in and returns the Firestore UserModel.
      // authStateChanges listener will also fire and call _onAuthStateChanged,
      // which will navigate. Both paths lead to the same result — no conflict
      // because isRegistering is false during login.
      await _authService.loginUser(email: email, password: password);

      // Navigation is handled by _onAuthStateChanged listener

    } on FirebaseAuthException catch (e) {
      errorMessage.value = _getAuthErrorMessage(e.code);
    } catch (e) {
      print('Login error: $e');
      errorMessage.value = 'Login failed. Please check your connection.';
    } finally {
      isLoading.value = false;
    }
  }

  // ────────────────────────────────────────────────────────────────────────────
  // FR-1.4: Password reset
  // ────────────────────────────────────────────────────────────────────────────
  Future<void> resetPassword(String email) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      await _authService.resetPassword(email);

      Get.snackbar(
        'Email Sent ✉️',
        'Password reset link sent to $email',
        snackPosition: SnackPosition.BOTTOM,
      );
      Get.back();
    } on FirebaseAuthException catch (e) {
      errorMessage.value = _getAuthErrorMessage(e.code);
    } catch (e) {
      errorMessage.value = 'Could not send reset email. Try again.';
    } finally {
      isLoading.value = false;
    }
  }

  // ── Logout ────────────────────────────────────────────────────────────────
  Future<void> logout() async {
    currentUser.value = null; // Clear immediately for instant UI feedback
    await _authService.signOut();
    // _onAuthStateChanged will fire with null and navigate to /login
  }

  // ── Refresh current user from Firestore ───────────────────────────────────
  Future<void> refreshUser() async {
    if (currentUser.value == null) return;
    final updated = await _authService.getUserById(currentUser.value!.uid);
    if (updated != null) currentUser.value = updated;
  }

  // ── Convert Firebase error codes → human readable messages ────────────────
  String _getAuthErrorMessage(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'This email is already registered. Please login instead.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait and try again.';
      case 'network-request-failed':
        return 'No internet connection. Check your network.';
      case 'user-disabled':
        return 'This account has been disabled.';
      default:
        return 'Error: $code. Please try again.';
    }
  }
}

