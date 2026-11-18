import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:fyp/controllers/AuthController.dart';
import 'package:fyp/models/UserModel.dart';
import 'package:fyp/routes/AppRoutes.dart';
import 'package:fyp/services/AuthService.dart';
import 'package:fyp/services/CloudinaryService.dart';
import 'package:fyp/utils/AppColors.dart';
import 'package:fyp/utils/Responsive.dart';
import 'package:fyp/views/shared%20Widgets/AppBanner.dart';
import 'package:fyp/views/shared%20Widgets/CustomTextField.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  
  final AuthController _authCtrl = Get.find<AuthController>();
  final AuthService _authService = Get.find<AuthService>();
  final CloudinaryService _cloudinaryService = Get.find<CloudinaryService>();
  final ImagePicker _picker = ImagePicker();

  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _universityCtrl;
  String? _selectedUniversity;

  bool _isEditing = false;

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
  bool _isSaving = false;
  XFile? _newProfileImage;
  Uint8List? _newProfileImageBytes;

  @override
  void initState() {
    super.initState();

    final user = _authCtrl.currentUser.value;

    if (user != null) {
      _nameCtrl = TextEditingController(text: user.name);
      _phoneCtrl = TextEditingController(text: user.phone);
      _universityCtrl = TextEditingController(text: user.university ?? '');
      _selectedUniversity = _universities.any((u) => u['name'] == user.university)
          ? user.university
          : null;
    } else {
      _nameCtrl = TextEditingController();
      _phoneCtrl = TextEditingController();
      _universityCtrl = TextEditingController();
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _universityCtrl.dispose();
    super.dispose();
  }

  // ── Pick new profile photo ─────────────────────────────────────────────────
  Future<void> _pickImage() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (file != null) {
      final bytes = await file.readAsBytes();
      setState(() {
        _newProfileImage = file;
        _newProfileImageBytes = bytes;
      });
    }
  }

  // ── Save profile changes ───────────────────────────────────────────────────
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final uid = _authCtrl.currentUser.value!.uid;
      final updates = <String, dynamic>{
        'name': _nameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
      };

      // Add university if student
      if (_authCtrl.isStudent) {
        updates['university'] = _selectedUniversity ?? _universityCtrl.text.trim();
      }

      // Upload new profile image if selected
      if (_newProfileImage != null) {
        final imageUrl = await _cloudinaryService.uploadProfileImage(
            uid, _newProfileImage!);
        updates['profileImage'] = imageUrl;
      }

      await _authService.updateUserProfile(uid, updates);
      await _authCtrl.refreshUser(); // reload local state

      setState(() {
        _isEditing = false;
        _newProfileImage = null;
        _newProfileImageBytes = null; // Clear temp file so it uses the Network URL
      });
      if (!mounted) return;
      AppBanner.showSuccess(
        title: 'Profile Updated',
        message: 'Your profile changes have been saved successfully.',
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      Get.snackbar('Error', 'Could not update profile.');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  List<DropdownMenuItem<String>> _buildUniversityItems() {
    final items = <DropdownMenuItem<String>>[];
    String? lastGroup;
    for (final uni in _universities) {
      final group = uni['group']!;
      final name = uni['name']!;
      if (group != lastGroup) {
        items.add(DropdownMenuItem<String>(
          enabled: false,
          value: '__header_',
          child: Text(
            '──  ──',
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
              fontSize: 12,
              letterSpacing: 0.8,
            ),
          ),
        ));
        lastGroup = group;
      }
      items.add(DropdownMenuItem<String>(
        value: name,
        child: Text(name, style: const TextStyle(fontSize: 13)),
      ));
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final isWide = Responsive.isWide(context);
    final user = _authCtrl.currentUser.value;

    if (user != null && isWide) {
      return _buildWebProfile(context, user);
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final cardColor = Theme.of(context).cardColor;
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'My Profile',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          TextButton(
            onPressed: () {
              if (_isEditing) {
                _saveProfile();
              } else {
                setState(() {
                  _isEditing = true;
                  final curUni = _authCtrl.currentUser.value?.university ?? _universityCtrl.text;
                  _selectedUniversity = _universities.any((u) => u['name'] == curUni)
                      ? curUni
                      : null;
                });
              }
            },
            child: Text(
              _isEditing ? 'Save' : 'Edit',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Obx(() {
        final user = _authCtrl.currentUser.value;
        if (user == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 90),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
            children: [
            const SizedBox(height: 4),
            // ── Profile Avatar ─────────────────────────────────────────
            GestureDetector(
              onTap: _isEditing ? _pickImage : null,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: scaffoldBg,
                      shape: BoxShape.circle,
                    ),
                    child: CircleAvatar(
                      radius: 56,
                      backgroundColor: AppColors.primaryLight,
                      backgroundImage: _newProfileImageBytes != null
                          ? MemoryImage(_newProfileImageBytes!)
                          : (user.profileImage != null && user.profileImage!.isNotEmpty
                              ? NetworkImage(user.profileImage!) as ImageProvider
                              : null),
                      child: (_newProfileImage == null && (user.profileImage == null || user.profileImage!.isEmpty))
                          ? Text(
                              user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                              style: const TextStyle(
                                  fontSize: 40,
                                  color: AppColors.primaryDark,
                                  fontWeight: FontWeight.bold),
                            )
                          : null,
                    ),
                  ),
                  if (_isEditing)
                    Positioned(
                      bottom: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: scaffoldBg, width: 2),
                        ),
                        child: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Name and Role
            Text(
              user.name,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                user.role.toUpperCase(),
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Editable Fields Card ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    if (!isDark)
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                  ],
                ),
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min, // Wrap content tightly
                    children: [
                      Text(
                        'Personal Information',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 20),

                      CustomTextField(
                        controller: _nameCtrl,
                        label: 'Full Name',
                        prefixIcon: Icons.person_outline,
                        readOnly: !_isEditing,
                        validator: (v) => v == null || v.isEmpty ? 'Name required' : null,
                      ),
                      const SizedBox(height: 16),

                      // Email (always read-only)
                      CustomTextField(
                        controller: TextEditingController(text: user.email),
                        label: 'Email Address',
                        prefixIcon: Icons.email_outlined,
                        readOnly: true,
                      ),
                      const SizedBox(height: 16),

                      CustomTextField(
                        controller: _phoneCtrl,
                        label: 'Phone Number',
                        prefixIcon: Icons.phone_outlined,
                        readOnly: !_isEditing,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 16),

                      // University field (students only)
                      if (_authCtrl.isStudent) ...[
                        if (_isEditing)
                          DropdownButtonFormField<String>(
                            value: _selectedUniversity,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'University',
                              prefixIcon: Icon(Icons.account_balance_outlined),
                            ),
                            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primary),
                            items: _buildUniversityItems(),
                            onChanged: (val) {
                              setState(() {
                                _selectedUniversity = val;
                                if (val != null) _universityCtrl.text = val;
                              });
                            },
                            validator: (v) => v == null || v.isEmpty ? 'Please select your university' : null,
                          )
                        else
                          CustomTextField(
                            controller: _universityCtrl,
                            label: 'University',
                            prefixIcon: Icons.account_balance_outlined,
                            readOnly: true,
                          ),
                        const SizedBox(height: 16),
                      ],

                      // Loading indicator while saving
                      if (_isSaving) ...[
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: CircularProgressIndicator(),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 6),

            // ── Logout Button ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: () => _confirmLogout(context),
                  icon: const Icon(Icons.logout, color: AppColors.error),
                  label: const Text(
                    'Logout',
                    style: TextStyle(
                      color: AppColors.error,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.error.withValues(alpha: 0.5), width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: AppColors.error.withValues(alpha: 0.05),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    ),
  );
}),
    );
  }

  // ── Web Portal Dedicated Profile View ─────────────────────────────────────
  Widget _buildWebProfile(BuildContext context, UserModel user) {
    final isDark = Theme.of(context).brightness == Brightness.dark || Get.isDarkMode;
    final bg = isDark ? const Color(0xFF0F171E) : const Color(0xFFF6F8FA);
    final surface = isDark ? const Color(0xFF14202E) : Colors.white;
    final border = isDark ? const Color(0xFF223242) : const Color(0xFFE2E8F0);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subTextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Scaffold(
      backgroundColor: bg,
      appBar: Navigator.canPop(context)
          ? AppBar(
              backgroundColor: surface,
              elevation: 0,
              leading: BackButton(color: textColor),
              title: Text(
                'My Profile',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(1),
                child: Divider(height: 1, color: border),
              ),
            )
          : null,
      body: Material(
        color: bg,
        child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1040),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'My Profile',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Manage your personal account details, contact info, and profile photo.',
                          style: TextStyle(fontSize: 13, color: subTextColor),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        if (_isEditing) ...[
                          OutlinedButton(
                            onPressed: () {
                              setState(() {
                                _isEditing = false;
                                _newProfileImage = null;
                                _newProfileImageBytes = null;
                                _nameCtrl.text = user.name;
                                _phoneCtrl.text = user.phone;
                                if (_authCtrl.isStudent) {
                                  _universityCtrl.text = user.university ?? '';
                                  _selectedUniversity = _universities.any((u) => u['name'] == user.university)
                                      ? user.university
                                      : null;
                                }
                              });
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: subTextColor,
                              side: BorderSide(color: border),
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton.icon(
                            onPressed: _isSaving ? null : _saveProfile,
                            icon: _isSaving
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Icon(Icons.check_rounded, size: 16),
                            label: Text(_isSaving ? 'Saving...' : 'Save Changes'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              elevation: 0,
                            ),
                          ),
                        ] else ...[
                          ElevatedButton.icon(
                            onPressed: () {
                              setState(() {
                                _isEditing = true;
                                final curUni = user.university ?? _universityCtrl.text;
                                _selectedUniversity = _universities.any((u) => u['name'] == curUni)
                                    ? curUni
                                    : null;
                              });
                            },
                            icon: const Icon(Icons.edit_rounded, size: 15),
                            label: const Text('Edit Profile'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              elevation: 0,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // 2-Column Desktop Grid
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left Column: User Summary & Avatar Card
                    SizedBox(
                      width: 320,
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: surface,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: border),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Avatar
                            GestureDetector(
                              onTap: _isEditing ? _pickImage : null,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  CircleAvatar(
                                    radius: 54,
                                    backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                                    backgroundImage: _newProfileImageBytes != null
                                        ? MemoryImage(_newProfileImageBytes!)
                                        : (user.profileImage != null && user.profileImage!.isNotEmpty
                                            ? NetworkImage(user.profileImage!) as ImageProvider
                                            : null),
                                    child: (_newProfileImage == null && (user.profileImage == null || user.profileImage!.isEmpty))
                                        ? Text(
                                            user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                                            style: const TextStyle(
                                              fontSize: 40,
                                              color: AppColors.primary,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          )
                                        : null,
                                  ),
                                  if (_isEditing)
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary,
                                          shape: BoxShape.circle,
                                          border: Border.all(color: surface, width: 2),
                                        ),
                                        child: const Icon(Icons.camera_alt_rounded, size: 16, color: Colors.white),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            if (_isEditing) ...[
                              const SizedBox(height: 8),
                              TextButton.icon(
                                onPressed: _pickImage,
                                icon: const Icon(Icons.upload_rounded, size: 14),
                                label: const Text('Change Photo', style: TextStyle(fontSize: 12.5)),
                              ),
                            ],
                            const SizedBox(height: 14),
                            Text(
                              user.name,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: textColor,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
                              ),
                              child: Text(
                                user.role.toUpperCase(),
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              user.email,
                              style: TextStyle(fontSize: 12.5, color: subTextColor),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 20),
                            Divider(color: border),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () => _confirmLogout(context),
                                icon: const Icon(Icons.logout_rounded, size: 16, color: AppColors.error),
                                label: const Text('Logout', style: TextStyle(fontWeight: FontWeight.w700)),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.error,
                                  side: BorderSide(color: AppColors.error.withValues(alpha: 0.4)),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  backgroundColor: AppColors.error.withValues(alpha: 0.04),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 24),

                    // Right Column: Personal Information Form Card
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: surface,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: border),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.badge_outlined, size: 20, color: AppColors.primary),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Personal Details',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                          color: textColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _isEditing
                                          ? const Color(0xFFF59E0B).withValues(alpha: 0.12)
                                          : const Color(0xFF16A34A).withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      _isEditing ? 'Editing Mode' : 'View Only',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                        color: _isEditing ? const Color(0xFFD97706) : const Color(0xFF16A34A),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),

                              // Row 1: Name & Phone
                              Row(
                                children: [
                                  Expanded(
                                    child: CustomTextField(
                                      controller: _nameCtrl,
                                      label: 'Full Name',
                                      prefixIcon: Icons.person_outline,
                                      readOnly: !_isEditing,
                                      validator: (v) => v == null || v.isEmpty ? 'Name required' : null,
                                    ),
                                  ),
                                  const SizedBox(width: 18),
                                  Expanded(
                                    child: CustomTextField(
                                      controller: _phoneCtrl,
                                      label: 'Phone Number',
                                      prefixIcon: Icons.phone_outlined,
                                      readOnly: !_isEditing,
                                      keyboardType: TextInputType.phone,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 18),

                              // Row 2: Email & University
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: CustomTextField(
                                      controller: TextEditingController(text: user.email),
                                      label: 'Email Address',
                                      prefixIcon: Icons.email_outlined,
                                      readOnly: true,
                                    ),
                                  ),
                                  if (_authCtrl.isStudent) ...[
                                    const SizedBox(width: 18),
                                    Expanded(
                                      child: _isEditing
                                          ? DropdownButtonFormField<String>(
                                              value: _selectedUniversity,
                                              isExpanded: true,
                                              decoration: const InputDecoration(
                                                labelText: 'University',
                                                prefixIcon: Icon(Icons.account_balance_outlined),
                                              ),
                                              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primary),
                                              items: _buildUniversityItems(),
                                              onChanged: (val) {
                                                setState(() {
                                                  _selectedUniversity = val;
                                                  if (val != null) _universityCtrl.text = val;
                                                });
                                              },
                                              validator: (v) => v == null || v.isEmpty ? 'Please select university' : null,
                                            )
                                          : CustomTextField(
                                              controller: _universityCtrl,
                                              label: 'University',
                                              prefixIcon: Icons.account_balance_outlined,
                                              readOnly: true,
                                            ),
                                    ),
                                  ],
                                ],
                              ),
                              if (_isSaving) ...[
                                const SizedBox(height: 24),
                                const Center(child: CircularProgressIndicator()),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

  void _confirmLogout(BuildContext ctx) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Get.toNamed(AppRoutes.login);
              _authCtrl.logout();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

}
