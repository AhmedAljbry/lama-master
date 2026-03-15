import 'package:flutter/material.dart';
import 'package:lama/ProFilterStudio1.dart';

class _PresetsTab extends StatelessWidget {
  final Map<AppPreset, PresetConfig> presets;
  final AppPreset selectedPreset;
  final ValueChanged<AppPreset> onPresetSelected;

  const _PresetsTab({
    required this.presets,
    required this.selectedPreset,
    required this.onPresetSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      scrollDirection: Axis.horizontal,
      children: presets.keys.map((preset) {
        final config = presets[preset]!;
        final isSelected = selectedPreset == preset;

        return GestureDetector(
          onTap: () => onPresetSelected(preset),
          child: Container(
            width: 80,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: isSelected ? Colors.white : Colors.white10,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? Colors.purpleAccent : Colors.white12,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  config.icon,
                  color: isSelected ? Colors.black : Colors.white70,
                  size: 28,
                ),
                const SizedBox(height: 6),
                Text(
                  config.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isSelected ? Colors.black : Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}