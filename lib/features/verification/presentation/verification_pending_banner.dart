import 'package:flutter/material.dart';

class VerificationPendingBanner extends StatelessWidget {
  const VerificationPendingBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9E6), // Soft warning yellow
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFFD4AF37).withOpacity(0.4),
            width: 1.0,
          ),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: Color(0xFFD4AF37), size: 20.0),
          const SizedBox(width: 12.0),
          const Expanded(
            child: Text(
              'Your Account is under review will be active soon.',
              style: TextStyle(
                color: Color(0xFF5E0B24),
                fontWeight: FontWeight.w600,
                fontSize: 13.0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
