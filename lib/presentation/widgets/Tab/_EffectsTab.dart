import 'package:flutter/material.dart';
import 'package:lama/presentation/widgets/Tab/SliderRow.dart';
import 'package:lama/presentation/widgets/Tab/ToggleBtn.dart';
import 'package:lama/presentation/widgets/bottom_controls.dart';

class _EffectsTab extends StatelessWidget {
  final double blur;
  final double aura;
  final Color auraColor;
  final double grain;
  final double scanlines;
  final double glitch;
  final bool ghost;
  final bool colorPop;
  final OnParamChanged onParamChanged;

  const _EffectsTab({
    required this.blur,
    required this.aura,
    required this.auraColor,
    required this.grain,
    required this.scanlines,
    required this.glitch,
    required this.ghost,
    required this.colorPop,
    required this.onParamChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        SliderRow(
          label: "Blur",
          value: blur,
          min: 0,
          max: 20,
          onChanged: (v) => onParamChanged("blur", v),
        ),
        SliderRow(
          label: "Aura",
          value: aura,
          min: 0,
          max: 1.0,
          onChanged: (v) => onParamChanged("aura", v),
        ),

        if (aura > 0)
          Row(
            children: [
              Colors.purpleAccent,
              Colors.blueAccent,
              Colors.greenAccent,
              Colors.redAccent,
              Colors.white,
            ].map((c) {
              final selected = c.value == auraColor.value;
              return GestureDetector(
                onTap: () => onParamChanged("auraColor", c),
                child: Container(
                  margin: const EdgeInsets.all(6),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: c,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: selected ? 3 : 1,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

        SliderRow(
          label: "Grain",
          value: grain,
          min: 0,
          max: 0.5,
          onChanged: (v) => onParamChanged("grain", v),
        ),

        SliderRow(
          label: "Scanlines",
          value: scanlines,
          min: 0,
          max: 0.8,
          onChanged: (v) => onParamChanged("scanlines", v),
        ),

        SliderRow(
          label: "Glitch",
          value: glitch,
          min: 0,
          max: 5.0,
          onChanged: (v) => onParamChanged("glitch", v),
        ),

        const SizedBox(height: 10),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ToggleBtn(
              label: "Ghost",
              isActive: ghost,
              onTap: () => onParamChanged("ghost", !ghost),
            ),
            ToggleBtn(
              label: "Color Pop",
              isActive: colorPop,
              onTap: () => onParamChanged("colorPop", !colorPop),
            ),
          ],
        ),
      ],
    );
  }
}