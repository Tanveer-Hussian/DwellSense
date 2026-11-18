// lib/views/shared Widgets/CustomButtons.dart
// ─────────────────────────────────────────────────────────────────────────────
// Reusable adaptive button that shows a loading spinner when isLoading is true.
// Automatically adjusts padding, height, and typography on Web vs Mobile.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:fyp/utils/AppColors.dart';
import 'package:fyp/utils/Responsive.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color? backgroundColor;
  final Color? textColor;
  final IconData? icon;
  final bool outlined;
  final double? width;
  final double? height;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.backgroundColor,
    this.textColor,
    this.icon,
    this.outlined = false,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveOnPressed = isLoading ? null : onPressed;
    final isWide = Responsive.isWide(context);
    final effectiveHeight = height ?? (isWide ? 42.0 : 48.0);
    final effectiveFontSize = isWide ? 13.5 : 15.0;
    final iconSize = isWide ? 16.0 : 18.0;

    Widget childContent = isLoading
        ? SizedBox(
            height: isWide ? 18 : 20,
            width: isWide ? 18 : 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: outlined ? AppColors.primary : Colors.white,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: iconSize),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: effectiveFontSize,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          );

    final buttonStyle = outlined
        ? OutlinedButton.styleFrom(
            padding: EdgeInsets.symmetric(
              horizontal: isWide ? 18 : 22,
              vertical: isWide ? 10 : 13,
            ),
            side: BorderSide(color: backgroundColor ?? AppColors.primary, width: 1.5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          )
        : ElevatedButton.styleFrom(
            backgroundColor: backgroundColor ?? AppColors.primary,
            foregroundColor: textColor ?? Colors.white,
            padding: EdgeInsets.symmetric(
              horizontal: isWide ? 18 : 22,
              vertical: isWide ? 10 : 13,
            ),
            elevation: isWide ? 1 : 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          );

    return SizedBox(
      width: width,
      height: effectiveHeight,
      child: outlined
          ? OutlinedButton(
              onPressed: effectiveOnPressed,
              style: buttonStyle,
              child: childContent,
            )
          : ElevatedButton(
              onPressed: effectiveOnPressed,
              style: buttonStyle,
              child: childContent,
            ),
    );
  }
}
