import 'package:flutter/material.dart';

class OfflineBanner extends StatelessWidget {
  final bool isOnline;
  const OfflineBanner({super.key, required this.isOnline});

  @override
  Widget build(BuildContext context) {
    if (isOnline) return const SizedBox.shrink();
    return Container(
      color: Colors.red,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: const SafeArea(
        bottom: false,
        child: Text('You are offline', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}
