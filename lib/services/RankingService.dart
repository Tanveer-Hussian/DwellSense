// lib/services/RankingService.dart
// ─────────────────────────────────────────────────────────────────────────────
// FR-9: Smart Ranking System (Machine Learning Based)
//
// Uses a trained XGBRegressor model (deployed on Render cloud API with local
// pure-Dart fallback) to predict a recommendation score based on 7 input features:
//   1. average_rating
//   2. complaint_resolution_rate
//   3. review_volume          (totalReviews)
//   4. num_bookings           (totalBookings)
//   5. proximity              (distance in km from hostel → user's university)
//   6. complaint_freq         (complaint frequency relative to bookings)
//   7. resolution_speed_hrs   (average hours taken to resolve complaints)
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:fyp/models/HostelModel.dart';
import 'package:fyp/services/DynamicHostelScoreModel.dart';
import 'dart:math';

class RankingService {
  RankingService._();

  static const String _renderBatchUrl =
      'https://nestiq-mmht.onrender.com/batch_predict_recommendations';

  // ── University GPS coordinates (lat, lng) ─────────────────────────────────
  // Source: verified coordinates for each supported university campus.
  static const Map<String, _LatLng> _universityCoordinates = {
    // ── Jamshoro ─────────────────────────────────────────────────────────────
    'University of Sindh':
        _LatLng(25.4236, 68.3602),
    'Mehran University of Engineering and Technology (MUET)':
        _LatLng(25.4292, 68.2743),
    'Liaquat University of Medical and Health Sciences (LUMHS)':
        _LatLng(25.4461, 68.3082),
    'Shaheed Allah Buksh Soomro (SABS) University of Art, Design and Heritages':
        _LatLng(25.4300, 68.3600),

    // ── Hyderabad ─────────────────────────────────────────────────────────────
    'Government College University Hyderabad (GCUH)':
        _LatLng(25.3840, 68.3680),
    'Isra University':
        _LatLng(25.3623, 68.3680),
    'Hyderabad Institute for Technology and Management Sciences (HITMS)':
        _LatLng(25.3800, 68.3700),
    'SZABIST Hyderabad Campus':
        _LatLng(25.3692, 68.3647),
    'NUML Hyderabad Campus':
        _LatLng(25.3960, 68.3762),
  };

  // ─────────────────────────────────────────────────────────────────────────
  // Main entry point: score and sort an entire list of hostels.
  // [universityName] — the university the student selected during sign-up.
  // ─────────────────────────────────────────────────────────────────────────
  static List<HostelModel> scoreAndSort(
    List<HostelModel> hostels, {
    String? universityName,
  }) {
    if (hostels.isEmpty) return hostels;

    final uniCoords = universityName != null
        ? _universityCoordinates[universityName]
        : null;

    final scored = hostels.map((h) {
      final double dist = uniCoords != null
          ? _haversineKm(uniCoords.lat, uniCoords.lng, h.latitude, h.longitude)
          : 0.0;
      final score = computeScore(h, dist);
      h.smartScore = score; // Cache it for the UI
      return _ScoredHostel(hostel: h, score: score);
    }).toList();

    // Sort descending by score
    scored.sort((a, b) => b.score.compareTo(a.score));

    return scored.map((s) => s.hostel).toList();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Asynchronous cloud-first scoring via Render API with seamless local fallback
  // ─────────────────────────────────────────────────────────────────────────
  static Future<List<HostelModel>> scoreAndSortAsync(
    List<HostelModel> hostels, {
    String? universityName,
  }) async {
    if (hostels.isEmpty) return hostels;

    final uniCoords = universityName != null
        ? _universityCoordinates[universityName]
        : null;

    try {
      final List<Map<String, dynamic>> items = hostels.map((h) {
        final double dist = uniCoords != null
            ? _haversineKm(uniCoords.lat, uniCoords.lng, h.latitude, h.longitude)
            : 0.0;
        return {
          'id': h.id,
          'average_rating': h.averageRating,
          'complaint_resolution_rate': h.complaintResolutionRate,
          'review_volume': h.totalReviews.toDouble(),
          'num_bookings': h.totalBookings.toDouble(),
          'proximity': dist,
          'complaint_freq': h.complaintFrequency,
          'resolution_speed_hrs': h.resolutionSpeedHours,
        };
      }).toList();

      final response = await http
          .post(
            Uri.parse(_renderBatchUrl),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'hostels': items}),
          )
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final Map<String, dynamic> scores = data['scores'] ?? {};
        for (var h in hostels) {
          if (scores.containsKey(h.id)) {
            h.smartScore = (scores[h.id] as num).toDouble();
          }
        }
        final scoredList = List<HostelModel>.from(hostels);
        scoredList.sort((a, b) => (b.smartScore ?? 0.0).compareTo(a.smartScore ?? 0.0));
        return scoredList;
      }
    } catch (_) {
      // Fallback silently to on-device calculation
    }

    return scoreAndSort(hostels, universityName: universityName);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Run inference — features must match the Python training order:
  //   [average_rating, complaint_resolution_rate, review_volume,
  //    num_bookings, proximity, complaint_freq, resolution_speed_hrs]
  // ─────────────────────────────────────────────────────────────────────────
  static double computeScore(HostelModel h, double distanceKm) {
    final List<double> input = [
      h.averageRating,
      h.complaintResolutionRate,
      h.totalReviews.toDouble(),
      h.totalBookings.toDouble(),
      distanceKm,
      h.complaintFrequency,
      h.resolutionSpeedHours,
    ];

    try {
      final double score = DynamicHostelScoreModel().predict(input);
      return score.clamp(0.0, 100.0);
    } catch (_) {
      return 0.0;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Haversine formula — returns distance in km between two GPS points.
  // ─────────────────────────────────────────────────────────────────────────
  static double _haversineKm(
      double lat1, double lng1, double lat2, double lng2) {
    const double r = 6371.0; // Earth radius in km
    final double dLat = _toRad(lat2 - lat1);
    final double dLng = _toRad(lng2 - lng1);
    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(lat1)) *
            cos(_toRad(lat2)) *
            sin(dLng / 2) *
            sin(dLng / 2);
    return r * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  static double _toRad(double deg) => deg * pi / 180.0;
}

// ── Simple lat/lng value type ─────────────────────────────────────────────────
class _LatLng {
  final double lat;
  final double lng;
  const _LatLng(this.lat, this.lng);
}

class _ScoredHostel {
  final HostelModel hostel;
  final double score;
  const _ScoredHostel({required this.hostel, required this.score});
}
