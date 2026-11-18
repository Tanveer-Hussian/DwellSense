// ─────────────────────────────────────────────────────────────────────────────
// Card widget to display a hostel summary in the search/browse list.
// Adapts cleanly between Mobile (compact card) and Web (interactive desktop card).
// ─────────────────────────────────────────────────────────────────────────────

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:fyp/utils/AppColors.dart';
import 'package:fyp/utils/Responsive.dart';
import 'package:fyp/views/shared%20Widgets/PlaceHolderImage.dart';
import 'package:shimmer/shimmer.dart';

class HostelCard extends StatelessWidget {
  final dynamic hostel; // HostelModel
  final VoidCallback onTap;

  const HostelCard({super.key, required this.hostel, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // ── On Web / Desktop: modern interactive card with hover effects ──────────
    if (Responsive.isWide(context)) {
      return _WebHostelCard(hostel: hostel, onTap: onTap);
    }

    // ── On Mobile: preserve original mobile layout 100% ──────────────────────
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Card(
          clipBehavior: Clip.antiAlias, // rounded corners clip the image
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Hostel Image with Hero Transition & Shimmer ───────────────
              SizedBox(
                height: 160,
                width: double.infinity,
                child: Hero(
                  tag: 'hostel-img-${hostel.id}',
                  child: Material(
                    type: MaterialType.transparency,
                    child: hostel.images.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: hostel.images[0],
                            fit: BoxFit.cover,
                            placeholder: (ctx, url) => Shimmer.fromColors(
                              baseColor: Colors.grey.shade300,
                              highlightColor: Colors.grey.shade100,
                              child: Container(color: Colors.white),
                            ),
                            errorWidget: (ctx, err, stack) =>
                                PlaceholderImage(),
                          )
                        : PlaceholderImage(),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Name & Rating ───────────────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            hostel.name,
                            style: Theme.of(context).textTheme.titleLarge,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Rating badge
                        Row(
                          children: [
                            const Icon(Icons.star,
                                size: 16, color: Colors.amber),
                            const SizedBox(width: 4),
                            Text(
                              hostel.averageRating.toStringAsFixed(1),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              ' (${hostel.totalReviews})',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // ── Location & Registration No ────────────────────────────
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            hostel.city,
                            style: Theme.of(context).textTheme.bodyMedium,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (hostel.registrationNumber != null &&
                            (hostel.registrationNumber as String).isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                  color: AppColors.primary.withValues(alpha: 0.3)),
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
                    ),
                    const SizedBox(height: 8),

                    // ── Rent & Gender ───────────────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'PKR ${hostel.rentPerMonth.toStringAsFixed(0)}/mo',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        // Gender preference chip
                        Builder(builder: (context) {
                          final isDark =
                              Theme.of(context).brightness == Brightness.dark;
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.primary.withValues(alpha: 0.25)
                                  : AppColors.primaryLight.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              hostel.genderPreference,
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark
                                    ? AppColors.primaryLight
                                    : AppColors.primaryDark,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // ── Availability ────────────────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              hostel.isAvailable
                                  ? Icons.check_circle_outline
                                  : Icons.cancel_outlined,
                              size: 14,
                              color: hostel.isAvailable
                                  ? AppColors.success
                                  : AppColors.error,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              hostel.isAvailable
                                  ? '${hostel.availableRooms} rooms available'
                                  : 'No rooms available',
                              style: TextStyle(
                                fontSize: 12,
                                color: hostel.isAvailable
                                    ? AppColors.success
                                    : AppColors.error,
                              ),
                            ),
                          ],
                        ),
                        // ML Score
                        if (hostel.smartScore != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Score: ${hostel.smartScore!.toStringAsFixed(0)}/100',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.amber,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Desktop / Web Card with Hover & Clean Layout ─────────────────────────────
class _WebHostelCard extends StatefulWidget {
  final dynamic hostel;
  final VoidCallback onTap;

  const _WebHostelCard({required this.hostel, required this.onTap});

  @override
  State<_WebHostelCard> createState() => _WebHostelCardState();
}

class _WebHostelCardState extends State<_WebHostelCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final hostel = widget.hostel;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E242B) : Colors.white;
    final borderColor = _isHovered
        ? AppColors.primary.withValues(alpha: 0.6)
        : (isDark ? const Color(0xFF2C3238) : const Color(0xFFE2E8F0));
    final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          transform: Matrix4.translationValues(0, _isHovered ? -5 : 0, 0),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: _isHovered ? 1.5 : 1.0),
            boxShadow: [
              BoxShadow(
                color: _isHovered
                    ? AppColors.primary.withValues(alpha: 0.2)
                    : Colors.black.withValues(alpha: isDark ? 0.35 : 0.05),
                blurRadius: _isHovered ? 18 : 8,
                offset: Offset(0, _isHovered ? 8 : 3),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Image with Badges Overlay ─────────────────────────────────
              Stack(
                children: [
                  SizedBox(
                    height: 190,
                    width: double.infinity,
                    child: Hero(
                      tag: 'hostel-img-${hostel.id}',
                      child: hostel.images.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: hostel.images[0],
                              fit: BoxFit.cover,
                              placeholder: (ctx, url) => Shimmer.fromColors(
                                baseColor: isDark
                                    ? Colors.grey.shade800
                                    : Colors.grey.shade300,
                                highlightColor: isDark
                                    ? Colors.grey.shade700
                                    : Colors.grey.shade100,
                                child: Container(color: cardBg),
                              ),
                              errorWidget: (ctx, err, stack) =>
                                  PlaceholderImage(),
                            )
                          : PlaceholderImage(),
                    ),
                  ),
                  // Subtle top & bottom shadow gradients for badge readability
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.4),
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.45),
                          ],
                          stops: const [0.0, 0.45, 1.0],
                        ),
                      ),
                    ),
                  ),
                  // Gender Badge (Top Left)
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white24, width: 0.8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            hostel.genderPreference == 'Male' ||
                                    hostel.genderPreference == 'Male Only'
                                ? Icons.male_rounded
                                : hostel.genderPreference == 'Female' ||
                                        hostel.genderPreference == 'Female Only'
                                    ? Icons.female_rounded
                                    : Icons.people_outline,
                            color: Colors.white,
                            size: 13,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            hostel.genderPreference,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Rating Badge (Top Right)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white24, width: 0.8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_rounded,
                              size: 14, color: Colors.amber),
                          const SizedBox(width: 3),
                          Text(
                            hostel.averageRating.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          if (hostel.totalReviews > 0)
                            Text(
                              ' (${hostel.totalReviews})',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  // ML Smart Score Badge (Bottom Right)
                  if (hostel.smartScore != null)
                    Positioned(
                      bottom: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF006D77).withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.white30, width: 0.8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.auto_awesome,
                                size: 11, color: Colors.amber),
                            const SizedBox(width: 4),
                            Text(
                              'Score ${hostel.smartScore!.toStringAsFixed(0)}/100',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),

              // ── Card Details Body ─────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title & Registration Number
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            hostel.name,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: titleColor,
                              letterSpacing: -0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (hostel.registrationNumber != null &&
                            (hostel.registrationNumber as String).isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                  color:
                                      AppColors.primary.withValues(alpha: 0.25)),
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
                    ),
                    const SizedBox(height: 5),

                    // Location
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined,
                            size: 14, color: subColor),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${hostel.city} · ${hostel.address}',
                            style: TextStyle(
                              fontSize: 12,
                              color: subColor,
                              fontWeight: FontWeight.w400,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Divider(
                        color: borderColor.withValues(alpha: 0.7), height: 1),
                    const SizedBox(height: 10),

                    // Price & Availability
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'PKR ${hostel.rentPerMonth.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                                letterSpacing: -0.3,
                              ),
                            ),
                            Text(
                              'per month',
                              style: TextStyle(
                                fontSize: 10,
                                color: subColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: hostel.isAvailable
                                ? const Color(0xFF2D9D5A).withValues(alpha: 0.1)
                                : const Color(0xFFE63946).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: hostel.isAvailable
                                  ? const Color(0xFF2D9D5A).withValues(alpha: 0.3)
                                  : const Color(0xFFE63946).withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: hostel.isAvailable
                                      ? const Color(0xFF2D9D5A)
                                      : const Color(0xFFE63946),
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                hostel.isAvailable
                                    ? '${hostel.availableRooms} rooms free'
                                    : 'Full',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: hostel.isAvailable
                                      ? const Color(0xFF2D9D5A)
                                      : const Color(0xFFE63946),
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
            ],
          ),
        ),
      ),
    );
  }
}
