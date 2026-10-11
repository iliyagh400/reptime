import 'package:flutter/material.dart';

class AppFeedback {
  // پالت دارک تراریوم Reptime (کاملاً منطبق بر پالت پروژه)
  static const Color _ink = Color(0xFFECE8DD);
  static const Color _surfaceRaised = Color(0xFF2D3930);
  static const Color _errorDark = Color(0xFF5A2B28);
  static const Color _forest = Color(0xFF6E8B52);
  static const Color _sand = Color(0xFFC8A66A);

  /// اسنک‌بار موفقیت (سبز/دارک هماهنگ با تراریوم)
  static void showSuccess(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    _showSnackBar(
      context,
      message: message,
      backgroundColor: _surfaceRaised,
      borderColor: _forest.withOpacity(0.4),
      icon: Icons.check_circle_outline_rounded,
      iconColor: _forest,
      duration: duration,
      action: action,
    );
  }

  /// اسنک‌بار خطا (تیره و هماهنگ با تم دارک - بدون کنتراست شدید)
  static void showError(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 4),
    SnackBarAction? action,
  }) {
    _showSnackBar(
      context,
      message: message,
      backgroundColor: _errorDark,
      borderColor: Colors.red.withOpacity(0.3),
      icon: Icons.error_outline_rounded,
      iconColor: const Color(0xFFE57373),
      duration: duration,
      action: action,
    );
  }

  /// اسنک‌بار هشدار یا اطلاعاتی
  static void showWarning(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    _showSnackBar(
      context,
      message: message,
      backgroundColor: _surfaceRaised,
      borderColor: _sand.withOpacity(0.4),
      icon: Icons.info_outline_rounded,
      iconColor: _sand,
      duration: duration,
      action: action,
    );
  }

  /// متد عمومی برای حفظ سازگاری کامل با هلپرهای موجود _showSnack(msg, isError)
  static void show(
    BuildContext context,
    String message, {
    bool isError = false,
    Duration? duration,
    SnackBarAction? action,
  }) {
    if (isError) {
      showError(context, message, duration: duration ?? const Duration(seconds: 4), action: action);
    } else {
      showSuccess(context, message, duration: duration ?? const Duration(seconds: 3), action: action);
    }
  }

  static void _showSnackBar(
    BuildContext context, {
    required String message,
    required Color backgroundColor,
    required Color borderColor,
    required IconData icon,
    required Color iconColor,
    required Duration duration,
    SnackBarAction? action,
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Directionality(
          textDirection: TextDirection.rtl,
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 14,
                    fontFamily: 'Vazirmatn',
                  ),
                ),
              ),
            ],
          ),
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: borderColor, width: 1),
        ),
        duration: duration,
        action: action,
      ),
    );
  }
}
