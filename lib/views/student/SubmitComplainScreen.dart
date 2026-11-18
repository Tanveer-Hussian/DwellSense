// ─────────────────────────────────────────────────────────────────────────────
// lib/views/student/SubmitComplainScreen.dart
// FR-7.1: Student submits a service complaint.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:fyp/controllers/AuthController.dart';
import 'package:fyp/controllers/BookingController.dart';
import 'package:fyp/controllers/ComplaintController.dart';
import 'package:fyp/controllers/HostelController.dart';
import 'package:fyp/controllers/NotificationController.dart';
import 'package:fyp/models/HostelModel.dart';
import 'package:fyp/routes/AppRoutes.dart';
import 'package:fyp/utils/AppColors.dart';
import 'package:fyp/utils/Responsive.dart';
import 'package:fyp/views/shared%20Widgets/CustomTextField.dart';
import 'package:fyp/views/shared%20Widgets/WebSidebarShell.dart';
import 'package:get/get.dart';

class SubmitComplaintScreen extends StatefulWidget {
  const SubmitComplaintScreen({super.key});

  @override
  State<SubmitComplaintScreen> createState() => _SubmitComplaintScreenState();
}

class _SubmitComplaintScreenState extends State<SubmitComplaintScreen> {
  // Arguments: HostelModel passed from HostelDetailScreen or resolved from active booking
  HostelModel? _hostel;

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments;
    if (args is HostelModel) {
      _hostel = args;
    } else {
      final bookingCtrl = Get.find<BookingController>();
      final hostelCtrl = Get.find<HostelController>();
      final booking = bookingCtrl.myBookings.firstWhereOrNull((b) => b.isActive) ??
          bookingCtrl.myBookings.firstOrNull;
      if (booking != null) {
        _hostel = hostelCtrl.approvedHostels.firstWhereOrNull((h) => h.id == booking.hostelId) ??
            hostelCtrl.allHostels.firstWhereOrNull((h) => h.id == booking.hostelId);
      }
      _hostel ??= hostelCtrl.approvedHostels.firstOrNull ?? hostelCtrl.allHostels.firstOrNull;
    }
  }

  static const _categories = [
    {'label': 'WiFi / Internet', 'icon': Icons.wifi_rounded},
    {'label': 'Electricity & Power', 'icon': Icons.electric_bolt_rounded},
    {'label': 'Water & Plumbing', 'icon': Icons.water_drop_rounded},
    {'label': 'Cleanliness & Washroom', 'icon': Icons.cleaning_services_rounded},
    {'label': 'Mess / Food', 'icon': Icons.restaurant_rounded},
    {'label': 'Room Maintenance', 'icon': Icons.home_repair_service_rounded},
    {'label': 'Other / Noise', 'icon': Icons.report_problem_outlined},
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final complaintCtrl = Get.find<ComplaintController>();
    final isWide = Responsive.isWide(context);

    if (_hostel == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Submit Complaint')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.info_outline, size: 48, color: AppColors.primary),
              const SizedBox(height: 16),
              const Text('No hostel selected for complaint.', style: TextStyle(fontSize: 16)),
              const SizedBox(height: 8),
              const Text('Please choose a hostel to submit a complaint for.', style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Get.back(),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    // ── Web Portal View ──────────────────────────────────────────────────────
    if (isWide) {
      return _buildWebView(context, complaintCtrl);
    }

    // ── Mobile layout (Android - 100% preserved) ──────────────────────────────
    return Scaffold(
      appBar: AppBar(title: const Text('Submit Complaint')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              const Icon(Icons.report_problem_outlined,
                  size: 48, color: AppColors.warning),
              const SizedBox(height: 12),
              Text(
                'Report an Issue',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              Text(
                _hostel!.name,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 32),

              // Complaint title
              CustomTextField(
                controller: _titleController,
                label: 'Issue Title',
                hint: 'e.g. WiFi not working, Broken door lock',
                prefixIcon: Icons.title,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Title is required' : null,
              ),
              const SizedBox(height: 16),

              // Detailed description
              TextFormField(
                controller: _descController,
                maxLines: 6,
                decoration: const InputDecoration(
                  labelText: 'Detailed Description',
                  hintText: 'Describe the issue in detail...',
                  prefixIcon: Icon(Icons.description_outlined),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Description is required';
                  if (v.length < 20) return 'Please provide more details (min 20 chars)';
                  return null;
                },
              ),
              const SizedBox(height: 32),

              Obx(() => ElevatedButton.icon(
                onPressed: complaintCtrl.isLoading.value
                    ? null
                    : () async {
                        if (!_formKey.currentState!.validate()) return;
                        final ok = await complaintCtrl.submitComplaint(
                          hostelId: _hostel!.id,
                          hostelName: _hostel!.name,
                          ownerId: _hostel!.ownerId,
                          title: _titleController.text.trim(),
                          description: _descController.text.trim(),
                        );
                        if (ok) Get.back();
                      },
                icon: complaintCtrl.isLoading.value
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.send_outlined),
                label: Text(complaintCtrl.isLoading.value
                    ? 'Submitting...'
                    : 'Submit Complaint'),
              )),
            ],
          ),
        ),
      ),
    );
  }

  // ── Web Portal Dedicated Layout ───────────────────────────────────────────
  Widget _buildWebView(BuildContext context, ComplaintController complaintCtrl) {
    final authCtrl = Get.find<AuthController>();
    final notifCtrl = Get.find<NotificationController>();
    final isDark = Theme.of(context).brightness == Brightness.dark || Get.isDarkMode;

    final surfaceColor = isDark ? const Color(0xFF1E242B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2C3238) : const Color(0xFFE2E8F0);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subTextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final inputFill = isDark ? const Color(0xFF14191E) : const Color(0xFFF8FAFC);

    return WebSidebarShell(
      currentIndex: 3,
      onTap: (i) => Get.offNamed(AppRoutes.studentHome),
      items: const [
        SidebarNavItem(icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Home'),
        SidebarNavItem(icon: Icons.book_outlined, activeIcon: Icons.book, label: 'My Bookings'),
        SidebarNavItem(icon: Icons.chat_bubble_outline, activeIcon: Icons.chat_bubble, label: 'Messages'),
        SidebarNavItem(icon: Icons.report_outlined, activeIcon: Icons.report, label: 'Complaints'),
        SidebarNavItem(icon: Icons.person_outline, activeIcon: Icons.person, label: 'Profile'),
      ],
      userName: authCtrl.currentUser.value?.name ?? 'Student',
      roleLabel: 'Student Portal',
      notificationCount: notifCtrl.unreadCount.value,
      body: Container(
        color: isDark ? AppColors.darkBackground : const Color(0xFFF3F6F9),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 820),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Breadcrumbs ──
                  Row(
                    children: [
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () => Get.back(),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: surfaceColor,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: borderColor),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.arrow_back_rounded, size: 14, color: subTextColor),
                                const SizedBox(width: 6),
                                Text(
                                  'Back',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: subTextColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text('/', style: TextStyle(color: subTextColor, fontSize: 13)),
                      const SizedBox(width: 10),
                      Text(
                        _hostel!.name,
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: subTextColor),
                      ),
                      const SizedBox(width: 10),
                      Text('/', style: TextStyle(color: subTextColor, fontSize: 13)),
                      const SizedBox(width: 10),
                      Text(
                        'Submit Complaint',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textColor),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Main Complaint Card ──
                  Container(
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: borderColor),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.04),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Card Header
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF171C22) : const Color(0xFFF8FAFC),
                            border: Border(bottom: BorderSide(color: borderColor)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                                  ),
                                ),
                                child: const Icon(
                                  Icons.report_problem_rounded,
                                  color: Color(0xFFF59E0B),
                                  size: 26,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Report an Issue',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                        color: textColor,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Submit a maintenance or facility complaint directly to hostel management.',
                                      style: TextStyle(fontSize: 13, color: subTextColor),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.domain_rounded, size: 14, color: AppColors.primary),
                                    const SizedBox(width: 6),
                                    Text(
                                      _hostel!.name,
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Form Body
                        Padding(
                          padding: const EdgeInsets.all(28),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Category Selection
                                Text(
                                  'Issue Category',
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: textColor,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Click a category to quickly categorize your complaint:',
                                  style: TextStyle(fontSize: 12.5, color: subTextColor),
                                ),
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: _categories.map((cat) {
                                    final label = cat['label'] as String;
                                    final icon = cat['icon'] as IconData;
                                    final isSelected = _selectedCategory == label;

                                    return InkWell(
                                      borderRadius: BorderRadius.circular(20),
                                      onTap: () {
                                        setState(() {
                                          _selectedCategory = isSelected ? null : label;
                                          if (_titleController.text.trim().isEmpty && !isSelected) {
                                            _titleController.text = '$label - ';
                                          }
                                        });
                                      },
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 150),
                                        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? AppColors.primary
                                              : (isDark ? const Color(0xFF14191E) : const Color(0xFFF1F5F9)),
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(
                                            color: isSelected ? AppColors.primary : borderColor,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              icon,
                                              size: 14,
                                              color: isSelected ? Colors.white : AppColors.primary,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              label,
                                              style: TextStyle(
                                                fontSize: 12.5,
                                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                                color: isSelected ? Colors.white : textColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                                const SizedBox(height: 24),

                                // Issue Title
                                Text(
                                  'Issue Title',
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: textColor,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _titleController,
                                  style: TextStyle(fontSize: 14, color: textColor),
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: inputFill,
                                    hintText: 'e.g. WiFi connection lost on 2nd floor, Tap leaking in washroom',
                                    hintStyle: TextStyle(color: subTextColor, fontSize: 13),
                                    prefixIcon: const Icon(Icons.title_rounded, color: AppColors.primary, size: 20),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: borderColor),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: AppColors.primary, width: 2),
                                    ),
                                    errorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: AppColors.error),
                                    ),
                                    focusedErrorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: AppColors.error, width: 2),
                                    ),
                                  ),
                                  validator: (v) =>
                                      v == null || v.trim().isEmpty ? 'Please enter a title for the issue' : null,
                                ),
                                const SizedBox(height: 20),

                                // Detailed Description
                                Text(
                                  'Detailed Description',
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: textColor,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _descController,
                                  maxLines: 5,
                                  style: TextStyle(fontSize: 14, color: textColor),
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: inputFill,
                                    hintText:
                                        'Provide exact details: what room or area is affected, when did it start, and any steps already taken...',
                                    hintStyle: TextStyle(color: subTextColor, fontSize: 13),
                                    prefixIcon: const Padding(
                                      padding: EdgeInsets.only(bottom: 80),
                                      child: Icon(Icons.notes_rounded, color: AppColors.primary, size: 20),
                                    ),
                                    contentPadding: const EdgeInsets.all(16),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: borderColor),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: AppColors.primary, width: 2),
                                    ),
                                    errorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: AppColors.error),
                                    ),
                                    focusedErrorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: AppColors.error, width: 2),
                                    ),
                                  ),
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) return 'Description is required';
                                    if (v.trim().length < 20) {
                                      return 'Please provide more details (at least 20 characters)';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 20),

                                // Information Notice
                                Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppColors.primary.withValues(alpha: 0.2),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.info_outline_rounded,
                                          size: 20, color: AppColors.primary),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          'Hostel administration will be notified immediately upon submission. You will receive updates directly under your Complaints tab.',
                                          style: TextStyle(
                                            fontSize: 12.5,
                                            color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                                            height: 1.4,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 28),

                                // Action Buttons
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    OutlinedButton(
                                      onPressed: () => Get.back(),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: subTextColor,
                                        side: BorderSide(color: borderColor),
                                        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                      ),
                                      child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
                                    ),
                                    const SizedBox(width: 14),
                                    Obx(() => ElevatedButton.icon(
                                          onPressed: complaintCtrl.isLoading.value
                                              ? null
                                              : () async {
                                                  if (!_formKey.currentState!.validate()) return;
                                                  final ok = await complaintCtrl.submitComplaint(
                                                    hostelId: _hostel!.id,
                                                    hostelName: _hostel!.name,
                                                    ownerId: _hostel!.ownerId,
                                                    title: _titleController.text.trim(),
                                                    description: _descController.text.trim(),
                                                  );
                                                  if (ok) Get.back();
                                                },
                                          icon: complaintCtrl.isLoading.value
                                              ? const SizedBox(
                                                  width: 16,
                                                  height: 16,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    color: Colors.white,
                                                  ),
                                                )
                                              : const Icon(Icons.send_rounded, size: 17),
                                          label: Text(
                                            complaintCtrl.isLoading.value
                                                ? 'Submitting...'
                                                : 'Submit Complaint',
                                            style: const TextStyle(fontWeight: FontWeight.w700),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.primary,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            elevation: 0,
                                          ),
                                        )),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
