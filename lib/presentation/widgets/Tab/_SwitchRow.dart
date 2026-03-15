import 'package:flutter/material.dart';

class SwitchRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const SwitchRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          Switch(
            value: value,
            activeColor: Colors.purpleAccent,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}