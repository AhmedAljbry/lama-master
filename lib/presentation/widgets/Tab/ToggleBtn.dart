import 'package:flutter/material.dart';

class ToggleBtn extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const ToggleBtn({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(horizontal: 6),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? Colors.purpleAccent : Colors.white10,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isActive ? Colors.purpleAccent : Colors.white24,
              width: isActive ? 2 : 1,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}