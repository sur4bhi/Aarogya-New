import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/animations.dart';

class SosFab extends StatelessWidget {
  final VoidCallback onPressed;
  const SosFab({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final fab = SizedBox(
      height: 64,
      width: 64,
      child: FloatingActionButton(
        heroTag: 'sos_fab',
        onPressed: onPressed,
        backgroundColor: AppColors.error,
        child: const Icon(Icons.emergency, color: Colors.white, size: 28),
      ),
    );
    return Pulse(child: fab);
  }
}
