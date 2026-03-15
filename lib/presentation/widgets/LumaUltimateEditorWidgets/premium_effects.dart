import 'package:flutter/material.dart';

class PremiumEffects {
  static const List<double> cinematicDramatic = [
    1.2, -0.1, -0.1, 0, 10,
    -0.1, 1.2, -0.1, 0, 10,
    -0.2, -0.2, 1.4, 0, -10,
    0, 0, 0, 1, 0,
  ];

  static const List<double> vintageWarm = [
    1.1, 0.1, 0.0, 0, 20,
    0.0, 1.0, 0.0, 0, 10,
    0.0, -0.1, 0.9, 0, -15,
    0, 0, 0, 1, 0,
  ];

  static const List<double> coolNight = [
    0.9, 0.0, 0.1, 0, -10,
    0.0, 0.95, 0.1, 0, 0,
    -0.1, 0.0, 1.2, 0, 25,
    0, 0, 0, 1, 0,
  ];

  static const List<double> goldenGlow = [
    1.15, 0.1, 0.0, 0, 30,
    0.1, 1.05, 0.0, 0, 15,
    0.0, 0.0, 0.85, 0, -20,
    0, 0, 0, 1, 0,
  ];

  static const List<double> matrixGreen = [
    0.8, 0.0, 0.0, 0, -10,
    0.0, 1.3, 0.0, 0, 20,
    0.0, 0.0, 0.8, 0, -10,
    0, 0, 0, 1, 0,
  ];

  static const List<double> cyberpunk = [
    1.3, -0.2, 0.2, 0, 20,
    -0.2, 0.8, 0.4, 0, -10,
    0.2, -0.2, 1.5, 0, 40,
    0, 0, 0, 1, 0,
  ];

  static const List<Map<String, dynamic>> allEffects = [
    {'name': 'دراماتيكي', 'matrix': cinematicDramatic, 'color': Colors.redAccent},
    {'name': 'كلاسيك دافئ', 'matrix': vintageWarm, 'color': Colors.orangeAccent},
    {'name': 'ليلي بارد', 'matrix': coolNight, 'color': Colors.lightBlueAccent},
    {'name': 'توهج ذهبي', 'matrix': goldenGlow, 'color': Colors.amber},
    {'name': 'ماتريكس', 'matrix': matrixGreen, 'color': Colors.greenAccent},
    {'name': 'سايبربانك', 'matrix': cyberpunk, 'color': Colors.purpleAccent},
  ];
}