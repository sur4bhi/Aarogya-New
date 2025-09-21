import 'package:flutter/material.dart';
import '../../core/constants.dart';

class CustomButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isPrimary;
  final bool fullWidth;

  const CustomButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isPrimary = true,
    this.fullWidth = true,
  });

  @override
  Widget build(BuildContext context) {
    final child = Center(
      child: Text(
        label,
        style: AppTextStyles.button.copyWith(color: isPrimary ? Colors.white : AppColors.primary),
      ),
    );

    if (isPrimary) {
      // Gradient primary button per spec
      return InkWell(
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLarge),
        onTap: onPressed,
        child: Ink(
          decoration: BoxDecoration(
            gradient: AppGradients.primary,
            borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLarge),
          ),
          height: AppDimensions.buttonHeight,
          width: fullWidth ? double.infinity : null,
          child: child,
        ),
      );
    } else {
      // Secondary outlined button per spec
      return Container(
        height: AppDimensions.buttonHeight,
        width: fullWidth ? double.infinity : null,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLarge),
          border: Border.all(color: AppColors.primary, width: 1),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLarge),
            onTap: onPressed,
            child: child,
          ),
        ),
      );
    }
  }
}
