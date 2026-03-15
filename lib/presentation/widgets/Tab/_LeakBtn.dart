import 'package:flutter/material.dart';

class LeakBtn extends StatelessWidget {
  final String label;
  final int index;
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const LeakBtn({
    required this.label,
    required this.index,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = selectedIndex == index;

    return GestureDetector(
      onTap: () => onTap(index),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.purpleAccent : Colors.white10,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.purpleAccent : Colors.white24,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}