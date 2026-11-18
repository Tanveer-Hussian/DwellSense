// lib/views/student/booking_request_screen.dart
// ─────────────────────────────────────────────────────────────────────────────
// FR-5.1: Student selects check-in/out dates, selects room with vacancy, and submits a booking request.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fyp/controllers/BookingController.dart';
import 'package:fyp/models/HostelModel.dart';
import 'package:fyp/models/RoomModel.dart';
import 'package:fyp/routes/AppRoutes.dart';
import 'package:fyp/services/BookingService.dart';
import 'package:fyp/utils/AppColors.dart';
import 'package:fyp/utils/AppConstants.dart';
import 'package:fyp/utils/Responsive.dart';
import 'package:fyp/views/shared%20Widgets/CustomButtons.dart';
import 'package:fyp/views/shared Widgets/StatusChip.dart';
import 'package:fyp/views/shared Widgets/AnimatedStates.dart';
import 'package:fyp/views/student/StudentSettingsScreen.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class BookingRequestScreen extends StatefulWidget {
  const BookingRequestScreen({super.key});

  @override
  State<BookingRequestScreen> createState() => _BookingRequestScreenState();
}

class _BookingRequestScreenState extends State<BookingRequestScreen> {
  late final HostelModel hostel;
  final BookingController bookingCtrl = Get.find<BookingController>();

  RoomModel? _selectedRoom;

  // Selected dates
  DateTime? _checkInDate;
  DateTime? _checkOutDate;

  // Date formatter
  final DateFormat _fmt = DateFormat('MMM dd, yyyy');

  @override
  void initState() {
    super.initState();
    final args = Get.arguments;
    if (args is HostelModel) {
      hostel = args;
    } else if (args is Map) {
      hostel = args['hostel'] as HostelModel;
      _selectedRoom = args['preselectedRoom'] as RoomModel?;
    } else {
      hostel = args as HostelModel;
    }

    // Auto-select first room with vacancy if none was preselected
    if (_selectedRoom == null && hostel.rooms.isNotEmpty) {
      final withVacancy = hostel.rooms.where((r) => r.hasVacancy);
      if (withVacancy.isNotEmpty) {
        _selectedRoom = withVacancy.first;
      }
    }
  }

  // ── Date picker helper ─────────────────────────────────────────────────────
  Future<void> _pickDate(bool isCheckIn) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: isCheckIn
          ? (now.add(const Duration(days: 1)))
          : (_checkInDate?.add(const Duration(days: 30)) ??
              now.add(const Duration(days: 31))),
      firstDate: isCheckIn ? now : (_checkInDate ?? now),
      lastDate: now.add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        if (isCheckIn) {
          _checkInDate = picked;
          // Reset check-out if it's before new check-in
          if (_checkOutDate != null &&
              _checkOutDate!.isBefore(picked.add(const Duration(days: 1)))) {
            _checkOutDate = null;
          }
        } else {
          _checkOutDate = picked;
        }
      });
    }
  }

  // ── Calculate months and total cost ───────────────────────────────────────
  double get _estimatedMonths {
    if (_checkInDate == null || _checkOutDate == null) return 0;
    return _checkOutDate!.difference(_checkInDate!).inDays / 30;
  }

  double get _totalCost => hostel.rentPerMonth * _estimatedMonths;

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) return _buildWeb(context);
    return _buildMobile(context);
  }

  // ── Mobile layout Redesign ────────────────────────────────────────────────
  Widget _buildMobile(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Curved Teal Hero Header
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF00585E), Color(0xFF007A85)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 20, 18),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Get.back(),
                      icon: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                            width: 1.2,
                          ),
                        ),
                        child: const Icon(Icons.arrow_back_rounded,
                            color: Colors.white, size: 20),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Book Hostel',
                            style: TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: -0.3,
                            ),
                          ),
                          Text(
                            hostel.name,
                            style: TextStyle(
                              fontSize: 12.5,
                              color: Colors.white.withValues(alpha: 0.85),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                      ),
                      child: Text(
                        'PKR ${hostel.rentPerMonth.toStringAsFixed(0)}/mo',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Scrollable Form
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
            // ── Hostel Summary Card ──────────────────────────────────────────
            Card(
              child: ListTile(
                contentPadding: const EdgeInsets.all(12),
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: hostel.images.isNotEmpty
                      ? Image.network(hostel.images[0],
                          width: 60, height: 60, fit: BoxFit.cover)
                      : Container(
                          width: 60,
                          height: 60,
                          color: AppColors.divider,
                          child: const Icon(Icons.home_work_outlined),
                        ),
                ),
                title: Text(hostel.name,
                    style: Theme.of(context).textTheme.titleLarge),
                subtitle: Text(hostel.city),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'PKR ${hostel.rentPerMonth.toStringAsFixed(0)}',
                      style: const TextStyle(
                          color: AppColors.primary, fontWeight: FontWeight.bold),
                    ),
                    const Text('/month',
                        style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── Room & Vacancy Selection ────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Select Room & Vacancy',
                    style: Theme.of(context).textTheme.titleLarge),
                if (_selectedRoom != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      '${_selectedRoom!.vacancies} Vacancies Left',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.success,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Choose an available room with vacancies. When approved, you will be assigned to this room.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 12),
            _buildRoomList(context),
            const SizedBox(height: 20),
            Text('Select Dates', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _DatePickerCard(
                    label: 'Check-In',
                    date: _checkInDate,
                    formatter: _fmt,
                    icon: Icons.login_outlined,
                    onTap: () => _pickDate(true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DatePickerCard(
                    label: 'Check-Out',
                    date: _checkOutDate,
                    formatter: _fmt,
                    icon: Icons.logout_outlined,
                    onTap: () => _pickDate(false),
                    isDisabled: _checkInDate == null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (_checkInDate != null && _checkOutDate != null) ...[
              _buildCostBox(context),
              const SizedBox(height: 24),
            ],
            _buildNoticeBox(),
            const SizedBox(height: 32),
            _buildSubmitButton(),
          ],
        ),
      ),
    ),
  ],
),
);
}

  // ── Web layout ─────────────────────────────────────────────────────────────
  Widget _buildWeb(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0F171E) : const Color(0xFFF6F8FA);
    final cardBg = isDark ? const Color(0xFF14202E) : Colors.white;
    final cardBorder = isDark ? const Color(0xFF223242) : const Color(0xFFE2E8F0);
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textMuted = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final subBg = isDark ? const Color(0xFF1B2836) : const Color(0xFFF8FAFC);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF14202E) : Colors.white,
        elevation: 0,
        title: Text('Book Hostel',
            style: TextStyle(fontWeight: FontWeight.w700, color: textPrimary)),
        iconTheme: IconThemeData(color: textPrimary),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: cardBorder),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // LEFT COLUMN (60%)
                Expanded(
                  flex: 6,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Hostel summary card
                      _webCard(
                        isDark: isDark,
                        cardBg: cardBg,
                        cardBorder: cardBorder,
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: hostel.images.isNotEmpty
                                  ? Image.network(hostel.images[0],
                                      width: 72, height: 72, fit: BoxFit.cover)
                                  : Container(
                                      width: 72,
                                      height: 72,
                                      color: isDark
                                          ? const Color(0xFF223242)
                                          : const Color(0xFFE2E8F0),
                                      child: Icon(Icons.home_work_outlined,
                                          color: textMuted),
                                    ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(hostel.name,
                                      style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w800,
                                          color: textPrimary)),
                                  const SizedBox(height: 4),
                                  Row(children: [
                                    Icon(Icons.location_on_outlined,
                                        size: 14, color: textMuted),
                                    const SizedBox(width: 4),
                                    Text(hostel.city,
                                        style: TextStyle(
                                            fontSize: 13, color: textMuted)),
                                  ]),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'PKR ${hostel.rentPerMonth.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF2DD4BF)),
                                ),
                                Text('/month',
                                    style: TextStyle(
                                        fontSize: 11, color: textMuted)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Room selection card
                      _webCard(
                        isDark: isDark,
                        cardBg: cardBg,
                        cardBorder: cardBorder,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Select Room & Vacancy',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: textPrimary)),
                                if (_selectedRoom != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.success
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                          color: AppColors.success
                                              .withValues(alpha: 0.3)),
                                    ),
                                    child: Text(
                                      '${_selectedRoom!.vacancies} Vacancies Left',
                                      style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.success),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Choose an available room. When approved, you will be assigned to this room.',
                              style:
                                  TextStyle(fontSize: 12.5, color: textMuted),
                            ),
                            const SizedBox(height: 14),
                            _buildRoomList(context),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),

                // RIGHT COLUMN (40%)
                Expanded(
                  flex: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Date picker card
                      _webCard(
                        isDark: isDark,
                        cardBg: cardBg,
                        cardBorder: cardBorder,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Select Dates',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: textPrimary)),
                            const SizedBox(height: 14),
                            // Check-In tile
                            GestureDetector(
                              onTap: () => _pickDate(true),
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: subBg,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: _checkInDate != null
                                        ? const Color(0xFF2DD4BF)
                                        : cardBorder,
                                    width: _checkInDate != null ? 2 : 1,
                                  ),
                                ),
                                child: Row(children: [
                                  Icon(Icons.login_outlined,
                                      size: 18, color: textMuted),
                                  const SizedBox(width: 10),
                                  Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text('Check-In',
                                            style: TextStyle(
                                                fontSize: 11, color: textMuted)),
                                        const SizedBox(height: 2),
                                        Text(
                                          _checkInDate != null
                                              ? _fmt.format(_checkInDate!)
                                              : 'Select date',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                            color: _checkInDate != null
                                                ? textPrimary
                                                : textMuted,
                                          ),
                                        ),
                                      ]),
                                ]),
                              ),
                            ),
                            const SizedBox(height: 10),
                            // Check-Out tile
                            GestureDetector(
                              onTap: _checkInDate == null
                                  ? null
                                  : () => _pickDate(false),
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: _checkInDate == null
                                      ? (isDark
                                          ? const Color(0xFF0F1923)
                                          : const Color(0xFFF1F5F9))
                                      : subBg,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: _checkOutDate != null
                                        ? const Color(0xFF2DD4BF)
                                        : cardBorder,
                                    width: _checkOutDate != null ? 2 : 1,
                                  ),
                                ),
                                child: Row(children: [
                                  Icon(Icons.logout_outlined,
                                      size: 18, color: textMuted),
                                  const SizedBox(width: 10),
                                  Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text('Check-Out',
                                            style: TextStyle(
                                                fontSize: 11, color: textMuted)),
                                        const SizedBox(height: 2),
                                        Text(
                                          _checkOutDate != null
                                              ? _fmt.format(_checkOutDate!)
                                              : 'Select date',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                            color: _checkOutDate != null
                                                ? textPrimary
                                                : textMuted,
                                          ),
                                        ),
                                      ]),
                                ]),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Cost estimate card (shown when dates selected)
                      if (_checkInDate != null && _checkOutDate != null) ...[
                        _webCard(
                          isDark: isDark,
                          cardBg: cardBg,
                          cardBorder: cardBorder,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2DD4BF)
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.calculate_outlined,
                                      size: 16, color: Color(0xFF2DD4BF)),
                                ),
                                const SizedBox(width: 10),
                                Text('Cost Estimate',
                                    style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: textPrimary)),
                              ]),
                              const SizedBox(height: 14),
                              _costRowWeb(
                                  'Monthly Rent',
                                  'PKR ${hostel.rentPerMonth.toStringAsFixed(0)}',
                                  textPrimary,
                                  textMuted),
                              const Divider(height: 20),
                              _costRowWeb(
                                  'Duration',
                                  '${_estimatedMonths.toStringAsFixed(1)} months',
                                  textPrimary,
                                  textMuted),
                              if (_selectedRoom != null)
                                _costRowWeb('Selected Room',
                                    _selectedRoom!.roomNumber, textPrimary, textMuted),
                              Container(
                                margin: const EdgeInsets.only(top: 12),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2DD4BF)
                                      .withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                      color: const Color(0xFF2DD4BF)
                                          .withValues(alpha: 0.2)),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Estimated Total',
                                        style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14,
                                            color: textPrimary)),
                                    Text(
                                      'PKR ${_totalCost.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 18,
                                          color: Color(0xFF2DD4BF)),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Notice box
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.info.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color:
                                  AppColors.info.withValues(alpha: 0.2)),
                        ),
                        child: Row(children: [
                          const Icon(Icons.info_outline,
                              color: AppColors.info, size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Your booking request will be sent to the owner for approval. '
                              'Upon acceptance, your vacancy will be secured in the room.',
                              style: TextStyle(
                                  fontSize: 12.5, color: textMuted),
                            ),
                          ),
                        ]),
                      ),
                      const SizedBox(height: 20),

                      // Submit button
                      _buildSubmitButton(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Shared helpers ──────────────────────────────────────────────────────────
  Widget _webCard({
    required bool isDark,
    required Color cardBg,
    required Color cardBorder,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _costRowWeb(String label, String value, Color textPrimary, Color textMuted) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: textMuted)),
          Text(value,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: textPrimary)),
        ],
      ),
    );
  }

  Widget _buildRoomList(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final subTextColor = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final cardBg = isDark ? AppColors.darkSurface : Colors.white;
    final disabledBg = isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade100;

    if (hostel.rooms.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8.0),
        child: Text('No rooms configured.',
            style: TextStyle(color: AppColors.textSecondary)),
      );
    }
    return Column(
      children: hostel.rooms.map((room) {
        final isSelected = _selectedRoom?.id == room.id;
        final hasVacancy = room.hasVacancy;
        return GestureDetector(
          onTap: hasVacancy ? () => setState(() => _selectedRoom = room) : null,
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: !hasVacancy
                  ? disabledBg
                  : isSelected
                      ? AppColors.primary.withValues(alpha: 0.10)
                      : cardBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: !hasVacancy
                    ? (isDark ? AppColors.darkDivider : AppColors.divider)
                    : isSelected
                        ? AppColors.primary
                        : (isDark ? AppColors.darkDivider : AppColors.divider),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isSelected
                      ? Icons.radio_button_checked
                      : (hasVacancy ? Icons.radio_button_off : Icons.block),
                  color: !hasVacancy
                      ? Colors.grey
                      : isSelected
                          ? AppColors.primary
                          : subTextColor,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            room.roomNumber,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: !hasVacancy ? Colors.grey : textColor,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '(${room.type} Room)',
                            style: TextStyle(fontSize: 12, color: subTextColor),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        hasVacancy
                            ? '${room.vacancies} of ${room.capacity} vacancies available'
                            : 'Filled \u2022 No vacancies remaining',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: hasVacancy ? AppColors.success : AppColors.error,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: hasVacancy
                        ? AppColors.success.withValues(alpha: 0.1)
                        : Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    hasVacancy ? '${room.vacancies} Left' : 'Full',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: hasVacancy ? AppColors.success : Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCostBox(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          _CostRow(
              label: 'Monthly Rent',
              value: 'PKR ${hostel.rentPerMonth.toStringAsFixed(0)}'),
          _CostRow(
              label: 'Duration',
              value: '${_estimatedMonths.toStringAsFixed(1)} months'),
          if (_selectedRoom != null)
            _CostRow(
              label: 'Selected Room',
              value: _selectedRoom!.roomNumber,
            ),
          const Divider(),
          _CostRow(
            label: 'Estimated Total',
            value: 'PKR ${_totalCost.toStringAsFixed(0)}',
            isTotal: true,
          ),
        ],
      ),
    );
  }

  Widget _buildNoticeBox() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, color: AppColors.info, size: 18),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Your booking request will be sent to the owner for approval. '
              'Upon acceptance, your vacancy will be secured in the room.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Obx(() => CustomButton(
          text: 'Send Booking Request',
          isLoading: bookingCtrl.isLoading.value,
          icon: Icons.send_outlined,
          onPressed: (_checkInDate != null &&
                  _checkOutDate != null &&
                  _selectedRoom != null &&
                  _selectedRoom!.hasVacancy)
              ? () async {
                  final success = await bookingCtrl.requestBooking(
                    hostel: hostel,
                    checkInDate: _checkInDate!,
                    checkOutDate: _checkOutDate!,
                    roomId: _selectedRoom!.id,
                    roomNumber: _selectedRoom!.roomNumber,
                  );
                  if (success) Get.back();
                }
              : null,
        ));
  }
}

// ── Date picker card ───────────────────────────────────────────────────────
class _DatePickerCard extends StatelessWidget {
  final String label;
  final DateTime? date;
  final DateFormat formatter;
  final IconData icon;
  final VoidCallback onTap;
  final bool isDisabled;

  const _DatePickerCard({
    required this.label,
    required this.date,
    required this.formatter,
    required this.icon,
    required this.onTap,
    this.isDisabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDisabled ? AppColors.divider : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: date != null ? AppColors.primary : AppColors.divider,
            width: date != null ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(label,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              date != null ? formatter.format(date!) : 'Select date',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: date != null
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Cost breakdown row ─────────────────────────────────────────────────────
class _CostRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isTotal;

  const _CostRow({required this.label, required this.value, this.isTotal = false});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                fontSize: isTotal ? 16 : 14,
              )),
          Text(value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: isTotal ? 18 : 14,
                color: isTotal ? AppColors.primary : textColor,
              )),
        ],
      ),
    );
  }
}


// ─────────────────────────────────────────────────────────────────────────────
// lib/views/student/my_bookings_screen.dart
// FR-5.5: Student's booking history.
// ─────────────────────────────────────────────────────────────────────────────

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  String _filter = 'all'; // 'all' | 'confirmed' | 'pending' | 'cancelled'
  String _searchQuery = '';

  List<dynamic> _applyFilters(List<dynamic> list) {
    final q = _searchQuery.toLowerCase().trim();
    return list.where((b) {
      bool matchesFilter = true;
      if (_filter == 'confirmed') {
        matchesFilter = b.status == AppConstants.bookingConfirmed;
      } else if (_filter == 'pending') {
        matchesFilter = b.status == AppConstants.bookingPending;
      } else if (_filter == 'cancelled') {
        matchesFilter = b.status == AppConstants.bookingCancelled;
      }

      final matchesSearch = q.isEmpty ||
          b.hostelName.toLowerCase().contains(q) ||
          (b.roomNumber?.toLowerCase().contains(q) ?? false);

      return matchesFilter && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final BookingController ctrl = Get.find<BookingController>();
    final isWide = Responsive.isWide(context);

    if (isWide) return _buildWeb(context, ctrl);
    return _buildMobile(context, ctrl);
  }

  // ── Mobile layout Redesign ────────────────────────────────────────────────
  Widget _buildMobile(BuildContext context, BookingController ctrl) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF111827) : const Color(0xFFF1F5F9);

    return Scaffold(
      backgroundColor: bgColor,
      body: Obx(() {
        final all = ctrl.myBookings;
        final confirmedCount =
            all.where((b) => b.status == AppConstants.bookingConfirmed).length;
        final pendingCount =
            all.where((b) => b.status == AppConstants.bookingPending).length;
        final cancelledCount =
            all.where((b) => b.status == AppConstants.bookingCancelled).length;

        final filtered = _applyFilters(all);

        return Column(
          children: [
            // ── Curved Teal Hero Header ─────────────────────────────────────
            _buildMobileCurvedHeader(
              totalCount: all.length,
              confirmedCount: confirmedCount,
            ),

            // ── Filter Pills Row ─────────────────────────────────────────────
            _buildMobileFilterPills(
              totalCount: all.length,
              confirmedCount: confirmedCount,
              pendingCount: pendingCount,
              cancelledCount: cancelledCount,
            ),

            // ── Bookings List ────────────────────────────────────────────────
            Expanded(
              child: filtered.isEmpty
                  ? _buildMobileEmptyState(isDark)
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 80),
                      itemCount: filtered.length,
                      itemBuilder: (_, i) => _MobileModernBookingCard(
                        booking: filtered[i],
                        isDark: isDark,
                        onCancel: () =>
                            _confirmCancel(context, ctrl, filtered[i]),
                        onPay: () => _launchPayment(context, filtered[i]),
                        onReview: () => Get.toNamed(
                          AppRoutes.writeReview,
                          arguments: filtered[i].hostelId,
                        ),
                      ),
                    ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildMobileCurvedHeader({
    required int totalCount,
    required int confirmedCount,
  }) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF00585E), Color(0xFF007A85)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 16, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Title + Settings
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                    ),
                    child: const Icon(Icons.book_online_rounded,
                        color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'My Bookings',
                          style: TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: -0.3,
                          ),
                        ),
                        Text(
                          '$totalCount bookings · $confirmedCount confirmed',
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings_outlined,
                        color: Colors.white, size: 24),
                    tooltip: 'Settings',
                    onPressed: () => Get.to(() => const StudentSettingsScreen()),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Search Bar
              Container(
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: TextField(
                  onChanged: (val) => setState(() => _searchQuery = val),
                  style: const TextStyle(fontSize: 13.5, color: Color(0xFF0F172A)),
                  decoration: InputDecoration(
                    hintText: 'Search hostel name, room...',
                    hintStyle:
                        const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                    prefixIcon: const Icon(Icons.search_rounded,
                        color: Color(0xFF007A85), size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? GestureDetector(
                            onTap: () => setState(() => _searchQuery = ''),
                            child: const Icon(Icons.close_rounded,
                                size: 18, color: Color(0xFF94A3B8)),
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileFilterPills({
    required int totalCount,
    required int confirmedCount,
    required int pendingCount,
    required int cancelledCount,
  }) {
    final pills = [
      {'key': 'all', 'label': 'All', 'count': totalCount},
      {'key': 'confirmed', 'label': 'Confirmed', 'count': confirmedCount},
      {'key': 'pending', 'label': 'Pending', 'count': pendingCount},
      {'key': 'cancelled', 'label': 'Cancelled', 'count': cancelledCount},
    ];

    return Container(
      height: 46,
      margin: const EdgeInsets.only(top: 10, bottom: 6),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: pills.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final item = pills[i];
          final isSelected = _filter == item['key'];
          return GestureDetector(
            onTap: () => setState(() => _filter = item['key'] as String),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF00585E) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF00585E)
                      : const Color(0xFFE2E8F0),
                  width: 1.2,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: const Color(0xFF00585E).withValues(alpha: 0.25),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item['label'] as String,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? Colors.white : const Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.22)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${item['count']}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? Colors.white
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMobileEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF00585E).withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.book_outlined,
                size: 40,
                color: Color(0xFF00585E),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No matching bookings'
                  : 'No bookings found',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Try searching with different terms.'
                  : 'You have not made any hostel bookings yet.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
    );
  }

  // ── Web layout ─────────────────────────────────────────────────────────────
  Widget _buildWeb(BuildContext context, BookingController ctrl) {
    final isDark = Theme.of(context).brightness == Brightness.dark || Get.isDarkMode;
    final bg = isDark ? AppColors.darkBackground : const Color(0xFFF3F6F9);
    final surface = isDark ? const Color(0xFF1E242B) : Colors.white;
    final border = isDark ? const Color(0xFF2C3238) : const Color(0xFFE2E8F0);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final sub = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Container(
      color: bg,
      child: Obx(() {
        final bookings = ctrl.myBookings;
        if (bookings.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.book_outlined, size: 38, color: AppColors.primary),
                ),
                const SizedBox(height: 16),
                Text('No bookings yet',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: textColor)),
                const SizedBox(height: 6),
                Text('Your booking history will appear here.',
                    style: TextStyle(fontSize: 13, color: sub)),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () => Get.toNamed(AppRoutes.allHostels),
                  icon: const Icon(Icons.search_rounded, size: 16),
                  label: const Text('Explore Hostels'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Page Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('My Bookings',
                              style: TextStyle(
                                  fontSize: 26, fontWeight: FontWeight.w800, color: textColor)),
                          const SizedBox(height: 4),
                          Text('Track and manage all your hostel bookings in one place.',
                              style: TextStyle(fontSize: 13, color: sub)),
                        ],
                      ),
                      Obx(() => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
                            ),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              const Icon(Icons.bookmark_rounded, size: 15, color: AppColors.primary),
                              const SizedBox(width: 6),
                              Text('${ctrl.myBookings.length} Bookings',
                                  style: const TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary)),
                            ]),
                          )),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ...bookings.map((booking) {
                    final statusColor = _statusColor(booking.status);
                    final statusIcon = _statusIcon(booking.status);
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: border),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                            blurRadius: 12,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: [
                          // Card Header
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF171C22) : const Color(0xFFF8FAFC),
                              border: Border(bottom: BorderSide(color: border)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.domain_rounded,
                                      color: AppColors.primary, size: 22),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(booking.hostelName,
                                          style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w800,
                                              color: textColor)),
                                      Text(
                                        'Booking ID: ${booking.id.substring(0, 8).toUpperCase()}',
                                        style: TextStyle(fontSize: 11, color: sub),
                                      ),
                                    ],
                                  ),
                                ),
                                // Status badge
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: statusColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                                  ),
                                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                                    Icon(statusIcon, size: 13, color: statusColor),
                                    const SizedBox(width: 5),
                                    Text(
                                      booking.status.toUpperCase(),
                                      style: TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w800,
                                          color: statusColor),
                                    ),
                                  ]),
                                ),
                              ],
                            ),
                          ),

                          // Info Grid
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    _WebInfoCell(
                                      icon: Icons.meeting_room_outlined,
                                      label: booking.status == AppConstants.bookingConfirmed
                                          ? 'Assigned Room'
                                          : 'Requested Room',
                                      value: (booking.roomNumber != null &&
                                              booking.roomNumber!.isNotEmpty)
                                          ? booking.roomNumber!
                                          : '—',
                                      isDark: isDark,
                                    ),
                                    _WebInfoCell(
                                      icon: Icons.login_rounded,
                                      label: 'Check-In',
                                      value: DateFormat('MMM dd, yyyy').format(booking.checkInDate),
                                      isDark: isDark,
                                      valueColor: const Color(0xFF16A34A),
                                    ),
                                    _WebInfoCell(
                                      icon: Icons.logout_rounded,
                                      label: 'Check-Out',
                                      value: DateFormat('MMM dd, yyyy').format(booking.checkOutDate),
                                      isDark: isDark,
                                      valueColor: const Color(0xFFDC2626),
                                    ),
                                    _WebInfoCell(
                                      icon: Icons.payments_outlined,
                                      label: 'Total Amount',
                                      value: 'PKR ${booking.totalAmount.toStringAsFixed(0)}',
                                      isDark: isDark,
                                    ),
                                    _WebInfoCell(
                                      icon: Icons.credit_card_rounded,
                                      label: 'Payment',
                                      value: booking.paymentStatus.toUpperCase(),
                                      isDark: isDark,
                                      valueColor: booking.isPaid
                                          ? const Color(0xFF16A34A)
                                          : const Color(0xFFDC2626),
                                      isLast: true,
                                    ),
                                  ],
                                ),
                                if (booking.ownerNote != null) ...[
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? const Color(0xFF14191E)
                                          : const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: border),
                                    ),
                                    child: Row(children: [
                                      Icon(Icons.comment_outlined, size: 15, color: sub),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Owner note: ${booking.ownerNote}',
                                          style: TextStyle(fontSize: 12.5, color: sub),
                                        ),
                                      ),
                                    ]),
                                  ),
                                ],
                                if (booking.status == 'pending' ||
                                    booking.status == 'confirmed') ...[
                                  const SizedBox(height: 14),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      if (booking.status == 'confirmed') ...[
                                        OutlinedButton.icon(
                                          onPressed: () => Get.toNamed(AppRoutes.writeReview,
                                              arguments: booking.hostelId),
                                          icon: const Icon(Icons.star_outline,
                                              size: 15, color: Color(0xFFD97706)),
                                          label: const Text('Write Review'),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: const Color(0xFFD97706),
                                            side: const BorderSide(color: Color(0xFFF59E0B)),
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 16, vertical: 10),
                                            shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(10)),
                                            textStyle: const TextStyle(
                                                fontSize: 13, fontWeight: FontWeight.w600),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        ElevatedButton.icon(
                                          onPressed: () => _launchPayment(context, booking),
                                          icon: const Icon(Icons.credit_card_rounded, size: 15),
                                          label: const Text('Pay Rent'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.primary,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 18, vertical: 10),
                                            shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(10)),
                                            elevation: 0,
                                            textStyle: const TextStyle(
                                                fontSize: 13, fontWeight: FontWeight.w700),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                      ],
                                      OutlinedButton.icon(
                                        onPressed: () =>
                                            _confirmCancel(context, ctrl, booking),
                                        icon: const Icon(Icons.cancel_outlined,
                                            size: 15, color: AppColors.error),
                                        label: const Text('Cancel Booking'),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: AppColors.error,
                                          side: const BorderSide(color: AppColors.error),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 10),
                                          shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(10)),
                                          textStyle: const TextStyle(
                                              fontSize: 13, fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'confirmed': return const Color(0xFF16A34A);
      case 'pending': return const Color(0xFFF59E0B);
      case 'cancelled': return const Color(0xFFDC2626);
      default: return AppColors.textSecondary;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'confirmed': return Icons.check_circle_rounded;
      case 'pending': return Icons.hourglass_top_rounded;
      case 'cancelled': return Icons.cancel_rounded;
      default: return Icons.info_rounded;
    }
  }

  void _confirmCancel(BuildContext ctx, BookingController ctrl, booking) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('Cancel Booking'),
        content: const Text('Are you sure you want to cancel this booking?'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('No')),
          TextButton(
            onPressed: () {
              Get.back();
              ctrl.cancelBooking(booking);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _launchPayment(BuildContext context, booking) async {
    final result = await Get.toNamed(
      AppRoutes.safepayCheckout,
      arguments: {
        'bookingId'    : booking.id,
        'amount'       : booking.totalAmount,
        'studentEmail' : booking.studentEmail,
        'hostelName'   : booking.hostelName,
      },
    );

    if (result == 'success') {
      try {
        await Get.find<BookingService>().markAsPaid(booking.id);
        if (!context.mounted) return;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SuccessCelebration(
                    title: 'Payment Successful!',
                    message: 'Your payment has been securely confirmed.',
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Get.back(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      minimumSize: const Size.fromHeight(45),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Great',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
        );
      } catch (e) {
        Get.snackbar('Error', 'Payment recorded but failed to update. Contact support.');
      }
    } else if (result == 'cancelled') {
      Get.snackbar('Payment Cancelled', 'Your payment was not completed.',
          snackPosition: SnackPosition.BOTTOM);
    }
  }
}

// ── Web info cell ──────────────────────────────────────────────────────────────
class _WebInfoCell extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isDark;
  final Color? valueColor;
  final bool isLast;

  const _WebInfoCell({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
    this.valueColor,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final sub = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final text = isDark ? Colors.white : const Color(0xFF0F172A);
    final divColor = isDark ? const Color(0xFF2C3238) : const Color(0xFFE2E8F0);

    return Expanded(
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(icon, size: 13, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Text(label, style: TextStyle(fontSize: 11, color: sub, fontWeight: FontWeight.w500)),
                  ]),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: valueColor ?? text,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
          if (!isLast)
            Container(width: 1, height: 32, color: divColor),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Modern Card for Student Mobile Bookings
// ─────────────────────────────────────────────────────────────────────────────
class _MobileModernBookingCard extends StatelessWidget {
  final dynamic booking;
  final bool isDark;
  final VoidCallback onCancel;
  final VoidCallback onPay;
  final VoidCallback onReview;

  const _MobileModernBookingCard({
    required this.booking,
    required this.isDark,
    required this.onCancel,
    required this.onPay,
    required this.onReview,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final cardBorder = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);

    Color statusColor;
    String statusLabel;
    IconData statusIcon;

    switch (booking.status.toString().toLowerCase()) {
      case 'confirmed':
        statusColor = const Color(0xFF10B981);
        statusLabel = 'Confirmed';
        statusIcon = Icons.check_circle_rounded;
        break;
      case 'pending':
        statusColor = const Color(0xFFF59E0B);
        statusLabel = 'Pending';
        statusIcon = Icons.hourglass_top_rounded;
        break;
      case 'cancelled':
        statusColor = const Color(0xFFEF4444);
        statusLabel = 'Cancelled';
        statusIcon = Icons.cancel_rounded;
        break;
      default:
        statusColor = const Color(0xFF64748B);
        statusLabel = booking.status.toString().toUpperCase();
        statusIcon = Icons.info_rounded;
    }

    final isPaid = booking.isPaid == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Hostel Name + Status Pill
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.hostelName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                      if (booking.roomNumber != null &&
                          booking.roomNumber!.toString().isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            const Icon(Icons.meeting_room_rounded,
                                size: 13, color: Color(0xFF007A85)),
                            const SizedBox(width: 4),
                            Text(
                              booking.status == AppConstants.bookingConfirmed
                                  ? 'Assigned Room: ${booking.roomNumber}'
                                  : 'Requested Room: ${booking.roomNumber}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF007A85),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 13, color: statusColor),
                      const SizedBox(width: 5),
                      Text(
                        statusLabel,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Key Info Container
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cardBorder),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded,
                          size: 14, color: Color(0xFF007A85)),
                      const SizedBox(width: 8),
                      Text(
                        '${DateFormat("MMM d, yyyy").format(booking.checkInDate)} → ${DateFormat("MMM d, yyyy").format(booking.checkOutDate)}',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.payments_rounded,
                              size: 15, color: Color(0xFF007A85)),
                          const SizedBox(width: 8),
                          Text(
                            'PKR ${booking.totalAmount.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF00585E),
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isPaid
                              ? const Color(0xFF10B981).withValues(alpha: 0.12)
                              : const Color(0xFFEF4444).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isPaid
                                ? const Color(0xFF10B981).withValues(alpha: 0.3)
                                : const Color(0xFFEF4444).withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isPaid
                                  ? Icons.check_circle_rounded
                                  : Icons.pending_rounded,
                              size: 12,
                              color: isPaid
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFEF4444),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isPaid ? 'PAID' : 'UNPAID',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: isPaid
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFFEF4444),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Owner Note (if present)
            if (booking.ownerNote != null &&
                booking.ownerNote.toString().isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF00585E).withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFF00585E).withValues(alpha: 0.15),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.comment_outlined,
                        size: 14, color: Color(0xFF00585E)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Owner note: ${booking.ownerNote}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Action Buttons
            if (booking.status == 'confirmed' ||
                booking.status == 'pending') ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  if (booking.status == 'confirmed' && !isPaid)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onPay,
                        icon: const Icon(Icons.credit_card_rounded, size: 15),
                        label: const Text('Pay Rent'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00585E),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  if (booking.status == 'confirmed' && !isPaid)
                    const SizedBox(width: 8),
                  if (booking.status == 'confirmed')
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onReview,
                        icon: const Icon(Icons.star_outline_rounded, size: 15),
                        label: const Text('Review'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF00585E),
                          side: const BorderSide(
                              color: Color(0xFF00585E), width: 1.2),
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  if (booking.status == 'confirmed') const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onCancel,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error, width: 1.2),
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Cancel', style: TextStyle(fontSize: 12.5)),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
