import 'package:flutter/foundation.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:fyp/controllers/ChatController.dart';
import 'package:fyp/controllers/HostelController.dart';
import 'package:fyp/models/HostelModel.dart';
import 'package:fyp/models/RoomModel.dart';
import 'package:fyp/models/UserModel.dart';
import 'package:fyp/routes/AppRoutes.dart';
import 'package:fyp/services/AuthService.dart';
import 'package:fyp/services/hostelService.dart';
import 'package:fyp/utils/AppColors.dart';
import 'package:fyp/utils/AppConstants.dart';
import 'package:fyp/services/NotificationService.dart';
import 'package:fyp/views/shared%20Widgets/StatusChip.dart';
import 'package:shimmer/shimmer.dart';
import 'package:get/get.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class AdminHostelDetailScreen extends StatefulWidget {
  const AdminHostelDetailScreen({super.key});

  @override
  State<AdminHostelDetailScreen> createState() => _AdminHostelDetailScreenState();
}

class _AdminHostelDetailScreenState extends State<AdminHostelDetailScreen> {
  late final HostelModel initialHostel = Get.arguments as HostelModel;
  final HostelController hostelCtrl = Get.find<HostelController>();
  final HostelService _hostelService = Get.find<HostelService>();
  final ChatController chatCtrl = Get.find<ChatController>();
  final AuthService authService = Get.find<AuthService>();
  final NotificationService _notifService = Get.find<NotificationService>();
  int _currentImageIndex = 0;
  final PageController _webPageCtrl = PageController();

  @override
  void dispose() {
    _webPageCtrl.dispose();
    super.dispose();
  }
  late Future<UserModel?> _ownerFuture;

  @override
  void initState() {
    super.initState();
    _ownerFuture = authService.getUserById(initialHostel.ownerId);
  }

  Future<void> _openMaps(double lat, double lng) async {
    final url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
    );
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      Get.snackbar('Error', 'Could not open Google Maps.');
    }
  }

  Future<void> _sendWarning(HostelModel hostel) async {
    final ctrl = TextEditingController();
    await Get.defaultDialog(
      title: 'Send Final Warning',
      content: TextField(
        controller: ctrl,
        decoration: const InputDecoration(hintText: 'Enter warning reason...'),
        maxLines: 3,
      ),
      textConfirm: 'Send',
      textCancel: 'Cancel',
      confirmTextColor: Colors.white,
      onConfirm: () async {
        if (ctrl.text.isEmpty) return;
        Get.back(); // close dialog
        await _notifService.sendNotification(
          userId: hostel.ownerId,
          title: 'FINAL WARNING',
          body: ctrl.text,
          type: 'warning',
          relatedId: hostel.id,
        );
        Get.snackbar(
          'Warning Sent',
          'The owner has been notified.',
          backgroundColor: AppColors.success,
          colorText: Colors.white,
        );
      },
    );
  }

  void _confirmRemove(HostelModel hostel) {
    Get.defaultDialog(
      title: 'Remove Hostel',
      middleText: 'Are you sure you want to completely remove this hostel listing?',
      textConfirm: 'Delete',
      textCancel: 'Cancel',
      confirmTextColor: Colors.white,
      buttonColor: AppColors.error,
      onConfirm: () async {
        Get.back(); // close dialog
        final ok = await hostelCtrl.deleteHostel(hostel.id);
        if (ok) {
          Get.back(); // close screen
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<HostelModel?>(
      stream: _hostelService.getHostelStream(initialHostel.id),
      initialData: initialHostel,
      builder: (context, snapshot) {
        final hostel = snapshot.data ?? initialHostel;
        final String formattedDate = DateFormat('dd MMM yyyy, hh:mm a').format(hostel.createdAt);
        final isDark = Theme.of(context).brightness == Brightness.dark;

        if (kIsWeb) {
          return _buildWebScaffold(context, hostel, formattedDate, isDark);
        }
        return _buildMobileScaffold(context, hostel, formattedDate, isDark);
      },
    );
  }

  Widget _buildMobileScaffold(BuildContext context, HostelModel hostel, String formattedDate, bool isDark) {
        return Scaffold(
          backgroundColor: kIsWeb
              ? (isDark ? const Color(0xFF0F171E) : const Color(0xFFF6F8FA))
              : null,
          appBar: AppBar(
            title: const Text('Hostel Request Details'),
            backgroundColor: AppColors.primary,
            actions: [
              Obx(() {
                if (chatCtrl.isLoading.value) {
                  return const Padding(
                    padding: EdgeInsets.all(14),
                    child: SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    ),
                  );
                }
                return IconButton(
                  icon: const Icon(Icons.chat_outlined, color: Colors.white),
                  tooltip: 'Message Owner',
                  onPressed: () async {
                    final roomId = await chatCtrl.startOrGetConversation(
                      ownerId: hostel.ownerId,
                      ownerName: hostel.ownerName,
                      ownerEmail: '',
                    );
                    Get.toNamed(
                      AppRoutes.chatConversation,
                      arguments: {
                        'roomId': roomId,
                        'title': hostel.ownerName,
                      },
                    );
                  },
                );
              }),
              PopupMenuButton<String>(
                onSelected: (val) {
                  if (val == 'edit') {
                    Get.toNamed(AppRoutes.addHostel, arguments: hostel);
                  } else if (val == 'warning') {
                    _sendWarning(hostel);
                  } else if (val == 'remove') {
                    _confirmRemove(hostel);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: ListTile(
                      leading: Icon(Icons.edit_outlined),
                      title: Text('Edit Hostel'),
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'warning',
                    child: ListTile(
                      leading: Icon(Icons.warning_amber_outlined, color: Colors.orange),
                      title: Text('Send Final Warning'),
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'remove',
                    child: ListTile(
                      leading: Icon(Icons.delete_outline, color: Colors.red),
                      title: Text('Remove Hostel', style: TextStyle(color: Colors.red)),
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Image Slider ──────────────────────────────────────────────────
                Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    Container(
                      height: 250,
                      width: double.infinity,
                      color: AppColors.divider,
                      child: hostel.images.isNotEmpty
                          ? PageView.builder(
                              itemCount: hostel.images.length,
                              onPageChanged: (i) => setState(() => _currentImageIndex = i),
                              itemBuilder: (ctx, i) {
                                final imgWidget = CachedNetworkImage(
                                  imageUrl: hostel.images[i],
                                  fit: BoxFit.cover,
                                  placeholder: (_, __) => Shimmer.fromColors(
                                    baseColor: Colors.grey.shade300,
                                    highlightColor: Colors.grey.shade100,
                                    child: Container(color: Colors.white),
                                  ),
                                  errorWidget: (_, __, ___) => const Icon(
                                    Icons.home_work_outlined,
                                    size: 64,
                                    color: AppColors.textSecondary,
                                  ),
                                );

                                if (i == 0) {
                                  return Hero(
                                    tag: 'admin-hostel-img-${hostel.id}',
                                    child: Material(
                                      type: MaterialType.transparency,
                                      child: imgWidget,
                                    ),
                                  );
                                }
                                return imgWidget;
                              },
                            )
                          : Hero(
                              tag: 'admin-hostel-img-${hostel.id}',
                              child: const Material(
                                type: MaterialType.transparency,
                                child: Icon(
                                  Icons.home_work_outlined,
                                  size: 80,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                    ),
                    if (hostel.images.length > 1)
                      Positioned(
                        bottom: 12,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            hostel.images.length,
                            (i) => AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: _currentImageIndex == i ? 16 : 6,
                              height: 6,
                              margin: const EdgeInsets.symmetric(horizontal: 2),
                              decoration: BoxDecoration(
                                color: _currentImageIndex == i ? Colors.white : Colors.white54,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),

                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Un-registration Request Action Card ─────────────────────
                      if (hostel.unregistrationRequested) ...[
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.red.shade400, width: 1.5),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.report_problem_rounded, color: Colors.red.shade800, size: 22),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Un-registration & Deletion Request',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color: Colors.red.shade900,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Hostel owner requested to close and un-register this hostel listing.',
                                style: TextStyle(fontSize: 13, color: Colors.grey.shade800),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.red.shade200),
                                ),
                                child: Text(
                                  'Reason: ${hostel.unregistrationReason ?? "No reason provided"}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontStyle: FontStyle.italic,
                                    color: Colors.red.shade900,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () async {
                                        final ok = await hostelCtrl.rejectUnregistration(
                                          hostel.id,
                                          hostel.ownerId,
                                          hostel.name,
                                        );
                                        if (ok) setState(() {});
                                      },
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppColors.textPrimary,
                                        side: const BorderSide(color: AppColors.divider),
                                        padding: const EdgeInsets.symmetric(vertical: 10),
                                      ),
                                      child: const Text('Reject Request'),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () {
                                        Get.defaultDialog(
                                          title: 'Unregister & Delete',
                                          middleText:
                                              'Are you sure you want to unregister and permanently delete "${hostel.name}"?',
                                          textConfirm: 'Accept & Delete',
                                          textCancel: 'Cancel',
                                          confirmTextColor: Colors.white,
                                          buttonColor: AppColors.error,
                                          onConfirm: () async {
                                            Get.back(); // close dialog
                                            final ok = await hostelCtrl.acceptUnregistrationAndDelete(
                                              hostel.id,
                                              hostel.ownerId,
                                              hostel.name,
                                            );
                                            if (ok) {
                                              Get.back(); // return to admin list
                                            }
                                          },
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.error,
                                        padding: const EdgeInsets.symmetric(vertical: 10),
                                      ),
                                      child: const Text(
                                        'Unregister & Delete',
                                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Name and Status Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              hostel.name,
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                            ),
                          ),
                          StatusChip(status: hostel.status),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // ── Registration Number Badge (Admin View) ──────────────────
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: (hostel.registrationNumber != null && hostel.registrationNumber!.isNotEmpty)
                              ? AppColors.primary.withValues(alpha: 0.1)
                              : Colors.amber.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: (hostel.registrationNumber != null && hostel.registrationNumber!.isNotEmpty)
                                ? AppColors.primary.withValues(alpha: 0.3)
                                : Colors.amber.shade700.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  (hostel.registrationNumber != null && hostel.registrationNumber!.isNotEmpty)
                                      ? Icons.verified
                                      : Icons.app_registration,
                                  size: 18,
                                  color: (hostel.registrationNumber != null && hostel.registrationNumber!.isNotEmpty)
                                      ? AppColors.primary
                                      : Colors.amber.shade900,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  (hostel.registrationNumber != null && hostel.registrationNumber!.isNotEmpty)
                                      ? 'Reg #: ${hostel.registrationNumber}'
                                      : 'No Registration # Assigned',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: (hostel.registrationNumber != null && hostel.registrationNumber!.isNotEmpty)
                                        ? AppColors.primary
                                        : Colors.amber.shade900,
                                  ),
                                ),
                              ],
                            ),
                            InkWell(
                              onTap: () => _showAssignRegistrationDialog(hostel),
                              borderRadius: BorderRadius.circular(4),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      (hostel.registrationNumber != null && hostel.registrationNumber!.isNotEmpty)
                                          ? Icons.edit_outlined
                                          : Icons.add_circle_outline,
                                      size: 14,
                                      color: AppColors.primary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      (hostel.registrationNumber != null && hostel.registrationNumber!.isNotEmpty)
                                          ? 'Edit'
                                          : 'Assign Reg #',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Price
                      Text(
                        'PKR ${hostel.rentPerMonth.toStringAsFixed(0)} / month',
                        style: const TextStyle(
                          fontSize: 18,
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Owner Details Card
                      const Text(
                        'Owner Information',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: FutureBuilder<UserModel?>(
                          future: _ownerFuture,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              );
                            }
                            if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Name: ${hostel.ownerName}', style: const TextStyle(fontSize: 14)),
                                  const Text('Email: Unable to fetch email', style: TextStyle(fontSize: 14, color: AppColors.error)),
                                  Text('Submitted: $formattedDate', style: const TextStyle(fontSize: 14)),
                                ],
                              );
                            }

                            final owner = snapshot.data!;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Name: ${owner.name}',
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Email: ${owner.email}',
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Phone: ${owner.phone}',
                                  style: const TextStyle(fontSize: 14),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Submitted At: $formattedDate',
                                  style: const TextStyle(fontSize: 14),
                                ),
                                if (owner.cnicImageUrl != null && owner.cnicImageUrl!.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  const Divider(),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Owner CNIC (Front Side):',
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 8),
                                  GestureDetector(
                                    onTap: () {
                                      Get.dialog(
                                        Dialog(
                                          backgroundColor: Colors.transparent,
                                          child: Stack(
                                            alignment: Alignment.topRight,
                                            children: [
                                              InteractiveViewer(
                                                child: ClipRRect(
                                                  borderRadius: BorderRadius.circular(16),
                                                  child: Image.network(owner.cnicImageUrl!, fit: BoxFit.contain),
                                                ),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                                                onPressed: () => Get.back(),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: AspectRatio(
                                        aspectRatio: 1.586,
                                        child: Image.network(
                                          owner.cnicImageUrl!,
                                          fit: BoxFit.cover,
                                          loadingBuilder: (context, child, loadingProgress) {
                                            if (loadingProgress == null) return child;
                                            return const Center(child: CircularProgressIndicator());
                                          },
                                          errorBuilder: (context, error, stackTrace) {
                                            return const Center(
                                              child: Icon(Icons.broken_image_outlined, size: 40),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 10),
                      // ── Message Owner Button ────────────────────────────────────
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.chat_outlined),
                          label: const Text('Message Owner'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.primary),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () async {
                            final roomId = await chatCtrl.startOrGetConversation(
                              ownerId: hostel.ownerId,
                              ownerName: hostel.ownerName,
                              ownerEmail: '',
                            );
                            Get.toNamed(
                              AppRoutes.chatConversation,
                              arguments: {
                                'roomId': roomId,
                                'title': hostel.ownerName,
                              },
                            );
                          },
                        ),
                      ),
                      const Divider(height: 24),

                      // Specs: Room type, Gender Pref
                      Row(
                        children: [
                          Expanded(
                            child: _buildSpecTile(
                              icon: Icons.meeting_room_outlined,
                              title: 'Room Type',
                              value: hostel.roomType,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildSpecTile(
                              icon: Icons.people_outline,
                              title: 'Gender Preference',
                              value: hostel.genderPreference,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // ── Admin: Rooms & Vacancies Management Section ──────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(
                            child: Text(
                              'Rooms & Vacancies',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: hostel.totalVacancies > 0
                                  ? AppColors.success.withValues(alpha: 0.1)
                                  : AppColors.error.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: hostel.totalVacancies > 0
                                    ? AppColors.success.withValues(alpha: 0.3)
                                    : AppColors.error.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              '${hostel.totalVacancies} Vacancies Available',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: hostel.totalVacancies > 0
                                    ? AppColors.success
                                    : AppColors.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Live audit of all rooms, current vacancies, filled rooms, and assigned students.',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 12),

                      // Summary Stat Grid
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildAdminMetric('Total Rooms', '${hostel.rooms.length}', AppColors.textPrimary),
                            Container(width: 1, height: 28, color: AppColors.divider),
                            _buildAdminMetric('Vacant Rooms', '${hostel.totalRoomsWithVacancy}', AppColors.success),
                            Container(width: 1, height: 28, color: AppColors.divider),
                            _buildAdminMetric('Filled Rooms', '${hostel.totalFilledRooms}', hostel.totalFilledRooms > 0 ? AppColors.error : AppColors.textSecondary),
                            Container(width: 1, height: 28, color: AppColors.divider),
                            _buildAdminMetric('Total Vacancies', '${hostel.totalVacancies}', AppColors.primary),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Room Cards List
                      if (hostel.rooms.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: Text('No rooms configured.', style: TextStyle(color: AppColors.textSecondary)),
                        )
                      else
                        ...hostel.rooms.map((room) => _buildAdminRoomCard(hostel, room)),

                      const Divider(height: 28),

                      // Location address & Google Maps preview
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.location_on_outlined, color: AppColors.primary),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${hostel.city}, Pakistan',
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      hostel.address,
                                      style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Coordinates: ${hostel.latitude.toStringAsFixed(6)}, ${hostel.longitude.toStringAsFixed(6)}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              TextButton.icon(
                                onPressed: () => _openMaps(hostel.latitude, hostel.longitude),
                                icon: const Icon(Icons.map_outlined, size: 18),
                                label: const Text('View Map'),
                                style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                              )
                            ],
                          ),
                          const SizedBox(height: 12),
                          // flutter_map — OpenStreetMap (no API key needed)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: SizedBox(
                              height: 200,
                              width: double.infinity,
                              child: FlutterMap(
                                options: MapOptions(
                                  initialCenter: LatLng(hostel.latitude, hostel.longitude),
                                  initialZoom: 15,
                                  interactionOptions: const InteractionOptions(
                                    flags: InteractiveFlag.all & ~InteractiveFlag.doubleTapZoom,
                                  ),
                                ),
                                children: [
                                  TileLayer(
                                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                    userAgentPackageName: 'com.example.fyp',
                                  ),
                                  MarkerLayer(
                                    markers: [
                                      Marker(
                                        point: LatLng(hostel.latitude, hostel.longitude),
                                        width: 40,
                                        height: 40,
                                        child: const Icon(
                                          Icons.location_pin,
                                          color: Colors.red,
                                          size: 40,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),

                      // Description
                      const Text(
                        'Description',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        hostel.description,
                        style: const TextStyle(fontSize: 14, height: 1.4, color: AppColors.textSecondary),
                      ),
                      const Divider(height: 24),

                      // Facilities
                      const Text(
                        'Facilities',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: hostel.facilities.map((f) {
                          return Chip(
                            label: Text(f),
                            backgroundColor: AppColors.background,
                            side: const BorderSide(color: AppColors.divider),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 80), // extra padding for bottom actions
                    ],
                  ),
                ),
              ],
            ),
          ),
          // ── Actions panel if pending ──────────────────────────────────────────
          bottomNavigationBar: hostel.status == AppConstants.statusPending
              ? SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () async {
                              await hostelCtrl.updateHostelStatus(hostel.id, AppConstants.statusRejected);
                              Get.back();
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.error,
                              side: const BorderSide(color: AppColors.error),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Text('Reject Listing'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _showApproveDialog(hostel),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.success,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Text('Approve Listing', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : null,
        );
  }

  // ==============================================================================
  // -- Web Layout & Components ---------------------------------------------------
  // ==============================================================================

  Widget _buildWebScaffold(BuildContext context, HostelModel hostel, String formattedDate, bool isDark) {
    final cardBg = isDark ? const Color(0xFF14202E) : Colors.white;
    final cardBorder = isDark ? const Color(0xFF223242) : const Color(0xFFE2E8F0);
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    const tealAccent = Color(0xFF2DD4BF);
    final hasReg = hostel.registrationNumber != null && hostel.registrationNumber!.isNotEmpty;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F171E) : const Color(0xFFF6F8FA),
      appBar: AppBar(
        backgroundColor: cardBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textPrimary),
          tooltip: 'Back to Hostels',
          onPressed: () => Get.back(),
        ),
        title: Row(
          children: [
            InkWell(
              onTap: () => Get.back(),
              child: Text(
                'Hostels',
                style: TextStyle(color: textSecondary, fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
            Text('  /  ', style: TextStyle(color: textSecondary, fontSize: 13)),
            Expanded(
              child: Text(
                hostel.name,
                style: TextStyle(color: textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: cardBorder, height: 1),
        ),
        actions: [
          // Registration Number Badge
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: hasReg ? tealAccent.withValues(alpha: 0.12) : Colors.amber.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: hasReg ? tealAccent.withValues(alpha: 0.3) : Colors.amber.withValues(alpha: 0.3),
              ),
            ),
            child: InkWell(
              onTap: () => _showAssignRegistrationDialog(hostel),
              borderRadius: BorderRadius.circular(6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    hasReg ? Icons.verified : Icons.app_registration,
                    size: 15,
                    color: hasReg ? tealAccent : Colors.amber.shade700,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    hasReg ? 'Reg: ${hostel.registrationNumber}' : 'Assign Reg #',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: hasReg ? tealAccent : Colors.amber.shade700,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.edit_outlined,
                    size: 13,
                    color: hasReg ? tealAccent : Colors.amber.shade700,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          StatusChip(status: hostel.status),
          const SizedBox(width: 10),
          // Quick Message Button
          Obx(() {
            if (chatCtrl.isLoading.value) {
              return const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: tealAccent),
                ),
              );
            }
            return OutlinedButton.icon(
              icon: const Icon(Icons.chat_outlined, size: 15),
              label: const Text('Message Owner'),
              style: OutlinedButton.styleFrom(
                foregroundColor: tealAccent,
                side: BorderSide(color: tealAccent.withValues(alpha: 0.5)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                final roomId = await chatCtrl.startOrGetConversation(
                  ownerId: hostel.ownerId,
                  ownerName: hostel.ownerName,
                  ownerEmail: '',
                );
                Get.toNamed(
                  AppRoutes.chatConversation,
                  arguments: {
                    'roomId': roomId,
                    'title': hostel.ownerName,
                  },
                );
              },
            );
          }),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(Icons.edit_outlined, color: textSecondary, size: 20),
            tooltip: 'Edit Hostel',
            onPressed: () => Get.toNamed(AppRoutes.addHostel, arguments: hostel),
          ),
          IconButton(
            icon: const Icon(Icons.warning_amber_outlined, color: Colors.orange, size: 20),
            tooltip: 'Send Final Warning',
            onPressed: () => _sendWarning(hostel),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
            tooltip: 'Remove Hostel',
            onPressed: () => _confirmRemove(hostel),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1140),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 880;
                  if (isWide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 7, child: _buildWebLeftColumn(context, hostel, isDark)),
                        const SizedBox(width: 24),
                        Expanded(flex: 5, child: _buildWebRightColumn(context, hostel, formattedDate, isDark)),
                      ],
                    );
                  }
                  return Column(
                    children: [
                      _buildWebLeftColumn(context, hostel, isDark),
                      const SizedBox(height: 20),
                      _buildWebRightColumn(context, hostel, formattedDate, isDark),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWebLeftColumn(BuildContext context, HostelModel hostel, bool isDark) {
    final cardBorder = isDark ? const Color(0xFF223242) : const Color(0xFFE2E8F0);
    final subBg = isDark ? const Color(0xFF1B2836) : const Color(0xFFF8FAFC);
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    const tealAccent = Color(0xFF2DD4BF);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Image Gallery Card
        Container(
          height: 360,
          width: double.infinity,
          decoration: BoxDecoration(
            color: subBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cardBorder),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              hostel.images.isNotEmpty
                  ? PageView.builder(
                      controller: _webPageCtrl,
                      itemCount: hostel.images.length,
                      onPageChanged: (i) => setState(() => _currentImageIndex = i),
                      itemBuilder: (ctx, i) {
                        return CachedNetworkImage(
                          imageUrl: hostel.images[i],
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          placeholder: (_, __) => Shimmer.fromColors(
                            baseColor: isDark ? const Color(0xFF1E293B) : Colors.grey.shade300,
                            highlightColor: isDark ? const Color(0xFF334155) : Colors.grey.shade100,
                            child: Container(color: Colors.white),
                          ),
                          errorWidget: (_, __, ___) => const Center(
                            child: Icon(Icons.home_work_outlined, size: 64, color: AppColors.textSecondary),
                          ),
                        );
                      },
                    )
                  : const Center(
                      child: Icon(Icons.home_work_outlined, size: 80, color: AppColors.textSecondary),
                    ),
              if (hostel.images.length > 1) ...[
                // Left Arrow Button
                Positioned(
                  left: 14,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: Material(
                      color: Colors.black54,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () {
                          if (_webPageCtrl.hasClients && _currentImageIndex > 0) {
                            _webPageCtrl.previousPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          }
                        },
                        child: const Padding(
                          padding: EdgeInsets.all(8),
                          child: Icon(Icons.chevron_left, color: Colors.white, size: 24),
                        ),
                      ),
                    ),
                  ),
                ),
                // Right Arrow Button
                Positioned(
                  right: 14,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: Material(
                      color: Colors.black54,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () {
                          if (_webPageCtrl.hasClients && _currentImageIndex < hostel.images.length - 1) {
                            _webPageCtrl.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          }
                        },
                        child: const Padding(
                          padding: EdgeInsets.all(8),
                          child: Icon(Icons.chevron_right, color: Colors.white, size: 24),
                        ),
                      ),
                    ),
                  ),
                ),
                // Dots Indicator
                Positioned(
                  bottom: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        hostel.images.length,
                        (i) => AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: _currentImageIndex == i ? 18 : 6,
                          height: 6,
                          margin: const EdgeInsets.symmetric(horizontal: 2.5),
                          decoration: BoxDecoration(
                            color: _currentImageIndex == i ? tealAccent : Colors.white60,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Overview & Facilities Card
        _webCard(
          isDark: isDark,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title & Price Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      hostel.name,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: tealAccent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: tealAccent.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      'PKR ${hostel.rentPerMonth.toStringAsFixed(0)} / mo',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: tealAccent,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Specs Row
              Row(
                children: [
                  Expanded(
                    child: _webSpecTile(
                      icon: Icons.meeting_room_outlined,
                      title: 'Room Type',
                      value: hostel.roomType,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _webSpecTile(
                      icon: Icons.people_outline,
                      title: 'Gender Preference',
                      value: hostel.genderPreference,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _webSpecTile(
                      icon: Icons.location_city_outlined,
                      title: 'City',
                      value: hostel.city,
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Divider(color: cardBorder, height: 1),
              const SizedBox(height: 18),

              // Description
              Text(
                'About this Hostel',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                hostel.description,
                style: TextStyle(fontSize: 14, height: 1.5, color: textSecondary),
              ),
              const SizedBox(height: 20),
              Divider(color: cardBorder, height: 1),
              const SizedBox(height: 18),

              // Facilities & Amenities
              Text(
                'Facilities & Amenities',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textPrimary),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: hostel.facilities.map((f) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: subBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: cardBorder),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle_outline, size: 14, color: tealAccent),
                        const SizedBox(width: 6),
                        Text(
                          f,
                          style: TextStyle(fontSize: 13, color: textPrimary, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Location & Map Card
        _webCard(
          isDark: isDark,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: tealAccent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.location_on_outlined, color: tealAccent, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${hostel.city}, Pakistan',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textPrimary),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          hostel.address,
                          style: TextStyle(fontSize: 13, color: textSecondary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'GPS Coordinates: ${hostel.latitude.toStringAsFixed(6)}, ${hostel.longitude.toStringAsFixed(6)}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: tealAccent),
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _openMaps(hostel.latitude, hostel.longitude),
                    icon: const Icon(Icons.map_outlined, size: 16),
                    label: const Text('View Map'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: tealAccent,
                      side: BorderSide(color: tealAccent.withValues(alpha: 0.5)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  height: 240,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: cardBorder),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: FlutterMap(
                    options: MapOptions(
                      initialCenter: LatLng(hostel.latitude, hostel.longitude),
                      initialZoom: 15,
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.all & ~InteractiveFlag.doubleTapZoom,
                      ),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.fyp',
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: LatLng(hostel.latitude, hostel.longitude),
                            width: 40,
                            height: 40,
                            child: const Icon(
                              Icons.location_pin,
                              color: Colors.red,
                              size: 40,
                            ),
                          ),
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
    );
  }

  Widget _buildWebRightColumn(BuildContext context, HostelModel hostel, String formattedDate, bool isDark) {
    final cardBorder = isDark ? const Color(0xFF223242) : const Color(0xFFE2E8F0);
    final subBg = isDark ? const Color(0xFF1B2836) : const Color(0xFFF8FAFC);
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    const tealAccent = Color(0xFF2DD4BF);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Un-registration Request Alert Card (if applicable)
        if (hostel.unregistrationRequested) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2D1419) : const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.red.shade400, width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.report_problem_rounded, color: Colors.red.shade400, size: 22),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Un-registration & Deletion Request',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Colors.red.shade400,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Hostel owner requested to close and permanently remove this hostel listing.',
                  style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.grey.shade800),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1B1B26) : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade300.withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    'Reason: ${hostel.unregistrationReason ?? "No reason provided"}',
                    style: TextStyle(
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      color: isDark ? Colors.red.shade300 : Colors.red.shade900,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          final ok = await hostelCtrl.rejectUnregistration(
                            hostel.id,
                            hostel.ownerId,
                            hostel.name,
                          );
                          if (ok) setState(() {});
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: isDark ? Colors.white : AppColors.textPrimary,
                          side: BorderSide(color: cardBorder),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Reject Request'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Get.defaultDialog(
                            title: 'Unregister & Delete',
                            middleText:
                                'Are you sure you want to unregister and permanently delete "${hostel.name}"?',
                            textConfirm: 'Accept & Delete',
                            textCancel: 'Cancel',
                            confirmTextColor: Colors.white,
                            buttonColor: AppColors.error,
                            onConfirm: () async {
                              Get.back();
                              final ok = await hostelCtrl.acceptUnregistrationAndDelete(
                                hostel.id,
                                hostel.ownerId,
                                hostel.name,
                              );
                              if (ok) Get.back();
                            },
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text(
                          'Unregister & Delete',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],

        // Pending Approval Review Card (if status == pending)
        if (hostel.status == AppConstants.statusPending) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF132A26) : const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: tealAccent.withValues(alpha: 0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.verified_user_outlined, color: tealAccent, size: 22),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Pending Verification Review',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textPrimary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Review owner identity and rooms details before approving this listing.',
                  style: TextStyle(fontSize: 13, color: textSecondary),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          await hostelCtrl.updateHostelStatus(hostel.id, AppConstants.statusRejected);
                          Get.back();
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: const BorderSide(color: AppColors.error),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Reject Listing'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _showApproveDialog(hostel),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text(
                          'Approve Listing',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],

        // Owner Information Card
        _webCard(
          isDark: isDark,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: tealAccent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.person_pin_outlined, color: tealAccent, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Owner Information',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textPrimary),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              FutureBuilder<UserModel?>(
                future: _ownerFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
                      ),
                    );
                  }
                  if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _webInfoRow(Icons.person_outline, 'Name', hostel.ownerName, textPrimary, textSecondary),
                        _webInfoRow(Icons.email_outlined, 'Email', 'Unable to fetch email', AppColors.error, textSecondary),
                        _webInfoRow(Icons.calendar_today_outlined, 'Submitted', formattedDate, textPrimary, textSecondary),
                      ],
                    );
                  }

                  final owner = snapshot.data!;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _webInfoRow(Icons.person_outline, 'Name', owner.name, textPrimary, textSecondary),
                      _webInfoRow(Icons.email_outlined, 'Email', owner.email, textPrimary, textSecondary),
                      _webInfoRow(Icons.phone_outlined, 'Phone', owner.phone, textPrimary, textSecondary),
                      _webInfoRow(Icons.calendar_today_outlined, 'Submitted At', formattedDate, textPrimary, textSecondary),
                      if (owner.cnicImageUrl != null && owner.cnicImageUrl!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Divider(color: cardBorder, height: 1),
                        const SizedBox(height: 12),
                        Text(
                          'Owner CNIC (Front Side)',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textPrimary),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () {
                            Get.dialog(
                              Dialog(
                                backgroundColor: Colors.transparent,
                                child: Stack(
                                  alignment: Alignment.topRight,
                                  children: [
                                    InteractiveViewer(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(16),
                                        child: Image.network(owner.cnicImageUrl!, fit: BoxFit.contain),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.close, color: Colors.white, size: 30),
                                      onPressed: () => Get.back(),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: cardBorder),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: AspectRatio(
                                aspectRatio: 1.586,
                                child: Image.network(
                                  owner.cnicImageUrl!,
                                  fit: BoxFit.cover,
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return const Center(child: CircularProgressIndicator());
                                  },
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Center(
                                      child: Icon(Icons.broken_image_outlined, size: 40),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.chat_outlined, size: 16, color: Colors.white),
                  label: const Text('Message Owner', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00A896),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () async {
                    final roomId = await chatCtrl.startOrGetConversation(
                      ownerId: hostel.ownerId,
                      ownerName: hostel.ownerName,
                      ownerEmail: '',
                    );
                    Get.toNamed(
                      AppRoutes.chatConversation,
                      arguments: {
                        'roomId': roomId,
                        'title': hostel.ownerName,
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Rooms & Vacancies Audit Card
        _webCard(
          isDark: isDark,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: tealAccent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.hotel_outlined, color: tealAccent, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Rooms & Vacancies',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textPrimary),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: hostel.totalVacancies > 0
                          ? AppColors.success.withValues(alpha: 0.12)
                          : AppColors.error.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: hostel.totalVacancies > 0
                            ? AppColors.success.withValues(alpha: 0.3)
                            : AppColors.error.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      '${hostel.totalVacancies} Vacancies',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: hostel.totalVacancies > 0 ? AppColors.success : AppColors.error,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Live audit of rooms, bed allocation, and vacancies.',
                style: TextStyle(fontSize: 12, color: textSecondary),
              ),
              const SizedBox(height: 14),

              // Summary Stats Box
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                decoration: BoxDecoration(
                  color: subBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: cardBorder),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildAdminMetric('Total Rooms', '${hostel.rooms.length}', textPrimary),
                    Container(width: 1, height: 26, color: cardBorder),
                    _buildAdminMetric('Vacant Rooms', '${hostel.totalRoomsWithVacancy}', AppColors.success),
                    Container(width: 1, height: 26, color: cardBorder),
                    _buildAdminMetric(
                      'Filled Rooms',
                      '${hostel.totalFilledRooms}',
                      hostel.totalFilledRooms > 0 ? AppColors.error : textSecondary,
                    ),
                    Container(width: 1, height: 26, color: cardBorder),
                    _buildAdminMetric('Vacancies', '${hostel.totalVacancies}', tealAccent),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Room Cards List
              if (hostel.rooms.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  child: Text('No rooms configured.', style: TextStyle(color: textSecondary)),
                )
              else
                ...hostel.rooms.map((room) => _buildWebRoomItem(hostel, room, isDark)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWebRoomItem(HostelModel hostel, RoomModel room, bool isDark) {
    final cardBorder = isDark ? const Color(0xFF223242) : const Color(0xFFE2E8F0);
    final subBg = isDark ? const Color(0xFF1B2836) : const Color(0xFFF8FAFC);
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    const tealAccent = Color(0xFF2DD4BF);
    final hasVacancy = room.hasVacancy;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: subBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: hasVacancy ? AppColors.success.withValues(alpha: 0.3) : cardBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.meeting_room_outlined,
                    size: 18,
                    color: hasVacancy ? tealAccent : textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    room.roomNumber,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textPrimary),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '(${room.type} · ${room.capacity} Bed)',
                    style: TextStyle(fontSize: 12, color: textSecondary),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: hasVacancy
                      ? AppColors.success.withValues(alpha: 0.12)
                      : AppColors.error.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  hasVacancy ? '${room.vacancies} Vacant' : 'Filled',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: hasVacancy ? AppColors.success : AppColors.error,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Bed Slots View with Admin Vacate Authority
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: List.generate(room.capacity, (i) {
              final isOcc = room.isBedOccupied(i);
              final occupantName = room.getBedStudentName(i);
              final isManual = room.isBedManual(i);

              return Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(6),
                  onTap: () {
                    if (!isOcc) {
                      Get.snackbar('Vacant Bed', 'Bed ${i + 1} is currently vacant.');
                    } else if (isManual) {
                      _showAdminVacateBedDialog(hostel, room, i, occupantName ?? 'Resident');
                    } else {
                      Get.defaultDialog(
                        title: 'App-Booked Bed (Protected)',
                        middleText:
                            'Bed ${i + 1} was booked through DwellSense by "${occupantName ?? 'Student'}".\n\nAdmin cannot unilaterally mark active app bookings as vacant until the booking expires or the student cancels.',
                        textConfirm: 'OK',
                        confirmTextColor: Colors.white,
                        onConfirm: () => Get.back(),
                      );
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isOcc
                          ? (isManual
                              ? Colors.orange.withValues(alpha: 0.12)
                              : tealAccent.withValues(alpha: 0.12))
                          : AppColors.success.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isOcc
                            ? (isManual
                                ? Colors.orange.withValues(alpha: 0.5)
                                : tealAccent.withValues(alpha: 0.4))
                            : AppColors.success.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isOcc ? Icons.bed : Icons.single_bed_outlined,
                          size: 13,
                          color: isOcc
                              ? (isManual ? Colors.orange.shade600 : tealAccent)
                              : AppColors.success,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isOcc
                              ? (isManual
                                  ? 'Bed ${i + 1}: ${occupantName ?? 'Filled'} (Tap to Vacate)'
                                  : 'Bed ${i + 1}: ${occupantName ?? 'Booked'} 🔒')
                              : 'Bed ${i + 1}: Vacant',
                          style: TextStyle(
                            fontSize: 10,
                            color: isOcc
                                ? (isManual ? Colors.orange.shade700 : tealAccent)
                                : AppColors.success,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),

          if (room.assignedStudentNames.where((n) => n.trim().isNotEmpty).isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Assigned: ${room.assignedStudentNames.where((n) => n.trim().isNotEmpty).join(", ")}',
              style: const TextStyle(fontSize: 11, color: tealAccent, fontWeight: FontWeight.w500),
            ),
          ],
        ],
      ),
    );
  }

  Widget _webCard({
    required bool isDark,
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(20),
    Color? borderColor,
  }) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF14202E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor ?? (isDark ? const Color(0xFF223242) : const Color(0xFFE2E8F0)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _webSpecTile({
    required IconData icon,
    required String title,
    required String value,
    required bool isDark,
  }) {
    final subBg = isDark ? const Color(0xFF1B2836) : const Color(0xFFF8FAFC);
    final cardBorder = isDark ? const Color(0xFF223242) : const Color(0xFFE2E8F0);
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    const tealAccent = Color(0xFF2DD4BF);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: subBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cardBorder),
      ),
      child: Row(
        children: [
          Icon(icon, color: tealAccent, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 11, color: textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textPrimary),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _webInfoRow(IconData icon, String label, String value, Color valColor, Color labelColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: labelColor),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(fontSize: 13, color: labelColor, fontWeight: FontWeight.w500),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 13, color: valColor, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminMetric(String label, String value, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _buildAdminRoomCard(HostelModel hostel, RoomModel room) {
    final hasVacancy = room.hasVacancy;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: hasVacancy
              ? AppColors.success.withValues(alpha: 0.3)
              : AppColors.divider,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.meeting_room_outlined,
                    size: 18,
                    color: hasVacancy ? AppColors.primary : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    room.roomNumber,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '(${room.type} · ${room.capacity} Bed)',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: hasVacancy
                      ? AppColors.success.withValues(alpha: 0.1)
                      : AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  hasVacancy ? '${room.vacancies} Vacant' : 'Filled',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: hasVacancy ? AppColors.success : AppColors.error,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Bed Slots View with Admin Vacate Authority
            Wrap(
            spacing: 6,
            runSpacing: 4,
            children: List.generate(room.capacity, (i) {
              final isOcc = room.isBedOccupied(i);
              final occupantName = room.getBedStudentName(i);
              final isManual = room.isBedManual(i);

              return Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(4),
                  onTap: () {
                    if (!isOcc) {
                      Get.snackbar('Vacant Bed', 'Bed ${i + 1} is currently vacant.');
                    } else if (isManual) {
                      _showAdminVacateBedDialog(hostel, room, i, occupantName ?? 'Resident');
                    } else {
                      Get.defaultDialog(
                        title: 'App-Booked Bed (Protected)',
                        middleText:
                            'Bed ${i + 1} was booked through DwellSense by "${occupantName ?? 'Student'}".\n\nAdmin cannot unilaterally mark active app bookings as vacant until the booking expires or the student cancels.',
                        textConfirm: 'OK',
                        confirmTextColor: Colors.white,
                        onConfirm: () => Get.back(),
                      );
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isOcc
                          ? (isManual
                              ? Colors.orange.withValues(alpha: 0.1)
                              : AppColors.primary.withValues(alpha: 0.1))
                          : AppColors.success.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isOcc
                            ? (isManual
                                ? Colors.orange.withValues(alpha: 0.5)
                                : AppColors.primary.withValues(alpha: 0.4))
                            : AppColors.success.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isOcc ? Icons.bed : Icons.single_bed_outlined,
                          size: 13,
                          color: isOcc
                              ? (isManual ? Colors.orange.shade800 : AppColors.primary)
                              : AppColors.success,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isOcc
                              ? (isManual
                                  ? 'Bed ${i + 1}: ${occupantName ?? 'Filled'} (Tap to Vacate)'
                                  : 'Bed ${i + 1}: ${occupantName ?? 'Booked'} 🔒')
                              : 'Bed ${i + 1}: Vacant',
                          style: TextStyle(
                            fontSize: 10,
                            color: isOcc
                                ? (isManual ? Colors.orange.shade900 : AppColors.primaryDark)
                                : AppColors.success,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),

          if (room.assignedStudentNames.where((n) => n.trim().isNotEmpty).isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Assigned: ${room.assignedStudentNames.where((n) => n.trim().isNotEmpty).join(", ")}',
              style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w500),
            ),
          ],
        ],
      ),
    );
  }

  // ── Admin Vacate Bed Dialog ───────────────────────────────────────────────
  void _showAdminVacateBedDialog(HostelModel hostel, RoomModel room, int bedIndex, String occupantName) {
    Get.defaultDialog(
      title: 'Admin: Vacate Bed ${bedIndex + 1}',
      titleStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      middleText:
          'Are you sure you want to mark Bed ${bedIndex + 1} in ${room.roomNumber} as vacant?\n\nCurrent Resident: $occupantName (Manual Allocation)',
      textConfirm: 'Mark Vacant',
      textCancel: 'Cancel',
      confirmTextColor: Colors.white,
      buttonColor: AppColors.error,
      onConfirm: () async {
        Get.back(); // Close dialog
        final success = await hostelCtrl.adminVacateBed(
          hostelId: hostel.id,
          room: room,
          bedIndex: bedIndex,
        );
        if (success) {
          Get.snackbar('Bed Vacated', 'Bed ${bedIndex + 1} has been marked vacant by Admin.');
        }
      },
    );
  }

  Widget _buildSpecTile({required IconData icon, required String title, required String value}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 28),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                Text(
                  value,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  // ── Approval Dialog with Required Registration Number ──────────────────────
  void _showApproveDialog(HostelModel hostel) {
    final suggestedReg = (hostel.registrationNumber != null && hostel.registrationNumber!.isNotEmpty)
        ? hostel.registrationNumber!
        : hostelCtrl.generateNextRegistrationNumber();
    final regCtrl = TextEditingController(text: suggestedReg);

    Get.defaultDialog(
      title: 'Approve Hostel Listing',
      titleStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      content: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Assign a unique registration number to approve "${hostel.name}".',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: regCtrl,
              decoration: InputDecoration(
                labelText: 'Hostel Registration Number *',
                hintText: 'e.g. DS-Hostel-1, DS-Hostel-2',
                prefixIcon: const Icon(Icons.verified_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              autofocus: true,
            ),
          ],
        ),
      ),
      textConfirm: 'Approve & Assign',
      textCancel: 'Cancel',
      confirmTextColor: Colors.white,
      buttonColor: AppColors.success,
      onConfirm: () async {
        final regNo = regCtrl.text.trim();
        if (regNo.isEmpty) {
          Get.snackbar('Required', 'Please enter a valid registration number');
          return;
        }
        Get.back(); // close dialog
        final ok = await hostelCtrl.updateHostelStatus(
          hostel.id,
          AppConstants.statusApproved,
          registrationNumber: regNo,
        );
        if (ok) {
          Get.back(); // return to list
        }
      },
    );
  }

  // ── Assign/Edit Registration Number for Already Approved Hostel ────────────
  void _showAssignRegistrationDialog(HostelModel hostel) {
    final defaultReg = (hostel.registrationNumber != null && hostel.registrationNumber!.isNotEmpty)
        ? hostel.registrationNumber!
        : hostelCtrl.generateNextRegistrationNumber();
    final regCtrl = TextEditingController(text: defaultReg);

    Get.defaultDialog(
      title: 'Hostel Registration Number',
      titleStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      content: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Update registration number for "${hostel.name}".',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: regCtrl,
              decoration: InputDecoration(
                labelText: 'Registration Number *',
                hintText: 'e.g. DS-Hostel-1',
                prefixIcon: const Icon(Icons.verified_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              autofocus: true,
            ),
          ],
        ),
      ),
      textConfirm: 'Save Registration #',
      textCancel: 'Cancel',
      confirmTextColor: Colors.white,
      buttonColor: AppColors.primary,
      onConfirm: () async {
        final regNo = regCtrl.text.trim();
        if (regNo.isEmpty) {
          Get.snackbar('Required', 'Please enter a valid registration number');
          return;
        }
        Get.back(); // close dialog
        await hostelCtrl.assignRegistrationNumber(hostel.id, regNo);
      },
    );
  }
}
