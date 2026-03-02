import 'package:flutter/material.dart';

/// A compact banner that displays when the app is offline
class OfflineBanner extends StatelessWidget {
  final VoidCallback? onRetry;

  const OfflineBanner({
    super.key,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFFE0B2), // orange.shade100
      child: SafeArea(
        bottom: false,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wifi_off, color: Color(0xFFE65100), size: 18), // orange.shade800
              const SizedBox(width: 8),
              const Text(
                'You are offline',
                style: TextStyle(
                  color: Color(0xFFBF360C), // orange.shade900
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
              if (onRetry != null) ...[
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: onRetry,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE65100), // orange.shade800
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Retry',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
