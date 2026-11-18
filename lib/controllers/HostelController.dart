// lib/controllers/HostelController.dart

import 'dart:async';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:fyp/controllers/AuthController.dart';
import 'package:fyp/models/HostelModel.dart';
import 'package:fyp/models/RoomModel.dart';
import 'package:fyp/services/CloudinaryService.dart';
import 'package:fyp/services/NotificationService.dart';
import 'package:fyp/services/RankingService.dart';
import 'package:fyp/services/DynamicHostelScoreModel.dart';
import 'package:fyp/services/hostelService.dart';
import 'package:fyp/utils/AppColors.dart';
import 'package:fyp/utils/AppConstants.dart';
import 'package:get/get.dart';

class HostelController extends GetxController {

  final HostelService _hostelService = Get.find<HostelService>();
  final CloudinaryService _cloudinaryService = Get.find<CloudinaryService>();
  final AuthController _authController = Get.find<AuthController>();

  // ── Observable lists ──────────────────────────────────────────────────────
  final RxList<HostelModel> approvedHostels = <HostelModel>[].obs;
  final RxList<HostelModel> ownerHostels    = <HostelModel>[].obs;
  final RxList<HostelModel> pendingHostels  = <HostelModel>[].obs;
  final RxList<HostelModel> allHostels      = <HostelModel>[].obs;
  final RxList<HostelModel> searchResults   = <HostelModel>[].obs;
  final RxString            searchQuery     = ''.obs;

  // ── Form / UI state ───────────────────────────────────────────────────────
  final RxBool   isLoading       = false.obs;
  final RxBool   isOwnerHostelsLoaded = false.obs;
  final RxBool   isUploading     = false.obs;
  final RxInt    uploadProgress  = 0.obs;
  final RxString errorMessage    = ''.obs;

  // ── Search & Filter state ─────────────────────────────────────────────────
  final RxString       selectedCity       = ''.obs;
  final RxString       selectedGender     = ''.obs;
  final RxDouble       minRent            = 0.0.obs;
  final RxDouble       maxRent            = 50000.0.obs;
  final RxList<String> selectedFacilities = <String>[].obs;

  // ── FR-9: Sort / Ranking mode ─────────────────────────────────────────
  // 'smart' = composite score | 'rating' | 'priceLow' | 'priceHigh' | 'newest'
  final RxString sortMode = 'smart'.obs;

  // ── Owner Aggregate Statistics Getters ────────────────────────────────────
  int get totalOwnerStudents => ownerHostels.fold(
        0,
        (acc, hostel) => acc + hostel.totalOccupiedBeds,
      );

  int get totalOwnerVacantBeds => ownerHostels.fold(
        0,
        (acc, hostel) => acc + hostel.totalVacancies,
      );

  int get totalOwnerCapacity => ownerHostels.fold(
        0,
        (acc, hostel) => acc + hostel.totalCapacity,
      );

  // ── Stream subscriptions (stored so we can cancel before re-subscribing) ──
  StreamSubscription<List<HostelModel>>? _approvedSub;
  StreamSubscription<List<HostelModel>>? _ownerSub;
  StreamSubscription<List<HostelModel>>? _pendingSub;
  StreamSubscription<List<HostelModel>>? _allHostelsSub;

  // ─────────────────────────────────────────────────────────────────────────
  @override
  void onInit() {
    super.onInit();
    DynamicHostelScoreModel().initLocalModel();
    loadApprovedHostels();

    // Reactively re-subscribe whenever auth state / currentUser changes (e.g. on login/logout)
    ever(_authController.currentUser, (user) {
      if (user == null) {
        ownerHostels.clear();
        pendingHostels.clear();
        allHostels.clear();
        return;
      }
      if (user.role == AppConstants.roleOwner) {
        loadOwnerHostels();
      } else if (user.role == AppConstants.roleAdmin) {
        loadAllHostels();
        loadPendingHostels();
      }
    });

    if (_authController.isOwner) loadOwnerHostels();
    if (_authController.isAdmin) {
      loadAllHostels();
      loadPendingHostels();
    }
  }

  void ensureAdminStreamsLoaded() {
    loadAllHostels();
    loadPendingHostels();
  }

  // ── Always cancel the old subscription before opening a new one ───────────
  // This prevents duplicate listeners from stacking up when these methods
  // are called more than once (e.g. after applyFilters / clearFilters).

  void loadApprovedHostels() {
    _approvedSub?.cancel();
    _approvedSub = _hostelService
        .getApprovedHostelsStream(
          city: selectedCity.value.isEmpty ? null : selectedCity.value,
          genderPreference:
              selectedGender.value.isEmpty ? null : selectedGender.value,
          minRent: minRent.value > 0      ? minRent.value : null,
          maxRent: maxRent.value < 50000  ? maxRent.value : null,
        )
        .listen(
          (hostels) {
            approvedHostels.value = _applySortMode(hostels);
            if (sortMode.value == 'smart') {
              _fetchCloudSmartScores(List.from(hostels));
            }
          },
          onError: (e) {
            errorMessage.value = 'Failed to load approved hostels: $e';
          },
        );
  }

  // ── FR-9: Apply sort mode to hostel list ───────────────────────────────
  List<HostelModel> _applySortMode(List<HostelModel> hostels) {
    switch (sortMode.value) {
      case 'smart':
        final String? university =
            _authController.currentUser.value?.university;
        return RankingService.scoreAndSort(hostels, universityName: university);
      case 'rating':
        return hostels..sort((a, b) => b.averageRating.compareTo(a.averageRating));
      case 'priceLow':
        return hostels..sort((a, b) => a.rentPerMonth.compareTo(b.rentPerMonth));
      case 'priceHigh':
        return hostels..sort((a, b) => b.rentPerMonth.compareTo(a.rentPerMonth));
      case 'newest':
      default:
        return hostels..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
  }

  // ── FR-9: Change sort mode and re-sort current list ──────────────────
  void applySortMode(String mode) {
    sortMode.value = mode;
    approvedHostels.value = _applySortMode(List.from(approvedHostels));
    if (mode == 'smart') {
      _fetchCloudSmartScores(List.from(approvedHostels));
    }
  }

  void _fetchCloudSmartScores(List<HostelModel> hostels) async {
    if (hostels.isEmpty || sortMode.value != 'smart') return;
    try {
      final String? university = _authController.currentUser.value?.university;
      final cloudSorted = await RankingService.scoreAndSortAsync(hostels, universityName: university);
      if (sortMode.value == 'smart') {
        approvedHostels.value = cloudSorted;
      }
    } catch (_) {
      // Local fallback is already displayed
    }
  }

  void loadOwnerHostels() {
    _ownerSub?.cancel();
    isOwnerHostelsLoaded.value = false;
    final ownerId = _authController.currentUser.value?.uid;
    if (ownerId == null || ownerId.isEmpty) {
      ownerHostels.clear();
      isOwnerHostelsLoaded.value = true;
      return;
    }
    _ownerSub = _hostelService
        .getOwnerHostelsStream(ownerId)
        .listen(
          (hostels) {
            ownerHostels.value = hostels;
            isOwnerHostelsLoaded.value = true;
          },
          onError: (e) {
            errorMessage.value = 'Failed to load owner hostels: $e';
            isOwnerHostelsLoaded.value = true;
          },
        );
  }

  void loadPendingHostels() {
    _pendingSub?.cancel();
    _pendingSub = _hostelService
        .getPendingHostelsStream()
        .listen(
          (hostels) => pendingHostels.value = hostels,
          onError: (e) {
            errorMessage.value = 'Failed to load pending hostels: $e';
          },
        );
  }

  void loadAllHostels() {
    _allHostelsSub?.cancel();
    _allHostelsSub = _hostelService
        .getAllHostelsStream()
        .listen(
          (hostels) => allHostels.value = hostels,
          onError: (e) {
            errorMessage.value = 'Failed to load all hostels: $e';
          },
        );
  }

  // ── Filters ───────────────────────────────────────────────────────────────
  void applyFilters({
    String? city,
    String? gender,
    double? min,
    double? max,
    List<String>? facilities,
  }) {
    if (city        != null) selectedCity.value       = city;
    if (gender      != null) selectedGender.value     = gender;
    if (min         != null) minRent.value             = min;
    if (max         != null) maxRent.value             = max;
    if (facilities  != null) selectedFacilities.value = facilities;
    // Cancels old approved stream and opens a fresh one with new filters
    loadApprovedHostels();
  }

  void clearFilters() {
    selectedCity.value      = '';
    selectedGender.value    = '';
    minRent.value           = 0.0;
    maxRent.value           = 50000.0;
    selectedFacilities.clear();
    loadApprovedHostels();
  }

  void searchHostels(String query) {
    searchQuery.value = query;
    if (query.trim().isEmpty) {
      searchResults.clear();
      return;
    }
    final lowercaseQuery = query.trim().toLowerCase();
    searchResults.value = approvedHostels.where((h) {
      return h.name.toLowerCase().contains(lowercaseQuery) ||
          h.city.toLowerCase().contains(lowercaseQuery) ||
          h.address.toLowerCase().contains(lowercaseQuery) ||
          h.description.toLowerCase().contains(lowercaseQuery);
    }).toList();
  }

  // ── onClose: cancel all streams when the controller is destroyed ──────────
  @override
  void onClose() {
    _approvedSub?.cancel();
    _ownerSub?.cancel();
    _pendingSub?.cancel();
    _allHostelsSub?.cancel();
    super.onClose();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // FR-3.1 & FR-3.2: Add hostel with Cloudinary image upload
  // ─────────────────────────────────────────────────────────────────────────
  Future<bool> addHostel({
    required String       name,
    required String       description,
    required String       city,
    required String       address,
    required double       latitude,
    required double       longitude,
    required double       rentPerMonth,
    required String       roomType,
    required String       genderPreference,
    required List<String> facilities,
    required List<XFile>  imageFiles,
    required int          totalRooms,
    List<RoomModel>?      rooms,
    bool                  showSnackbar = false,
  }) async {
    try {
      isLoading.value     = true;
      errorMessage.value  = '';

      final owner = _authController.currentUser.value!;

      // Use custom rooms if provided, otherwise generate defaults
      final hostelRooms = rooms ?? HostelModel.generateDefaultRooms(
        totalRooms: totalRooms,
        roomType: roomType,
        availableRooms: totalRooms,
      );

      final tempHostel = HostelModel(
        id:               '',
        ownerId:          owner.uid,
        ownerName:        owner.name,
        name:             name,
        description:      description,
        city:             city,
        address:          address,
        latitude:         latitude,
        longitude:        longitude,
        rentPerMonth:     rentPerMonth,
        roomType:         roomType,
        genderPreference: genderPreference,
        facilities:       facilities,
        images:           [],
        totalRooms:       totalRooms,
        availableRooms:   totalRooms,
        rooms:            hostelRooms,
        createdAt:        DateTime.now(),
        updatedAt:        DateTime.now(),
      );

      final hostelId = await _hostelService.addHostel(tempHostel);

      // Step 2: Upload images to Cloudinary
      List<String> imageUrls = [];
      if (imageFiles.isNotEmpty) {
        isUploading.value = true;

        imageUrls = await _cloudinaryService.uploadMultipleImages(
          hostelId,
          imageFiles,
          onProgress: (uploaded, total) {
            uploadProgress.value = ((uploaded / total) * 100).round();
          },
        );

        isUploading.value = false;
      }

      // Step 3: Update Firestore with Cloudinary image URLs
      if (imageUrls.isNotEmpty) {
        await _hostelService.updateHostel(hostelId, {'images': imageUrls});
      }

      if (showSnackbar) {
        Get.snackbar(
          'Listing Submitted',
          'Your hostel is pending admin approval.',
          snackPosition: SnackPosition.BOTTOM,
        );
      }

      return true;

    } catch (e) {
      errorMessage.value = 'Failed to add hostel: $e';
      return false;
    } finally {
      isLoading.value   = false;
      isUploading.value = false;
    }
  }

  Future<bool> updateHostel(
    String hostelId, 
    Map<String, dynamic> updates, {
    List<XFile>? newImageFiles,
    List<String>? existingImageUrls,
    bool showSnackbar = true,
  }) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      List<String> finalImageUrls = existingImageUrls != null ? List.from(existingImageUrls) : [];

      if (newImageFiles != null && newImageFiles.isNotEmpty) {
        isUploading.value = true;
        final uploadedUrls = await _cloudinaryService.uploadMultipleImages(
          hostelId,
          newImageFiles,
          onProgress: (uploaded, total) {
            uploadProgress.value = ((uploaded / total) * 100).round();
          },
        );
        finalImageUrls.addAll(uploadedUrls);
        isUploading.value = false;
      }
      
      // If we passed image tracking lists, add the combined result to updates
      if (existingImageUrls != null || (newImageFiles != null && newImageFiles.isNotEmpty)) {
        updates['images'] = finalImageUrls;
      }

      await _hostelService.updateHostel(hostelId, updates);
      if (showSnackbar) {
        Get.snackbar('Updated', 'Hostel updated successfully.');
      }
      return true;
    } catch (e) {
      errorMessage.value = 'Update failed: $e';
      return false;
    } finally {
      isLoading.value = false;
      isUploading.value = false;
    }
  }

  Future<bool> deleteHostel(String hostelId) async {
    // Non-admin users (such as hostel owners) cannot directly delete hostels.
    // They must submit an un-registration request with a reason for admin approval.
    if (!_authController.isAdmin) {
      Get.snackbar(
        'Action Restricted',
        'Owners cannot delete hostels directly. Please submit an un-registration request for admin approval.',
        backgroundColor: AppColors.error,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }

    try {
      await _hostelService.deleteHostel(hostelId);
      Get.snackbar('Deleted', 'Hostel listing removed.');
      return true;
    } catch (e) {
      errorMessage.value = 'Delete failed: $e';
      return false;
    }
  }

  // Generate a recommended sequential registration number like "DS-Hostel-1", "DS-Hostel-2"
  String generateNextRegistrationNumber() {
    final approvedCount = allHostels
        .where((h) => h.status == AppConstants.statusApproved || (h.registrationNumber != null && h.registrationNumber!.isNotEmpty))
        .length;
    return 'DS-Hostel-${approvedCount + 1}';
  }

  Future<bool> updateHostelStatus(
    String hostelId,
    String status, {
    String? registrationNumber,
  }) async {
    try {
      await _hostelService.updateHostelStatus(
        hostelId,
        status,
        registrationNumber: registrationNumber,
      );
      final msg = status == AppConstants.statusApproved ? 'approved' : 'rejected';
      Get.snackbar('Done', 'Hostel listing $msg.');
      return true;
    } catch (e) {
      Get.snackbar('Error', 'Failed to update status: $e');
      return false;
    }
  }

  // Admin assigns or updates registration number for an approved hostel
  Future<bool> assignRegistrationNumber(
    String hostelId,
    String registrationNumber,
  ) async {
    try {
      await _hostelService.updateRegistrationNumber(hostelId, registrationNumber);
      Get.snackbar(
        'Registration Updated',
        'Assigned Registration #: $registrationNumber',
        backgroundColor: AppColors.success,
        colorText: Colors.white,
      );
      return true;
    } catch (e) {
      Get.snackbar('Error', 'Failed to update registration number: $e');
      return false;
    }
  }

  // ── Un-registration / Deletion Request Workflow ───────────────────────────
  List<HostelModel> get unregistrationRequests =>
      allHostels.where((h) => h.unregistrationRequested).toList();

  // Owner submits request to admin to unregister / delete hostel
  Future<bool> requestUnregistration(String hostelId, String reason) async {
    try {
      isLoading.value = true;
      await _hostelService.requestUnregistration(hostelId, reason);
      Get.snackbar(
        'Request Submitted',
        'Un-registration request sent to admin for review.',
        backgroundColor: AppColors.success,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return true;
    } catch (e) {
      Get.snackbar('Error', 'Failed to submit request: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Admin rejects unregistration request — hostel remains registered
  Future<bool> rejectUnregistration(
    String hostelId,
    String ownerId,
    String hostelName,
  ) async {
    try {
      await _hostelService.rejectUnregistration(hostelId);
      if (Get.isRegistered<NotificationService>()) {
        await Get.find<NotificationService>().sendNotification(
          userId: ownerId,
          title: 'Un-registration Request Rejected',
          body: 'Your request to un-register "$hostelName" was rejected by Admin. The hostel remains active.',
          type: 'unregistration_rejected',
          relatedId: hostelId,
        );
      }
      Get.snackbar(
        'Request Rejected',
        'Un-registration request rejected. "$hostelName" remains registered.',
      );
      return true;
    } catch (e) {
      Get.snackbar('Error', 'Failed to reject un-registration request: $e');
      return false;
    }
  }

  // Admin accepts unregistration request & deletes the hostel
  Future<bool> acceptUnregistrationAndDelete(
    String hostelId,
    String ownerId,
    String hostelName,
  ) async {
    try {
      if (Get.isRegistered<NotificationService>()) {
        await Get.find<NotificationService>().sendNotification(
          userId: ownerId,
          title: 'Hostel Unregistered & Deleted',
          body: 'Your request to un-register "$hostelName" has been accepted. The listing is now removed.',
          type: 'unregistration_accepted',
          relatedId: hostelId,
        );
      }
      await _hostelService.deleteHostel(hostelId);
      Get.snackbar(
        'Hostel Unregistered',
        '"$hostelName" has been unregistered and deleted.',
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
      return true;
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete hostel: $e');
      return false;
    }
  }

  // ── Manual Bed Allocation (Owner) ─────────────────────────────────────────
  // Owner manually marks a vacant bed as occupied with a student name at exact bedIndex.
  // Uses 'manual_' prefix on student ID to distinguish from app bookings.
  Future<bool> manuallyAllocateBed({
    required String hostelId,
    required RoomModel room,
    required int bedIndex,
    required String studentName,
  }) async {
    try {
      if (bedIndex < 0 || bedIndex >= room.capacity) return false;

      final updatedStudentIds = List<String>.generate(
        room.capacity,
        (i) => (i < room.assignedStudents.length) ? room.assignedStudents[i] : '',
      );
      final updatedStudentNames = List<String>.generate(
        room.capacity,
        (i) => (i < room.assignedStudentNames.length) ? room.assignedStudentNames[i] : '',
      );

      // Generate a unique manual ID for this specific bed slot
      final manualId = 'manual_${DateTime.now().millisecondsSinceEpoch}';
      updatedStudentIds[bedIndex] = manualId;
      updatedStudentNames[bedIndex] = studentName.trim();

      await _hostelService.updateRoomAllocation(
        hostelId,
        room.id,
        assignedStudents: updatedStudentIds,
        assignedStudentNames: updatedStudentNames,
      );
      return true;
    } catch (e) {
      Get.snackbar('Error', 'Failed to allocate bed: $e');
      return false;
    }
  }

  // Owner manually vacates a bed that was manually allocated (not app-booked).
  Future<bool> manuallyVacateBed({
    required String hostelId,
    required RoomModel room,
    required int bedIndex,
  }) async {
    try {
      if (bedIndex < 0 || bedIndex >= room.assignedStudents.length) return false;

      final studentId = room.assignedStudents[bedIndex];
      if (studentId.isEmpty) return true; // already vacant

      // Only allow vacating manually-allocated beds
      if (!studentId.startsWith('manual_')) {
        Get.snackbar(
          'Cannot Vacate',
          'This bed was booked through the app. It will be automatically vacated when the booking expires or is cancelled.',
          snackPosition: SnackPosition.BOTTOM,
        );
        return false;
      }

      final updatedStudentIds = List<String>.generate(
        room.capacity,
        (i) => (i < room.assignedStudents.length) ? room.assignedStudents[i] : '',
      );
      final updatedStudentNames = List<String>.generate(
        room.capacity,
        (i) => (i < room.assignedStudentNames.length) ? room.assignedStudentNames[i] : '',
      );

      // Reset specific bed slot to vacant
      updatedStudentIds[bedIndex] = '';
      updatedStudentNames[bedIndex] = '';

      await _hostelService.updateRoomAllocation(
        hostelId,
        room.id,
        assignedStudents: updatedStudentIds,
        assignedStudentNames: updatedStudentNames,
      );
      return true;
    } catch (e) {
      Get.snackbar('Error', 'Failed to vacate bed: $e');
      return false;
    }
  }

  // ── Admin Vacate Bed ──────────────────────────────────────────────────────
  // Admin can only vacate manually-allocated beds. App-booked beds are protected.
  Future<bool> adminVacateBed({
    required String hostelId,
    required RoomModel room,
    required int bedIndex,
  }) async {
    try {
      if (bedIndex < 0 || bedIndex >= room.assignedStudents.length) return false;

      final studentId = room.assignedStudents[bedIndex];
      if (studentId.isEmpty) return true; // already vacant

      if (!studentId.startsWith('manual_')) {
        Get.snackbar(
          'Protected Booking',
          'This bed is booked through the app. Cannot vacate until booking expires or student cancels.',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 4),
        );
        return false;
      }

      final updatedStudentIds = List<String>.generate(
        room.capacity,
        (i) => (i < room.assignedStudents.length) ? room.assignedStudents[i] : '',
      );
      final updatedStudentNames = List<String>.generate(
        room.capacity,
        (i) => (i < room.assignedStudentNames.length) ? room.assignedStudentNames[i] : '',
      );

      // Reset specific bed slot to vacant
      updatedStudentIds[bedIndex] = '';
      updatedStudentNames[bedIndex] = '';

      await _hostelService.updateRoomAllocation(
        hostelId,
        room.id,
        assignedStudents: updatedStudentIds,
        assignedStudentNames: updatedStudentNames,
      );
      return true;
    } catch (e) {
      Get.snackbar('Error', 'Failed to vacate bed: $e');
      return false;
    }
  }
}
