import 'package:flutter/material.dart';

/// Error boundary widget that catches errors and displays a fallback UI
class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final Widget Function? fallback;

  const ErrorBoundary({
    super.key,
    required this.child,
    this.fallback,
  });

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();

class _ErrorBoundaryState extends State<ErrorBoundary> {
  @override
  Widget build(BuildContext context) {
    return ErrorBoundaryData(
      child: child,
      fallback: fallback ?? const Center(child: const Text('Something went wrong')),
    );
  }
}

class ErrorFallback extends StatelessWidget {
  final String message;

  const ErrorFallback({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.red.shade(700),
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
  }
}
