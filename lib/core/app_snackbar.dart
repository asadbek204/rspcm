import 'dart:convert';
import 'package:flutter/material.dart';

class AppSnackbar {
  static final GlobalKey<ScaffoldMessengerState> messengerKey =
      GlobalKey<ScaffoldMessengerState>();

  /// Extracts the backend `message` field from the exception string.
  /// Exception format: "... Server Error (NNN): {\"message\":\"...\", ...}"
  static String parseBackendMessage(Object e) {
    final raw = e.toString();
    final jsonStart = raw.indexOf('{');
    if (jsonStart != -1) {
      try {
        final decoded = jsonDecode(raw.substring(jsonStart));
        if (decoded is Map && decoded['message'] != null) {
          return decoded['message'].toString();
        }
      } catch (_) {}
    }
    if (raw.contains('401') || raw.contains('Unauthorized')) {
      return 'Необходима авторизация';
    }
    if (raw.contains('403') || raw.contains('Forbidden')) {
      return 'Доступ запрещён';
    }
    if (raw.contains('Network error') || raw.contains('SocketException')) {
      return 'Нет соединения с сервером';
    }
    return 'Произошла ошибка. Попробуйте ещё раз.';
  }

  static void showError(Object e) {
    messengerKey.currentState
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  parseBackendMessage(e),
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 4),
        ),
      );
  }

  static void showSuccess(String message) {
    messengerKey.currentState
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_outline,
                  color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Expanded(child: Text(message, style: const TextStyle(fontSize: 14))),
            ],
          ),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 3),
        ),
      );
  }
}
