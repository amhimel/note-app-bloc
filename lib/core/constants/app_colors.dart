import 'package:flutter/material.dart';


class AppColors {
  AppColors._(); 

  // --- Background Colors ---
  static const Color scaffoldBg = Color(0xFF252525); // Main background
  static const Color surfaceBg = Color(0xFF3B3B3B); // Card/Dialog background
  static const Color black = Color(0xFF000000);

  // --- Note Card Colors (6টি রং পর্যায়ক্রমে assign হবে) ---
  static const Color notePink = Color(0xFFFD99FF);
  static const Color noteSalmon = Color(0xFFFF9E9E);
  static const Color noteGreen = Color(0xFF91F48F);
  static const Color noteYellow = Color(0xFFFFF599);
  static const Color noteCyan = Color(0xFF9EFFFF);
  static const Color notePurple = Color(0xFFB69CFF);

  // Note card colors একটি list এ রাখা হলো
  // যাতে index দিয়ে সহজে pick করা যায়
  static const List<Color> noteColors = [
    notePink,
    noteSalmon,
    noteGreen,
    noteYellow,
    noteCyan,
    notePurple,
  ];

  // --- Action Colors ---
  static const Color discardRed = Color(0xFFFF0000); // Discard button
  static const Color saveGreen = Color(0xFF30BE71); // Save button

  // --- Text Colors ---
  static const Color textWhite = Colors.white;
  static const Color textDark = Color(0xFF1A1A1A); // Note card এর উপর text
  static const Color textHint = Color(0xFF888888); // Placeholder text

  // --- Icon/Button Background ---
  static const Color iconBg = Color(0xFF3B3B3B);
  static const Color searchBarBg = Color(0xFF3B3B3B);
}
