import 'package:flutter/material.dart';
import 'package:lama/presentation/widgets/Tab/SliderRow.dart';
import 'package:lama/presentation/widgets/Tab/_LeakBtn.dart';
import 'package:lama/presentation/widgets/Tab/_SwitchRow.dart';
import 'package:lama/presentation/widgets/bottom_controls.dart';

class _OverlaysTab extends StatelessWidget {
  final bool showDateStamp;
  final bool cinemaMode;
  final bool polaroidFrame;
  final double vignette;
  final int lightLeakIndex;
  final OnParamChanged onParamChanged;

  const _OverlaysTab({
    required this.showDateStamp,
    required this.cinemaMode,
    required this.polaroidFrame,
    required this.vignette,
    required this.lightLeakIndex,
    required this.onParamChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        SwitchRow(
          label: "Date Stamp",
          value: showDateStamp,
          onChanged: (v) => onParamChanged("showDateStamp", v),
        ),
        SwitchRow(
          label: "Cinema Bar",
          value: cinemaMode,
          onChanged: (v) => onParamChanged("cinemaMode", v),
        ),
        SwitchRow(
          label: "Polaroid",
          value: polaroidFrame,
          onChanged: (v) => onParamChanged("polaroidFrame", v),
        ),
        SliderRow(
          label: "Vignette",
          value: vignette,
          min: 0,
          max: 0.8,
          onChanged: (v) => onParamChanged("vignette", v),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            LeakBtn(label: "None", index: 0, selectedIndex: lightLeakIndex, onTap: (i) => onParamChanged("lightLeakIndex", i)),
            LeakBtn(label: "Warm", index: 1, selectedIndex: lightLeakIndex, onTap: (i) => onParamChanged("lightLeakIndex", i)),
            LeakBtn(label: "Cool", index: 2, selectedIndex: lightLeakIndex, onTap: (i) => onParamChanged("lightLeakIndex", i)),
          ],
        ),
      ],
    );
  }
}