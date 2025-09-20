import 'package:flutter/material.dart';
import '../../core/constants.dart';

class CustomButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isPrimary;

  const CustomButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isPrimary = true,
  });

  @override
  Widget build(BuildContext context) {
    final style = isPrimary
        ? ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, AppDimensions.buttonHeight))
        : OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, AppDimensions.buttonHeight));

    return isPrimary
        ? ElevatedButton(onPressed: onPressed, style: style, child: Text(label))
        : OutlinedButton(onPressed: onPressed, style: style, child: Text(label));
  }
}
