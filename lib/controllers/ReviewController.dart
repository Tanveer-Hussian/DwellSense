import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:fyp/controllers/AuthController.dart';
import 'package:fyp/models/ReviewModel.dart';
import 'package:fyp/services/ReviewService.dart';
import 'package:fyp/services/hostelService.dart';
import 'package:get/get.dart';
class ReviewController extends GetxController {

  final ReviewService _reviewService = Get.find<ReviewService>();
  final HostelService _hostelService = Get.find<HostelService>();
  final AuthController _authController = Get.find<AuthController>();

  final RxList<ReviewModel> hostelReviews = <ReviewModel>[].obs;
  final RxList<ReviewModel> flaggedReviews = <ReviewModel>[].obs;
  final RxBool isLoading = false.obs;

  // ────────────────────────────────────────────────────────────────────────────
  // FR-6.1: Student submits a review
  // FR-6.3: AI-based suspicious review detection (simple heuristic here)
  // ────────────────────────────────────────────────────────────────────────────
  Future<bool> submitReview({
    required String hostelId,
    required double rating,
    required String comment,
  }) async {
    try {
      isLoading.value = true;

      final student = _authController.currentUser.value!;

      // Check if student has already reviewed
      final alreadyReviewed =
          await _reviewService.hasReviewed(student.uid, hostelId);
      if (alreadyReviewed) {
        Get.snackbar('Already Reviewed', 'You have already reviewed this hostel.');
        return false;
      }

      // ── FR-6.3: Simple fake review detection heuristic ──────────────────
      // Call the NLP REST API backend
      final isSuspicious = await _detectFakeReviewAPI(comment, rating);

      final review = ReviewModel(
        id: '',
        hostelId: hostelId,
        studentId: student.uid,
        studentName: student.name,
        studentImage: student.profileImage,
        rating: rating,
        comment: comment,
        isFlagged: isSuspicious,
        flagReason: isSuspicious ? 'Auto-flagged by NLP AI detector' : null,
        createdAt: DateTime.now(),
      );

      await _reviewService.addReview(review);

      // ── FR-9 Smart Recommendation Protection ───────────────────────────
      // Only legitimate (unflagged) reviews update the hostel's official average rating & review count.
      // Flagged reviews are held for admin moderation without polluting the recommendation model.
      if (!isSuspicious) {
        await _hostelService.updateHostelRating(hostelId, rating);
        Get.snackbar('Review Submitted', 'Thank you for your feedback!');
      } else {
        Get.snackbar(
          'Review Under Moderation',
          'Your review has been submitted and held for moderation by our AI authenticity filter.',
          duration: const Duration(seconds: 4),
        );
      }
      return true;
    } catch (e) {
      Get.snackbar('Error', 'Could not submit review.');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // ────────────────────────────────────────────────────────────────────────────
  // FR-6.3: NLP fake review detection via REST API.
  // Returns true if the review looks suspicious.
  // ────────────────────────────────────────────────────────────────────────────
  Future<bool> _detectFakeReviewAPI(String comment, double rating) async {
    try {
      final response = await http.post(
        Uri.parse('https://nestiq-mmht.onrender.com/predict_review'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'comment': comment,
          'rating': rating,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['is_suspicious'] ?? false;
      }
    } catch (e) {
      print('NLP API Error: $e');
    }
    // Fallback if API fails
    return _detectFakeReviewLocal(comment, rating);
  }

  bool _detectFakeReviewLocal(String comment, double rating) {
    final trimmed = comment.trim();
    // 1. Extreme rating with minimal descriptive detail
    if (trimmed.length < 15 && (rating >= 4.5 || rating <= 1.5)) {
      return true;
    }
    // 2. All-caps shouting/spam
    if (trimmed == trimmed.toUpperCase() && trimmed.length > 20) {
      return true;
    }
    // 3. Repeated character spam (e.g. "soooo", "greeeeat")
    final repeatedChars = RegExp(r'(.)\1{3,}');
    if (repeatedChars.hasMatch(trimmed)) return true;

    // 4. Rating-Sentiment contradiction
    final lower = trimmed.toLowerCase();
    final negWords = ['terrible', 'worst', 'horrible', 'dirty', 'scam', 'bad', 'disaster', 'awful'];
    final posWords = ['excellent', 'amazing', 'best', 'wonderful', 'perfect', 'love', 'superb'];
    final hasNegative = negWords.any((w) => lower.contains(w));
    final hasPositive = posWords.any((w) => lower.contains(w));

    if (rating >= 4.0 && hasNegative && !hasPositive) return true;
    if (rating <= 2.0 && hasPositive && !hasNegative) return true;

    return false;
  }

  void loadHostelReviews(String hostelId) {
    _reviewService
        .getHostelReviewsStream(hostelId)
        .listen((reviews) => hostelReviews.value = reviews);
  }

  void loadFlaggedReviews() {
    _reviewService
        .getFlaggedReviewsStream()
        .listen((reviews) => flaggedReviews.value = reviews);
  }

    // Delete a review (admin action)
  Future<void> deleteReview(String reviewId) async {
    await _reviewService.deleteReview(reviewId);
    Get.snackbar('Deleted', 'Review removed.');
  }

  // Approve a previously flagged review (mark as legitimate)
  Future<void> approveReview(String reviewId, {String? hostelId, double? rating}) async {
    await _reviewService.approveReview(reviewId);
    if (hostelId != null && rating != null) {
      await _hostelService.updateHostelRating(hostelId, rating);
    }
    Get.snackbar('Approved', 'Review approved as legitimate.');
  }

}
