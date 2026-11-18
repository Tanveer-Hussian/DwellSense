// lib/views/owner/add_hostel_screen.dart
// ─────────────────────────────────────────────────────────────────────────────
// FR-3.1, FR-3.2, FR-3.3: Owner creates or edits a hostel listing.
// Supports image upload, map location picker, facilities checkboxes,
// and per-room capacity configuration.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:fyp/controllers/HostelController.dart';
import 'package:fyp/models/HostelModel.dart';
import 'package:fyp/models/RoomModel.dart';
import 'package:fyp/utils/AppColors.dart';
import 'package:fyp/utils/AppConstants.dart';
import 'package:fyp/utils/Responsive.dart';
import 'package:fyp/views/shared%20Widgets/AppBanner.dart';
import 'package:fyp/views/shared%20Widgets/CustomButtons.dart';
import 'package:fyp/views/shared%20Widgets/CustomTextField.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;



class AddHostelScreen extends StatefulWidget {
  const AddHostelScreen({super.key});

  @override
  State<AddHostelScreen> createState() => _AddHostelScreenState();
}


class _AddHostelScreenState extends State<AddHostelScreen> {
  // If arguments provided, we're in edit mode
  final HostelModel? _editHostel = Get.arguments as HostelModel?;
  bool get _isEditing => _editHostel != null;

  final _formKey = GlobalKey<FormState>();
  final HostelController _hostelCtrl = Get.find<HostelController>();
  final ImagePicker _picker = ImagePicker();

  // ── Form controllers ───────────────────────────────────────────────────────
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _rentCtrl;
  late final TextEditingController _roomsCtrl;
  late final TextEditingController _latCtrl;
  late final TextEditingController _lngCtrl;
  late final TextEditingController _mapsUrlCtrl;
  final MapController _mapController = MapController();

  // ── Form state ─────────────────────────────────────────────────────────────
  String _selectedCity = AppConstants.supportedCities[0];
  // Room type kept as a default value for Firestore backward compatibility;
  // individual room capacities are now set per-room in the Room Capacities section.
  static const String _defaultRoomType = 'Double';
  String _selectedGender = AppConstants.genderOptions[0];
  List<String> _selectedFacilities = [];
  List<XFile> _selectedImages = [];      // new images to upload
  List<String> _existingImages = [];    // already uploaded URLs (edit mode)
  double _lat = 25.3792;                // default: Hyderabad, Pakistan
  double _lng = 68.3682;

  // ── Per-room capacity controllers ─────────────────────────────────────────
  // Each controller holds the capacity (max students) for one room.
  List<TextEditingController> _roomCapacityControllers = [];

  @override
  void initState() {
    super.initState();

    // Pre-fill form if editing
    _nameCtrl = TextEditingController(text: _editHostel?.name ?? '');
    _descCtrl = TextEditingController(text: _editHostel?.description ?? '');
    _addressCtrl = TextEditingController(text: _editHostel?.address ?? '');
    _rentCtrl = TextEditingController(
        text: _editHostel?.rentPerMonth.toStringAsFixed(0) ?? '');
    _roomsCtrl = TextEditingController(
        text: _editHostel?.totalRooms.toString() ?? '1');

    if (_isEditing) {
      _selectedCity = _editHostel!.city;
      _selectedGender = _editHostel!.genderPreference;
      _selectedFacilities = List.from(_editHostel!.facilities);
      _existingImages = List.from(_editHostel!.images);
      _lat = _editHostel!.latitude;
      _lng = _editHostel!.longitude;

      // Pre-fill per-room capacities from existing rooms
      _roomCapacityControllers = _editHostel!.rooms
          .map((r) => TextEditingController(text: r.capacity.toString()))
          .toList();
    } else {
      // Default: 1 room with capacity based on the selected room type
      _roomCapacityControllers = [
        TextEditingController(
            text: RoomModel.defaultCapacityForType(_defaultRoomType).toString()),
      ];
    }

    _latCtrl = TextEditingController(text: _lat.toStringAsFixed(6));
    _lngCtrl = TextEditingController(text: _lng.toStringAsFixed(6));
    _mapsUrlCtrl = TextEditingController();
  }

  // ── Sync room capacity controllers when total rooms changes ────────────────
  // Adds or removes controllers to match the desired count, preserving existing
  // values for rooms that already have a controller.
  void _syncRoomCapacityControllers(int newCount) {
    if (newCount < 1) newCount = 1;
    if (newCount > 100) newCount = 100; // Reasonable upper limit

    if (newCount > _roomCapacityControllers.length) {
      // Add new controllers with default capacity
      final defaultCap = RoomModel.defaultCapacityForType(_defaultRoomType);
      for (int i = _roomCapacityControllers.length; i < newCount; i++) {
        _roomCapacityControllers.add(
          TextEditingController(text: defaultCap.toString()),
        );
      }
    } else if (newCount < _roomCapacityControllers.length) {
      // Remove excess controllers (dispose them first)
      for (int i = _roomCapacityControllers.length - 1; i >= newCount; i--) {
        _roomCapacityControllers[i].dispose();
        _roomCapacityControllers.removeAt(i);
      }
    }
    setState(() {});
  }

  // ── Called when Total Rooms text field value changes ────────────────────────
  void _onTotalRoomsChanged(String value) {
    final count = int.tryParse(value);
    if (count != null && count > 0) {
      _syncRoomCapacityControllers(count);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _addressCtrl.dispose();
    _rentCtrl.dispose();
    _roomsCtrl.dispose();
    _latCtrl.dispose();
    _lngCtrl.dispose();
    _mapsUrlCtrl.dispose();
    for (final ctrl in _roomCapacityControllers) {
      ctrl.dispose();
    }
    super.dispose();
  }

  // ── Pick images from gallery ───────────────────────────────────────────────
  Future<void> _pickImages() async {
    final List<XFile> files = await _picker.pickMultiImage(
      imageQuality: 70, // compress to reduce upload size
    );
    if (files.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(files);
      });
    }
  }

  // ── Get device current location ────────────────────────────────────────────
  Future<void> _getCurrentLocation() async {
    try {
      // Check and request location permission
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever) {
        Get.snackbar('Permission Denied', 'Please enable location in settings.');
        return;
      }

      final pos = await Geolocator.getCurrentPosition();
      setState(() {
        _lat = pos.latitude;
        _lng = pos.longitude;
        _latCtrl.text = _lat.toStringAsFixed(6);
        _lngCtrl.text = _lng.toStringAsFixed(6);
      });
      _mapController.move(LatLng(_lat, _lng), 15);
      Get.snackbar('Location Set', 'Hostel location updated to current GPS position.');
    } catch (e) {
      Get.snackbar('Error', 'Could not get location: $e');
    }
  }

  // -- Parse Google Maps link / coordinates input -----------------------------
  // Handles: plain coords, long URLs, short goo.gl / maps.app.goo.gl links
  Future<void> _parseMapsInput(String input) async {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return;

    // -- Step 1: normalise input ---------------------------------------------
    String url = trimmed;

    // If the user pasted only the path (e.g. /GXbMRBZhig9AERrD8), prepend domain
    if ((url.startsWith('/') || (!url.startsWith('http') && !url.contains(' '))) &&
        !url.contains(',')) {
      if (!url.startsWith('https')) {
        url = 'https://maps.app.goo.gl/${url.replaceFirst(RegExp(r'^/'), '')}';
      }
    }

    // -- Step 2: try to extract coords directly from the typed text ----------
    final coords = _tryExtractCoords(url);
    if (coords != null) {
      _applyCoords(coords[0], coords[1]);
      return;
    }

    // -- Step 3: fetch the URL and search the response body + final URL ------
    if (url.startsWith('http://') || url.startsWith('https://')) {
      try {
        Get.snackbar('Parsing Link', 'Resolving Google Maps link�',
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(seconds: 3));

        final response = await http.get(Uri.parse(url), headers: {
          // Use a real browser UA so Google returns proper HTML with embedded coords
          'User-Agent':
              'Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36 '
              '(KHTML, like Gecko) Chrome/120.0.6099.210 Mobile Safari/537.36',
        });

        // a) Check the final URL after redirects (often has @lat,lng in it)
        final finalUrl = response.request?.url.toString() ?? '';
        final fromUrl = _tryExtractCoords(finalUrl);
        if (fromUrl != null) {
          _applyCoords(fromUrl[0], fromUrl[1]);
          return;
        }

        // b) Search the HTML body � Google embeds coords in JS / meta content
        final fromBody = _tryExtractCoords(response.body);
        if (fromBody != null) {
          _applyCoords(fromBody[0], fromBody[1]);
          return;
        }
      } catch (e) {
        debugPrint('Maps parse error: $e');
      }
    }

    Get.snackbar(
      'Invalid Link',
      'Could not extract coordinates.\n'
      'Try: paste a long Google Maps URL, or type coordinates directly (e.g. 25.3792, 68.3682).',
      duration: const Duration(seconds: 4),
    );
  }

  /// Tries multiple regex patterns to find lat/lng in [text].
  /// Returns [lat, lng] or null.
  List<double>? _tryExtractCoords(String text) {
    final patterns = [
      RegExp(r'[/@!](-?\d+\.\d{4,}),(-?\d+\.\d{4,})'),      // @lat,lng  /lat,lng
      RegExp(r'[?&]ll=(-?\d+\.\d+),(-?\d+\.\d+)'),           // ll=lat,lng
      RegExp(r'[?&]q=(-?\d+\.\d+),(-?\d+\.\d+)'),            // q=lat,lng
      RegExp(r'[?&]center=(-?\d+\.\d+),(-?\d+\.\d+)'),       // center=lat,lng
      RegExp(r'\bq=(-?\d+\.\d+)%2C(-?\d+\.\d+)'),            // URL-encoded q=lat%2Clng
      RegExp(r'"(-?\d+\.\d{5,})",(-?\d+\.\d{5,})'),          // JSON coord pairs
      RegExp(r'(-?\d+\.\d{5,}),\s*(-?\d+\.\d{5,})'),         // bare high-precision coords
    ];
    for (final re in patterns) {
      final m = re.firstMatch(text);
      if (m != null) {
        final lat = double.tryParse(m.group(1)!);
        final lng = double.tryParse(m.group(2)!);
        if (lat != null && lng != null &&
            lat >= -90 && lat <= 90 &&
            lng >= -180 && lng <= 180) {
          return [lat, lng];
        }
      }
    }
    return null;
  }

  void _applyCoords(double lat, double lng) {
    setState(() {
      _lat = lat;
      _lng = lng;
      _latCtrl.text = lat.toStringAsFixed(6);
      _lngCtrl.text = lng.toStringAsFixed(6);
    });
    _mapController.move(LatLng(lat, lng), 15);
    Get.snackbar('Location Updated', 'Coordinates set to ($lat, $lng)');
  }

  // ── Build RoomModel list from per-room capacity controllers ─────────────
  List<RoomModel> _buildRoomsFromControllers() {
    final List<RoomModel> rooms = [];
    for (int i = 0; i < _roomCapacityControllers.length; i++) {
      final cap = int.tryParse(_roomCapacityControllers[i].text) ?? 2;
      rooms.add(RoomModel(
        id: 'room_${i + 1}',
        roomNumber: 'Room ${i + 1}',
        type: _defaultRoomType,
        capacity: cap,
        vacancies: (_isEditing && i < (_editHostel?.rooms.length ?? 0))
            ? _editHostel!.rooms[i].vacancies.clamp(0, cap)
            : cap,
        assignedStudents: (_isEditing && i < (_editHostel?.rooms.length ?? 0))
            ? _editHostel!.rooms[i].assignedStudents
            : const [],
        assignedStudentNames: (_isEditing && i < (_editHostel?.rooms.length ?? 0))
            ? _editHostel!.rooms[i].assignedStudentNames
            : const [],
      ));
    }
    return rooms;
  }

  // ── Form submission ────────────────────────────────────────────────────────
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedImages.isEmpty && _existingImages.isEmpty) {
      Get.snackbar('Images Required', 'Please add at least one photo.');
      return;
    }

    final totalRooms = int.tryParse(_roomsCtrl.text) ?? 1;
    final rooms = _buildRoomsFromControllers();

    if (_isEditing) {
      // Edit mode: update fields (images handled separately)
      final updates = {
        'name': _nameCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'city': _selectedCity,
        'address': _addressCtrl.text.trim(),
        'latitude': _lat,
        'longitude': _lng,
        'rentPerMonth': double.tryParse(_rentCtrl.text) ?? 0,
        'roomType': _defaultRoomType,
        'genderPreference': _selectedGender,
        'facilities': _selectedFacilities,
        'totalRooms': totalRooms,
        'rooms': rooms.map((r) => r.toMap()).toList(),
        'status': AppConstants.statusPending,
      };
      final ok = await _hostelCtrl.updateHostel(
        _editHostel!.id, 
        updates,
        newImageFiles: _selectedImages,
        existingImageUrls: _existingImages,
        showSnackbar: false,
      );
      if (ok) {
        AppBanner.showSuccess(
          title: 'Hostel Updated',
          message: 'Hostel has been sent to admin for approval.',
          duration: const Duration(seconds: 3),
        );
        Get.back();
      }
    } else {
      // Add mode: create new listing
      final ok = await _hostelCtrl.addHostel(
        name: _nameCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        city: _selectedCity,
        address: _addressCtrl.text.trim(),
        latitude: _lat,
        longitude: _lng,
        rentPerMonth: double.tryParse(_rentCtrl.text) ?? 0,
        roomType: _defaultRoomType,
        genderPreference: _selectedGender,
        facilities: _selectedFacilities,
        imageFiles: _selectedImages,
        totalRooms: totalRooms,
        rooms: rooms,
        showSnackbar: false,
      );
      if (ok) {
        AppBanner.showSuccess(
          title: 'Hostel Registered',
          message: 'Hostel has been sent to admin for approval.',
          duration: const Duration(seconds: 3),
        );
        Get.back();
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totalPhotos = _existingImages.length + _selectedImages.length;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isEditing ? 'Edit Hostel' : 'Add New Hostel',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            if (_isEditing && (_editHostel?.name.isNotEmpty ?? false))
              Text(
                _editHostel!.name,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.85),
                  fontWeight: FontWeight.normal,
                ),
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        actions: [
          Obx(() => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: _hostelCtrl.isLoading.value ? null : _submit,
                  icon: _hostelCtrl.isLoading.value
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        )
                      : const Icon(Icons.check, size: 18),
                  label: Text(
                    _isEditing ? 'Save' : 'Publish',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              )),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              children: [
                // ── Edit Banner ──────────────────────────────────────────────
                if (_isEditing)
                  Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withOpacity(isDark ? 0.25 : 0.12),
                          AppColors.primaryLight.withOpacity(isDark ? 0.15 : 0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.35),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.edit_note_rounded,
                              color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Editing "${_editHostel?.name ?? 'Hostel'}"',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'Changes will be sent to admin for approval before updating your public listing.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Active Listing',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.primaryLight : AppColors.primaryDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // ── Card 1: Basic Information ────────────────────────────────
                _FormCard(
                  title: 'Basic Information',
                  subtitle: 'Hostel name, address, and marketing overview',
                  icon: Icons.business_outlined,
                  child: Column(
                    children: [
                      CustomTextField(
                        controller: _nameCtrl,
                        label: 'Hostel Name *',
                        prefixIcon: Icons.home_work_outlined,
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Name required' : null,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedCity,
                        decoration: const InputDecoration(
                          labelText: 'City *',
                          prefixIcon: Icon(Icons.location_city_outlined),
                        ),
                        items: AppConstants.supportedCities
                            .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                            .toList(),
                        onChanged: (v) => setState(() => _selectedCity = v!),
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _addressCtrl,
                        label: 'Full Address *',
                        prefixIcon: Icons.pin_drop_outlined,
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Address required' : null,
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _descCtrl,
                        label: 'Description *',
                        prefixIcon: Icons.description_outlined,
                        maxLines: 4,
                        validator: (v) =>
                            v == null || v.length < 20 ? 'Min 20 characters' : null,
                      ),
                    ],
                  ),
                ),

                // ── Card 2: Room & Pricing Details ───────────────────────────
                _FormCard(
                  title: 'Room Details & Pricing',
                  subtitle: 'Rent amount, room counts, and student preferences',
                  icon: Icons.payments_outlined,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: CustomTextField(
                              controller: _rentCtrl,
                              label: 'Monthly Rent (PKR) *',
                              prefixIcon: Icons.payments_outlined,
                              keyboardType: TextInputType.number,
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Required';
                                if (double.tryParse(v) == null) {
                                  return 'Invalid amount';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: CustomTextField(
                              controller: _roomsCtrl,
                              label: 'Total Rooms *',
                              prefixIcon: Icons.meeting_room_outlined,
                              keyboardType: TextInputType.number,
                              onChanged: _onTotalRoomsChanged,
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Required';
                                final n = int.tryParse(v);
                                if (n == null || n < 1) return 'Min 1';
                                if (n > 100) return 'Max 100';
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedGender,
                        decoration: const InputDecoration(
                          labelText: 'Gender Preference *',
                          prefixIcon: Icon(Icons.people_outline),
                        ),
                        items: AppConstants.genderOptions
                            .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                            .toList(),
                        onChanged: (v) => setState(() => _selectedGender = v!),
                      ),
                    ],
                  ),
                ),

                // ── Card 3: Per-Room Capacities ──────────────────────────────
                if (_roomCapacityControllers.isNotEmpty)
                  _FormCard(
                    title: 'Room Capacities',
                    subtitle: 'Define maximum student occupancy for each room',
                    icon: Icons.bed_outlined,
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_roomCapacityControllers.length} Rooms',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth > 520;
                        return Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children:
                              _roomCapacityControllers.asMap().entries.map((entry) {
                            final index = entry.key;
                            final ctrl = entry.value;
                            return SizedBox(
                              width: isWide
                                  ? (constraints.maxWidth - 12) / 2
                                  : constraints.maxWidth,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF242424)
                                      : const Color(0xFFF8F9FA),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isDark
                                        ? const Color(0xFF333333)
                                        : const Color(0xFFE2E8F0),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        '${index + 1}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'Room ${index + 1}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: 'Decrease',
                                      icon: const Icon(
                                          Icons.remove_circle_outline,
                                          size: 20),
                                      visualDensity: VisualDensity.compact,
                                      onPressed: () {
                                        final curr =
                                            int.tryParse(ctrl.text) ?? 1;
                                        if (curr > 1) {
                                          ctrl.text = (curr - 1).toString();
                                          setState(() {});
                                        }
                                      },
                                    ),
                                    SizedBox(
                                      width: 44,
                                      child: TextFormField(
                                        controller: ctrl,
                                        textAlign: TextAlign.center,
                                        keyboardType: TextInputType.number,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                        decoration: const InputDecoration(
                                          isDense: true,
                                          contentPadding:
                                              EdgeInsets.symmetric(vertical: 4),
                                          border: InputBorder.none,
                                        ),
                                        validator: (v) {
                                          if (v == null || v.isEmpty) return 'Req';
                                          final n = int.tryParse(v);
                                          if (n == null || n < 1) return 'Min 1';
                                          if (n > 20) return 'Max 20';
                                          return null;
                                        },
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: 'Increase',
                                      icon: const Icon(
                                          Icons.add_circle_outline,
                                          size: 20),
                                      visualDensity: VisualDensity.compact,
                                      onPressed: () {
                                        final curr =
                                            int.tryParse(ctrl.text) ?? 1;
                                        if (curr < 20) {
                                          ctrl.text = (curr + 1).toString();
                                          setState(() {});
                                        }
                                      },
                                    ),
                                    const Text(
                                      'beds',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ),

                // ── Card 4: Facilities ───────────────────────────────────────
                _FormCard(
                  title: 'Facilities & Amenities',
                  subtitle: 'Select available amenities offered to residents',
                  icon: Icons.checklist_rounded,
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_selectedFacilities.length} Selected',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: AppConstants.facilities.map((f) {
                      final selected = _selectedFacilities.contains(f);
                      return FilterChip(
                        label: Text(f),
                        selected: selected,
                        selectedColor: AppColors.primary.withOpacity(0.2),
                        checkmarkColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(
                            color: selected
                                ? AppColors.primary
                                : (isDark
                                    ? const Color(0xFF333333)
                                    : const Color(0xFFE2E8F0)),
                          ),
                        ),
                        onSelected: (_) => setState(() {
                          if (selected) {
                            _selectedFacilities.remove(f);
                          } else {
                            _selectedFacilities.add(f);
                          }
                        }),
                      );
                    }).toList(),
                  ),
                ),

                // ── Card 5: Photos ───────────────────────────────────────────
                _FormCard(
                  title: 'Hostel Photos',
                  subtitle: 'Add crisp pictures of bedrooms, mess, and building',
                  icon: Icons.photo_library_outlined,
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$totalPhotos Photos',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_existingImages.isNotEmpty || _selectedImages.isNotEmpty) ...[
                        SizedBox(
                          height: 105,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: [
                              ..._existingImages.map((url) => _ImageThumb.network(
                                    url: url,
                                    onRemove: () => setState(
                                        () => _existingImages.remove(url)),
                                  )),
                              ..._selectedImages.map((file) => _ImageThumb.xfile(
                                    file: file,
                                    onRemove: () => setState(
                                        () => _selectedImages.remove(file)),
                                  )),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      InkWell(
                        onTap: _pickImages,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 22),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF222222)
                                : const Color(0xFFF8F9FA),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark
                                  ? const Color(0xFF3A3A3A)
                                  : const Color(0xFFCBD5E1),
                              style: BorderStyle.solid,
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.add_photo_alternate_rounded,
                                size: 36,
                                color: AppColors.primary,
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Click to Upload More Photos',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Supports PNG, JPG, JPEG',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Card 6: Google Maps Location ─────────────────────────────
                _FormCard(
                  title: 'Location & Map Pin',
                  subtitle:
                      'Tap map or drag pin to pinpoint exact hostel entrance',
                  icon: Icons.map_outlined,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: isDark
                                  ? const Color(0xFF333333)
                                  : const Color(0xFFE2E8F0),
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          height: 240,
                          child: FlutterMap(
                            mapController: _mapController,
                            options: MapOptions(
                              initialCenter: LatLng(_lat, _lng),
                              initialZoom: 15,
                              onTap: (tapPosition, point) {
                                setState(() {
                                  _lat = point.latitude;
                                  _lng = point.longitude;
                                  _latCtrl.text = _lat.toStringAsFixed(6);
                                  _lngCtrl.text = _lng.toStringAsFixed(6);
                                });
                              },
                            ),
                            children: [
                              TileLayer(
                                urlTemplate:
                                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName: 'com.example.fyp',
                              ),
                              MarkerLayer(
                                markers: [
                                  Marker(
                                    point: LatLng(_lat, _lng),
                                    width: 44,
                                    height: 44,
                                    child: const Icon(
                                      Icons.location_pin,
                                      color: Colors.redAccent,
                                      size: 44,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _getCurrentLocation,
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              icon: const Icon(Icons.my_location,
                                  size: 18, color: AppColors.primary),
                              label: const Text('Use Current GPS Location'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: CustomTextField(
                              controller: _latCtrl,
                              label: 'Latitude *',
                              prefixIcon: Icons.location_on_outlined,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true, signed: true),
                              onChanged: (val) {
                                final parsed = double.tryParse(val);
                                if (parsed != null) {
                                  setState(() => _lat = parsed);
                                  _mapController.move(LatLng(_lat, _lng),
                                      _mapController.camera.zoom);
                                }
                              },
                              validator: (v) {
                                if (v == null || v.isEmpty) {
                                  return 'Latitude required';
                                }
                                if (double.tryParse(v) == null) {
                                  return 'Invalid lat';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: CustomTextField(
                              controller: _lngCtrl,
                              label: 'Longitude *',
                              prefixIcon: Icons.explore_outlined,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true, signed: true),
                              onChanged: (val) {
                                final parsed = double.tryParse(val);
                                if (parsed != null) {
                                  setState(() => _lng = parsed);
                                  _mapController.move(LatLng(_lat, _lng),
                                      _mapController.camera.zoom);
                                }
                              },
                              validator: (v) {
                                if (v == null || v.isEmpty) {
                                  return 'Longitude required';
                                }
                                if (double.tryParse(v) == null) {
                                  return 'Invalid lng';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: CustomTextField(
                              controller: _mapsUrlCtrl,
                              label: 'Paste Google Maps Link / Coordinates',
                              prefixIcon: Icons.link_rounded,
                            ),
                          ),
                          const SizedBox(width: 10),
                          FilledButton(
                            onPressed: () => _parseMapsInput(_mapsUrlCtrl.text),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 18, vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text('Parse'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ── Upload Progress ──────────────────────────────────────────
                Obx(() {
                  if (!_hostelCtrl.isUploading.value) {
                    return const SizedBox.shrink();
                  }
                  return Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E1E1E)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF2C2C2C)
                            : const Color(0xFFE9ECEF),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Uploading images: ${_hostelCtrl.uploadProgress.value}%',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: _hostelCtrl.uploadProgress.value / 100,
                          backgroundColor: AppColors.divider,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  );
                }),

                // ── Actions Footer ───────────────────────────────────────────
                if (!Responsive.isWide(context)) ...[
                  SizedBox(
                    width: double.infinity,
                    child: Obx(() => CustomButton(
                          text: _isEditing
                              ? 'Save Changes'
                              : 'Submit for Approval',
                          isLoading: _hostelCtrl.isLoading.value,
                          icon: _isEditing
                              ? Icons.save_outlined
                              : Icons.send_outlined,
                          onPressed: _submit,
                        )),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Cancel',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                ] else
                  Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: OutlinedButton(
                          onPressed: () => Get.back(),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Cancel',
                              style: TextStyle(fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: Obx(() => CustomButton(
                              text: _isEditing
                                  ? 'Save Changes'
                                  : 'Submit for Approval',
                              isLoading: _hostelCtrl.isLoading.value,
                              icon: _isEditing
                                  ? Icons.save_outlined
                                  : Icons.send_outlined,
                              onPressed: _submit,
                            )),
                      ),
                    ],
                  ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Card container with header & divider ─────────────────────────────────────
class _FormCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Widget child;
  final Widget? trailing;

  const _FormCard({
    required this.title,
    this.subtitle,
    required this.icon,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final borderColor =
        isDark ? const Color(0xFF2C2C2C) : const Color(0xFFE9ECEF);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
          ),
          Divider(height: 1, color: borderColor),
          Padding(
            padding: const EdgeInsets.all(18),
            child: child,
          ),
        ],
      ),
    );
  }
}

// ── Image thumbnail with remove button ────────────────────────────────────
class _ImageThumb extends StatelessWidget {
  final Widget _image;
  final VoidCallback onRemove;

  const _ImageThumb._({required Widget image, required this.onRemove})
      : _image = image;

  factory _ImageThumb.network({required String url, required VoidCallback onRemove}) {
    return _ImageThumb._(
      image: Image.network(url, width: 90, height: 90, fit: BoxFit.cover),
      onRemove: onRemove,
    );
  }

  factory _ImageThumb.xfile({required XFile file, required VoidCallback onRemove}) {
    return _ImageThumb._(
      image: _XFileThumbnail(file: file),
      onRemove: onRemove,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          margin: const EdgeInsets.only(right: 8),
          width: 90,
          height: 90,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: _image,
          ),
        ),
        Positioned(
          top: 0,
          right: 4,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.error,
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(2),
              child: const Icon(Icons.close, size: 14, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}

class _XFileThumbnail extends StatelessWidget {
  final XFile file;
  const _XFileThumbnail({required this.file});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: file.readAsBytes(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Image.memory(
            snapshot.data!,
            width: 90,
            height: 90,
            fit: BoxFit.cover,
          );
        }
        return const SizedBox(
          width: 90,
          height: 90,
          child: Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        );
      },
    );
  }
}
