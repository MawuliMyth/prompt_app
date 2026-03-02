import 'package:flutter/material.dart';

/// A banner that displays when the app is offline
class OfflineBanner extends StatelessWidget {
  final Void Function? onRetry;

  const OfflineBanner({
    super.key,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.orange.shade(100),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off, color: Colors.orange),
            const SizedBox(height: 8),
            Text(
              'You are offline',
              style: TextStyle(
                color: Colors.orange.shade(700),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            if (onRetry != null)
              ElevatedButton(
                onPressed: onRetry,
                child: const Text('Retry'),
              )
          else
            const Text('Check your connection'),
          ],
        ],
      ),
    );
  }
}
