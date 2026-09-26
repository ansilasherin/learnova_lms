import 'package:flutter/material.dart';
import '../../core/constants/app_styles.dart';
import '../common/custom_button.dart';

class CelebrationDialog extends StatelessWidget {
  final String studentName;
  final String message;
  final int percentage;
  final VoidCallback onDismiss;

  const CelebrationDialog({
    super.key,
    required this.studentName,
    this.message = 'You have completed 80% of your goals.',
    this.percentage = 80,
    required this.onDismiss,
  });

  static void show(
    BuildContext context, {
    required String studentName,
    String message = 'You have completed 80% of your goals.',
    int percentage = 80,
    VoidCallback? onDismiss,
  }) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => CelebrationDialog(
        studentName: studentName,
        message: message,
        percentage: percentage,
        onDismiss: onDismiss ?? () => Navigator.pop(context),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        width: 360,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2E1065), Color(0xFF1E1B4B)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.purple.withOpacity(0.3),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Floating Golden Trophy
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.12), width: 1.5),
              ),
              child: const Icon(
                Icons.emoji_events_rounded,
                size: 72,
                color: Color(0xFFFBBF24),
              ),
            ),
            const SizedBox(height: 24),

            // Congratulations text
            Text(
              'Great Work,\n$studentName! 🎉',
              textAlign: TextAlign.center,
              style: AppStyles.heading1.copyWith(
                color: Colors.white,
                fontSize: 24,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppStyles.bodyMedium.copyWith(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 28),

            // Action Button
            CustomButton(
              text: 'View Achievements',
              backgroundColor: Colors.white,
              textColor: const Color(0xFF1E1B4B),
              onPressed: () {
                Navigator.pop(context);
                onDismiss();
              },
            ),
          ],
        ),
      ),
    );
  }
}
