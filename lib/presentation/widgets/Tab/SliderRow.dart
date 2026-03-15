import 'package:flutter/material.dart';

class SliderRow extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  const SliderRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final safeValue = value.clamp(min, max);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: Colors.purpleAccent,
                inactiveTrackColor: Colors.white12,
                thumbColor: Colors.purpleAccent,
                overlayColor: Colors.purpleAccent.withOpacity(0.15),
                trackHeight: 3,
              ),
              child: Slider(
                value: safeValue,
                min: min,
                max: max,
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }
}