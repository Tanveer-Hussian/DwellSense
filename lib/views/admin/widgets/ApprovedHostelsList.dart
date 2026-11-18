import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:fyp/controllers/HostelController.dart';
import 'package:fyp/models/HostelModel.dart';
import 'package:fyp/routes/AppRoutes.dart';
import 'package:fyp/utils/AppColors.dart';
import 'package:fyp/utils/AppConstants.dart';
import 'package:fyp/views/shared%20Widgets/StatusChip.dart';
import 'package:shimmer/shimmer.dart';
import 'package:get/get.dart';

class HostelApprovalList extends StatelessWidget {
  final List<HostelModel> hostels;
  final String emptyMessage;
  final HostelController hostelCtrl;
  final bool showActions;
  final bool showUnregistrationActions;

  const HostelApprovalList({
    super.key,
    required this.hostels,
    required this.emptyMessage,
    required this.hostelCtrl,
    required this.showActions,
    this.showUnregistrationActions = false,
  });

  @override
  Widget build(BuildContext context) {
    if (hostels.isEmpty) {
      return Center(
        child: Text(emptyMessage,
            style: const TextStyle(color: AppColors.textSecondary)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: hostels.length,
      itemBuilder: (_, i) {
        final hostel = hostels[i];
        return GestureDetector(
          onTap: () => Get.toNamed(AppRoutes.adminHostelDetail, arguments: hostel),
          child: Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Hero(
                        tag: 'admin-hostel-img-${hostel.id}',
                        child: Material(
                          type: MaterialType.transparency,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: hostel.images.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: hostel.images[0],
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                    placeholder: (_, __) => Shimmer.fromColors(
                                      baseColor: Colors.grey.shade300,
                                      highlightColor: Colors.grey.shade100,
                                      child: Container(
                                        width: 60,
                                        height: 60,
                                        color: Colors.white,
                                      ),
                                    ),
                                    errorWidget: (_, __, ___) => Container(
                                      width: 60,
                                      height: 60,
                                      color: AppColors.divider,
                                      child: const Icon(Icons.home_work_outlined),
                                    ),
                                  )
                                : Container(
                                    width: 60,
                                    height: 60,
                                    color: AppColors.divider,
                                    child: const Icon(Icons.home_work_outlined)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(hostel.name,
                                style: Theme.of(context).textTheme.titleLarge),
                            if (hostel.registrationNumber != null && hostel.registrationNumber!.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                                ),
                                child: Text(
                                  'Reg: ${hostel.registrationNumber}',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 2),
                            Text(
                                '${hostel.city} · ${hostel.roomType} · ${hostel.genderPreference}'),
                            Text(
                                'PKR ${hostel.rentPerMonth.toStringAsFixed(0)}/mo',
                                style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      StatusChip(status: hostel.status),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 4,
                    children: hostel.facilities
                        .take(3)
                        .map((f) => Chip(
                              label: Text(f,
                                  style: const TextStyle(fontSize: 10)),
                              padding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                            ))
                        .toList(),
                  ),
                  if (showActions) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => hostelCtrl.updateHostelStatus(
                                hostel.id, AppConstants.statusRejected),
                            icon: const Icon(Icons.close, size: 16),
                            label: const Text('Reject'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.error,
                              side: const BorderSide(color: AppColors.error),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _showApproveDialog(context, hostel),
                            icon: const Icon(Icons.check, size: 16),
                            label: const Text('Approve'),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.success),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (showUnregistrationActions) ...[
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Reason: ${hostel.unregistrationReason ?? "Closing hostel"}',
                            style: TextStyle(fontSize: 12, color: Colors.red.shade900, fontStyle: FontStyle.italic),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => hostelCtrl.rejectUnregistration(
                                hostel.id, hostel.ownerId, hostel.name),
                            icon: const Icon(Icons.close, size: 16),
                            label: const Text('Reject Request'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.textPrimary,
                              side: const BorderSide(color: AppColors.divider),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Get.defaultDialog(
                                title: 'Unregister & Delete',
                                middleText: 'Permanently delete "${hostel.name}"?',
                                textConfirm: 'Delete',
                                textCancel: 'Cancel',
                                confirmTextColor: Colors.white,
                                buttonColor: AppColors.error,
                                onConfirm: () {
                                  Get.back();
                                  hostelCtrl.acceptUnregistrationAndDelete(
                                      hostel.id, hostel.ownerId, hostel.name);
                                },
                              );
                            },
                            icon: const Icon(Icons.delete_forever, size: 16),
                            label: const Text('Unregister & Delete'),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.error),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showApproveDialog(BuildContext context, HostelModel hostel) {
    final suggested = (hostel.registrationNumber != null && hostel.registrationNumber!.isNotEmpty)
        ? hostel.registrationNumber!
        : hostelCtrl.generateNextRegistrationNumber();
    final ctrl = TextEditingController(text: suggested);

    Get.defaultDialog(
      title: 'Approve Hostel',
      titleStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      content: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Assign registration number for "${hostel.name}":',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              decoration: InputDecoration(
                labelText: 'Registration Number *',
                hintText: 'e.g. DS-Hostel-1',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                prefixIcon: const Icon(Icons.verified_outlined),
              ),
              autofocus: true,
            ),
          ],
        ),
      ),
      textConfirm: 'Approve',
      textCancel: 'Cancel',
      confirmTextColor: Colors.white,
      buttonColor: AppColors.success,
      onConfirm: () async {
        final regNo = ctrl.text.trim();
        if (regNo.isEmpty) {
          Get.snackbar('Required', 'Please enter registration number');
          return;
        }
        Get.back();
        await hostelCtrl.updateHostelStatus(
          hostel.id,
          AppConstants.statusApproved,
          registrationNumber: regNo,
        );
      },
    );
  }
}
