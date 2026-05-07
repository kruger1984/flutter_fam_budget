import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:talker/talker.dart';
import 'package:toastification/toastification.dart';
import '../utils/talker_pod.dart';

part 'notification_service.g.dart';

class NotificationService {
  NotificationService(this._talker);

  final Talker _talker;

  void showSuccess({
    required BuildContext context,
    required String title,
    String? description,
  }) {
    _talker.info('🔔 Success Toast: $title');
    _showWithBarrier(
      context: context,
      type: ToastificationType.success,
      title: title,
      description: description,
      iconData: Icons.check_circle_outline_rounded,
      primaryColor: Colors.green,
    );
  }

  void showError({
    required BuildContext context,
    required String title,
    String? description,
  }) {
    _talker.error('🚨 Error Toast: $title');
    _showWithBarrier(
      context: context,
      type: ToastificationType.error,
      title: title,
      description: description,
      iconData: Icons.error_outline_rounded,
      primaryColor: Colors.red,
    );
  }

  void _showWithBarrier({
    required BuildContext context,
    required ToastificationType type,
    required String title,
    required IconData iconData,
    required Color primaryColor,
    String? description,
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry barrierEntry;

    // Створюємо Barrier
    barrierEntry = OverlayEntry(
      builder: (_) => const ModalBarrier(
        color: Colors.black54,
        dismissible: false,
      ),
    );

    overlay.insert(barrierEntry);

    toastification.show(
      context: context,
      type: type,
      style: ToastificationStyle.flat,
      autoCloseDuration: const Duration(seconds: 3),
      title: Text(
        title,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      description: description != null ? Text(description) : null,
      alignment: Alignment.topCenter,

      icon: Icon(iconData, color: primaryColor, size: 28),
      primaryColor: primaryColor,
      backgroundColor: const Color(0xFF89BBBE),
      borderRadius: BorderRadius.circular(24),
      showProgressBar: false,
      callbacks: ToastificationCallbacks(
        onDismissed: (_) {

          if (barrierEntry.mounted) barrierEntry.remove();
        },
      ),
    );
  }
}

@Riverpod(keepAlive: true)
NotificationService notificationService(Ref ref) {
  return NotificationService(ref.watch(talkerProvider));
}