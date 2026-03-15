import 'package:flutter/material.dart';

class EmptyState extends StatelessWidget {
  final VoidCallback onTap;
  const EmptyState({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: Colors.white10,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white24),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_photo_alternate, size: 50, color: Colors.white54),
              SizedBox(height: 10),
              Text("Open Gallery", style: TextStyle(color: Colors.white54)),
            ],
          ),
        ),
      ),
    );
  }
}