import 'package:flutter/material.dart';

class LanguageSelector extends StatelessWidget {
  final void Function(String code) onSelected;
  const LanguageSelector({super.key, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TextButton(onPressed: () => onSelected('en'), child: const Text('EN')),
        TextButton(onPressed: () => onSelected('hi'), child: const Text('HI')),
        TextButton(onPressed: () => onSelected('mr'), child: const Text('MR')),
      ],
    );
  }
}
