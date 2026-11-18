// ─────────────────────────────────────────────────────────────────────────────
// FR-1.1 & FR-1.2: Registration screen – responsive on Mobile & Web.
// Modernized UI: atmospheric background, layered logo badge, modern card & inputs.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:fyp/controllers/AuthController.dart';
import 'package:fyp/routes/AppRoutes.dart';
import 'package:fyp/services/CloudinaryService.dart';
import 'package:fyp/utils/AppColors.dart';
import 'package:fyp/utils/AppConstants.dart';
import 'package:fyp/utils/Responsive.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  String _selectedRole = AppConstants.roleStudent;
  String? _selectedUniversity;

  // CNIC image (owners only)
  XFile? _cnicFile;
  bool _isUploadingCnic = false;

  // ── Universities list ─────────────────────────────────────────────────────
  static const List<Map<String, String>> _universities = [
    // Jamshoro
    {'group': 'Jamshoro', 'name': 'University of Sindh'},
    {'group': 'Jamshoro', 'name': 'Mehran University of Engineering and Technology (MUET)'},
    {'group': 'Jamshoro', 'name': 'Liaquat University of Medical and Health Sciences (LUMHS)'},
    {'group': 'Jamshoro', 'name': 'Shaheed Allah Buksh Soomro (SABS) University of Art, Design and Heritages'},
    // Hyderabad
    {'group': 'Hyderabad', 'name': 'Government College University Hyderabad (GCUH)'},
    {'group': 'Hyderabad', 'name': 'Isra University'},
    {'group': 'Hyderabad', 'name': 'Hyderabad Institute for Technology and Management Sciences (HITMS)'},
    {'group': 'Hyderabad', 'name': 'SZABIST Hyderabad Campus'},
    {'group': 'Hyderabad', 'name': 'NUML Hyderabad Campus'},
  ];

  final AuthController _authController = Get.find<AuthController>();
  final CloudinaryService _cloudinaryService = Get.find<CloudinaryService>();
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // ── Pick CNIC image ────────────────────────────────────────────────────────
  Future<void> _pickCnic(ImageSource source) async {
    final picked = await _picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1200,
    );
    if (picked != null) {
      setState(() => _cnicFile = picked);
    }
  }

  void _showCnicPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2)),
              ),
              Text(
                'Upload CNIC (Front Side)',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _PickerOption(
                      icon: Icons.camera_alt_outlined,
                      label: 'Camera',
                      onTap: () {
                        Get.back();
                        _pickCnic(ImageSource.camera);
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _PickerOption(
                      icon: Icons.photo_library_outlined,
                      label: 'Gallery',
                      onTap: () {
                        Get.back();
                        _pickCnic(ImageSource.gallery);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Register handler ───────────────────────────────────────────────────────
  Future<void> _handleRegister() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    // Validate CNIC for owners
    if (_selectedRole == AppConstants.roleOwner && _cnicFile == null) {
      Get.snackbar(
        'CNIC Required',
        'Please upload the front side of your CNIC to register as a hostel owner.',
        backgroundColor: AppColors.error,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        icon: const Icon(Icons.warning_outlined, color: Colors.white),
      );
      return;
    }

    // Upload CNIC to Cloudinary if selected
    String? cnicUrl;
    if (_cnicFile != null) {
      setState(() => _isUploadingCnic = true);
      try {
        cnicUrl = await _cloudinaryService.uploadImage(
          _cnicFile!,
          folder: 'cnic',
        );
      } catch (e) {
        setState(() => _isUploadingCnic = false);
        Get.snackbar(
          'Upload Failed',
          'Could not upload CNIC image. Please try again.',
          backgroundColor: AppColors.error,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }
      setState(() => _isUploadingCnic = false);
    }

    await _authController.register(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      role: _selectedRole,
      phone: _phoneController.text.trim(),
      university: _selectedRole == AppConstants.roleStudent
          ? _selectedUniversity
          : null,
      cnicImageUrl: cnicUrl,
    );
  }

  // ── Build grouped university dropdown items ───────────────────────────────
  List<DropdownMenuItem<String>> _buildUniversityItems() {
    final items = <DropdownMenuItem<String>>[];
    String? lastGroup;
    for (final uni in _universities) {
      final group = uni['group']!;
      final name  = uni['name']!;
      if (group != lastGroup) {
        items.add(DropdownMenuItem<String>(
          enabled: false,
          value: '__header_$group',
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: Divider(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    thickness: 1,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    group.toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
                Expanded(
                  child: Divider(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    thickness: 1,
                  ),
                ),
              ],
            ),
          ),
        ));
        lastGroup = group;
      }
      items.add(DropdownMenuItem<String>(
        value: name,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            name,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ));
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final bool isOwner = _selectedRole == AppConstants.roleOwner;
    final isWide = Responsive.isWide(context);
    final buttonHeight = isWide ? 46.0 : 50.0;
    final buttonFontSize = isWide ? 14.0 : 15.0;

    return Scaffold(
      backgroundColor: const Color(0xFF00383F),
      body: Stack(
        children: [
          // ── Ambient Background Gradients ─────────────────────────────────────
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF00434C),
                    Color(0xFF006D77),
                    Color(0xFF002F35),
                  ],
                  stops: [0.0, 0.55, 1.0],
                ),
              ),
            ),
          ),

          // Glowing accent orbs
          Positioned(
            top: -80,
            right: -80,
            child: Container(
              width: 290,
              height: 290,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primaryLight.withValues(alpha: 0.25),
                    AppColors.primaryLight.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -90,
            left: -80,
            child: Container(
              width: 310,
              height: 310,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.accent.withValues(alpha: 0.20),
                    AppColors.accent.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),

          // ── Main content ──────────────────────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                // Top bar / back button
                Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 16.0, top: 12.0),
                    child: InkWell(
                      onTap: () {
                        if (Navigator.of(context).canPop()) {
                          Get.back();
                        } else {
                          Get.offAllNamed(AppRoutes.welcome);
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.25),
                            width: 1,
                          ),
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ),

                // Form scrollable wrapper
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: isWide ? 500 : double.infinity),
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: EdgeInsets.only(
                          top: 4,
                          left: isWide ? 20 : 0,
                          right: isWide ? 20 : 0,
                          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                        ),
                        child: Column(
                          children: [
                            // ── Modern Brand Badge Header ────────────────────────
                            Container(
                              width: isWide ? 76 : 72,
                              height: isWide ? 76 : 72,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Colors.white.withValues(alpha: 0.24),
                                    Colors.white.withValues(alpha: 0.08),
                                  ],
                                ),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.35),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.15),
                                    blurRadius: 18,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Container(
                                  width: isWide ? 50 : 46,
                                  height: isWide ? 50 : 46,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(14),
                                    color: Colors.white.withValues(alpha: 0.95),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primaryDark.withValues(alpha: 0.25),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.home_work_rounded,
                                    size: isWide ? 28 : 26,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'DwellSense',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: isWide ? 26 : 28,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Find your perfect student hostel',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: isWide ? 13 : 13.5,
                                letterSpacing: 0.2,
                              ),
                            ),
                            SizedBox(height: isWide ? 24 : 28),

                            // ── Modern White Card ────────────────────────────────
                            Container(
                              margin: EdgeInsets.symmetric(horizontal: isWide ? 0 : 20),
                              padding: EdgeInsets.fromLTRB(
                                isWide ? 28 : 24,
                                isWide ? 26 : 24,
                                isWide ? 28 : 24,
                                isWide ? 24 : 22,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(28),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  width: 1.2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.22),
                                    blurRadius: 32,
                                    offset: const Offset(0, 14),
                                  ),
                                  BoxShadow(
                                    color: AppColors.primaryLight.withValues(alpha: 0.1),
                                    blurRadius: 24,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    // ── Role Segmented Selector ─────────────────────────
                                    Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF1F5F6),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: _RoleSegment(
                                              icon: Icons.school_rounded,
                                              label: 'Student',
                                              isSelected: _selectedRole ==
                                                  AppConstants.roleStudent,
                                              onTap: () => setState(() =>
                                                  _selectedRole =
                                                      AppConstants.roleStudent),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: _RoleSegment(
                                              icon: Icons.business_rounded,
                                              label: 'Hostel Owner',
                                              isSelected: isOwner,
                                              onTap: () => setState(() =>
                                                  _selectedRole =
                                                      AppConstants.roleOwner),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 16),

                                    // ── Full Name ─────────────────────────────
                                    _ModernInputField(
                                      controller: _nameController,
                                      hint: 'Display Name',
                                      icon: Icons.person_outline_rounded,
                                      validator: (v) => v == null || v.isEmpty
                                          ? 'Name is required'
                                          : null,
                                    ),
                                    const SizedBox(height: 14),

                                    // ── Email ─────────────────────────────────
                                    _ModernInputField(
                                      controller: _emailController,
                                      hint: 'Email Address',
                                      icon: Icons.email_outlined,
                                      keyboardType: TextInputType.emailAddress,
                                      validator: (v) {
                                        if (v == null || v.isEmpty) {
                                          return 'Email is required';
                                        }
                                        if (!GetUtils.isEmail(v)) {
                                          return 'Enter a valid email';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 14),

                                    // ── Phone Number ──────────────────────────
                                    _ModernInputField(
                                      controller: _phoneController,
                                      hint: 'Phone Number',
                                      icon: Icons.phone_outlined,
                                      keyboardType: TextInputType.phone,
                                      validator: (v) => v == null || v.isEmpty
                                          ? 'Phone is required'
                                          : null,
                                    ),
                                    const SizedBox(height: 14),

                                    // ── University (Students) ─────────────────
                                    if (!isOwner) ...[
                                      DropdownButtonFormField<String>(
                                        value: _selectedUniversity,
                                        dropdownColor: Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                        menuMaxHeight: 320,
                                        elevation: 6,
                                        decoration: InputDecoration(
                                          hintText: 'Select University',
                                          hintStyle: TextStyle(
                                            color: AppColors.textSecondary.withValues(alpha: 0.8),
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w400,
                                          ),
                                          prefixIcon: const Icon(
                                            Icons.account_balance_outlined,
                                            color: AppColors.primary,
                                            size: 20,
                                          ),
                                          filled: true,
                                          fillColor: const Color(0xFFF7FAFA),
                                          contentPadding: const EdgeInsets.symmetric(
                                            vertical: 14,
                                            horizontal: 16,
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(16),
                                            borderSide: BorderSide(
                                              color: AppColors.primary.withValues(alpha: 0.25),
                                              width: 1.2,
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(16),
                                            borderSide: const BorderSide(
                                              color: AppColors.primary,
                                              width: 1.8,
                                            ),
                                          ),
                                          errorBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(16),
                                            borderSide: const BorderSide(color: AppColors.error),
                                          ),
                                          focusedErrorBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(16),
                                            borderSide: const BorderSide(
                                              color: AppColors.error,
                                              width: 1.8,
                                            ),
                                          ),
                                        ),
                                        isExpanded: true,
                                        icon: const Icon(
                                          Icons.keyboard_arrow_down_rounded,
                                          color: AppColors.primary,
                                        ),
                                        style: const TextStyle(
                                          color: AppColors.textPrimary,
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        validator: (v) => v == null || v.isEmpty
                                            ? 'Please select your university'
                                            : null,
                                        onChanged: (val) => setState(
                                            () => _selectedUniversity = val),
                                        items: _buildUniversityItems(),
                                      ),
                                      const SizedBox(height: 14),
                                    ],

                                    // ── CNIC (Owners) ─────────────────────────
                                    if (isOwner) ...[
                                      _ModernCnicUpload(
                                        cnicFile: _cnicFile,
                                        isUploading: _isUploadingCnic,
                                        onTap: _showCnicPicker,
                                        onRemove: () =>
                                            setState(() => _cnicFile = null),
                                      ),
                                      const SizedBox(height: 14),
                                    ],

                                    // ── Password ──────────────────────────────
                                    _ModernInputField(
                                      controller: _passwordController,
                                      hint: 'Password',
                                      icon: Icons.lock_outline_rounded,
                                      obscureText: _obscurePassword,
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscurePassword
                                              ? Icons.visibility_outlined
                                              : Icons.visibility_off_outlined,
                                          color: AppColors.primary,
                                          size: 20,
                                        ),
                                        onPressed: () => setState(() =>
                                            _obscurePassword = !_obscurePassword),
                                      ),
                                      validator: (v) {
                                        if (v == null || v.isEmpty) {
                                          return 'Password is required';
                                        }
                                        if (v.length < 6) {
                                          return 'At least 6 characters';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 14),

                                    // ── Confirm Password ──────────────────────
                                    _ModernInputField(
                                      controller: _confirmPasswordController,
                                      hint: 'Confirm Password',
                                      icon: Icons.lock_outline_rounded,
                                      obscureText: _obscurePassword,
                                      validator: (v) {
                                        if (v == null || v.isEmpty) {
                                          return 'Please confirm password';
                                        }
                                        if (v != _passwordController.text) {
                                          return 'Passwords do not match';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 8),

                                    // ── Error message ─────────────────────────
                                    Obx(() {
                                      if (_authController
                                          .errorMessage.value.isEmpty) {
                                        return const SizedBox.shrink();
                                      }
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 6),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: AppColors.error.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(
                                              color: AppColors.error.withValues(alpha: 0.3),
                                            ),
                                          ),
                                          child: Text(
                                            _authController.errorMessage.value,
                                            style: const TextStyle(
                                              color: AppColors.error,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      );
                                    }),

                                    const SizedBox(height: 10),

                                    // ── Create Account Button ─────────────────
                                    Obx(() => ElevatedButton(
                                          onPressed: _handleRegister,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.primary,
                                            foregroundColor: Colors.white,
                                            minimumSize:
                                                Size(double.infinity, buttonHeight),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(16),
                                            ),
                                            elevation: 3,
                                            shadowColor: AppColors.primary.withValues(alpha: 0.4),
                                          ),
                                          child: _authController.isLoading.value ||
                                                  _isUploadingCnic
                                              ? const SizedBox(
                                                  width: 20,
                                                  height: 20,
                                                  child: CircularProgressIndicator(
                                                    color: Colors.white,
                                                    strokeWidth: 2,
                                                  ),
                                                )
                                              : Row(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Text(
                                                      'Create Account',
                                                      style: TextStyle(
                                                        fontSize: buttonFontSize,
                                                        fontWeight: FontWeight.w700,
                                                        letterSpacing: 0.5,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    const Icon(Icons.arrow_forward_rounded, size: 18),
                                                  ],
                                                ),
                                        )),
                                    const SizedBox(height: 16),

                                    // ── Login Link ────────────────────────────
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Text(
                                          'Already have an account?',
                                          style: TextStyle(
                                            color: AppColors.textSecondary,
                                            fontSize: 13,
                                          ),
                                        ),
                                        TextButton(
                                          onPressed: () => Get.offNamed(AppRoutes.login),
                                          style: TextButton.styleFrom(
                                            foregroundColor: AppColors.primary,
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 6),
                                          ),
                                          child: const Text(
                                            'Login',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Role segment button ───────────────────────────────────────────────────────
class _RoleSegment extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleSegment({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.28),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : AppColors.textSecondary,
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Modern CNIC Upload Widget ─────────────────────────────────────────────────
class _ModernCnicUpload extends StatelessWidget {
  final XFile? cnicFile;
  final bool isUploading;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _ModernCnicUpload({
    required this.cnicFile,
    required this.isUploading,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: cnicFile != null
              ? AppColors.primary.withValues(alpha: 0.08)
              : const Color(0xFFF7FAFA),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: cnicFile != null
                ? AppColors.primary
                : AppColors.primary.withValues(alpha: 0.25),
            width: cnicFile != null ? 1.6 : 1.2,
          ),
        ),
        child: isUploading
            ? const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : Row(
                children: [
                  Icon(
                    cnicFile != null
                        ? Icons.check_circle_rounded
                        : Icons.badge_outlined,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      cnicFile != null
                          ? 'CNIC Front Attached'
                          : 'Upload CNIC (Front Side)',
                      style: TextStyle(
                        color: cnicFile != null ? AppColors.primary : AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (cnicFile != null)
                    GestureDetector(
                      onTap: onRemove,
                      child: const Icon(Icons.close_rounded,
                          color: AppColors.error, size: 18),
                    )
                  else
                    const Text(
                      '*Required',
                      style: TextStyle(
                        color: AppColors.error,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}

// ── Source picker option tile ─────────────────────────────────────────────────
class _PickerOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PickerOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Modern Input Field ────────────────────────────────────────────────────────
class _ModernInputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;

  const _ModernInputField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.keyboardType,
    this.suffixIcon,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: AppColors.textSecondary.withValues(alpha: 0.8),
          fontSize: 13.5,
          fontWeight: FontWeight.w400,
        ),
        prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: const Color(0xFFF7FAFA),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 14,
          horizontal: 16,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: AppColors.primary.withValues(alpha: 0.25),
            width: 1.2,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: AppColors.primary,
            width: 1.8,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.error, width: 1.8),
        ),
      ),
    );
  }
}
